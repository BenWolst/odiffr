# Generate HTML Report for Batch Comparison Results

Creates a standalone HTML report summarizing batch image comparison
results. Includes pass/fail statistics, failure reasons, diff
statistics, and thumbnails of the worst offenders.

## Usage

``` r
batch_report(
  object,
  output_file = NULL,
  title = "odiffr Comparison Report",
  embed = FALSE,
  relative_paths = FALSE,
  n_worst = 10,
  show_all = FALSE,
  ...
)
```

## Arguments

- object:

  An `odiffr_batch` object from
  [`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md)
  or
  [`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md).

- output_file:

  Path to write the HTML file. If NULL, returns HTML as a character
  string.

- title:

  Report title. Default: "odiffr Comparison Report".

- embed:

  If TRUE, embed diff images as base64 data URIs for a fully
  self-contained file. If FALSE (default), link to image files on disk.

- relative_paths:

  If TRUE and `output_file` is specified, use paths relative to the
  report location for image `src` attributes. This makes reports
  portable without embedding. Ignored when `embed = TRUE`. Default:
  FALSE.

- n_worst:

  Number of worst offenders to display. Default: 10.

- show_all:

  If TRUE, include a table of all comparisons. Default: FALSE.

- ...:

  Additional arguments passed to
  [`summary.odiffr_batch()`](https://benwolst.github.io/odiffr/reference/summary.odiffr_batch.md).

## Value

If `output_file` is NULL, returns the HTML as a character string
(invisibly). If `output_file` is specified, writes the file and returns
the file path (invisibly).

## Details

Diff image thumbnails (or embedded images when `embed = TRUE`) are only
shown for comparisons where a `diff_output` file was created. This
requires using `diff_dir` in
[`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md)
or
[`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md).
Comparisons without diff images will show "No diff" in the preview
column.

## See also

[`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md),
[`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md),
[`summary.odiffr_batch()`](https://benwolst.github.io/odiffr/reference/summary.odiffr_batch.md)

## Examples

``` r
if (FALSE) { # \dontrun{
results <- compare_image_dirs("baseline/", "current/", diff_dir = "diffs/")

# Generate report file
batch_report(results, output_file = "report.html")

# Self-contained report with embedded images
batch_report(results, output_file = "report.html", embed = TRUE)

# Get HTML as string
html <- batch_report(results)
} # }
```
