# Tests for expect_snapshot_image() and compare_file_odiff()

# Write a 100x100 PNG of `color`, optionally with one changed pixel / a
# changed region
write_snapshot_png <- function(path, color = c(1, 0, 0), modify = "none") {
  img <- array(0, dim = c(100, 100, 3))
  for (i in 1:3) img[, , i] <- color[i]
  if (modify == "pixel") {
    img[50, 50, ] <- c(color[1], color[2], 0.04)  # tiny colour change
  } else if (modify == "region") {
    img[30:70, 30:70, ] <- 1
  }
  png::writePNG(img, path)
  path
}

# The generated test files use `odiffr:::` so they also work under
# pkgload::load_all() before NAMESPACE is regenerated.

# Set up a throwaway package-like directory with one test file that snapshots
# `image` (a PNG path). Returns the path of the test file.
local_snapshot_project <- function(body, env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  test_dir <- file.path(dir, "tests", "testthat")
  dir.create(test_dir, recursive = TRUE)
  test_file <- file.path(test_dir, "test-img.R")
  writeLines(c("testthat::local_edition(3)", body), test_file)
  test_file
}

# Run a test file and return a one-row summary of its results
run_snapshot_test <- function(test_file) {
  withr::local_envvar(CI = "false", NOT_CRAN = "true")
  res <- testthat::test_file(test_file, reporter = "silent",
                             stop_on_failure = FALSE)
  df <- as.data.frame(res)
  list(
    failed = sum(df$failed),
    warning = sum(df$warning),
    skipped = sum(df$skipped),
    error = any(df$error),
    passed = sum(df$passed),
    results = res
  )
}

snap_body <- function(image, ...) {
  args <- list(...)
  extra <- if (length(args)) {
    paste0(", ", paste(names(args), vapply(args, function(a) paste(deparse(a), collapse = ""), ""), sep = " = ",
                       collapse = ", "))
  } else {
    ""
  }
  c(
    sprintf("img <- %s", deparse(image)),
    "test_that('image snapshot', {",
    sprintf("  odiffr:::expect_snapshot_image(img, name = 'square'%s)", extra),
    "})"
  )
}

# compare_file_odiff() --------------------------------------------------------

test_that("compare_file_odiff() returns a comparison function", {
  cmp <- compare_file_odiff()
  expect_type(cmp, "closure")
  expect_named(formals(cmp), c("old", "new"))
})

test_that("compare_file_odiff() compares files with odiff", {
  skip_if_no_odiff()
  skip_if_not_installed("png")
  dir <- withr::local_tempdir()
  a <- write_snapshot_png(file.path(dir, "a.png"))
  b <- write_snapshot_png(file.path(dir, "b.png"))
  c <- write_snapshot_png(file.path(dir, "c.png"), modify = "region")
  d <- write_snapshot_png(file.path(dir, "d.png"), modify = "pixel")

  expect_true(compare_file_odiff()(a, b))
  expect_false(compare_file_odiff()(a, c))
  # A tiny colour change is below the threshold, but not byte-identical
  expect_false(identical(readBin(a, "raw", 1e5), readBin(d, "raw", 1e5)))
  expect_true(compare_file_odiff(threshold = 0.1)(a, d))
  expect_false(compare_file_odiff(threshold = 0)(a, d))
  # Ignore regions are honoured
  expect_true(compare_file_odiff(
    ignore_regions = list(ignore_region(25, 25, 75, 75))
  )(a, c))
})

test_that("compare_file_odiff() honours fail_on_layout", {
  skip_if_no_odiff()
  a <- create_test_image(100, 100, "red")
  b <- create_test_image(120, 100, "red")
  on.exit(unlink(c(a, b)), add = TRUE)
  expect_false(compare_file_odiff(fail_on_layout = TRUE)(a, b))
})

test_that("compare_file_odiff() warns and returns FALSE when odiff errors", {
  skip_if_no_odiff()
  dir <- withr::local_tempdir()
  a <- write_snapshot_png(file.path(dir, "a.png"))
  bad <- file.path(dir, "bad.png")
  writeLines("not an image", bad)
  expect_warning(
    res <- compare_file_odiff()(bad, a),
    "odiff could not compare 'bad.png' with 'a.png'"
  )
  expect_false(res)
})

