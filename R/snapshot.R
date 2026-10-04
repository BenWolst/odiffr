#' Snapshot Testing for Images
#'
#' `expect_snapshot_image()` is a testthat snapshot expectation for images
#' that compares the image with its stored snapshot using odiff, rather than
#' requiring the files to be byte-for-byte identical. Snapshots are managed
#' with testthat's usual tools ([testthat::snapshot_review()],
#' [testthat::snapshot_accept()]).
#'
#' @param x The image to snapshot: a path to an image file (PNG; other
#'   formats are converted to PNG with magick), a magick-image
#'   object, a ggplot object, a function of no arguments that draws a plot
#'   (base or grid graphics) when called, or a recorded plot
#'   ([grDevices::recordPlot()]). Plots are rendered to PNG using
#'   `plot_options`.
#' @param name Snapshot file name. A `.png` extension is added if missing.
#'   If `NULL` (the default), the name is the base name of `x` when `x` is a
#'   file path, or the variable name when `x` is a simple variable (e.g.
#'   `expect_snapshot_image(p)` uses `"p.png"`). For any other expression
#'   (e.g. an inline function), `name` must be supplied. Names must be unique
#'   within a test file.
#' @param threshold Numeric; color difference threshold between 0.0 and 1.0.
#'   Default is 0.1.
#' @param antialiasing Logical; if `TRUE`, ignore antialiased pixels.
#'   Default is `FALSE`.
#' @param ignore_regions List of regions to ignore during comparison.
#'   Use [ignore_region()] to create regions, or pass a data.frame with
#'   columns `x1`, `y1`, `x2`, `y2`.
#' @param fail_on_layout Logical; if `TRUE` (the default), images with
#'   different dimensions do not match.
#' @param plot_options Options for rendering plot inputs, created with
#'   [plot_options()]. `NULL` uses the defaults of [plot_options()].
#' @param variant If not `NULL`, the snapshot is stored in a
#'   variant-specific subdirectory (`_snaps/<variant>/<file>/`). See the
#'   section on platform differences.
#' @param ... Additional arguments passed to [odiff_run()] (via
#'   [compare_file_odiff()]).
#'
#' @details
#' On the first run, the image is saved as the snapshot
#' `tests/testthat/_snaps/<test-file>/<name>.png` and testthat emits an
#' "Adding new file snapshot" warning. On subsequent runs the image is
#' compared with the snapshot using odiff and the expectation fails if they
#' differ (beyond `threshold`, after `ignore_regions` and, optionally,
#' antialiasing are taken into account). On failure, the new image is saved
#' next to the snapshot as `<name>.new.png`.
#'
#' Like [testthat::expect_snapshot_file()], on which it is built:
#' \itemize{
#'   \item It requires the third edition of testthat.
#'   \item It is skipped on CRAN (when `NOT_CRAN` is not `"true"`), because
#'     snapshots are not shipped reliably and image rendering differs
#'     between machines.
#'   \item Snapshots must be committed to version control: depending on
#'     the testthat version, a missing snapshot may be reported as a failure
#'     rather than created when running on CI (the `CI` environment variable
#'     is `"true"`).
#' }
#' The expectation is skipped if the odiff binary is not available.
#'
#' If odiff cannot compare the images (e.g. the stored snapshot is not a
#' valid image), a warning with odiff's error message is given and the
#' expectation fails, so the new image can still be reviewed and accepted.
#'
#' @section Reviewing changes:
#' When a snapshot changes, run [testthat::snapshot_review()] to compare the
#' old and new images side by side in an interactive viewer, then accept the
#' new image with [testthat::snapshot_accept()] (or from the viewer) if the
#' change is intended. Unwanted `.new.png` files are removed on the next
#' successful run.
#'
#' @section Platform differences:
#' Rendered plots can differ slightly between operating systems, graphics
#' devices and installed fonts. To reduce spurious failures:
#' \itemize{
#'   \item Install the ragg package: plots are then rendered with
#'     [ragg::agg_png()], which gives consistent output across platforms.
#'   \item Use a tolerant comparison (`threshold`, `antialiasing = TRUE`,
#'     `ignore_regions`).
#'   \item Store separate snapshots per platform with `variant`, e.g.
#'     `variant = Sys.info()[["sysname"]]`.
#' }
#'
#' @section Comparison with vdiffr:
#' vdiffr snapshots plots as SVG and compares the SVG text. odiffr compares
#' rendered pixels, which also works for images that are not plots (e.g.
#' screenshots or magick images) and tolerates small rendering differences.
#'
#' @return Invisibly returns `NULL`, like other testthat snapshot
#'   expectations.
#'
#' @seealso [compare_file_odiff()] for the comparison function,
#'   [expect_images_match()] for comparing against a baseline file that you
#'   manage yourself, [testthat::expect_snapshot_file()].
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # tests/testthat/test-plots.R
#' test_that("scatter plot is stable", {
#'   p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
#'     ggplot2::geom_point()
#'   expect_snapshot_image(p)  # snapshot: _snaps/plots/p.png
#' })
#'
#' test_that("base graphics histogram is stable", {
#'   expect_snapshot_image(
#'     function() hist(mtcars$mpg),
#'     name = "mpg-histogram",
#'     plot_options = plot_options(width = 5, height = 4),
#'     antialiasing = TRUE
#'   )
#' })
#'
#' test_that("screenshot is stable on each OS", {
#'   expect_snapshot_image(
#'     "output/screenshot.png",
#'     threshold = 0.2,
#'     ignore_regions = list(ignore_region(0, 0, 200, 40)),  # timestamp
#'     variant = Sys.info()[["sysname"]]
#'   )
#' })
#'
#' # After an intended change, review and accept the new snapshots:
#' testthat::snapshot_review("plots")
#' testthat::snapshot_accept("plots")
#' }
expect_snapshot_image <- function(x,
                                  name = NULL,
                                  threshold = 0.1,
                                  antialiasing = FALSE,
                                  ignore_regions = NULL,
                                  fail_on_layout = TRUE,
                                  plot_options = NULL,
                                  variant = NULL,
                                  ...) {
  expr_label <- deparse(substitute(x))
  check_testthat()

  name <- .snapshot_image_name(x, name, expr_label)

  # Skip if odiff not available
  if (!odiff_available()) {
    testthat::skip("odiff binary not available")
  }

  path <- .snapshot_image_file(x, plot_options = plot_options)
  on.exit(unlink(path), add = TRUE)

  compare <- compare_file_odiff(
    threshold = threshold,
    antialiasing = antialiasing,
    ignore_regions = ignore_regions,
    fail_on_layout = fail_on_layout,
    ...
  )

  testthat::expect_snapshot_file(
    path,
    name = name,
    compare = compare,
    variant = variant
  )

  invisible(NULL)
}


