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
                 "differs from `img2` only within the tolerance \\(1 px")
})

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

# Final review fixes and coverage ---------------------------------------------

test_that("expect_images_match() does not return a deleted diff path", {
  skip_if_no_odiff()
  withr::local_options(odiffr.diff_dir = withr::local_tempdir())
  img1 <- create_test_image(1000, 1000, "red")
  img2 <- create_modified_image(img1, "pixel")
  on.exit(unlink(c(img1, img2)), add = TRUE)

  res <- expect_images_match(img2, img1, max_diff_pixels = 1)
  expect_identical(res$diff_output, NA_character_)
})

test_that("batch_report() and batch_junit() show passes within tolerance", {
  withr::local_envvar(GITHUB_STEP_SUMMARY = NA)
  batch <- make_batch(match = c(TRUE, TRUE),
                      reason = c("match", "within-tolerance"),
                      diff_count = c(0L, 5L), diff_percentage = c(0, 0.05))

  html <- batch_report(batch)
  expect_match(html, "Within tolerance: 1 (counted as passed)", fixed = TRUE)
  html <- batch_report(batch, show_all = TRUE)
  expect_match(html, "within-tolerance", fixed = TRUE)
  expect_false(grepl("Within tolerance",
                     batch_report(make_batch(match = TRUE, reason = "match")),
                     fixed = TRUE))

  skip_if_not_installed("xml2")
  doc <- xml2::read_xml(batch_junit(batch))
  suite <- xml2::xml_find_first(doc, "//testsuite")
  expect_equal(xml2::xml_attr(suite, "failures"), "0")
  expect_length(xml2::xml_find_all(doc, "//failure"), 0)
})

test_that("the tolerance reaches compare_pdfs() and compare_pdf_dirs()", {
  skip_if_no_odiff()
  skip_if_not_installed("pdftools")
  root <- withr::local_tempdir()
  base_dir <- file.path(root, "base")
  cur_dir <- file.path(root, "cur")
  dir.create(base_dir)
  dir.create(cur_dir)
  make_page <- function(path, changed) {
    grDevices::pdf(path, width = 3, height = 3)
    graphics::plot(1:10)
    if (changed) graphics::points(5, 5, pch = 19, col = "red")
    grDevices::dev.off()
    path
  }
  base <- make_page(file.path(base_dir, "a.pdf"), FALSE)
  cur <- make_page(file.path(cur_dir, "a.pdf"), TRUE)

  expect_equal(compare_pdfs(base, cur)$reason, "pixel-diff")
  res <- compare_pdfs(base, cur, max_diff_percent = 100)
  expect_equal(res$reason, "within-tolerance")
  expect_true(res$match)

  res <- compare_pdf_dirs(base_dir, cur_dir, max_diff_percent = 100)
  expect_equal(res$reason, "within-tolerance")
})

test_that("the tolerance reaches snapshot_report()", {
  skip_if_no_odiff()
  skip_if_not_installed("png")
  withr::local_envvar(GITHUB_STEP_SUMMARY = NA)
  snaps <- file.path(withr::local_tempdir(), "_snaps", "plots")
  dir.create(snaps, recursive = TRUE)
  base <- create_test_image(100, 100, "red")
  new <- create_modified_image(base, "pixel")
  on.exit(unlink(c(base, new)), add = TRUE)
  file.copy(base, file.path(snaps, "p.png"))
  file.copy(new, file.path(snaps, "p.new.png"))

  batch <- snapshot_report(dirname(snaps), format = "markdown")
  expect_equal(batch$reason, "pixel-diff")
  batch <- snapshot_report(dirname(snaps), format = "markdown",
                           max_diff_pixels = 1)
  expect_equal(batch$reason, "within-tolerance")
  expect_true(batch$match)
})
