# Get the Diff Image of a Comparison

Read the diff image produced by a comparison.

## Usage

``` r
diff_image(x, as = c("magick", "raster"))
```

## Arguments

- x:

  An `odiff_result` from
  [`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md),
  a one-row data.frame from
  [`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md),
  a single row of an `odiffr_batch` (e.g. `results[2, ]`), or the path
  to a diff image file.

- as:

  Output type: `"magick"` (default) returns a `magick-image` (requires
  the magick package); `"raster"` returns a `raster` object (see
  [`grDevices::as.raster()`](https://rdrr.io/r/grDevices/as.raster.html))
  read with
  [`png::readPNG()`](https://rdrr.io/pkg/png/man/readPNG.html), so
  magick is not required.

## Value

A `magick-image` or a `raster` object.

## Details

A diff image only exists when the comparison was run with `diff_output`
(or `diff_dir` for batches) and the images differ. An error is raised
otherwise.

## See also

[`plot.odiff_result()`](https://benwolst.github.io/odiffr/reference/plot.odiff_result.md)

## Examples

``` r
if (FALSE) { # \dontrun{
result <- compare_images("baseline.png", "current.png", diff_output = TRUE)
img <- diff_image(result)

# Without magick
plot(diff_image(result, as = "raster"))

# One row of a batch
results <- compare_image_dirs("baseline/", "current/", diff_dir = "diffs/")
diff_image(failed_pairs(results)[1, ])
} # }
```
