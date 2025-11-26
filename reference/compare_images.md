# Compare Two Images

High-level function for comparing images with convenient output. Returns
a tibble if the tibble package is available, otherwise a data.frame.
Accepts file paths or magick-image objects.

## Usage

``` r
compare_images(
  img1,
  img2,
  diff_output = NULL,
  threshold = 0.1,
  antialiasing = FALSE,
  fail_on_layout = FALSE,
  ignore_regions = NULL,
  ...
)
```

## Arguments

- img1:

  Path to the first image, or a magick-image object.

- img2:

  Path to the second image, or a magick-image object.

- diff_output:

  Path for the diff output image (PNG only). Use `NULL` for no diff
  output, or `TRUE` to auto-generate a temporary file path.

- threshold:

  Numeric; color difference threshold between 0.0 and 1.0. Default is
  0.1.

- antialiasing:

  Logical; if `TRUE`, ignore antialiased pixels. Default is `FALSE`.

- fail_on_layout:

  Logical; if `TRUE`, fail if images have different dimensions. Default
  is `FALSE`.

- ignore_regions:

  List of regions to ignore during comparison. Use
  [`ignore_region()`](https://benwolst.github.io/odiffr/reference/ignore_region.md)
  to create regions, or pass a data.frame with columns `x1`, `y1`, `x2`,
  `y2`.

- ...:

  Additional arguments passed to
  [`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md).

## Value

A tibble (if available) or data.frame with columns:

- match:

  Logical; `TRUE` if images match.

- reason:

  Character; comparison result reason.

- diff_count:

  Integer; number of different pixels.

- diff_percentage:

  Numeric; percentage of different pixels.

- diff_output:

  Character; path to diff image, or `NA`.

- img1:

  Character; path to first image.

- img2:

  Character; path to second image.

## See also

[`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md)
for the low-level interface,
[`ignore_region()`](https://benwolst.github.io/odiffr/reference/ignore_region.md)
for creating ignore regions.

## Examples

``` r
if (FALSE) { # \dontrun{
# Compare two image files
result <- compare_images("baseline.png", "current.png")
result$match

# With diff output
result <- compare_images("baseline.png", "current.png", diff_output = TRUE)
result$diff_output

# Compare magick-image objects (requires magick package)
library(magick)
img1 <- image_read("baseline.png")
img2 <- image_read("current.png")
result <- compare_images(img1, img2)

# Ignore specific regions
result <- compare_images("baseline.png", "current.png",
                         ignore_regions = list(
                           ignore_region(0, 0, 100, 50),    # Header
                           ignore_region(0, 500, 800, 600)  # Footer
                         ))
} # }
```
