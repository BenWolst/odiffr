# Compare Directories and Generate HTML Report

Convenience function that compares all images in two directories and
generates an HTML report in one step.

## Usage

``` r
compare_dirs_report(
  baseline_dir,
  current_dir,
  diff_dir = "diffs",
  output_file = file.path(diff_dir, "report.html"),
  parallel = FALSE,
  title = "odiffr Comparison Report",
  embed = FALSE,
  relative_paths = FALSE,
  n_worst = 10,
  show_all = FALSE,
  ...
)
```

## Arguments

- baseline_dir:

  Path to the directory containing baseline images.

- current_dir:

  Path to the directory containing current images to compare against
  baseline.

- diff_dir:

  Directory to save diff images. If `NULL`, no diff images are created.

- output_file:

  Path for the HTML report. Defaults to
  `file.path(diff_dir, "report.html")`.

- parallel:

  Logical; if `TRUE`, compare images in parallel. See
  [`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md)
  for details.

- title:

  Title for the HTML report.

- embed:

  Logical; if `TRUE`, embed images as base64 data URIs for a
  self-contained report. If `FALSE` (default), link to image files.

- relative_paths:

  Logical; if `TRUE`, use relative paths for images in the HTML report.
  Makes reports portable without embedding. Ignored when `embed = TRUE`.
  Default: `FALSE`.

- n_worst:

  Number of worst offenders to display in the report.

- show_all:

  Logical; if `TRUE`, show all comparisons in the report, not just
  failures.

- ...:

  Additional arguments passed to
  [`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md)
  (e.g. `threshold`, `antialiasing`, `pattern`, `recursive`).

## Value

The `odiffr_batch` results (invisibly). The HTML report is written to
`output_file` as a side effect.

## See also

[`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md),
[`batch_report()`](https://benwolst.github.io/odiffr/reference/batch_report.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# One-liner for QA workflow
compare_dirs_report("baseline/", "current/")
# -> Creates diffs/ directory with diff images and report.html

# With parallel processing and embedded images
compare_dirs_report("baseline/", "current/", parallel = TRUE, embed = TRUE)

# Pass comparison options via ...
compare_dirs_report("baseline/", "current/", threshold = 0.1, antialiasing = TRUE)
} # }
```
