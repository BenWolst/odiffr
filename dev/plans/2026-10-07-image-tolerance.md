# Image-level Tolerance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add opt-in `max_diff_percent` / `max_diff_pixels` arguments that let a small pixel difference pass, recorded as `reason = "within-tolerance"`, across `compare_images()` and everything built on it.

**Architecture:** Tolerance is a verdict applied in `compare_images()` after `odiff_run()` (which stays factual), by one internal function `.apply_tolerance()`. Batch, directory, PDF and `snapshot_report()` functions inherit it through `...`; the testthat helpers get named arguments. Consumers (summary, Markdown, approval, audit) get small, targeted updates.

**Tech Stack:** R (>= 4.1), testthat 3e, withr, roxygen2 8.1.0, odiff CLI.

**Spec:** `dev/specs/2026-10-07-image-tolerance-design.md`

## Global Constraints

- Defaults: `max_diff_percent = NULL`, `max_diff_pixels = NULL` (off). Existing behaviour must not change when both are `NULL`.
- `max_diff_percent`: `NULL` or a single finite number in `[0, 100]`. `max_diff_pixels`: `NULL` or a single finite non-negative whole number. Invalid values error up front.
- Limits are inclusive (`<=`); when both are set, both must hold.
- Only `reason == "pixel-diff"` with a non-`NA` `diff_count` can be tolerated, and only when both images' dimensions are known and equal. Unknown dimensions: not tolerated.
- A tolerated result: `match = TRUE`, `reason = "within-tolerance"`, `diff_count`, `diff_percentage`, `diff_output` unchanged.
- `odiff_run()` is not changed.
- No tolerance in `odiff_preset()`; no global option.
- Never name internal functions with a leading dot *if they need mocking from tests*: `.apply_tolerance()` and `.image_dimensions()` are mocked via `testthat::local_mocked_bindings(..., .package = "odiffr")`, which works for them (existing tests already mock `.image_dimensions` and `.run_odiff`).
- Tests use `withr::local_tempdir()` / `on.exit(unlink(...), add = TRUE)`, never touch the real user cache or options, and keep diff images out of the source tree (`withr::local_options(odiffr.diff_dir = withr::local_tempdir())` or `odiffr.save_diff = FALSE`).
- Commits: plain messages, no AI attribution lines (user's global instruction).
- Run tests with `R --vanilla --quiet -e 'devtools::test()'`; a single file with `R --vanilla --quiet -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/<file>")'`.

## Review Focus

1. **Plot and magick-image inputs.** `compare_images()` renders these to temporary PNGs that are deleted on exit; `.apply_tolerance()` must read dimensions before that. Expect a tolerance to apply to two plots of the same size. Test in Task 2.
2. **Size change on odiff >= 4.3.5 with `fail_on_layout = FALSE`.** odiff reports a `pixel-diff` with a count; even `max_diff_percent = 100` must not pass it. The local odiff may be 4.2.1, so this needs a mocked newer odiff. Test in Task 2.
3. **Parallel batches.** `compare_images_batch(parallel = TRUE)` forks with `mclapply()` on Unix; the tolerance arguments must reach each worker through `...`. Test in Task 2.
4. **Summary objects without the new field.** `print()` of an `odiffr_batch_summary` built before this change (no `tolerated` element) must still work. Test in Task 4.
5. **`expect_images_match()` after a previous failing run.** A stale diff image from an earlier failure must not survive a later pass within tolerance. Test in Task 3.

---

### Task 0: Prepare the branch

**Files:** none changed except by rebase.

- [ ] **Step 1: Wait for PR #22 to merge, then rebase.** PR #22 changes `R/summary.R`, `R/ci-output.R`, `R/expect.R`, `R/snapshot.R`, `R/report.R` and `NEWS.md`, which this plan also edits.

```bash
git checkout feature/image-tolerance
git fetch origin
git rebase origin/main
```

Expected: clean rebase (this branch only adds `dev/` and a `.Rbuildignore` line so far).

- [ ] **Step 2: Upgrade roxygen2 to 8.1.0 (needs the user's OK; it changes their R library).** The repo's Rd files were generated with roxygen2 8.1.0 (`Config/roxygen2/version: 8.1.0` in DESCRIPTION); 7.3.3 rewrites unrelated Rd files and adds a `RoxygenNote` line.

```bash
R --vanilla --quiet -e 'install.packages("roxygen2", repos = "https://cloud.r-project.org")'
R --vanilla --quiet -e 'devtools::document()'
git status --short
```

Expected: no changes reported by `git status` (documentation already matches 8.1.0).

- [ ] **Step 3: Baseline the suite.**

Run: `R --vanilla --quiet -e 'devtools::test(reporter = "summary")'`
Expected: no failures.

---

### Task 1: Validation and `.apply_tolerance()`

**Files:**
- Modify: `R/utils.R` (add two validators after `.validate_threshold()`, around line 296)
- Modify: `R/compare_images.R` (add `.apply_tolerance()` after `compare_images()`, before `.odiff_error_message()`)
- Create: `tests/testthat/test-tolerance.R`

**Interfaces:**
- Produces: `.validate_max_diff_percent(max_diff_percent)` and `.validate_max_diff_pixels(max_diff_pixels)`, each returning its argument invisibly or erroring.
- Produces: `.apply_tolerance(result, max_diff_percent = NULL, max_diff_pixels = NULL)`, where `result` is an `odiff_run()` result list (uses `result$reason`, `result$diff_count`, `result$diff_percentage`, `result$img1`, `result$img2`); returns `result`, with `match = TRUE` and `reason = "within-tolerance"` when tolerated.

- [ ] **Step 1: Write the failing tests**

Create `tests/testthat/test-tolerance.R`:

```r
# Tests for the image-level tolerance (max_diff_percent / max_diff_pixels)

# A hand-built odiff_run()-style result for two image files
tol_result <- function(img1, img2, reason = "pixel-diff", diff_count = 10L,
                       diff_percentage = 0.1) {
  list(match = identical(reason, "match"), reason = reason,
       diff_count = diff_count, diff_percentage = diff_percentage,
       img1 = img1, img2 = img2)
}

test_that("tolerance validators accept valid values and NULL", {
  expect_null(odiffr:::.validate_max_diff_percent(NULL))
  expect_equal(odiffr:::.validate_max_diff_percent(0), 0)
  expect_equal(odiffr:::.validate_max_diff_percent(100), 100)
  expect_equal(odiffr:::.validate_max_diff_percent(2.5), 2.5)
  expect_null(odiffr:::.validate_max_diff_pixels(NULL))
  expect_equal(odiffr:::.validate_max_diff_pixels(0), 0)
  expect_equal(odiffr:::.validate_max_diff_pixels(50L), 50L)
})

test_that("tolerance validators reject invalid values", {
  for (bad in list(-1, 100.1, NA_real_, Inf, c(1, 2), "1", TRUE)) {
    expect_error(odiffr:::.validate_max_diff_percent(bad),
                 "max_diff_percent must be NULL or a single number between 0 and 100")
  }
  for (bad in list(-1, 1.5, NA_real_, Inf, c(1, 2), "1", TRUE)) {
    expect_error(odiffr:::.validate_max_diff_pixels(bad),
                 "max_diff_pixels must be NULL or a single non-negative whole number")
  }
})

test_that(".apply_tolerance() leaves results alone without limits", {
  a <- create_test_image(100, 100, "red")
  b <- create_test_image(100, 100, "blue")
  on.exit(unlink(c(a, b)), add = TRUE)

  r <- tol_result(a, b)
  expect_identical(odiffr:::.apply_tolerance(r), r)
})

test_that(".apply_tolerance() applies inclusive pixel and percent limits", {
  a <- create_test_image(100, 100, "red")
  b <- create_test_image(100, 100, "blue")
  on.exit(unlink(c(a, b)), add = TRUE)
  r <- tol_result(a, b, diff_count = 10L, diff_percentage = 0.1)

  ok <- odiffr:::.apply_tolerance(r, max_diff_pixels = 10)
  expect_true(ok$match)
  expect_equal(ok$reason, "within-tolerance")
  expect_identical(ok$diff_count, 10L)
  expect_identical(ok$diff_percentage, 0.1)

  expect_false(odiffr:::.apply_tolerance(r, max_diff_pixels = 9)$match)
  expect_true(odiffr:::.apply_tolerance(r, max_diff_percent = 0.1)$match)
  expect_false(odiffr:::.apply_tolerance(r, max_diff_percent = 0.09)$match)
  expect_equal(odiffr:::.apply_tolerance(r, max_diff_percent = 0.09)$reason,
               "pixel-diff")
})

test_that(".apply_tolerance() requires both limits when both are given", {
  a <- create_test_image(100, 100, "red")
  b <- create_test_image(100, 100, "blue")
  on.exit(unlink(c(a, b)), add = TRUE)
  r <- tol_result(a, b, diff_count = 10L, diff_percentage = 0.1)

  expect_true(odiffr:::.apply_tolerance(
    r, max_diff_percent = 0.1, max_diff_pixels = 10)$match)
  expect_false(odiffr:::.apply_tolerance(
    r, max_diff_percent = 0.1, max_diff_pixels = 9)$match)
  expect_false(odiffr:::.apply_tolerance(
    r, max_diff_percent = 0.09, max_diff_pixels = 10)$match)
})

test_that(".apply_tolerance() only tolerates pixel differences with a count", {
  a <- create_test_image(100, 100, "red")
  b <- create_test_image(100, 100, "blue")
  on.exit(unlink(c(a, b)), add = TRUE)

  for (reason in c("match", "layout-diff", "error", "missing")) {
    r <- tol_result(a, b, reason = reason, diff_count = NA_integer_,
                    diff_percentage = NA_real_)
    expect_identical(odiffr:::.apply_tolerance(r, max_diff_percent = 100), r)
  }
  r <- tol_result(a, b, diff_count = NA_integer_, diff_percentage = NA_real_)
  expect_identical(odiffr:::.apply_tolerance(r, max_diff_percent = 100), r)
})

test_that(".apply_tolerance() never tolerates a size change", {
  a <- create_test_image(100, 100, "red")
  b <- create_test_image(100, 110, "red")
  on.exit(unlink(c(a, b)), add = TRUE)

  r <- tol_result(a, b, diff_count = 1000L, diff_percentage = 9.09)
  expect_identical(odiffr:::.apply_tolerance(r, max_diff_percent = 100), r)
})

test_that(".apply_tolerance() does not tolerate unknown dimensions", {
  a <- create_test_image(100, 100, "red")
  b <- create_test_image(100, 100, "blue")
  on.exit(unlink(c(a, b)), add = TRUE)
  testthat::local_mocked_bindings(.image_dimensions = function(path) NULL,
                                  .package = "odiffr")

  r <- tol_result(a, b)
  expect_identical(odiffr:::.apply_tolerance(r, max_diff_percent = 100), r)
})
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `R --vanilla --quiet -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-tolerance.R")'`
Expected: errors such as `could not find function ".validate_max_diff_percent"` and `".apply_tolerance"`.

- [ ] **Step 3: Implement the validators**

In `R/utils.R`, directly after `.validate_threshold()`:

```r
.validate_max_diff_percent <- function(max_diff_percent) {
  if (is.null(max_diff_percent)) {
    return(invisible(NULL))
  }
  if (!is.numeric(max_diff_percent) || length(max_diff_percent) != 1 ||
      !is.finite(max_diff_percent) || max_diff_percent < 0 ||
      max_diff_percent > 100) {
    stop("max_diff_percent must be NULL or a single number between 0 and 100.",
         call. = FALSE)
  }
  invisible(max_diff_percent)
}

.validate_max_diff_pixels <- function(max_diff_pixels) {
  if (is.null(max_diff_pixels)) {
    return(invisible(NULL))
  }
  if (!is.numeric(max_diff_pixels) || length(max_diff_pixels) != 1 ||
      !is.finite(max_diff_pixels) || max_diff_pixels < 0 ||
      max_diff_pixels != round(max_diff_pixels)) {
    stop("max_diff_pixels must be NULL or a single non-negative whole number.",
         call. = FALSE)
  }
  invisible(max_diff_pixels)
}
```

- [ ] **Step 4: Implement `.apply_tolerance()`**

In `R/compare_images.R`, after the closing brace of `compare_images()`:

```r
# Internal: accept a small pixel difference under an image-level tolerance.
# `result` is an odiff_run() result. It is returned with match = TRUE and
# reason = "within-tolerance" when odiff reported a pixel difference with a
# count, both images have the same, readable dimensions (a size change always
# fails), and every given limit holds (limits are inclusive).
.apply_tolerance <- function(result, max_diff_percent = NULL,
                             max_diff_pixels = NULL) {
  if (is.null(max_diff_percent) && is.null(max_diff_pixels)) {
    return(result)
  }
  if (!identical(result$reason, "pixel-diff") || is.na(result$diff_count)) {
    return(result)
  }
  d1 <- .image_dimensions(result$img1)
  d2 <- .image_dimensions(result$img2)
  if (is.null(d1) || is.null(d2) || !isTRUE(all(d1 == d2))) {
    return(result)
  }
  within <- (is.null(max_diff_pixels) ||
               result$diff_count <= max_diff_pixels) &&
    (is.null(max_diff_percent) ||
       isTRUE(result$diff_percentage <= max_diff_percent))
  if (within) {
    result$match <- TRUE
    result$reason <- "within-tolerance"
  }
  result
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `R --vanilla --quiet -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-tolerance.R")'`
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add R/utils.R R/compare_images.R tests/testthat/test-tolerance.R
git commit -m "Add tolerance validation and .apply_tolerance()"
```

---

### Task 2: `compare_images()` arguments and the functions built on it

**Files:**
- Modify: `R/compare_images.R` (`compare_images()` signature, body, roxygen; `@param ...` of `compare_images_batch()` and `compare_image_dirs()`)
- Modify: `R/pdf.R` (`@param ...` of `compare_pdfs()` and `compare_pdf_dirs()`)
- Modify: `R/snapshot-report.R` (`@param ...`)
- Test: `tests/testthat/test-tolerance.R`

**Interfaces:**
- Consumes: `.validate_max_diff_percent()`, `.validate_max_diff_pixels()`, `.apply_tolerance()` from Task 1.
- Produces: `compare_images(img1, img2, diff_output = NULL, threshold = 0.1, antialiasing = FALSE, fail_on_layout = FALSE, ignore_regions = NULL, plot_options = NULL, max_diff_percent = NULL, max_diff_pixels = NULL, ...)`. Its `reason` column may now be `"within-tolerance"`.

- [ ] **Step 1: Write the failing tests**

Append to `tests/testthat/test-tolerance.R`:

```r
# compare_images() and the functions built on it -----------------------------

test_that("compare_images() accepts a difference within the tolerance", {
  skip_if_no_odiff()
  img1 <- create_test_image(1000, 1000, "red")
  img2 <- create_modified_image(img1, "pixel")
  on.exit(unlink(c(img1, img2)), add = TRUE)

  res <- compare_images(img1, img2, max_diff_pixels = 1)
  expect_true(res$match)
  expect_equal(res$reason, "within-tolerance")
  expect_identical(res$diff_count, 1L)
  expect_equal(res$diff_percentage, 1e-4)

  expect_true(compare_images(img1, img2, max_diff_percent = 1e-4)$match)

  res <- compare_images(img1, img2, max_diff_pixels = 0)
  expect_false(res$match)
  expect_equal(res$reason, "pixel-diff")

  # No limits: unchanged behaviour
  expect_equal(compare_images(img1, img2)$reason, "pixel-diff")
})

test_that("compare_images() validates the tolerance arguments", {
  skip_if_no_odiff()
  img <- create_test_image(10, 10, "red")
  on.exit(unlink(img), add = TRUE)
  expect_error(compare_images(img, img, max_diff_percent = 101),
               "max_diff_percent")
  expect_error(compare_images(img, img, max_diff_pixels = -1),
               "max_diff_pixels")
})

test_that("compare_images() never tolerates a size change (odiff >= 4.3.5)", {
  skip_if_no_odiff()
  small <- create_test_image(100, 100, "red")
  tall <- create_test_image(100, 110, "red")
  on.exit(unlink(c(small, tall)), add = TRUE)

  # odiff >= 4.3.5 reports a size change as a pixel diff with a count
  testthat::local_mocked_bindings(
    odiff_version = function() "4.5.0",
    .run_odiff = function(odiff_path, args, timeout_secs = 0) {
      list(stdout = "1000;9.09", stderr = character(), exit_code = 22L,
           error = NA_character_)
    },
    .package = "odiffr"
  )
  res <- compare_images(small, tall, max_diff_percent = 100)
  expect_false(res$match)
  expect_equal(res$reason, "pixel-diff")
})

test_that("compare_images() applies the tolerance to plot inputs", {
  skip_if_no_odiff()
  opts <- plot_options(width = 2, height = 2, res = 50)
  p1 <- function() plot(1:3, pch = 16)
  p2 <- function() plot(c(1, 2, 3.1), pch = 16)

  expect_false(compare_images(p1, p2, plot_options = opts)$match)
  res <- compare_images(p1, p2, plot_options = opts, max_diff_percent = 100)
  expect_true(res$match)
  expect_equal(res$reason, "within-tolerance")
})

test_that("the tolerance reaches batch, directory and parallel comparisons", {
  skip_if_no_odiff()
  root <- withr::local_tempdir()
  dir.create(file.path(root, "baseline"))
  dir.create(file.path(root, "current"))
  base <- create_test_image(100, 100, "red")
  mod <- create_modified_image(base, "pixel")
  on.exit(unlink(c(base, mod)), add = TRUE)
  for (nm in c("a.png", "b.png")) {
    file.copy(base, file.path(root, "baseline", nm))
    file.copy(mod, file.path(root, "current", nm))
  }
  pairs <- data.frame(img1 = file.path(root, "baseline", c("a.png", "b.png")),
                      img2 = file.path(root, "current", c("a.png", "b.png")),
                      stringsAsFactors = FALSE)

  res <- compare_images_batch(pairs, max_diff_pixels = 1)
  expect_equal(res$reason, rep("within-tolerance", 2))
  expect_true(all(res$match))

  res <- compare_images_batch(pairs, parallel = TRUE, max_diff_pixels = 1)
  expect_equal(res$reason, rep("within-tolerance", 2))

  res <- compare_image_dirs(file.path(root, "baseline"),
                            file.path(root, "current"), max_diff_pixels = 1)
  expect_equal(res$reason, rep("within-tolerance", 2))

  res <- compare_image_dirs(file.path(root, "baseline"),
                            file.path(root, "current"))
  expect_equal(res$reason, rep("pixel-diff", 2))
})

test_that("expect_images_differ() fails for a difference within tolerance", {
  skip_if_no_odiff()
  img1 <- create_test_image(100, 100, "red")
  img2 <- create_modified_image(img1, "pixel")
  on.exit(unlink(c(img1, img2)), add = TRUE)

  expect_success(expect_images_differ(img1, img2))
  expect_failure(expect_images_differ(img1, img2, max_diff_pixels = 1),
                 "unexpectedly matches")
})
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `R --vanilla --quiet -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-tolerance.R")'`
Expected: the new tests fail with `unused argument (max_diff_pixels = 1)` (passed on to `odiff_run()` through `...`).

- [ ] **Step 3: Wire the arguments into `compare_images()`**

Change the signature (keep argument order; add the two before `...`):

```r
compare_images <- function(img1, img2,
                           diff_output = NULL,
                           threshold = 0.1,
                           antialiasing = FALSE,
                           fail_on_layout = FALSE,
                           ignore_regions = NULL,
                           plot_options = NULL,
                           max_diff_percent = NULL,
                           max_diff_pixels = NULL,
                           ...) {
  .validate_max_diff_percent(max_diff_percent)
  .validate_max_diff_pixels(max_diff_pixels)

  # Resolve image inputs (paths, magick objects and plots)
```

After the `odiff_run()` call and before `# Build output data frame`:

```r
  # Image-level tolerance (applied before temporary plot files are removed)
  result <- .apply_tolerance(result, max_diff_percent, max_diff_pixels)
```

- [ ] **Step 4: Document the arguments and the new reason**

In the roxygen block of `compare_images()`, after `@param plot_options ...`:

```r
#' @param max_diff_percent,max_diff_pixels Image-level tolerance. `NULL`
#'   (the default) for none, or the largest percentage of differing pixels
#'   (0 to 100, on the scale of `diff_percentage`) and/or the largest number
#'   of differing pixels to accept. Each limit is inclusive; if both are
#'   given, both must hold. See "Tolerance".
```

Replace the `match` and `reason` items of `@return`:

```r
#'     \item{match}{Logical; `TRUE` if images match, or differ within the
#'       tolerance (see `max_diff_percent`).}
#'     \item{reason}{Character; `"match"`, `"pixel-diff"`, `"layout-diff"`,
#'       `"error"`, or `"within-tolerance"` for a pixel difference accepted
#'       by `max_diff_percent`/`max_diff_pixels`.}
```

Add a section before `@seealso`:

```r
#' @section Tolerance:
#' By default any differing pixel (after `threshold`, `antialiasing` and
#' `ignore_regions`) makes a comparison fail. `max_diff_percent` and
#' `max_diff_pixels` accept a pixel difference up to a limit instead: the
#' result then has `match = TRUE` and `reason = "within-tolerance"`, and
#' `diff_count`, `diff_percentage` and `diff_output` still describe the
#' difference. A tolerance never applies to images of different sizes (even
#' with `fail_on_layout = FALSE`), to errors, or when the image dimensions
#' cannot be read (non-PNG images without the magick package).
#'
#' Use a tolerance with care. Font rendering differs between systems, and
#' for plots it can change a few percent of pixels, while real regressions
#' are often tiny: a dropped data point or an edited axis label can be well
#' under 0.1% of a plot. A tolerance large enough to absorb font differences
#' hides such changes, so it is best kept for comparisons across
#' environments, with exact matching elsewhere.
```

Update the `@param ...` lines:

- `R/compare_images.R`, `compare_images_batch()`: `#' @param ... Additional arguments passed to [compare_images()], e.g. \`threshold\` or \`max_diff_percent\`.`
- `R/compare_images.R`, `compare_image_dirs()`: `#' @param ... Additional arguments passed to [compare_images_batch()] (and on to [compare_images()]), e.g. \`max_diff_percent\`.`
- `R/pdf.R`: append to both `...` descriptions: `Use \`max_diff_percent\` or \`max_diff_pixels\` for an image-level tolerance, see [compare_images()].`
- `R/snapshot-report.R`: change to `#' @param ... Additional arguments passed to [compare_images()] (and from there to [odiff_run()]), e.g. \`ignore_regions\` or \`max_diff_percent\`. Use the settings of the tests that produced the snapshots.`

Read each existing `@param ...` line before editing and keep its current wording apart from the addition.

- [ ] **Step 5: Regenerate the documentation**

Run: `R --vanilla --quiet -e 'devtools::document()'`
Expected: changes only in `man/compare_images.Rd`, `man/compare_images_batch.Rd`, `man/compare_image_dirs.Rd`, `man/compare_pdfs.Rd`, `man/compare_pdf_dirs.Rd`, `man/snapshot_report.Rd`, and Rd files that inherit from `compare_images` (`man/expect_images.Rd`). Check with `git status --short`.

- [ ] **Step 6: Run the tests to verify they pass**

Run: `R --vanilla --quiet -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-tolerance.R")'`
Expected: all pass. Then run the full suite: `R --vanilla --quiet -e 'devtools::test(reporter = "summary")'`, expected no failures.

- [ ] **Step 7: Commit**

```bash
git add R/compare_images.R R/pdf.R R/snapshot-report.R man/ tests/testthat/test-tolerance.R
git commit -m "Add max_diff_percent and max_diff_pixels to compare_images()"
```

---

### Task 3: The testthat helpers

**Files:**
- Modify: `R/expect.R` (`expect_images_match()`)
- Modify: `R/snapshot.R` (`expect_snapshot_image()`, `compare_file_odiff()`)
- Test: `tests/testthat/test-tolerance.R`

**Interfaces:**
- Consumes: `compare_images(..., max_diff_percent, max_diff_pixels)` from Task 2; `.validate_max_diff_percent()`, `.validate_max_diff_pixels()` from Task 1.
- Produces: named `max_diff_percent = NULL, max_diff_pixels = NULL` arguments on `expect_images_match()` (after `ignore_regions`), `compare_file_odiff()` (after `fail_on_layout`) and `expect_snapshot_image()` (after `variant`), all before `...`.

- [ ] **Step 1: Write the failing tests**

Append to `tests/testthat/test-tolerance.R`:

```r
# testthat helpers -------------------------------------------------------------

test_that("expect_images_match() passes within tolerance and leaves no diff", {
  skip_if_no_odiff()
  diff_dir <- withr::local_tempdir()
  withr::local_options(odiffr.diff_dir = diff_dir)
  img1 <- create_test_image(1000, 1000, "red")
  img2 <- create_modified_image(img1, "pixel")
  on.exit(unlink(c(img1, img2)), add = TRUE)

  # A failing run leaves a diff image ...
  expect_failure(expect_images_match(img2, img1))
  expect_length(list.files(diff_dir), 1)

  # ... which a later pass within tolerance removes
  expect_success(expect_images_match(img2, img1, max_diff_pixels = 1))
  expect_length(list.files(diff_dir), 0)

  res <- expect_images_match(img2, img1, max_diff_percent = 1e-4)
  expect_equal(res$reason, "within-tolerance")
  expect_failure(expect_images_match(img2, img1, max_diff_pixels = 0))
})

test_that("compare_file_odiff() returns TRUE within tolerance", {
  skip_if_no_odiff()
  diff_dir <- withr::local_tempdir()
  # 100x100 red with a 21x21 white square: 441 differing pixels (4.41%)
  old <- create_test_image(100, 100, "red")
  new <- create_modified_image(old, "region")
  on.exit(unlink(c(old, new)), add = TRUE)

  expect_silent(res <- compare_file_odiff(diff_dir = diff_dir,
                                          max_diff_pixels = 441)(old, new))
  expect_true(res)
  expect_length(list.files(diff_dir, recursive = TRUE), 0)

  expect_true(compare_file_odiff(diff_dir = FALSE,
                                 max_diff_percent = 4.41)(old, new))
  expect_message(expect_false(
    compare_file_odiff(diff_dir = FALSE, max_diff_pixels = 440)(old, new)
  ), "pixels differ")
})

test_that("compare_file_odiff() validates the tolerance when created", {
  expect_error(compare_file_odiff(max_diff_percent = -1), "max_diff_percent")
  expect_error(compare_file_odiff(max_diff_pixels = 0.5), "max_diff_pixels")
})
```

(`create_modified_image(.., "region")` whitens rows/cols 40:60, i.e. 21 x 21 = 441 pixels of a 100x100 image, 4.41%; see `test-odiff_run.R`.)

Append to `tests/testthat/test-snapshot.R`, in the "Full snapshot workflow" section:

```r
test_that("expect_snapshot_image() passes within tolerance and keeps the baseline", {
  skip_if_no_odiff()
  skip_if_not_installed("png")
  withr::local_options(odiffr.snapshot_diff_dir = withr::local_tempdir())

  img_dir <- withr::local_tempdir()
  img <- write_snapshot_png(file.path(img_dir, "img.png"))
  test_file <- local_snapshot_project(snap_body(img, max_diff_pixels = 1681))
  snap_dir <- file.path(dirname(test_file), "_snaps", "img")
  snap <- file.path(snap_dir, "square.png")
  snap_new <- file.path(snap_dir, "square.new.png")

  # First run records the baseline
  res <- run_snapshot_test(test_file)
  expect_equal(res$failed, 0)
  baseline <- readBin(snap, "raw", 1e5)

  # A 1681-pixel change is within the tolerance: pass, baseline unchanged
  write_snapshot_png(img, modify = "region")
  res <- run_snapshot_test(test_file)
  expect_equal(res$failed, 0)
  expect_false(file.exists(snap_new))
  expect_identical(readBin(snap, "raw", 1e5), baseline)

  # One pixel fewer allowed: fails as before (keep the edition line that
  # local_snapshot_project() writes first)
  writeLines(c("testthat::local_edition(3)",
               snap_body(img, max_diff_pixels = 1680)), test_file)
  res <- run_snapshot_test(test_file)
  expect_equal(res$failed, 1)
  expect_true(file.exists(snap_new))
})
```

`write_snapshot_png(modify = "region")` whitens a 41x41 square (rows/cols 30:70) of the 100x100 image: 1681 pixels, 16.81%.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `R --vanilla --quiet -e 'devtools::load_all(quiet = TRUE); for (f in c("test-tolerance.R", "test-snapshot.R")) testthat::test_file(file.path("tests/testthat", f))'`
Expected: two failures. After Task 2 the arguments already reach `compare_images()` through `...`, so the verdicts are right, but `expect_images_match()` leaves the diff image (`list.files(diff_dir)` has length 1, not 0), and `compare_file_odiff()` only validates when the returned function runs, so the "validates the tolerance when created" test gets no error. The snapshot test may already pass; it pins the baseline-keeping behaviour.

- [ ] **Step 3: `expect_images_match()`**

Add the arguments after `ignore_regions = NULL,`:

```r
                                max_diff_percent = NULL,
                                max_diff_pixels = NULL,
```

Pass them in the `compare_images()` call, after `ignore_regions = ignore_regions,`:

```r
    max_diff_percent = max_diff_percent,
    max_diff_pixels = max_diff_pixels,
```

Before `# Use testthat::expect() - the modern pattern`:

```r
  # A pass within tolerance leaves no diff image behind
  if (identical(result$reason, "within-tolerance") && !is.null(diff_output)) {
    unlink(diff_output)
  }
```

The roxygen block already has `@inheritParams compare_images`, so the arguments are documented. Add to its `@details`, after the paragraph about diff images: `With \`max_diff_percent\` or \`max_diff_pixels\`, a small pixel difference passes (see the "Tolerance" section of [compare_images()]); no diff image is kept for it.`

- [ ] **Step 4: `compare_file_odiff()`**

Add the arguments after `fail_on_layout = TRUE,`:

```r
                               max_diff_percent = NULL,
                               max_diff_pixels = NULL,
```

Validate and force them with the others:

```r
  .validate_max_diff_percent(max_diff_percent)
  .validate_max_diff_pixels(max_diff_pixels)
```

(after `.check_snapshot_diff_dir(diff_dir)`), and add `force(max_diff_percent)` and `force(max_diff_pixels)` after `force(fail_on_layout)`. In the `do.call(compare_images, ...)` list, after `ignore_regions = ignore_regions`:

```r
        max_diff_percent = max_diff_percent,
        max_diff_pixels = max_diff_pixels,
```

No other change: a tolerated result has `match = TRUE`, so the existing branch returns `TRUE` and removes the diff image.

- [ ] **Step 5: `expect_snapshot_image()`**

Add the arguments after `variant = NULL,`:

```r
                                  max_diff_percent = NULL,
                                  max_diff_pixels = NULL,
```

Add them to the `args` list:

```r
  args <- list(
    ignore_regions = ignore_regions,
    fail_on_layout = fail_on_layout,
    max_diff_percent = max_diff_percent,
    max_diff_pixels = max_diff_pixels,
    preset = preset,
    diff_dir = diff_dir
  )
```

In its roxygen block, add after `@param variant ...`:

```r
#' @param max_diff_percent,max_diff_pixels Image-level tolerance: the largest
#'   percentage (0 to 100) and/or number of differing pixels to accept.
#'   `NULL` (the default) accepts no difference. A comparison within the
#'   tolerance passes and keeps the original snapshot, so differences cannot
#'   accumulate. Images of different sizes always fail. See the "Tolerance"
#'   section of [compare_images()] before using this.
```

`compare_file_odiff()` has `@inheritParams expect_snapshot_image`, so it inherits these.

- [ ] **Step 6: Regenerate the documentation and run the tests**

Run: `R --vanilla --quiet -e 'devtools::document()'` then `git status --short` (expected: `man/expect_images.Rd`, `man/expect_snapshot_image.Rd`, `man/compare_file_odiff.Rd` changed).
Run: `R --vanilla --quiet -e 'devtools::test(reporter = "summary")'`
Expected: no failures.

- [ ] **Step 7: Commit**

```bash
git add R/expect.R R/snapshot.R man/ tests/testthat/test-tolerance.R tests/testthat/test-snapshot.R
git commit -m "Add the tolerance to the testthat helpers"
```

---

### Task 4: Summary and Markdown output

**Files:**
- Modify: `R/summary.R` (`summary.odiffr_batch()`, `print.odiffr_batch_summary()`, roxygen `@return`)
- Modify: `R/ci-output.R` (`.build_markdown()`)
- Test: `tests/testthat/test-summary.R`, `tests/testthat/test-ci-output.R`

**Interfaces:**
- Consumes: batch rows with `reason == "within-tolerance"` and `match == TRUE`.
- Produces: an integer `tolerated` element in `odiffr_batch_summary` objects.

- [ ] **Step 1: Write the failing tests**

Append to `tests/testthat/test-summary.R`:

```r
test_that("summary counts comparisons within tolerance as passed", {
  batch <- make_batch(match = c(TRUE, TRUE, FALSE),
                      reason = c("match", "within-tolerance", "pixel-diff"),
                      diff_count = c(0L, 5L, 500L),
                      diff_percentage = c(0, 0.05, 5))
  summ <- summary(batch)
  expect_equal(summ$passed, 2L)
  expect_equal(summ$tolerated, 1L)
  expect_equal(names(summ$reason_counts), "pixel-diff")

  out <- capture.output(print(summ))
  expect_true(any(grepl("Within tolerance: 1", out, fixed = TRUE)))

  out <- capture.output(print(summary(make_batch(match = TRUE,
                                                 reason = "match"))))
  expect_false(any(grepl("tolerance", out)))
})

test_that("print works for summaries without a tolerated count", {
  summ <- summary(make_batch(match = TRUE, reason = "match"))
  summ$tolerated <- NULL
  expect_output(print(summ), "Passed: 1")
})
```

Append to `tests/testthat/test-ci-output.R`:

```r
test_that("batch_markdown notes comparisons within tolerance", {
  withr::local_envvar(GITHUB_STEP_SUMMARY = NA)
  batch <- make_batch(match = c(TRUE, TRUE),
                      reason = c("match", "within-tolerance"),
                      diff_count = c(0L, 5L), diff_percentage = c(0, 0.05))
  md <- batch_markdown(batch)
  expect_match(md, "**All 2 comparisons passed.**", fixed = TRUE)
  expect_match(md, "1 of the passing comparisons was within tolerance.",
               fixed = TRUE)

  md <- batch_markdown(make_batch(match = TRUE, reason = "match"))
  expect_false(grepl("tolerance", md))
})
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `R --vanilla --quiet -e 'devtools::load_all(quiet = TRUE); for (f in c("test-summary.R", "test-ci-output.R")) testthat::test_file(file.path("tests/testthat", f))'`
Expected: failures on `summ$tolerated` (NULL), the print line and the Markdown note.

- [ ] **Step 3: Implement**

In `summary.odiffr_batch()`, after `failed <- total - passed`:

```r
  tolerated <- sum(object$reason == "within-tolerance", na.rm = TRUE)
```

and add `tolerated = tolerated,` to the returned list after `failed = failed,`. Add to the roxygen `@return` list after `failed`:

```r
#'     \item{tolerated}{Number of passing comparisons that differ within a
#'       tolerance (`reason = "within-tolerance"`, see [compare_images()]).}
```

In `print.odiffr_batch_summary()`, after the `Failed:` line:

```r
  if (isTRUE(x$tolerated > 0)) {
    cat(sprintf("Within tolerance: %d (counted as passed)\n", x$tolerated))
  }
```

In `.build_markdown()` (`R/ci-output.R`), directly after the `if (summ$total == 0) ... else ...` block that adds the status line:

```r
  if (isTRUE(summ$tolerated > 0)) {
    lines <- c(lines, sprintf(
      "%d of the passing comparisons %s within tolerance.",
      summ$tolerated, if (summ$tolerated == 1) "was" else "were"
    ))
  }
```

- [ ] **Step 4: Regenerate the documentation and run the tests**

Run: `R --vanilla --quiet -e 'devtools::document()'` (expected: `man/summary.odiffr_batch.Rd` changed), then `R --vanilla --quiet -e 'devtools::test(reporter = "summary")'`.
Expected: no failures.

- [ ] **Step 5: Commit**

```bash
git add R/summary.R R/ci-output.R man/ tests/testthat/test-summary.R tests/testthat/test-ci-output.R
git commit -m "Count comparisons within tolerance in summaries and Markdown"
```

---

### Task 5: Approval and audit records

**Files:**
- Modify: `R/approve.R` (roxygen `@details` only)
- Modify: `R/audit.R` (`.audit_param_names`, roxygen)
- Test: `tests/testthat/test-approve.R`, `tests/testthat/test-audit.R`

**Interfaces:**
- Consumes: batch rows with `reason == "within-tolerance"`.
- Produces: `.audit_param_names` with `"max_diff_percent"` and `"max_diff_pixels"` appended.

`approve_changes()` needs no code change: by default it only approves `reasons = c("pixel-diff", "layout-diff")`, so `"within-tolerance"` rows are skipped with the detail `reason 'within-tolerance' not in \`reasons\``, and can be approved explicitly with `which` or by adding the reason to `reasons`. The tests pin that behaviour.

- [ ] **Step 1: Write the tests**

Append to `tests/testthat/test-approve.R` (uses the file's own `make_file_batch()` and `same_file_content()` helpers):

```r
test_that("approve_changes skips rows within tolerance unless selected", {
  root <- withr::local_tempdir()
  b <- make_file_batch(root, c("pixel-diff", "within-tolerance"))

  expect_message(actions <- approve_changes(b),
                 "skipped 1 \\(within-tolerance\\)")
  expect_equal(actions$action, c("updated", "skipped"))
  expect_equal(actions$detail[2],
               "reason 'within-tolerance' not in `reasons`")
  expect_false(same_file_content(b$img1[2], b$img2[2]))

  expect_message(actions <- approve_changes(b, which = 2L), "Approved 1")
  expect_equal(actions$action, "updated")
  expect_true(same_file_content(b$img1[2], b$img2[2]))
})
```

Before writing it, read `make_file_batch()` at the top of `test-approve.R`: it sets `match = reasons == "match"`, so the tolerated row gets `match = FALSE`, which is fine for `approve_changes()` (it selects by `reason`).

Append to `tests/testthat/test-audit.R`:

```r
test_that("audit_record() records tolerance parameters and reasons", {
  dir <- withr::local_tempdir()
  a <- write_bytes(dir, "a.png", 1:10)
  b <- write_bytes(dir, "b.png", 1:12)
  batch <- make_batch(match = TRUE, reason = "within-tolerance",
                      diff_count = 3L, diff_percentage = 0.5,
                      img1 = a, img2 = b)
  out <- file.path(dir, "audit.csv")

  audit_record(batch, file = out, format = "csv", hash = "md5",
               params = list(max_diff_percent = 1))
  csv <- utils::read.csv(out, stringsAsFactors = FALSE)
  expect_equal(csv$reason, "within-tolerance")
  expect_equal(csv$param_max_diff_percent, 1)
  expect_true(is.na(csv$param_max_diff_pixels))
})
```

- [ ] **Step 2: Run the tests to verify which fail**

Run: `R --vanilla --quiet -e 'devtools::load_all(quiet = TRUE); for (f in c("test-approve.R", "test-audit.R")) testthat::test_file(file.path("tests/testthat", f))'`
Expected: the approve test passes already (it pins existing behaviour); the audit test fails on `param_max_diff_pixels` (no such column).

- [ ] **Step 3: Implement**

In `R/audit.R`:

```r
.audit_param_names <- c("threshold", "antialiasing", "fail_on_layout",
                        "ignore_regions", "diff_mask", "diff_overlay",
                        "diff_color", "reduce_ram", "enable_asm",
                        "max_diff_percent", "max_diff_pixels")
```

In its roxygen, change the `reason` item to:

```r
#'   \item{reason}{Character; `"match"`, `"pixel-diff"`, `"layout-diff"`,
#'     `"error"`, `"missing"` or `"within-tolerance"`.}
```

and the standard parameter list in `@details` to include `` `max_diff_percent`, `max_diff_pixels` `` after `` `enable_asm` ``. Add one sentence after the `params` description: `[odiff_run()] results never include the tolerance parameters, which are applied by [compare_images()]; pass them in \`params\` to record them.`

In `R/approve.R`, add to the `@details` paragraph that starts "Rows with `reason = "match"` are never modified": `Rows with \`reason = "within-tolerance"\` passed within a tolerance (see [compare_images()]) and are skipped unless selected with \`which\` or listed in \`reasons\`.`

- [ ] **Step 4: Regenerate the documentation and run the tests**

Run: `R --vanilla --quiet -e 'devtools::document()'` (expected: `man/audit_record.Rd`, `man/approve_changes.Rd` changed), then `R --vanilla --quiet -e 'devtools::test(reporter = "summary")'`.
Expected: no failures.

- [ ] **Step 5: Commit**

```bash
git add R/approve.R R/audit.R man/ tests/testthat/test-approve.R tests/testthat/test-audit.R
git commit -m "Record tolerance parameters in audits and document approval"
```

---

### Task 6: NEWS, spec alignment and full verification

**Files:**
- Modify: `NEWS.md`
- Modify: `dev/specs/2026-10-07-image-tolerance-design.md`

- [ ] **Step 1: NEWS**

Under `# odiffr (development version)`, add a `## New features` section above `## Bug fixes`:

```markdown
## New features

* `compare_images()` gains `max_diff_percent` and `max_diff_pixels`, an
  opt-in image-level tolerance: a pixel difference up to the limit passes,
  with `match = TRUE` and the new `reason = "within-tolerance"`, while
  `diff_count` and `diff_percentage` still record it. Images of different
  sizes never pass. `expect_images_match()`, `expect_snapshot_image()` and
  `compare_file_odiff()` have the same arguments, and the batch, directory,
  PDF and `snapshot_report()` functions accept them through `...`.
  Within-tolerance snapshots keep their original baseline. `summary()` and
  `batch_markdown()` report how many passes were within tolerance,
  `approve_changes()` skips them unless selected, and `audit_record()` has
  columns for both parameters.
```

- [ ] **Step 2: Align the spec with two implementation decisions**

In `dev/specs/2026-10-07-image-tolerance-design.md`:
- In the Consumers table, the `approve_changes()` row: replace `reported as skipped with detail "within tolerance"` with `reported as skipped by the existing \`reasons\` filter (detail "reason 'within-tolerance' not in \`reasons\`"). Can be approved with \`which\` or by adding it to \`reasons\`.`
- In "Implementation outline", replace `.apply_tolerance(result, img1, img2, max_diff_percent, max_diff_pixels)` with `.apply_tolerance(result, max_diff_percent, max_diff_pixels)`, reading the image paths from `result`.

- [ ] **Step 3: Full verification**

```bash
R --vanilla --quiet -e 'devtools::test(reporter = "summary")'
R CMD build .
_R_CHECK_CRAN_INCOMING_REMOTE_=false NOT_CRAN=true R CMD check --as-cran --no-manual odiffr_0.6.0.9000.tar.gz
```

Expected: no test failures; check status with no ERRORs or WARNINGs (NOTEs for the development version number and, offline, "unable to verify current time" are expected). Also run the suite with `GITHUB_STEP_SUMMARY` set, since CI sets it:

```bash
GITHUB_STEP_SUMMARY="$(mktemp)" R --vanilla --quiet -e 'devtools::test(reporter = "summary")'
```

Expected: no failures. Delete the `odiffr_*.tar.gz` and `odiffr.Rcheck/` outputs afterwards (both are gitignored, but keep the tree tidy).

- [ ] **Step 4: Commit**

```bash
git add NEWS.md dev/specs/2026-10-07-image-tolerance-design.md
git commit -m "Add NEWS for the image-level tolerance"
```
