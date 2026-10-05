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
  images = c("diff", "all"),
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
  string. The file is written as UTF-8 and its parent directory is
  created if it does not exist.

- title:

  Report title. Default: "odiffr Comparison Report".

- embed:

  If TRUE, embed diff images as base64 data URIs for a fully
  self-contained file. If FALSE (default), link to image files on disk
  using `file://` URIs.

- relative_paths:

  If TRUE and `output_file` is specified, use paths relative to the
  report location for image `src` attributes. This makes reports
  portable without embedding. Paths are percent-encoded so that file
  names containing spaces, `#`, `?` or `%` work. If no relative path can
  be built (e.g. different drives on Windows), a `file://` URI is used
  instead. Ignored when `embed = TRUE`. Default: FALSE.

- n_worst:

  Number of worst offenders to display. Default: 10.

- show_all:

  If TRUE, include a table of all comparisons. Default: FALSE.

- images:

  Which images to show for each comparison: `"diff"` (default) shows
  only the diff image; `"all"` shows the baseline (`img1`), current
  (`img2`) and diff images side by side, each with a caption. Clicking a
  thumbnail shows the full-size image (a link to the file for linked
  reports, an in-page zoom for embedded ones).

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

With `images = "all"`, baseline and current images are linked or
embedded in the same way as diff images (`embed`, `relative_paths`).
Embedded images get a MIME type based on their file extension (PNG,
JPEG, WebP, BMP or TIFF; note that most browsers cannot display TIFF).
Images that are not files on disk (for example `"<magick-image>"`
inputs) or that no longer exist are shown as a placeholder. The report
stays a single HTML file with inline CSS and no JavaScript.

Failures without pixel statistics (layout differences, errors, or
baseline images with no current counterpart) show "-" for the diff
percentage and pixel count. If the results contain an `error` column,
its message is shown in the Reason column. An empty batch produces a
valid report with a pass rate of "-".

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

# Baseline, current and diff images side by side
batch_report(results, output_file = "report.html", images = "all")

# Get HTML as string
html <- batch_report(results)
} # }
```
