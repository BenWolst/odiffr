# Compare Two Images

High-level function for comparing images with convenient output. Returns
a tibble if the tibble package is available, otherwise a data.frame.
Accepts file paths, magick-image objects, and plots (ggplot objects,
functions that draw a plot, or recorded plots), which are rendered to a
temporary PNG file before comparison.

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
  plot_options = NULL,
  ...
)
```

## Arguments

- img1:

  Path to the first image, a magick-image object, or a plot: a ggplot
  object, a function of no arguments that draws a plot (base or grid
  graphics) or returns a ggplot, lattice or grid object when called, or
  a recorded plot
  ([`grDevices::recordPlot()`](https://rdrr.io/r/grDevices/recordplot.html)).

- img2:

  Path to the second image, a magick-image object, or a plot (see
  `img1`).

- diff_output:

  Path for the diff output image (PNG only). Use `NULL` for no diff
  output, or `TRUE` to auto-generate a temporary file path.

- threshold:

  Numeric; colour difference threshold between 0.0 and 1.0. Default is
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

- plot_options:

  Options for rendering plot inputs, created with
  [`plot_options()`](https://benwolst.github.io/odiffr/reference/plot_options.md).
  `NULL` (the default) uses
  [`plot_options()`](https://benwolst.github.io/odiffr/reference/plot_options.md):
  7 x 5 inches at 96 dpi on a white background. Ignored for file and
  magick-image inputs.

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

  Character; path to first image (`"<magick-image>"` or `"<plot>"` for
  magick-image and plot inputs).

- img2:

  Character; path to second image (labelled as `img1`).

- error:

  Character; the error message reported by odiff when `reason` is
  `"error"` (e.g. an image could not be loaded or has an unsupported
  format), otherwise `NA`. This is always the last column.

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

# Compare a ggplot against a baseline PNG (rendered with ragg if
# installed, otherwise grDevices::png())
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
result <- compare_images("baseline_plot.png", p,
                         plot_options = plot_options(width = 6, height = 4))

# Base graphics: pass a function that draws the plot
result <- compare_images("baseline_hist.png", function() hist(mtcars$mpg))

# Ignore specific regions
result <- compare_images("baseline.png", "current.png",
                         ignore_regions = list(
                           ignore_region(0, 0, 100, 50),    # Header
                           ignore_region(0, 500, 800, 600)  # Footer
                         ))
} # }
```
