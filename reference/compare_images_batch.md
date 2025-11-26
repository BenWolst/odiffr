# Compare Multiple Image Pairs

Compare multiple pairs of images in batch. Useful for visual regression
testing across many screenshots.

## Usage

``` r
compare_images_batch(pairs, diff_dir = NULL, ...)
```

## Arguments

- pairs:

  A data.frame with columns `img1` and `img2` containing file paths, or
  a list of named lists with `img1` and `img2` elements.

- diff_dir:

  Directory to save diff images. If `NULL`, no diff images are created.
  If provided, diff images are named based on the input file names.

- ...:

  Additional arguments passed to
  [`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md).

## Value

A tibble (if available) or data.frame with one row per comparison,
containing all columns from
[`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md)
plus a `pair_id` column.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a data frame of image pairs
pairs <- data.frame(
  img1 = c("baseline/page1.png", "baseline/page2.png"),
  img2 = c("current/page1.png", "current/page2.png")
)

# Compare all pairs
results <- compare_images_batch(pairs, diff_dir = "diffs/")

# Check which comparisons failed
results[!results$match, ]
} # }
```
