# Write a Markdown Summary of Batch Comparison Results

Produces a GitHub-flavoured Markdown summary of batch image comparison
results: a heading, a pass/fail line, a breakdown of failure reasons and
a table of the worst offenders. On GitHub Actions the summary is
appended to the job summary page by default.

## Usage

``` r
batch_markdown(
  object,
  output_file = NULL,
  title = "odiffr comparison",
  n_worst = 10,
  append = TRUE
)
```

## Arguments

- object:

  An `odiffr_batch` object from
  [`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md)
  or
  [`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md).

- output_file:

  Path to write the Markdown to. If NULL (default), the file named by
  the `GITHUB_STEP_SUMMARY` environment variable is used when that
  variable is set; otherwise nothing is written.

- title:

  Heading of the summary. Default: "odiffr comparison".

- n_worst:

  Maximum number of failures listed in the table. Default: 10. Use 0 to
  omit the table.

- append:

  If TRUE (default), append to `output_file` instead of overwriting it,
  as GitHub step summaries are built up by appending.

## Value

If the summary is written to a file, the file path (invisibly);
otherwise the Markdown as a character string (invisibly). Nothing is
printed.

## Details

The worst offenders table has columns Image, Reason, Diff %, Pixels and
Error, ordered as in
[`summary.odiffr_batch()`](https://benwolst.github.io/odiffr/reference/summary.odiffr_batch.md).
Cell text is escaped so that `|`, line breaks, Markdown emphasis
characters and HTML-like text such as `<magick-image>` are shown
literally. Files are written as UTF-8 and the parent directory is
created if needed.

## See also

[`batch_junit()`](https://benwolst.github.io/odiffr/reference/batch_junit.md),
[`batch_report()`](https://benwolst.github.io/odiffr/reference/batch_report.md),
[`summary.odiffr_batch()`](https://benwolst.github.io/odiffr/reference/summary.odiffr_batch.md)

## Examples

``` r
if (FALSE) { # \dontrun{
results <- compare_image_dirs("baseline/", "current/", diff_dir = "diffs/")

# In a GitHub Actions step: appends to the job summary
batch_markdown(results)

# Anywhere else: get the Markdown as a string
md <- batch_markdown(results)
cat(md)
} # }
```
