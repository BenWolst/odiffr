# Snapshot Testing for Images

`expect_snapshot_image()` is a testthat snapshot expectation for images
that compares the image with its stored snapshot using odiff, rather
than requiring the files to be byte-for-byte identical. Snapshots are
managed with testthat's usual tools
([`testthat::snapshot_review()`](https://testthat.r-lib.org/reference/snapshot_accept.html),
[`testthat::snapshot_accept()`](https://testthat.r-lib.org/reference/snapshot_accept.html)).

## Usage

``` r
expect_snapshot_image(
  x,
  name = NULL,
  threshold = 0.1,
  antialiasing = FALSE,
  ignore_regions = NULL,
  fail_on_layout = TRUE,
  plot_options = NULL,
  variant = NULL,
  ...,
  preset = NULL,
  diff_dir = getOption("odiffr.snapshot_diff_dir")
)
```

## Arguments

- x:

  The image to snapshot: a path to an image file (PNG; other formats are
  converted to PNG with magick), a magick-image object, a ggplot object,
  a function of no arguments that draws a plot (base or grid graphics)
  or returns a ggplot, lattice or grid object when called, or a recorded
  plot
  ([`grDevices::recordPlot()`](https://rdrr.io/r/grDevices/recordplot.html)).
  Plots are rendered to PNG using `plot_options`.

- name:

  Snapshot file name. A `.png` extension is added if missing. If `NULL`
  (the default), the name is the base name of `x` when `x` is a file
  path, or the variable name when `x` is a simple variable (e.g.
  `expect_snapshot_image(p)` uses `"p.png"`). For any other expression
  (e.g. an inline function), `name` must be supplied. Names must be
  unique within a test file.

- threshold:

  Numeric; colour difference threshold between 0.0 and 1.0. Default is
  0.1 (or the value from `preset`).

- antialiasing:

  Logical; if `TRUE`, ignore antialiased pixels. Default is `FALSE` (or
  the value from `preset`).

- ignore_regions:

  List of regions to ignore during comparison. Use
  [`ignore_region()`](https://benwolst.github.io/odiffr/reference/ignore_region.md)
  to create regions, or pass a data.frame with columns `x1`, `y1`, `x2`,
  `y2`.

- fail_on_layout:

  Logical; if `TRUE` (the default), images with different dimensions do
  not match.

- plot_options:

  Options for rendering plot inputs, created with
  [`plot_options()`](https://benwolst.github.io/odiffr/reference/plot_options.md).
  `NULL` uses the defaults of
  [`plot_options()`](https://benwolst.github.io/odiffr/reference/plot_options.md).

- variant:

  If not `NULL`, the snapshot is stored in a variant-specific
  subdirectory (`_snaps/<variant>/<file>/`). See the section on platform
  differences.

- ...:

  Additional arguments passed to
  [`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md)
  (via
  [`compare_file_odiff()`](https://benwolst.github.io/odiffr/reference/compare_file_odiff.md)).

- preset:

  Optional name of a comparison preset, see
  [`odiff_preset()`](https://benwolst.github.io/odiffr/reference/odiff_preset.md):
  `"strict"`, `"default"`, `"screenshot"` or `"cross_platform"`. The
  preset supplies `threshold` and `antialiasing`; values given
  explicitly for those arguments take precedence. `NULL` (the default)
  uses the argument defaults.

- diff_dir:

  Where to write a diff image when the comparison fails. See the section
  "Diff images" in
  [`compare_file_odiff()`](https://benwolst.github.io/odiffr/reference/compare_file_odiff.md).
  `NULL` (the default, unless the `odiffr.snapshot_diff_dir` option is
  set) uses `tests/testthat/_odiffr/`; `FALSE` disables diff images.

## Value

Invisibly returns `NULL`, like other testthat snapshot expectations.

## Details

On the first run, the image is saved as the snapshot
`tests/testthat/_snaps/<test-file>/<name>.png` and testthat emits an
"Adding new file snapshot" warning. On subsequent runs the image is
compared with the snapshot using odiff and the expectation fails if they
differ (beyond `threshold`, after `ignore_regions` and, optionally,
antialiasing are taken into account). On failure, the new image is saved
next to the snapshot as `<name>.new.png`, and a diff image highlighting
the changed pixels is written to `tests/testthat/_odiffr/` (outside
`_snaps/`, see
[`compare_file_odiff()`](https://benwolst.github.io/odiffr/reference/compare_file_odiff.md));
a message gives its path.

Like
[`testthat::expect_snapshot_file()`](https://testthat.r-lib.org/reference/expect_snapshot_file.html),
on which it is built:

- It requires the third edition of testthat.

- It is skipped on CRAN (when `NOT_CRAN` is not `"true"`), because
  snapshots are not shipped reliably and image rendering differs between
  machines.

- Snapshots must be committed to version control: depending on the
  testthat version, a missing snapshot may be reported as a failure
  rather than created when running on CI (the `CI` environment variable
  is `"true"`).

The expectation is skipped if the odiff binary is not available.

If odiff cannot compare the images (e.g. the stored snapshot is not a
valid image), a warning with odiff's error message is given and the
expectation fails, so the new image can still be reviewed and accepted.

## Reviewing changes

When a snapshot changes, run
[`testthat::snapshot_review()`](https://testthat.r-lib.org/reference/snapshot_accept.html)
to compare the old and new images side by side in an interactive viewer,
then accept the new image with
[`testthat::snapshot_accept()`](https://testthat.r-lib.org/reference/snapshot_accept.html)
(or from the viewer) if the change is intended. Unwanted `.new.png`
files are removed on the next successful run.

## Platform differences

Rendered plots can differ slightly between operating systems, graphics
devices and installed fonts. To reduce spurious failures:

- Install the ragg package: plots are then rendered with
  [`ragg::agg_png()`](https://ragg.r-lib.org/reference/agg_png.html),
  which gives consistent output across platforms.

- Use a tolerant comparison (`preset = "screenshot"` or
  `preset = "cross_platform"`, or `threshold`, `antialiasing = TRUE`,
  `ignore_regions`).

- Store separate snapshots per platform with `variant`, e.g.
  `variant = Sys.info()[["sysname"]]`.

## Comparison with vdiffr

vdiffr snapshots plots as SVG and compares the SVG text. odiffr compares
rendered pixels, which also works for images that are not plots (e.g.
screenshots or magick images) and tolerates small rendering differences.

## See also

[`compare_file_odiff()`](https://benwolst.github.io/odiffr/reference/compare_file_odiff.md)
for the comparison function,
[`expect_images_match()`](https://benwolst.github.io/odiffr/reference/expect_images.md)
for comparing against a baseline file that you manage yourself,
[`testthat::expect_snapshot_file()`](https://testthat.r-lib.org/reference/expect_snapshot_file.html).

## Examples

``` r
if (FALSE) { # \dontrun{
# tests/testthat/test-plots.R
test_that("scatter plot is stable", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point()
  expect_snapshot_image(p)  # snapshot: _snaps/plots/p.png
})

test_that("base graphics histogram is stable", {
  expect_snapshot_image(
    function() hist(mtcars$mpg),
    name = "mpg-histogram",
    plot_options = plot_options(width = 5, height = 4),
    antialiasing = TRUE
  )
})

test_that("screenshot is stable on each OS", {
  expect_snapshot_image(
    "output/screenshot.png",
    preset = "screenshot",
    ignore_regions = list(ignore_region(0, 0, 200, 40)),  # timestamp
    variant = Sys.info()[["sysname"]]
  )
})

# After an intended change, review and accept the new snapshots:
testthat::snapshot_review("plots")
testthat::snapshot_accept("plots")
} # }
```
