# Get Passed Comparisons from Batch Results

Extract only the passed (matching) comparisons from batch results.

## Usage

``` r
passed_pairs(object)
```

## Arguments

- object:

  An `odiffr_batch` object from
  [`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md)
  or
  [`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md).

## Value

A tibble or data.frame containing only rows where `match` is `TRUE`.

## See also

[`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md),
[`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md),
[`failed_pairs()`](https://benwolst.github.io/odiffr/reference/failed_pairs.md)

## Examples

``` r
if (FALSE) { # \dontrun{
results <- compare_image_dirs("baseline/", "current/")
passed <- passed_pairs(results)
nrow(passed)  # Number of passing comparisons
} # }
```