# Snapshot names -------------------------------------------------------------

test_that("snapshot names are derived and validated", {
  nm <- odiffr:::.snapshot_image_name
  expect_equal(nm("dir/plot.png", NULL, "\"dir/plot.png\""), "plot.png")
  expect_equal(nm("dir/plot.jpg", NULL, "x"), "plot.jpg.png")
  expect_equal(nm(function() 1, NULL, "my_plot"), "my_plot.png")
  expect_equal(nm(1, NULL, "p.2"), "p.2.png")
  expect_equal(nm(1, "scatter", "x"), "scatter.png")
  expect_equal(nm(1, "scatter.PNG", "x"), "scatter.PNG")
  expect_error(nm(1, NULL, "function() plot(1)"), "Supply `name`")
  expect_error(nm(1, NULL, c("function() {", "plot(1)", "}")), "Supply `name`")
  expect_error(nm(1, NULL, "f(x)"), "Supply `name`")
  expect_error(nm(1, "a/b", "x"), "not a path")
  expect_error(nm(1, "", "x"), "non-empty")
  expect_error(nm(1, c("a", "b"), "x"), "non-empty")
})

test_that("expect_snapshot_image() requires a name for inline functions", {
  expect_error(
    expect_snapshot_image(function() plot(1:3)),
    "Supply `name`"
  )
})

test_that("expect_snapshot_image() skips when odiff is unavailable", {
  testthat::local_mocked_bindings(odiff_available = function() FALSE,
                                  .package = "odiffr")
  expect_condition(
    expect_snapshot_image("x.png"),
    class = "skip"
  )
})

# Snapshot input conversion ------------------------------------------------

test_that(".snapshot_image_file() always returns a fresh PNG copy", {
  skip_if_not_installed("png")
  src <- create_test_image(10, 10, "blue")
  on.exit(unlink(src), add = TRUE)

  out <- odiffr:::.snapshot_image_file(src)
  on.exit(unlink(out), add = TRUE)
  expect_false(identical(normalizePath(out), normalizePath(src)))
  expect_identical(readBin(out, "raw", 1e5), readBin(src, "raw", 1e5))

  out2 <- odiffr:::.snapshot_image_file(function() plot(1:3),
                                        plot_options(width = 2, height = 2,
                                                     res = 20))
  on.exit(unlink(out2), add = TRUE)
  expect_equal(dim(png::readPNG(out2))[1:2], c(40, 40))
})

test_that(".snapshot_image_file() converts non-PNG files with magick", {
  skip_if_not_installed("magick")
  src <- create_test_image(10, 10, "green")
  jpg <- tempfile(fileext = ".jpg")
  on.exit(unlink(c(src, jpg)), add = TRUE)
  magick::image_write(magick::image_read(src), jpg, format = "jpeg")

  out <- odiffr:::.snapshot_image_file(jpg)
  on.exit(unlink(out), add = TRUE)
  expect_equal(magick::image_info(magick::image_read(out))$format, "PNG")
})

# Full snapshot workflow -----------------------------------------------------

