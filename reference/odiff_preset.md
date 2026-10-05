# Comparison Presets

Named sets of comparison settings (`threshold` and `antialiasing`) for
common situations. Pass the name as `preset` to
[`compare_file_odiff()`](https://benwolst.github.io/odiffr/reference/compare_file_odiff.md),
[`expect_snapshot_image()`](https://benwolst.github.io/odiffr/reference/expect_snapshot_image.md)
or
[`snapshot_report()`](https://benwolst.github.io/odiffr/reference/snapshot_report.md),
or splice the values into other functions with
[`do.call()`](https://rdrr.io/r/base/do.call.html).

## Usage

``` r
odiff_preset(name = c("strict", "default", "screenshot", "cross_platform"))
```

## Arguments

- name:

  One of `"strict"`, `"default"`, `"screenshot"` or `"cross_platform"`.

## Value

A named list with elements `threshold` and `antialiasing`.

## Details

- `"strict"`:

  `threshold = 0`, `antialiasing = FALSE`. Any change to any pixel
  fails.

- `"default"`:

  `threshold = 0.1`, `antialiasing = FALSE`. The defaults of
  [`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md)
  and
  [`expect_snapshot_image()`](https://benwolst.github.io/odiffr/reference/expect_snapshot_image.md).

- `"screenshot"`:

  `threshold = 0.1`, `antialiasing = TRUE`. For browser screenshots
  (shinytest2, webshot2, chromote) and plots compared on the same
  platform. Browsers render the edges of rounded corners, circles and
  thin borders with slightly different anti-aliasing from run to run;
  odiff's anti-aliasing detection ignores those pixels. The colour
  threshold stays at 0.1 so that real colour changes are still caught.

- `"cross_platform"`:

  `threshold = 0.2`, `antialiasing = TRUE`. For baselines shared across
  machines or operating systems. Also tolerates edges that move by up to
  about half a pixel, thicker anti-aliased borders and small colour or
  gamma shifts. The price: changes between colours of similar brightness
  (e.g. a blue element turning green) and very faint elements (light
  grey on white) can go unnoticed. Different fonts or text rendering are
  not tolerated; use snapshot variants or `ignore_regions` for those.

The values were calibrated with images rendered by ragg: shapes with
rounded corners and 1px borders drawn at sub-pixel offsets (0.25 and 0.5
px), and with a different anti-aliasing rasteriser (cairo), should pass,
while a new 10 x 10 pixel element, or a 10 x 10 pixel patch recoloured
from blue to green, must fail. With the `"default"` settings the
anti-aliasing-only differences fail (5 to 439 differing pixels); with
`"screenshot"` they pass, except a 0.5 px shift of a bordered shape (2
pixels), which `"cross_platform"` passes too. A blue to green
recolouring is detected up to a threshold of 0.14, which is why
`"screenshot"` keeps 0.1. The calibration is part of the package's
tests.

## See also

[`compare_file_odiff()`](https://benwolst.github.io/odiffr/reference/compare_file_odiff.md),
[`expect_snapshot_image()`](https://benwolst.github.io/odiffr/reference/expect_snapshot_image.md)

## Examples

``` r
odiff_preset("screenshot")
#> $threshold
#> [1] 0.1
#> 
#> $antialiasing
#> [1] TRUE
#> 

if (FALSE) { # \dontrun{
# Use with any comparison function
do.call(compare_images, c(list("before.png", "after.png"),
                          odiff_preset("cross_platform")))
} # }
```
