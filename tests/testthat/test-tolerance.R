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
                 "unexpectedly matches")
})
