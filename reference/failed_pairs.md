# Get Failed Comparisons from Batch Results

Extract only the failed (non-matching) comparisons from batch results.

## Usage

``` r
failed_pairs(object)
```

## Arguments

- object:

  An `odiffr_batch` object from
  [`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md)
  or
  [`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md).

## Value

A tibble or data.frame containing only rows where `match` is `FALSE`.

## See also

[`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md),
[`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md),
[`passed_pairs()`](https://benwolst.github.io/odiffr/reference/passed_pairs.md)

## Examples

``` r
if (FALSE) { # \dontrun{
results <- compare_image_dirs("baseline/", "current/")
failed <- failed_pairs(results)
nrow(failed)  # Number of failures
} # }
```
