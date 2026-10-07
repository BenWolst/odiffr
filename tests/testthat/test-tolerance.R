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
