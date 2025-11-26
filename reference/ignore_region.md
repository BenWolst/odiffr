# Create an Ignore Region

Helper function to create a region specification for use with
[`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md)
and
[`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md).

## Usage

``` r
ignore_region(x1, y1, x2, y2)
```

## Arguments

- x1:

  Integer; x-coordinate of the top-left corner.

- y1:

  Integer; y-coordinate of the top-left corner.

- x2:

  Integer; x-coordinate of the bottom-right corner.

- y2:

  Integer; y-coordinate of the bottom-right corner.

## Value

A list with components `x1`, `y1`, `x2`, `y2`.

## Examples

``` r
# Create a region to ignore
region <- ignore_region(10, 10, 100, 50)

# Use with odiff_run
if (FALSE) { # \dontrun{
result <- odiff_run("img1.png", "img2.png",
                    ignore_regions = list(region))
} # }
```
