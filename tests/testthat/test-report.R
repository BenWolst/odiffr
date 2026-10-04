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

test_that("batch_report relative_paths uses relative src", {
  skip_if_no_odiff()

  output_dir <- withr::local_tempdir()
  diff_dir <- file.path(output_dir, "diffs")
  report_file <- file.path(output_dir, "reports", "qa-report.html")

  # Create test comparison with diff
  baseline_dir <- withr::local_tempdir()
  current_dir <- withr::local_tempdir()

  img_red <- create_test_image(30, 30, "red")
  img_blue <- create_test_image(30, 30, "blue")
  file.copy(img_red, file.path(baseline_dir, "test.png"))
  file.copy(img_blue, file.path(current_dir, "test.png"))
  on.exit(unlink(c(img_red, img_blue)), add = TRUE)

  results <- compare_image_dirs(baseline_dir, current_dir, diff_dir = diff_dir)

  dir.create(dirname(report_file), recursive = TRUE)
  batch_report(results, output_file = report_file, relative_paths = TRUE)

  html <- paste(readLines(report_file), collapse = "\n")

  # Should have relative path, not absolute
  # Check that absolute path prefix is NOT present (normalize for consistent comparison)
  abs_prefix <- gsub("\\\\", "/", normalizePath(output_dir, mustWork = FALSE))
  expect_false(grepl(abs_prefix, html, fixed = TRUE))
  # Check for relative path pattern (always forward slashes from .make_relative_path)
  # Should contain ".." (go up) followed by "/" and "diffs", or just "diffs/" at start
  expect_true(
    grepl('src="../diffs/', html, fixed = TRUE) ||
    grepl('src="diffs/', html, fixed = TRUE)
  )
})

