# Approve Changes as New Baselines

Accept the current images of a batch comparison as the new baselines:
for each selected failing pair, the current image (`img2`) is copied
over the baseline image (`img1`). This is intended for the
directory/batch workflow
([`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md),
[`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md));
review the differences first (e.g. with
[`batch_report()`](https://benwolst.github.io/odiffr/reference/batch_report.md)),
then approve them.

## Usage

``` r
approve_changes(
  object,
  which = NULL,
  reasons = c("pixel-diff", "layout-diff"),
  remove_missing = FALSE,
  dry_run = FALSE,
  backup_dir = NULL
)
```

## Arguments

- object:

  An `odiffr_batch` object returned by
  [`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md)
  or
  [`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md).

- which:

  Optional selection of rows to approve. One of:

  - an integer/numeric vector of `pair_id`s,

  - a logical vector with one element per row of `object`,

  - a character vector of image names, matched against the base names of
    `img1`/`img2` or against the trailing part of their paths (e.g.
    `"subdir/page.png"`).

  When `NULL` (the default), all failing rows whose `reason` is in
  `reasons` are approved. An explicit selection takes precedence over
  `reasons`.

- reasons:

  Character vector of failure reasons to approve when `which` is `NULL`.
  Defaults to `c("pixel-diff", "layout-diff")`. Add `"missing"`
  (together with `remove_missing = TRUE`) to also delete baselines whose
  current image no longer exists.

- remove_missing:

  Logical; if `TRUE`, selected rows with `reason = "missing"` have their
  baseline file deleted (the screenshot was intentionally removed). If
  `FALSE` (the default), such rows are skipped.

- dry_run:

  Logical; if `TRUE`, no files are changed and the returned actions
  describe what would happen. Default is `FALSE`.

- backup_dir:

  Optional directory in which to save a copy of each baseline before it
  is overwritten or deleted. Paths relative to the common parent
  directory of the affected baselines are preserved; if there is no
  usable common directory, files are saved as `<pair_id>_<basename>`.
  Baselines that are already identical to the current image are not
  backed up.

## Value

Invisibly, a data.frame with one row per considered pair and columns:

- pair_id:

  Integer; the pair's `pair_id`.

- baseline:

  Character; path of the baseline image (`img1`).

- current:

  Character; path of the current image (`img2`).

- action:

  Character; one of `"updated"`, `"removed"`, `"skipped"`, `"failed"`,
  `"would update"`, or `"would remove"`.

- detail:

  Character; explanation (e.g. why a row was skipped), or `NA`.

A one-line summary of the actions is emitted as a message.

## Details

Rows with `reason = "match"` are never modified, and rows with
`reason = "error"` cannot be approved (the comparison itself failed, so
there is no valid current image to accept); they are reported as
skipped. Rows whose `img1`/`img2` are not files (e.g. `"<magick-image>"`
labels) are skipped as well.

Parent directories of baselines are created as needed. A failed copy or
deletion is reported (action `"failed"`) and does not stop the remaining
rows from being processed. Approving the same batch twice is harmless.

## See also

[`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md),
[`batch_report()`](https://benwolst.github.io/odiffr/reference/batch_report.md),
[`failed_pairs()`](https://benwolst.github.io/odiffr/reference/failed_pairs.md)

## Examples

``` r
if (FALSE) { # \dontrun{
results <- compare_image_dirs("baseline/", "current/", diff_dir = "diffs/")
batch_report(results, "diffs/report.html")

# Preview, then accept all pixel and layout changes
approve_changes(results, dry_run = TRUE)
approve_changes(results, backup_dir = "baseline-backup/")

# Approve selected images only
approve_changes(results, which = c("home.png", "settings/profile.png"))

# Also delete baselines of screenshots that were removed
approve_changes(results, reasons = "missing", remove_missing = TRUE)
} # }
```
