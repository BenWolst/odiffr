# Run odiff Command (Low-Level)

Direct wrapper around the odiff CLI with zero external dependencies.
Returns a structured list with comparison results.

## Usage

``` r
odiff_run(
  img1,
  img2,
  diff_output = NULL,
  threshold = 0.1,
  antialiasing = FALSE,
  fail_on_layout = FALSE,
  diff_mask = FALSE,
  diff_overlay = NULL,
  diff_color = NULL,
  diff_lines = FALSE,
  reduce_ram = FALSE,
  ignore_regions = NULL,
  timeout = 60
)
```

## Arguments

- img1:

  Character; path to the first (baseline) image file.

- img2:

  Character; path to the second (comparison) image file.

- diff_output:

  Character or `NULL`; optional path for the diff output image. Must
  have `.png` extension. If `NULL`, no diff image is created.

- threshold:

  Numeric; color difference threshold between 0.0 and 1.0. Lower values
  are more precise. Default is 0.1.

- antialiasing:

  Logical; if `TRUE`, ignore antialiased pixels. Default is `FALSE`.

- fail_on_layout:

  Logical; if `TRUE`, fail immediately if images have different
  dimensions. Default is `FALSE`.

- diff_mask:

  Logical; if `TRUE`, output only the changed pixels in the diff image.
  Default is `FALSE`.

- diff_overlay:

  Logical or numeric; if `TRUE` or a number between 0 and 1, add a white
  shaded overlay to the diff image for easier reading. Default is `NULL`
  (no overlay).

- diff_color:

  Character; hex color for highlighting differences (e.g., `"#FF0000"`).
  Default is `NULL` (uses odiff default, red).

- diff_lines:

  Logical; if `TRUE`, include line numbers containing different pixels
  in the output. Default is `FALSE`.

- reduce_ram:

  Logical; if `TRUE`, use less memory but run slower. Useful for very
  large images. Default is `FALSE`.

- ignore_regions:

  A list of regions to ignore during comparison. Each region should be a
  list with `x1`, `y1`, `x2`, `y2` components, or use
  [`ignore_region()`](https://benwolst.github.io/odiffr/reference/ignore_region.md)
  to create them. Can also be a data.frame with these columns.

- timeout:

  Numeric; timeout in seconds for the odiff process. Default is 60.

## Value

A list with the following components:

- match:

  Logical; `TRUE` if images match, `FALSE` otherwise.

- reason:

  Character; one of `"match"`, `"pixel-diff"`, `"layout-diff"`, or
  `"error"`.

- diff_count:

  Integer; number of different pixels, or `NA`.

- diff_percentage:

  Numeric; percentage of different pixels, or `NA`.

- diff_lines:

  Integer vector of line numbers with differences, or `NULL`.

- exit_code:

  Integer; odiff exit code (0 = match, 21 = layout diff, 22 = pixel
  diff).

- stdout:

  Character; raw stdout output.

- stderr:

  Character; raw stderr output.

- img1:

  Character; path to first image.

- img2:

  Character; path to second image.

- diff_output:

  Character or `NULL`; path to diff image if created.

- duration:

  Numeric; time elapsed in seconds.

## See also

[`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md)
for a higher-level interface,
[`ignore_region()`](https://benwolst.github.io/odiffr/reference/ignore_region.md)
for creating ignore regions.

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic comparison
result <- odiff_run("baseline.png", "current.png")
result$match

# With diff output
result <- odiff_run("baseline.png", "current.png", "diff.png")

# With threshold and antialiasing
result <- odiff_run("baseline.png", "current.png",
                    threshold = 0.05, antialiasing = TRUE)

# Ignoring specific regions
result <- odiff_run("baseline.png", "current.png",
                    ignore_regions = list(
                      ignore_region(10, 10, 100, 50),
                      ignore_region(200, 200, 300, 300)
                    ))
} # }
```
