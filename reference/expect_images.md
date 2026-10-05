# testthat Expectations for Image Comparison

Assert that images match or differ using odiff. These expectations are
designed for visual regression testing in testthat test suites.

## Usage

``` r
expect_images_match(
  actual,
  expected,
  threshold = 0.1,
  antialiasing = FALSE,
  fail_on_layout = TRUE,
  ignore_regions = NULL,
  ...,
  info = NULL,
  label = NULL
)

expect_images_differ(
  img1,
  img2,
  threshold = 0.1,
  antialiasing = FALSE,
  ...,
  info = NULL,
  label = NULL
)
```

## Arguments

- actual:

  Path to the actual/current image, or a magick-image object.

- expected:

  Path to the expected/baseline image, or a magick-image object.

- threshold:

  Numeric; colour difference threshold between 0.0 and 1.0. Default is
  0.1.

- antialiasing:

  Logical; if `TRUE`, ignore antialiased pixels. Default is `FALSE`.

- fail_on_layout:

  Logical; if `TRUE`, fail if images have different dimensions. Default
  is `TRUE` for tests (stricter than
  [`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md)).

- ignore_regions:

  List of regions to ignore during comparison. Use
  [`ignore_region()`](https://benwolst.github.io/odiffr/reference/ignore_region.md)
  to create regions, or pass a data.frame with columns `x1`, `y1`, `x2`,
  `y2`.

- ...:

  Additional arguments passed to
  [`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md).

- info:

  Extra information to be included in the failure message (useful for
  providing context about what was being tested).

- label:

  Optional custom label for the actual image in failure messages. If not
  provided, uses the deparsed expression.

- img1, img2:

  Paths to images being compared (for `expect_images_differ`).

## Value

Invisibly returns the comparison result (a data.frame/tibble with match,
reason, diff_count, diff_percentage, error, etc.), allowing further
inspection if needed.

## Details

`expect_images_match()` asserts that two images are visually identical
(within the specified threshold). On failure, a diff image is saved to
`tests/testthat/_odiffr/` by default, which can be controlled via
`options(odiffr.save_diff = FALSE)` or
`options(odiffr.diff_dir = "path")`. Diff file names are deterministic,
so re-running a failing test overwrites the previous diff rather than
accumulating files: for file paths the name is
`<actual>_vs_<expected>.png` (basenames without extension); for
magick-image objects it is built from the `label`/expressions passed
(e.g. `img_new_vs_img_old.png`). If two different comparisons in the
same session would produce the same name (e.g. identical basenames in
different directories), the parent directory names, or else a numeric
suffix, are added. A stale diff image left by a previous failing run is
removed when the expectation is run again (odiff writes no diff image
when the images match).

`expect_images_differ()` asserts that two images are visually different.
No diff image is saved since there's nothing to debug when images match
unexpectedly.

If odiff cannot compare the images (`reason == "error"`, e.g. a file
that cannot be loaded or has an unsupported format), both expectations
fail and the failure message includes odiff's error message. In
particular, an error does not count as the images differing for
`expect_images_differ()`.

Both expectations will skip (not fail) if the odiff binary is not
available, making tests portable across environments.

## Comparison with vdiffr

odiffr expectations are designed for **pixel-based** comparison of
screenshots, rendered images, and bitmap files. For **SVG-based**
comparison of ggplot2 and grid graphics, consider using the vdiffr
package instead. The two approaches are complementary.

## See also

[`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md)
for the underlying comparison function,
[`ignore_region()`](https://benwolst.github.io/odiffr/reference/ignore_region.md)
for excluding regions from comparison.

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic visual regression test
test_that("login page renders correctly", {
  skip_if_no_odiff()

  expect_images_match(
    "screenshots/login_current.png",
    "screenshots/login_baseline.png"
  )
})

# With tolerance for minor differences
test_that("chart renders correctly", {
  skip_if_no_odiff()

  expect_images_match(
    "actual_chart.png",
    "expected_chart.png",
    threshold = 0.2,
    antialiasing = TRUE,
    ignore_regions = list(
      ignore_region(0, 0, 100, 30)  # Ignore timestamp
    )
  )
})

# Assert images are different
test_that("button changes on hover", {
  skip_if_no_odiff()

  expect_images_differ(
    "button_normal.png",
    "button_hover.png"
  )
})
} # }
```
