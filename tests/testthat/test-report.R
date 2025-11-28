# Tests for batch_report()

test_that("batch_report returns HTML string when output_file is NULL", {
  skip_if_no_odiff()

  img <- create_test_image(30, 30, "red")
  on.exit(unlink(img), add = TRUE)

  pairs <- data.frame(img1 = img, img2 = img, stringsAsFactors = FALSE)
  result <- compare_images_batch(pairs)

  html <- batch_report(result)

  expect_type(html, "character")
  expect_true(grepl("<!DOCTYPE html>", html))

  expect_true(grepl("odiffr Comparison Report", html))
})

test_that("batch_report writes to file when output_file specified", {
  skip_if_no_odiff()

  img <- create_test_image(30, 30, "red")
  output_file <- tempfile(fileext = ".html")
  on.exit(unlink(c(img, output_file)), add = TRUE)

  pairs <- data.frame(img1 = img, img2 = img, stringsAsFactors = FALSE)
  result <- compare_images_batch(pairs)

  returned_path <- batch_report(result, output_file = output_file)

  expect_equal(returned_path, output_file)
  expect_true(file.exists(output_file))

  content <- readLines(output_file)
  expect_true(any(grepl("<!DOCTYPE html>", content)))
})

test_that("batch_report includes summary statistics", {
  skip_if_no_odiff()

  img_red <- create_test_image(30, 30, "red")
  img_blue <- create_test_image(30, 30, "blue")
  on.exit(unlink(c(img_red, img_blue)), add = TRUE)

  pairs <- data.frame(
    img1 = c(img_red, img_red),
    img2 = c(img_red, img_blue),
    stringsAsFactors = FALSE
  )
  result <- compare_images_batch(pairs)

  html <- batch_report(result)

  expect_true(grepl("Passed", html))
  expect_true(grepl("Failed", html))
  expect_true(grepl("50", html))
})

test_that("batch_report shows worst offenders", {
  skip_if_no_odiff()

  img_red <- create_test_image(30, 30, "red")
  img_blue <- create_test_image(30, 30, "blue")
  diff_dir <- withr::local_tempdir()
  on.exit(unlink(c(img_red, img_blue)), add = TRUE)

  pairs <- data.frame(img1 = img_red, img2 = img_blue, stringsAsFactors = FALSE)
  result <- compare_images_batch(pairs, diff_dir = diff_dir)

  html <- batch_report(result)

  expect_true(grepl("Worst Offenders", html))
  expect_true(grepl("pixel-diff", html))
})

test_that("batch_report embeds images when embed = TRUE", {
  skip_if_no_odiff()

  img_red <- create_test_image(30, 30, "red")
  img_blue <- create_test_image(30, 30, "blue")
  diff_dir <- withr::local_tempdir()
  on.exit(unlink(c(img_red, img_blue)), add = TRUE)

  pairs <- data.frame(img1 = img_red, img2 = img_blue, stringsAsFactors = FALSE)
  result <- compare_images_batch(pairs, diff_dir = diff_dir)

  html <- batch_report(result, embed = TRUE)

  expect_true(grepl("data:image/png;base64,", html))
})

test_that("batch_report links images when embed = FALSE", {
  skip_if_no_odiff()

  img_red <- create_test_image(30, 30, "red")
  img_blue <- create_test_image(30, 30, "blue")
  diff_dir <- withr::local_tempdir()
  on.exit(unlink(c(img_red, img_blue)), add = TRUE)

  pairs <- data.frame(img1 = img_red, img2 = img_blue, stringsAsFactors = FALSE)
  result <- compare_images_batch(pairs, diff_dir = diff_dir)

  html <- batch_report(result, embed = FALSE)

  expect_false(grepl("data:image/png;base64,", html))
  expect_true(grepl("_diff\\.png", html))
})

test_that("batch_report respects n_worst parameter", {
  skip_if_no_odiff()

  img_red <- create_test_image(30, 30, "red")
  img_blue <- create_test_image(30, 30, "blue")
  on.exit(unlink(c(img_red, img_blue)), add = TRUE)

  pairs <- data.frame(
    img1 = rep(img_red, 10),
    img2 = rep(img_blue, 10),
    stringsAsFactors = FALSE
  )
  result <- compare_images_batch(pairs)

  html_3 <- batch_report(result, n_worst = 3)

  rows <- gregexpr("<tr>", html_3)[[1]]
  expect_lte(length(rows), 10)
})