test_that("batch_report relative_paths=FALSE uses absolute paths", {
  skip_if_no_odiff()

  output_dir <- withr::local_tempdir()
  diff_dir <- file.path(output_dir, "diffs")
  report_file <- file.path(output_dir, "report.html")

  baseline_dir <- withr::local_tempdir()
  current_dir <- withr::local_tempdir()

  img_red <- create_test_image(30, 30, "red")
  img_blue <- create_test_image(30, 30, "blue")
  file.copy(img_red, file.path(baseline_dir, "test.png"))
  file.copy(img_blue, file.path(current_dir, "test.png"))
  on.exit(unlink(c(img_red, img_blue)), add = TRUE)

  results <- compare_image_dirs(baseline_dir, current_dir, diff_dir = diff_dir)
  batch_report(results, output_file = report_file, relative_paths = FALSE)

  html <- paste(readLines(report_file), collapse = "\n")

  # Should NOT have relative path (no "../")
  expect_false(grepl('src="\\.\\./', html))
  # Should have an absolute path containing "diffs" directory
  # Note: exact path format varies by platform (forward/back slashes, symlink resolution)
  # so we check for the key path component rather than the full path
  expect_true(grepl("diffs", html, fixed = TRUE))
  expect_true(grepl("\\.png", html))  # Should have .png file reference
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


# Image link URIs -------------------------------------------------------------

test_that(".file_uri builds Unix file URIs with encoded segments", {
  f <- odiffr:::.file_uri
  expect_equal(f("/tmp/diffs/a.png", windows = FALSE), "file:///tmp/diffs/a.png")
  expect_equal(
    f("/tmp/my dir/a#1?.png", windows = FALSE),
    "file:///tmp/my%20dir/a%231%3F.png"
  )
  expect_equal(f("/tmp/100%/x.png", windows = FALSE), "file:///tmp/100%25/x.png")
  # An already-encoded-looking name is encoded again (it is a literal name)
  expect_equal(f("/tmp/a%20b.png", windows = FALSE), "file:///tmp/a%2520b.png")
  # Backslash is a valid file name character on Unix
  expect_equal(f("/tmp/a\\b.png", windows = FALSE), "file:///tmp/a%5Cb.png")
  # Non-ASCII is encoded as UTF-8 bytes
  expect_equal(f("/tmp/\u00e9.png", windows = FALSE), "file:///tmp/%C3%A9.png")
})

test_that(".file_uri builds Windows file URIs", {
  f <- odiffr:::.file_uri
  expect_equal(
    f("C:\\Users\\Jane Doe\\diffs\\a#1.png", windows = TRUE),
    "file:///C:/Users/Jane%20Doe/diffs/a%231.png"
  )
  expect_equal(f("D:/x/y.png", windows = TRUE), "file:///D:/x/y.png")
  expect_equal(
    f("\\\\server\\share\\my diffs\\a.png", windows = TRUE),
    "file://server/share/my%20diffs/a.png"
  )
})

test_that(".encode_url_path keeps separators and dot segments", {
  e <- odiffr:::.encode_url_path
  expect_equal(e("../diffs/a b.png"), "../diffs/a%20b.png")
  expect_equal(e("./x/100%.png"), "./x/100%25.png")
  expect_equal(e("../../q?#.png"), "../../q%3F%23.png")
})

test_that(".relative_path_or_na compares components case-insensitively on Windows", {
  r <- odiffr:::.relative_path_or_na
  expect_equal(
    r("c:/users/bob/diffs/a.png", "C:/Users/Bob/reports/r.html", windows = TRUE),
    "../diffs/a.png"
  )
  expect_equal(
    r("C:\\Users\\Bob\\diffs\\a.png", "C:\\Users\\Bob\\r.html", windows = TRUE),
    "diffs/a.png"
  )
  # Different drives: no relative path possible
  expect_true(is.na(r("D:/diffs/a.png", "C:/reports/r.html", windows = TRUE)))
  expect_equal(
    odiffr:::.make_relative_path("D:/diffs/a.png", "C:/reports/r.html", windows = TRUE),
    "D:/diffs/a.png"
  )
  # Case-sensitive elsewhere
  expect_true(is.na(r("c:/x/a.png", "C:/x/r.html", windows = FALSE)))
})

test_that(".format_diff_image encodes special characters in linked paths", {
  root <- withr::local_tempdir()
  diff_dir <- file.path(root, "my diffs #1")
  dir.create(diff_dir)
  diff_file <- file.path(diff_dir, "a b%.png")
  writeBin(as.raw(1:10), diff_file)

  # Absolute: file:// URI
  html <- odiffr:::.format_diff_image(diff_file, embed = FALSE)
  src <- sub('.*src="([^"]*)".*', "\\1", html)
  expect_match(src, "^file:///")
  expect_match(src, "my%20diffs%20%231/a%20b%25.png", fixed = TRUE)
  expect_false(grepl("\\", src, fixed = TRUE))

  # Relative to the report
  report <- file.path(root, "reports", "r.html")
  dir.create(dirname(report))
  html_rel <- odiffr:::.format_diff_image(diff_file, embed = FALSE,
                                          output_file = report,
                                          relative_paths = TRUE)
  expect_match(html_rel, 'src="../my%20diffs%20%231/a%20b%25.png"', fixed = TRUE)
})


# HTML escaping -----------------------------------------------------------------

test_that(".html_escape is vectorized and escapes quotes", {
  expect_equal(
    odiffr:::.html_escape(c("<a href='x'>", NA, "\"&\"")),
    c("&lt;a href=&#39;x&#39;&gt;", "", "&quot;&amp;&quot;")
  )
  expect_equal(odiffr:::.html_escape(character(0)), character(0))
  expect_equal(odiffr:::.html_escape(NA_character_), "")
})


# base64 ---------------------------------------------------------------------

test_that(".base64_encode matches RFC 4648 test vectors", {
  inputs <- c("", "f", "fo", "foo", "foob", "fooba", "foobar")
  expected <- c("", "Zg==", "Zm8=", "Zm9v", "Zm9vYg==", "Zm9vYmE=", "Zm9vYmFy")
  for (i in seq_along(inputs)) {
    expect_equal(odiffr:::.base64_encode(charToRaw(inputs[i])), expected[i],
                 info = inputs[i])
  }
})

test_that(".base64_encode is identical to the previous loop implementation", {
  old_impl <- function(raw_data) {
    if (length(raw_data) == 0) return("")
    b64_chars <- c(LETTERS, letters, 0:9, "+", "/")
    n <- length(raw_data)
    padding <- (3 - n %% 3) %% 3
    raw_data <- c(raw_data, rep(as.raw(0), padding))
    result <- character(length(raw_data) / 3 * 4)
    j <- 1
    for (i in seq(1, length(raw_data), 3)) {
      chunk <- as.integer(raw_data[i:(i + 2)])
      result[j]     <- b64_chars[(chunk[1] %/% 4) + 1]
      result[j + 1] <- b64_chars[((chunk[1] %% 4) * 16 + chunk[2] %/% 16) + 1]
      result[j + 2] <- b64_chars[((chunk[2] %% 16) * 4 + chunk[3] %/% 64) + 1]
      result[j + 3] <- b64_chars[(chunk[3] %% 64) + 1]
      j <- j + 4
    }
    if (padding > 0) {
      result[(length(result) - padding + 1):length(result)] <- "="
    }
    paste(result, collapse = "")
  }

  withr::local_seed(42)
  for (n in c(1, 2, 3, 4, 255, 256, 257, 1000)) {
    x <- as.raw(sample(0:255, n, replace = TRUE))
    expect_identical(odiffr:::.base64_encode(x), old_impl(x), info = n)
  }
  all_bytes <- as.raw(0:255)
  expect_identical(odiffr:::.base64_encode(all_bytes), old_impl(all_bytes))
})

test_that(".base64_encode round-trips random data (base64enc)", {
  skip_if_not_installed("base64enc")
  withr::local_seed(1)
  x <- as.raw(sample(0:255, 10000, replace = TRUE))
  enc <- odiffr:::.base64_encode(x)
  expect_identical(enc, base64enc::base64encode(x))
  expect_identical(base64enc::base64decode(enc), x)
})

test_that(".base64_encode matches jsonlite", {
  skip_if_not_installed("jsonlite")
  withr::local_seed(2)
  x <- as.raw(sample(0:255, 10001, replace = TRUE))
  expect_identical(odiffr:::.base64_encode(x), gsub("\\s", "", jsonlite::base64_enc(x)))
})


# NA / error / missing rows --------------------------------------------------

test_that("batch_report shows '-' instead of NA for rows without pixel stats", {
  batch <- make_batch(
    match = c(FALSE, FALSE, FALSE, TRUE),
    reason = c("layout-diff", "missing", "pixel-diff", "match"),
    diff_count = c(NA, NA, 42L, 0L),
    diff_percentage = c(NA, NA, 4.2, 0)
  )
  html <- batch_report(batch, show_all = TRUE)

  expect_false(grepl("NA%", html, fixed = TRUE))
  expect_false(grepl("<td>NA</td>", html, fixed = TRUE))
  expect_true(grepl("<td>-</td>", html, fixed = TRUE))
  expect_true(grepl("4.20%", html, fixed = TRUE))
  expect_true(grepl("missing (no current image)", html, fixed = TRUE))

  # Worst offenders: the row with a percentage comes first
  worst <- sub(".*<section class=\"worst-offenders\">(.*?)</section>.*", "\\1", html)
  expect_lt(regexpr("img3.png", worst), regexpr("img1.png", worst))
})

test_that("batch_report shows escaped error messages when available", {
  batch <- make_batch(
    match = c(FALSE, FALSE),
    reason = c("error", "pixel-diff"),
    diff_count = c(NA, 5L),
    diff_percentage = c(NA, 1),
    error = c("bad <file> & \"quote\"", NA),
    tibble = requireNamespace("tibble", quietly = TRUE)
  )
  html <- batch_report(batch, show_all = TRUE)

  esc <- "bad &lt;file&gt; &amp; &quot;quote&quot;"
  expect_true(grepl(paste0('title="', esc, '"'), html, fixed = TRUE))
  expect_true(grepl(paste0('<span class="error-msg">', esc, "</span>"), html, fixed = TRUE))
  expect_false(grepl("<file>", html, fixed = TRUE))
  # Two tables (worst + all), error shown in each
  expect_equal(lengths(regmatches(html, gregexpr("error-msg\">", html))), 2)
})

test_that("batch_report works without an error column (older objects)", {
  batch <- make_batch(
    match = FALSE, reason = "error",
    tibble = requireNamespace("tibble", quietly = TRUE)
  )
  expect_false("error" %in% names(batch))
  expect_silent(html <- batch_report(batch, show_all = TRUE))
  expect_false(grepl("error-msg\">", html))
})


# Empty batch -------------------------------------------------------------------

test_that("batch_report produces valid HTML for an empty batch", {
  empty <- make_batch()
  html <- batch_report(empty, show_all = TRUE)

  expect_true(grepl("<!DOCTYPE html>", html, fixed = TRUE))
  expect_true(grepl("</html>$", html))
  expect_false(grepl("NaN|NA%", html))
  expect_true(grepl("Passed (-)", html, fixed = TRUE))
  expect_true(grepl("Failed (-)", html, fixed = TRUE))
  expect_true(grepl("No failures", html, fixed = TRUE))
  expect_true(grepl("No comparisons", html, fixed = TRUE))
})


# Output file -------------------------------------------------------------------

test_that("batch_report writes UTF-8 and creates the parent directory", {
  root <- withr::local_tempdir()
  out <- file.path(root, "nested", "dir", "report.html")
  title <- "Pr\u00fcfbericht \u2713 \u65e5\u672c"

  batch <- make_batch(match = TRUE, reason = "match",
                      diff_count = 0L, diff_percentage = 0)
  res <- batch_report(batch, output_file = out, title = title)

  expect_equal(res, out)
  expect_true(file.exists(out))
  bytes <- readBin(out, "raw", file.info(out)$size)
  expect_true(grepl(enc2utf8(title), rawToChar(bytes), useBytes = TRUE, fixed = TRUE))
  content <- readLines(out, encoding = "UTF-8", warn = FALSE)
  expect_true(any(grepl(title, content, fixed = TRUE)))
})
