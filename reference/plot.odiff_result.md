# Plot an odiff Comparison

Display the baseline, current and diff images of an
[`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md)
result in the current graphics device, using base graphics.

## Usage

``` r
# S3 method for class 'odiff_result'
plot(x, which = c("all", "diff", "baseline", "current"), ...)
```

## Arguments

- x:

  An `odiff_result` object returned by
  [`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md).

- which:

  Which image(s) to show: `"all"` (default) shows the baseline, current
  and diff images side by side; `"diff"`, `"baseline"` or `"current"`
  show a single image.

- ...:

  Currently unused.

## Value

`x`, invisibly.

## Details

PNG images are read with
[`png::readPNG()`](https://rdrr.io/pkg/png/man/readPNG.html) (the png
package must be installed). Other formats (JPEG, WEBP, TIFF, ...) are
read with the magick package if it is installed.

A diff image is only available when the comparison was run with
`diff_output` and the images differ; otherwise the diff panel says "No
diff image".

The graphical parameters
([`par()`](https://rdrr.io/r/graphics/par.html)) are restored on exit.

For data-frame results of
[`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md)
or a row of a batch, use
[`diff_image()`](https://benwolst.github.io/odiffr/reference/diff_image.md)
to get the diff image.

## See also

[`diff_image()`](https://benwolst.github.io/odiffr/reference/diff_image.md),
[`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md)

## Examples

``` r
if (FALSE) { # \dontrun{
result <- odiff_run("baseline.png", "current.png", diff_output = "diff.png")
plot(result)
plot(result, which = "diff")
} # }
```