test_that("expect_snapshot_image() creates, passes and fails snapshots", {
  skip_if_no_odiff()
  skip_if_not_installed("png")

  img_dir <- withr::local_tempdir()
  img <- write_snapshot_png(file.path(img_dir, "img.png"))
  test_file <- local_snapshot_project(snap_body(img))
  snap_dir <- file.path(dirname(test_file), "_snaps", "img")
  snap <- file.path(snap_dir, "square.png")
  snap_new <- file.path(snap_dir, "square.new.png")

  # 1. First run creates the snapshot (with a warning)
  res <- run_snapshot_test(test_file)
  expect_equal(res$failed, 0)
  expect_false(res$error)
  expect_equal(res$warning, 1)
  expect_true(file.exists(snap))
  expect_identical(readBin(snap, "raw", 1e5), readBin(img, "raw", 1e5))

  # 2. Identical image passes
  res <- run_snapshot_test(test_file)
  expect_equal(res$failed, 0)
  expect_equal(res$warning, 0)
  expect_false(res$error)
  expect_false(file.exists(snap_new))

  # 3. A tiny change below the threshold passes: odiff is used, not byte
  #    equality
  write_snapshot_png(img, modify = "pixel")
  res <- run_snapshot_test(test_file)
  expect_equal(res$failed, 0)
  expect_false(res$error)
  expect_false(file.exists(snap_new))

  # 4. A visible change fails and writes <name>.new.png
  write_snapshot_png(img, modify = "region")
  res <- run_snapshot_test(test_file)
  expect_equal(res$failed, 1)
  expect_false(res$error)
  expect_true(file.exists(snap_new))
  expect_identical(readBin(snap_new, "raw", 1e5), readBin(img, "raw", 1e5))
  # The baseline itself is untouched
  expect_false(identical(readBin(snap, "raw", 1e5),
                         readBin(img, "raw", 1e5)))

  # 5. Restoring the original image passes again and removes the .new file
  write_snapshot_png(img)
  res <- run_snapshot_test(test_file)
  expect_equal(res$failed, 0)
  expect_false(file.exists(snap_new))
})

test_that("expect_snapshot_image() uses threshold and ignore_regions", {
  skip_if_no_odiff()
  skip_if_not_installed("png")

  img_dir <- withr::local_tempdir()
  img <- write_snapshot_png(file.path(img_dir, "img.png"))
  test_file <- local_snapshot_project(
    snap_body(img, ignore_regions = list(ignore_region(25, 25, 75, 75)))
  )
  run_snapshot_test(test_file)

  # The changed region is ignored
  write_snapshot_png(img, modify = "region")
  res <- run_snapshot_test(test_file)
  expect_equal(res$failed, 0)

  # With threshold = 0, the tiny change is detected
  img2 <- write_snapshot_png(file.path(img_dir, "img2.png"))
  test_file2 <- local_snapshot_project(snap_body(img2, threshold = 0))
  run_snapshot_test(test_file2)
  write_snapshot_png(img2, modify = "pixel")
  res <- run_snapshot_test(test_file2)
  expect_equal(res$failed, 1)
})

test_that("expect_snapshot_image() snapshots plots and supports variants", {
  skip_if_no_odiff()

  body <- c(
    "draw <- function() plot(1:10)",
    "test_that('plot snapshot', {",
    "  odiffr:::expect_snapshot_image(draw, variant = 'linux',",
    "    plot_options = odiffr:::plot_options(width = 3, height = 3, res = 30))",
    "})"
  )
  test_file <- local_snapshot_project(body)
  snap <- file.path(dirname(test_file), "_snaps", "linux", "img", "draw.png")

  res <- run_snapshot_test(test_file)
  expect_equal(res$failed, 0)
  expect_false(res$error)
  expect_true(file.exists(snap))
  expect_equal(dim(png::readPNG(snap))[1:2], c(90, 90))

  res <- run_snapshot_test(test_file)
  expect_equal(res$failed, 0)
  expect_equal(res$warning, 0)

  # Changing the plot fails
  writeLines(sub("plot(1:10)", "plot(10:1)", readLines(test_file),
                 fixed = TRUE), test_file)
  res <- run_snapshot_test(test_file)
  expect_equal(res$failed, 1)
})

test_that("expect_snapshot_image() snapshots ggplot objects", {
  skip_if_no_odiff()
  skip_if_not_installed("ggplot2")

  body <- c(
    "p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +",
    "  ggplot2::geom_point()",
    "test_that('ggplot snapshot', {",
    "  odiffr:::expect_snapshot_image(p,",
    "    plot_options = odiffr:::plot_options(width = 3, height = 3, res = 30))",
    "})"
  )
  test_file <- local_snapshot_project(body)
  snap <- file.path(dirname(test_file), "_snaps", "img", "p.png")

  run_snapshot_test(test_file)
  expect_true(file.exists(snap))
  res <- run_snapshot_test(test_file)
  expect_equal(res$failed, 0)
  expect_equal(res$warning, 0)
})
