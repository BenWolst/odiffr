# Summarize Batch Comparison Results

Generate a summary of batch image comparison results, including
pass/fail statistics, failure reasons, and worst offenders.

## Usage

``` r
# S3 method for class 'odiffr_batch'
summary(object, n_worst = 5, ...)

# S3 method for class 'odiffr_batch_summary'
print(x, ...)
```

## Arguments

- object:

  An `odiffr_batch` object returned by
  [`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md)
  or
  [`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md).

- n_worst:

  Integer; number of worst offenders to include in the summary. Default
  is 5.

- ...:

  Additional arguments (currently unused).

- x:

  An `odiffr_batch_summary` object.

## Value

An `odiffr_batch_summary` object with the following components:

- total:

  Total number of comparisons.

- passed:

  Number of matching image pairs.

- failed:

  Number of non-matching image pairs.

- pass_rate:

  Proportion of passing comparisons (0 to 1).

- reason_counts:

  Table of failure reasons (NULL if no failures).

- diff_stats:

  List with min, median, mean, max diff percentages (NULL if no failures
  with diff data).

- worst:

  Data frame of worst offenders by diff percentage (NULL if no
  failures).

## Details

The summary method expects the standard output of
[`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md),
which includes columns: `match`, `reason`, `diff_percentage`,
`diff_count`, `pair_id`, and `img2`.

## See also

[`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md),
[`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Compare image pairs and summarize
pairs <- data.frame(
  img1 = c("baseline/a.png", "baseline/b.png", "baseline/c.png"),
  img2 = c("current/a.png", "current/b.png", "current/c.png")
)
results <- compare_images_batch(pairs)
summary(results)

# Get summary with more worst offenders
summary(results, n_worst = 10)
} # }
```
