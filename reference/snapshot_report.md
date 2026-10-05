# Report Failing Image Snapshots

Finds the image snapshots that changed in the last test run (the
`<name>.new.png` files testthat leaves next to `<name>.png` in
`tests/testthat/_snaps/`), compares each with its baseline using odiff
and writes an HTML, Markdown or JUnit XML report. Unlike
[`testthat::snapshot_review()`](https://testthat.r-lib.org/reference/snapshot_accept.html),
this works non-interactively, so it is suited to continuous integration.

## Usage

``` r
snapshot_report(
  path = "tests/testthat/_snaps",
  output_file = NULL,
  format = c("html", "markdown", "junit"),
  threshold = 0.1,
  antialiasing = FALSE,
  ...,
  images = "all",
  embed = TRUE,
  title = "Image snapshot changes",
  diff_dir = NULL,
  preset = NULL
)
```

## Arguments

- path:

  Path to the snapshot directory. Searched recursively, so variant
  subdirectories (`_snaps/<variant>/<test-file>/`) are included.
  Default: `"tests/testthat/_snaps"`.

- output_file:

  Path of the report file. Required for `"html"` and `"junit"`. For
  `"markdown"`, `NULL` (the default) appends to the GitHub Actions job
  summary when the `GITHUB_STEP_SUMMARY` environment variable is set,
  and otherwise writes nothing (see
  [`batch_markdown()`](https://benwolst.github.io/odiffr/reference/batch_markdown.md)).

- format:

  Report format: `"html"`
  ([`batch_report()`](https://benwolst.github.io/odiffr/reference/batch_report.md)),
  `"markdown"`
  ([`batch_markdown()`](https://benwolst.github.io/odiffr/reference/batch_markdown.md))
  or `"junit"`
  ([`batch_junit()`](https://benwolst.github.io/odiffr/reference/batch_junit.md)).

- threshold:

  Numeric; colour difference threshold between 0.0 and 1.0. Default is
  0.1 (or the value from `preset`). Use the settings of the tests that
  produced the snapshots to get the same verdicts.

- antialiasing:

  Logical; if `TRUE`, ignore antialiased pixels. Default is `FALSE` (or
  the value from `preset`).

- ...:

  Additional arguments passed to
  [`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md)
  (and from there to
  [`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md)),
  e.g. `ignore_regions`.

- images:

  For `"html"`: which images to show per snapshot, `"all"` (default:
  baseline, new and diff side by side) or `"diff"`.

- embed:

  For `"html"`: if `TRUE` (default), images are embedded so the report
  is a single self-contained file, e.g. for a CI artifact.

- title:

  Report title. Default: `"Image snapshot changes"`.

- diff_dir:

  Directory for the diff images. `NULL` (default) uses a
  `snapshot-diffs` directory next to `output_file`, or a directory in
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html) when there is no
  `output_file`. It must not be inside `path`, because testthat deletes
  unknown files in `_snaps/`. Diff images left there by an earlier
  report (`NNN_<name>_diff.png`) are removed first.

- preset:

  Optional comparison preset, see
  [`odiff_preset()`](https://benwolst.github.io/odiffr/reference/odiff_preset.md).
  It supplies `threshold` and `antialiasing` unless those are given.

## Value

The comparison results, an `odiffr_batch` (invisibly).

## Details

Each `<name>.new.png` is paired with `<name>.png` in the same directory
and compared with
[`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md).
The returned batch has an extra column `snapshot` with the snapshot's
path relative to `path` (e.g. `"linux/plots/scatter.png"`). Reports
label rows by this relative snapshot path.

A `.new.png` file without a baseline cannot be compared; it is reported
with `reason = "error"` and the error "no baseline snapshot", so it is
not silently missed.

If no `.new.png` files are found, an empty batch is returned. The HTML
and JUnit reports are still written (with no comparisons); the Markdown
report contains "No image snapshot changes.".

Snapshots whose new image matches the baseline under the given settings
are reported as passing: testthat compares more strictly (or with other
settings) than the report.

## Continuous integration

Run the tests without stopping at the first failure, then write the
report. In GitHub Actions:


    - name: Test
      run: |
        res <- testthat::test_local(stop_on_failure = FALSE)
        odiffr::snapshot_report(format = "markdown")
        odiffr::snapshot_report(output_file = "snapshot-report.html")
        if (any(as.data.frame(res)$failed > 0)) stop("Tests failed")
      shell: Rscript {0}

    - name: Upload snapshot report
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: snapshot-report
        path: snapshot-report.html

## See also

[`expect_snapshot_image()`](https://benwolst.github.io/odiffr/reference/expect_snapshot_image.md),
[`compare_file_odiff()`](https://benwolst.github.io/odiffr/reference/compare_file_odiff.md),
[`batch_report()`](https://benwolst.github.io/odiffr/reference/batch_report.md),
[`batch_markdown()`](https://benwolst.github.io/odiffr/reference/batch_markdown.md),
[`batch_junit()`](https://benwolst.github.io/odiffr/reference/batch_junit.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# After a test run with failing image snapshots
snapshot_report(output_file = "snapshot-report.html")

# GitHub Actions job summary
snapshot_report(format = "markdown")

# JUnit XML for a CI test reporter
snapshot_report(output_file = "snapshots.xml", format = "junit")
} # }
```
