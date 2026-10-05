# Plot Rendering Options

Create a set of options controlling how plot inputs (ggplot objects,
plotting functions and recorded plots) are rendered to PNG before being
compared by
[`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md),
[`expect_images_match()`](https://benwolst.github.io/odiffr/reference/expect_images.md),
[`expect_images_differ()`](https://benwolst.github.io/odiffr/reference/expect_images.md)
and
[`expect_snapshot_image()`](https://benwolst.github.io/odiffr/reference/expect_snapshot_image.md).

## Usage

``` r
plot_options(width = 7, height = 5, units = "in", res = 96, bg = "white")
```

## Arguments

- width, height:

  Plot dimensions, in `units`. Default is 7 x 5 inches.

- units:

  Units for `width` and `height`: one of `"in"`, `"cm"`, `"mm"` or
  `"px"`. Default is `"in"`.

- res:

  Resolution in pixels per inch. Default is 96.

- bg:

  Background colour. Default is `"white"`.

## Value

A list of class `odiffr_plot_options`, to be passed as the
`plot_options` argument.

## Details

Plots are rendered with
[`ragg::agg_png()`](https://ragg.r-lib.org/reference/agg_png.html) when
the ragg package is installed (recommended: its output is consistent
across platforms), and with
[`grDevices::png()`](https://rdrr.io/r/grDevices/png.html) otherwise.
When comparing a plot against a stored baseline PNG, render it with the
same options (and the same graphics device) that were used to create the
baseline, or the comparison will fail with a layout difference.

## See also

[`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md),
[`expect_snapshot_image()`](https://benwolst.github.io/odiffr/reference/expect_snapshot_image.md)

## Examples

``` r
plot_options(width = 4, height = 3, res = 72)
#> <odiffr plot options> 4 x 3 in, 72 dpi, bg = white
```