test_that("batch_report handles all-passing results gracefully", {
  skip_if_no_odiff()

  img <- create_test_image(30, 30, "red")
  on.exit(unlink(img), add = TRUE)

  pairs <- data.frame(img1 = img, img2 = img, stringsAsFactors = FALSE)
  result <- compare_images_batch(pairs)

  html <- batch_report(result)

  expect_true(grepl("Passed", html))
  expect_true(grepl("No failures", html))
})

test_that("batch_report includes custom title", {
  skip_if_no_odiff()

  img <- create_test_image(30, 30, "red")
  on.exit(unlink(img), add = TRUE)

  pairs <- data.frame(img1 = img, img2 = img, stringsAsFactors = FALSE)
  result <- compare_images_batch(pairs)

  html <- batch_report(result, title = "My Custom Report")

  expect_true(grepl("My Custom Report", html))
})

test_that("batch_report escapes HTML in paths", {
  html <- batch_report(
    structure(
      data.frame(
        pair_id = 1L, match = FALSE, reason = "pixel-diff",
        diff_count = 100L, diff_percentage = 5.0,
        diff_output = NA_character_,
        img1 = "test<script>.png",
        img2 = "test<script>.png",
        stringsAsFactors = FALSE
      ),
      class = c("odiffr_batch", "data.frame")
    )
  )

  expect_false(grepl("<script>", html))
  expect_true(grepl("&lt;script&gt;", html))
})

test_that("batch_report shows all results when show_all = TRUE", {
  skip_if_no_odiff()

  img_red <- create_test_image(30, 30, "red")
  img_blue <- create_test_image(30, 30, "blue")
  on.exit(unlink(c(img_red, img_blue)), add = TRUE)

  pairs <- data.frame(
    img1 = c(img_red, img_red),
    img2 = c(img_red, img_blue),
    stringsAsFactors = FALSE
  )
  result <- compare_images_batch(pairs)

  html <- batch_report(result, show_all = TRUE)

  expect_true(grepl("All Comparisons", html))
})

test_that(".base64_encode produces valid output", {
  input <- charToRaw("Hello")
  result <- odiffr:::.base64_encode(input)

  expect_equal(result, "SGVsbG8=")

  expect_equal(nchar(odiffr:::.base64_encode(charToRaw("a"))), 4)
  expect_true(grepl("==$", odiffr:::.base64_encode(charToRaw("a"))))

  expect_equal(nchar(odiffr:::.base64_encode(charToRaw("ab"))), 4)
  expect_true(grepl("=$", odiffr:::.base64_encode(charToRaw("ab"))))
  expect_false(grepl("==$", odiffr:::.base64_encode(charToRaw("ab"))))

  expect_equal(nchar(odiffr:::.base64_encode(charToRaw("abc"))), 4)
  expect_false(grepl("=", odiffr:::.base64_encode(charToRaw("abc"))))
})

test_that(".base64_encode handles empty input", {
  expect_equal(odiffr:::.base64_encode(raw(0)), "")
})

test_that("batch_report validates n_worst parameter", {
  skip_if_no_odiff()

  img <- create_test_image(30, 30, "red")
  on.exit(unlink(img), add = TRUE)

  pairs <- data.frame(img1 = img, img2 = img, stringsAsFactors = FALSE)
  result <- compare_images_batch(pairs)

  expect_error(batch_report(result, n_worst = -1), "non-negative")
  expect_error(batch_report(result, n_worst = "abc"), "non-negative")
})

test_that("batch_report validates object class", {
  expect_error(
    batch_report(data.frame(a = 1)),
    "inherits"
  )
})

test_that(".html_escape handles NA values", {
  expect_equal(odiffr:::.html_escape(NA), "")
})

test_that("batch_report includes timestamp", {
  skip_if_no_odiff()

  img <- create_test_image(30, 30, "red")
  on.exit(unlink(img), add = TRUE)

  pairs <- data.frame(img1 = img, img2 = img, stringsAsFactors = FALSE)
  result <- compare_images_batch(pairs)

  html <- batch_report(result)

  expect_true(grepl("Generated:", html))
  expect_true(grepl("\\d{4}-\\d{2}-\\d{2}", html))
})

test_that("batch_report includes footer with version", {
  skip_if_no_odiff()

  img <- create_test_image(30, 30, "red")
  on.exit(unlink(img), add = TRUE)

  pairs <- data.frame(img1 = img, img2 = img, stringsAsFactors = FALSE)
  result <- compare_images_batch(pairs)

  html <- batch_report(result)

  expect_true(grepl("<footer>", html))
  expect_true(grepl("Generated by odiffr", html))
})
