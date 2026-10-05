# Compare Files with odiff (for testthat and shinytest2 Snapshots)

A function factory that returns a comparison function suitable for the
`compare` argument of
[`testthat::expect_snapshot_file()`](https://testthat.r-lib.org/reference/expect_snapshot_file.html)
and of `shinytest2::AppDriver$expect_screenshot()`. The returned
function takes the paths of the old (snapshot) and new image files and
returns `TRUE` if odiff considers them a match. When they do not match,
it writes a diff image highlighting the changed pixels and reports where
it is.
[`expect_snapshot_image()`](https://benwolst.github.io/odiffr/reference/expect_snapshot_image.md)
uses it internally; use it directly when you write image files yourself
or take screenshots with shinytest2.

## Usage

``` r
compare_file_odiff(
  threshold = 0.1,
  antialiasing = FALSE,
  ignore_regions = NULL,
  fail_on_layout = TRUE,
  ...,
  preset = NULL,
  diff_dir = getOption("odiffr.snapshot_diff_dir")
)
```

## Arguments

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

- ...:

  Additional arguments passed to
  [`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md).

- preset:

  Optional name of a comparison preset, see
  [`odiff_preset()`](https://benwolst.github.io/odiffr/reference/odiff_preset.md):
  `"strict"`, `"default"`, `"screenshot"` or `"cross_platform"`. The
  preset supplies `threshold` and `antialiasing`; values given
  explicitly for those arguments take precedence. `NULL` (the default)
  uses the argument defaults.

- diff_dir:

  Directory for diff images of failed comparisons. `NULL` (the default,
  unless the `odiffr.snapshot_diff_dir` option is set) chooses a
  directory automatically, see "Diff images". `FALSE` disables diff
  images. The directory is resolved each time the comparison runs.

## Value

A function with arguments `old` and `new` (file paths) that returns a
single `TRUE` or `FALSE`. If odiff cannot compare the files
(`reason == "error"`), the function gives a warning with odiff's error
message and returns `FALSE`.

## Diff images

testthat removes unrecognised files from `tests/testthat/_snaps/`, so
diff images are written elsewhere. With `diff_dir = NULL` the directory
is, in order of preference:

1.  the `odiffr.diff_dir` option (shared with
    [`expect_images_match()`](https://benwolst.github.io/odiffr/reference/expect_images.md));

2.  `tests/testthat/_odiffr/` when running tests (or when called from a
    package root that has a `tests/testthat` directory);

3.  a directory in [`tempdir()`](https://rdrr.io/r/base/tempfile.html)
    otherwise.

Setting `options(odiffr.save_diff = FALSE)` disables automatic diff
images (an explicit `diff_dir` still wins).

Inside that directory, the layout below `_snaps/` is mirrored and the
file is named after the snapshot: the diff for
`_snaps/<variant>/<test-file>/<name>.png` is
`<diff_dir>/<variant>/<test-file>/<name>_diff.png`. Re-running a failing
test overwrites the diff; a passing comparison removes a stale one. Add
`tests/testthat/_odiffr/` to `.gitignore` and `.Rbuildignore`.

When a comparison fails, a message (not a warning, so it does not add a
warning to the test results) such as
`odiff: 1.26% pixels differ (126 px) in 'plot.png'; diff image: <path>`
is shown.

## See also

[`expect_snapshot_image()`](https://benwolst.github.io/odiffr/reference/expect_snapshot_image.md),
[`odiff_preset()`](https://benwolst.github.io/odiffr/reference/odiff_preset.md),
[`snapshot_report()`](https://benwolst.github.io/odiffr/reference/snapshot_report.md)
for reviewing failed snapshots on CI.

## Examples

``` r
if (FALSE) { # \dontrun{
test_that("exported chart is stable", {
  path <- tempfile(fileext = ".png")
  save_my_chart(path)
  testthat::expect_snapshot_file(
    path,
    name = "chart.png",
    compare = compare_file_odiff(threshold = 0.2, antialiasing = TRUE)
  )
})

# shinytest2: tolerate anti-aliasing noise in browser screenshots
test_that("app looks right", {
  app <- shinytest2::AppDriver$new()
  app$expect_screenshot(compare = compare_file_odiff(preset = "screenshot"))
})
} # }
```