#' Compare Files with odiff (for testthat Snapshots)
#'
#' A function factory that returns a comparison function suitable for the
#' `compare` argument of [testthat::expect_snapshot_file()]. The returned
#' function takes the paths of the old (snapshot) and new image files and
#' returns `TRUE` if odiff considers them a match. [expect_snapshot_image()]
#' uses it internally; use it directly when you write image files yourself.
#'
#' @inheritParams expect_snapshot_image
#' @param ... Additional arguments passed to [odiff_run()].
#'
#' @return A function with arguments `old` and `new` (file paths) that
#'   returns a single `TRUE` or `FALSE`. If odiff cannot compare the files
#'   (`reason == "error"`), the function gives a warning with odiff's error
#'   message and returns `FALSE`.
#'
#' @seealso [expect_snapshot_image()]
#'
#' @export
#'
#' @examples
#' \dontrun{
#' test_that("exported chart is stable", {
#'   path <- tempfile(fileext = ".png")
#'   save_my_chart(path)
#'   testthat::expect_snapshot_file(
#'     path,
#'     name = "chart.png",
#'     compare = compare_file_odiff(threshold = 0.2, antialiasing = TRUE)
#'   )
#' })
#' }
compare_file_odiff <- function(threshold = 0.1,
                               antialiasing = FALSE,
                               ignore_regions = NULL,
                               fail_on_layout = TRUE,
                               ...) {
  # Force arguments now so later changes in the caller do not leak in
  force(threshold)
  force(antialiasing)
  force(ignore_regions)
  force(fail_on_layout)
  dots <- list(...)

  function(old, new) {
    result <- do.call(compare_images, c(
      list(
        img1 = old,
        img2 = new,
        diff_output = NULL,
        threshold = threshold,
        antialiasing = antialiasing,
        fail_on_layout = fail_on_layout,
        ignore_regions = ignore_regions
      ),
      dots
    ))

    if (identical(result$reason, "error")) {
      err <- .result_error(result)
      warning(
        sprintf("odiff could not compare '%s' with '%s': %s",
                basename(old), basename(new),
                if (is.na(err)) "unknown error" else err),
        call. = FALSE
      )
      return(FALSE)
    }

    isTRUE(result$match)
  }
}


# Internal: determine the snapshot file name for expect_snapshot_image()
.snapshot_image_name <- function(x, name, expr_label) {
  if (is.null(name)) {
    expr_label <- paste(expr_label, collapse = "")
    if (is.character(x) && length(x) == 1 && !is.na(x) && nzchar(x)) {
      name <- basename(x)
    } else if (grepl("^[A-Za-z][A-Za-z0-9._]*$", expr_label)) {
      name <- expr_label
    } else {
      stop(
        "Can't derive a snapshot name from `", expr_label, "`. ",
        "Supply `name`, e.g. expect_snapshot_image(..., name = \"my-plot\").",
        call. = FALSE
      )
    }
  }

  if (!is.character(name) || length(name) != 1 || is.na(name) ||
      !nzchar(trimws(name))) {
    stop("name must be a single non-empty character string.", call. = FALSE)
  }
  if (grepl("[/\\\\]", name)) {
    stop("name must be a file name, not a path: ", name, call. = FALSE)
  }

  ext <- tools::file_ext(name)
  if (!identical(tolower(ext), "png")) {
    name <- paste0(name, ".png")
  }
  name
}


# Internal: convert a snapshot input into a temporary PNG file (always a
# fresh temp file that the caller removes)
.snapshot_image_file <- function(x, plot_options = NULL) {
  resolved <- .resolve_image_input(x, "x", plot_options = plot_options)
  if (isTRUE(resolved$temp)) {
    return(resolved$path)
  }
  path <- tempfile(fileext = ".png")
  if (!identical(tolower(tools::file_ext(resolved$path)), "png")) {
    # Snapshots are stored as PNG: convert other formats with magick
    if (!.has_magick()) {
      stop("x must be a PNG file (converting other formats requires the ",
           "'magick' package).", call. = FALSE)
    }
    magick::image_write(magick::image_read(resolved$path), path = path,
                        format = "png")
    return(path)
  }
  # File input: copy, so the snapshot machinery never touches the original
  if (!file.copy(resolved$path, path)) {
    stop("Could not copy ", resolved$path, " to a temporary file.",
         call. = FALSE)
  }
  path
}
