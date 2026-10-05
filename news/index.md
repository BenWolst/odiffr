# Changelog

## odiffr 0.6.0

CRAN release: 2026-10-05

### Breaking changes

- odiffr now requires odiff \>= 4.1.1 (previously documented as \>=
  3.0.0). odiff 4.0.0 produced incomplete machine-readable output.
- [`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md)
  now reports files missing from `current_dir` as failing rows with
  `reason = "missing"` instead of silently dropping them (the warning is
  still emitted), so a disappearing screenshot now fails CI.
- [`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md)
  (and therefore
  [`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md))
  no longer stops when a single pair fails, including a nonexistent path
  or a parallel worker crash; that pair is reported as a
  `reason = "error"` row with the message in the new `error` column.
  Empty input returns an empty `odiffr_batch`, and malformed list input
  gives a clear error.
- `diff_count` and `diff_percentage` are now `0` (rather than `NA`) for
  matching images. `NA` now means “unknown” (layout difference or
  error).
- The `stdout` element of
  [`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md)
  results now holds odiff’s machine-readable output (e.g. `"126;1.26"`)
  rather than the human-readable message, and `stderr` is now populated.
- [`expect_images_differ()`](https://benwolst.github.io/odiffr/reference/expect_images.md)
  now fails, rather than passes, when the images cannot be compared.
- The default
  [`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md)
  pattern now matches `.bmp` (supported by odiff) and no longer matches
  `.tif` (rejected by odiff; use `.tiff`).
- `threshold`, `diff_color` and `diff_overlay` are validated up front,
  so invalid values (e.g. `diff_color = "red"`, which odiff rejects) now
  error in R. Small thresholds are no longer passed in scientific
  notation.

### New Features

- [`install_odiff()`](https://benwolst.github.io/odiffr/reference/install_odiff.md)
  downloads the odiff binary for your platform to the user cache, so
  odiff can be installed from R without Node.js or npm. When odiff is
  not found, functions that need it
  (e.g. [`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md))
  now offer to run
  [`install_odiff()`](https://benwolst.github.io/odiffr/reference/install_odiff.md)
  in interactive sessions, once per session; nothing is ever downloaded
  without asking, and the offer is never made in non-interactive
  sessions, testthat runs, while knitting or during `R CMD check`. Set
  `options(odiffr.ask_install = FALSE)` to turn it off.
  [`odiff_available()`](https://benwolst.github.io/odiffr/reference/odiff_available.md)
  remains a silent check. The startup message and the “odiff binary not
  found” error now recommend
  [`install_odiff()`](https://benwolst.github.io/odiffr/reference/install_odiff.md).
- [`use_odiffr_ci()`](https://benwolst.github.io/odiffr/reference/use_odiffr_ci.md)
  writes a ready-to-use GitHub Actions workflow for visual tests: it
  installs odiff with
  [`install_odiff()`](https://benwolst.github.io/odiffr/reference/install_odiff.md),
  runs the testthat tests, adds a
  [`snapshot_report()`](https://benwolst.github.io/odiffr/reference/snapshot_report.md)
  summary of changed image snapshots to the job summary and uploads new
  snapshots and diff images when tests fail.
- [`find_odiff()`](https://benwolst.github.io/odiffr/reference/find_odiff.md)
  now bypasses the Node.js launcher script installed by
  `npm install -g odiff-bin` (odiff \>= 4.4) and calls the native odiff
  binary directly, making each comparison around 5x faster. A path set
  with `options(odiffr.path)` is used as-is, and
  `options(odiffr.resolve_npm = FALSE)` disables the lookup.
  [`odiff_info()`](https://benwolst.github.io/odiffr/reference/odiff_info.md)
  gains a `shim` field.
- [`compare_file_odiff()`](https://benwolst.github.io/odiffr/reference/compare_file_odiff.md)
  and
  [`expect_snapshot_image()`](https://benwolst.github.io/odiffr/reference/expect_snapshot_image.md)
  now write a diff image when a snapshot comparison fails (outside
  `_snaps/`, in `tests/testthat/_odiffr/` by default) and report its
  location. Both gain a `preset` argument, and the new
  [`odiff_preset()`](https://benwolst.github.io/odiffr/reference/odiff_preset.md)
  provides calibrated settings: `"strict"`, `"default"`, `"screenshot"`
  (ignores anti-aliasing noise) and `"cross_platform"`.
  [`compare_file_odiff()`](https://benwolst.github.io/odiffr/reference/compare_file_odiff.md)
  works as the `compare` function of
  `shinytest2::AppDriver$expect_screenshot()`; see
  [`vignette("shinytest2", package = "odiffr")`](https://benwolst.github.io/odiffr/articles/shinytest2.md).
- [`snapshot_report()`](https://benwolst.github.io/odiffr/reference/snapshot_report.md)
  builds an HTML, Markdown or JUnit report of changed image snapshots
  (`*.new.png` files under `_snaps/`), for reviewing snapshot failures
  in CI.
- [`compare_pdfs()`](https://benwolst.github.io/odiffr/reference/compare_pdfs.md)
  compares two PDF files page by page, and
  [`compare_pdf_dirs()`](https://benwolst.github.io/odiffr/reference/compare_pdf_dirs.md)
  compares directories of PDFs, returning batch results that work with
  [`summary()`](https://rdrr.io/r/base/summary.html),
  [`batch_report()`](https://benwolst.github.io/odiffr/reference/batch_report.md),
  [`batch_markdown()`](https://benwolst.github.io/odiffr/reference/batch_markdown.md)
  and
  [`batch_junit()`](https://benwolst.github.io/odiffr/reference/batch_junit.md).
  Requires the pdftools package. See
  [`vignette("pdf-outputs", package = "odiffr")`](https://benwolst.github.io/odiffr/articles/pdf-outputs.md).
- [`audit_record()`](https://benwolst.github.io/odiffr/reference/audit_record.md)
  writes a JSON or CSV record of comparisons, including input and output
  file hashes, the odiff version and binary hash, parameters, timestamp
  and platform.
  [`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md)
  results gain a `params` element with the effective comparison
  parameters.
- New vignette on comparing web pages and htmlwidgets screenshots taken
  with webshot2.
- [`expect_snapshot_image()`](https://benwolst.github.io/odiffr/reference/expect_snapshot_image.md)
  is a testthat snapshot expectation that compares images with odiff, so
  baselines are managed with
  [`testthat::snapshot_review()`](https://testthat.r-lib.org/reference/snapshot_accept.html)
  and
  [`testthat::snapshot_accept()`](https://testthat.r-lib.org/reference/snapshot_accept.html).
  [`compare_file_odiff()`](https://benwolst.github.io/odiffr/reference/compare_file_odiff.md)
  returns the underlying compare function for use with
  [`testthat::expect_snapshot_file()`](https://testthat.r-lib.org/reference/expect_snapshot_file.html).
- [`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md),
  the testthat expectations and
  [`expect_snapshot_image()`](https://benwolst.github.io/odiffr/reference/expect_snapshot_image.md)
  accept plots as inputs: ggplot objects, functions that draw a plot,
  and recorded plots. Plots are rendered to PNG (with ragg when
  installed); rendering is controlled with the new
  [`plot_options()`](https://benwolst.github.io/odiffr/reference/plot_options.md).
- [`approve_changes()`](https://benwolst.github.io/odiffr/reference/approve_changes.md)
  accepts current images as the new baselines for the directory/batch
  workflow, with `dry_run`, `backup_dir` and optional removal of
  baselines whose current image no longer exists.
- [`plot()`](https://rdrr.io/r/graphics/plot.default.html) method for
  `odiff_result` objects shows the baseline, current and diff images
  side by side;
  [`diff_image()`](https://benwolst.github.io/odiffr/reference/diff_image.md)
  returns the diff image as a magick image or raster.
- [`batch_report()`](https://benwolst.github.io/odiffr/reference/batch_report.md)
  and
  [`compare_dirs_report()`](https://benwolst.github.io/odiffr/reference/compare_dirs_report.md)
  gain `images = "all"` to show baseline, current and diff thumbnails
  side by side.
- [`batch_markdown()`](https://benwolst.github.io/odiffr/reference/batch_markdown.md)
  writes a Markdown summary of batch results (appending to the GitHub
  Actions job summary by default when run in GitHub Actions), and
  [`batch_junit()`](https://benwolst.github.io/odiffr/reference/batch_junit.md)
  writes JUnit XML for CI test reporting.
- [`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md)
  gains an `enable_asm` parameter to enable AVX-512 optimised assembly
  for ~12% faster comparisons on supported x86_64 CPUs. Requires odiff
  \>= 4.1.1.
- [`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md)
  gains a `diff_cols` parameter (`--output-diff-cols`) that returns the
  column numbers containing differences. Requires odiff \>= 4.5.0.
- [`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md)
  results gain an `error` element, and
  [`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md),
  [`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md)
  and
  [`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md)
  results gain an `error` column (last), holding odiff’s error message
  when `reason == "error"`. Error messages are also shown by
  [`print()`](https://rdrr.io/r/base/print.html), in testthat failure
  messages and in
  [`batch_report()`](https://benwolst.github.io/odiffr/reference/batch_report.md).

### Bug Fixes

- Image paths containing spaces (or other shell-special characters) now
  work. Previously every comparison involving such a path failed with
  `reason = "error"`.
- `odiff_run(diff_lines = TRUE)` now returns correct `diff_count`,
  `diff_percentage` and `diff_lines`. Previously the count and
  percentage were `NA` and the line numbers included unrelated digits.
- odiff is now always run with `--parsable-stdout` and its
  machine-readable output is parsed strictly. stdout and stderr are
  captured separately, so the `stderr` element is now populated.
- `_R_CHECK_LIMIT_CORES_=false` no longer limits parallel workers to 2.
- [`expect_images_match()`](https://benwolst.github.io/odiffr/reference/expect_images.md)
  uses deterministic diff file names, so re-runs overwrite the previous
  diff instead of accumulating files in `_odiffr/`, and a stale diff is
  removed once the expectation passes.
- A `diff_output` path without an extension now gets `.png` appended
  (previously odiff failed to write the diff).
- `timeout` values below one second are rounded up to one second instead
  of silently disabling the timeout; `0` or `Inf` means no timeout.
  Timeouts are reported via `error`.
- [`odiff_version()`](https://benwolst.github.io/odiffr/reference/odiff_version.md)
  is cached per binary, so `enable_asm`/`diff_cols` no longer spawn
  `odiff --version` on every comparison.
- [`batch_report()`](https://benwolst.github.io/odiffr/reference/batch_report.md):
  image links are proper `file:///` URIs (or percent-encoded relative
  URLs), fixing broken images on Windows and for paths containing
  spaces, `#`, `?` or `%`. Rows without pixel statistics show “-”
  instead of `NA%`, empty batches produce a valid report, reports are
  written as UTF-8, the output directory is created if needed, and
  embedding images is much faster.
- [`summary()`](https://rdrr.io/r/base/summary.html) of an empty batch
  returns `pass_rate = NA` instead of `NaN`.
- [`odiffr_update()`](https://benwolst.github.io/odiffr/reference/odiffr_update.md)
  accepts versions with or without the `v` prefix, uses
  `GITHUB_PAT`/`GITHUB_TOKEN` for the GitHub API, never leaves a partial
  binary behind after a failed download, gives a clearer error for
  releases without binaries (e.g. v4.3.8, v4.4.0), and allows at least
  300 seconds for the download.

## odiffr 0.5.1

CRAN release: 2025-12-09

### Bug Fixes

- [`odiff_version()`](https://benwolst.github.io/odiffr/reference/odiff_version.md)
  now correctly parses the version from `odiff --version` output instead
  of `--help`, which did not contain version information.
- [`batch_report()`](https://benwolst.github.io/odiffr/reference/batch_report.md)
  with `relative_paths = TRUE` now produces correct relative paths on
  Windows by normalizing path separators before computing relative
  paths.

## Odiffr 0.5.0

### New Features

- [`batch_report()`](https://benwolst.github.io/odiffr/reference/batch_report.md)
  gains a `relative_paths` parameter. When `TRUE`, image paths in HTML
  reports are relative to the report location, making reports portable
  without embedding images.
- [`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md)
  now emits a message when files in `current_dir` have no corresponding
  baseline, helping catch missing or extra images early.
- New accessor functions
  [`failed_pairs()`](https://benwolst.github.io/odiffr/reference/failed_pairs.md)
  and
  [`passed_pairs()`](https://benwolst.github.io/odiffr/reference/passed_pairs.md)
  make it easy to filter batch comparison results.

### Documentation

- Expanded README and vignette coverage for batch workflows, HTML
  reports, and CI/testthat integration, including examples using
  `embed = TRUE`, `show_all = TRUE`, and `relative_paths = TRUE`.

## Odiffr 0.4.1

### New Features

- [`compare_dirs_report()`](https://benwolst.github.io/odiffr/reference/compare_dirs_report.md)
  convenience function combines
  [`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md)
  and
  [`batch_report()`](https://benwolst.github.io/odiffr/reference/batch_report.md)
  into a single call for the common QA workflow of comparing two
  directories and generating an HTML report.

### Documentation

- Added CI integration examples showing how to run visual regression
  tests in GitHub Actions and upload diff artifacts on failure.

## Odiffr 0.4.0

### HTML Diff Reports

- [`batch_report()`](https://benwolst.github.io/odiffr/reference/batch_report.md):
  Generate standalone HTML reports from batch comparison results.
  Reports include pass/fail statistics, failure reason breakdown, diff
  statistics, and thumbnails of worst offenders.
- Configurable image embedding: Use `embed = TRUE` for self-contained
  reports with base64-encoded images, or `embed = FALSE` (default) to
  link to files.
- Customizable: Set report title, number of worst offenders to display,
  and optionally include all comparisons (not just failures) with
  `show_all = TRUE`.

## Odiffr 0.3.0

### Directory Comparison

- [`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md):
  Compare all images in two directories by matching relative paths.
  Baseline directory is source of truth; missing files in current
  directory trigger warnings and are excluded from results.

### Batch Results Summary

- [`summary()`](https://rdrr.io/r/base/summary.html) method for batch
  results: Get aggregate statistics including pass/fail counts, failure
  reason breakdown, diff statistics (min, median, mean, max), and worst
  offenders ranked by diff percentage.
- [`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md)
  and
  [`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md)
  now return objects with class `odiffr_batch` for S3 method dispatch.

### Parallel Batch Processing

- New `parallel` parameter for
  [`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md)
  and
  [`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md):
  Set `parallel = TRUE` to compare images using multiple CPU cores.
- Uses [`parallel::mclapply`](https://rdrr.io/r/parallel/mclapply.html)
  on Unix systems (macOS, Linux) for faster batch comparisons.
- Automatically falls back to sequential processing on Windows.

## Odiffr 0.2.0

### testthat Integration

- [`expect_images_match()`](https://benwolst.github.io/odiffr/reference/expect_images.md):
  Assert two images are visually identical
- [`expect_images_differ()`](https://benwolst.github.io/odiffr/reference/expect_images.md):
  Assert two images are visually different
- Automatic diff image saving to `tests/testthat/_odiffr/` on failure
- Configurable via `options(odiffr.save_diff)` and
  `options(odiffr.diff_dir)`

## Odiffr 0.1.0

CRAN release: 2025-12-01

Initial release.

### Features

- [`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md):
  High-level image comparison returning tibble/data.frame
- [`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md):
  Batch comparison of multiple image pairs
- [`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md):
  Low-level CLI wrapper with full option control
- [`ignore_region()`](https://benwolst.github.io/odiffr/reference/ignore_region.md):
  Helper for creating ignore region specifications

### Binary Management

- [`find_odiff()`](https://benwolst.github.io/odiffr/reference/find_odiff.md):
  Locate Odiff binary with priority-based search
- [`odiff_available()`](https://benwolst.github.io/odiffr/reference/odiff_available.md):
  Check if Odiff is available
- [`odiff_version()`](https://benwolst.github.io/odiffr/reference/odiff_version.md):
  Get Odiff version string
- [`odiff_info()`](https://benwolst.github.io/odiffr/reference/odiff_info.md):
  Display full configuration information
- [`odiffr_update()`](https://benwolst.github.io/odiffr/reference/odiffr_update.md):
  Download Odiff binary to user cache (fallback option)
- [`odiffr_cache_path()`](https://benwolst.github.io/odiffr/reference/odiffr_cache_path.md):
  Get cache directory path
- [`odiffr_clear_cache()`](https://benwolst.github.io/odiffr/reference/odiffr_clear_cache.md):
  Remove cached binaries

### System Requirements

Requires Odiff (\>= 3.0.0) to be installed. Install via:

- npm (cross-platform): `npm install -g odiff-bin`
- Manual: Download from
  <https://github.com/dmtrKovalenko/odiff/releases>

Alternatively, use
[`odiffr_update()`](https://benwolst.github.io/odiffr/reference/odiffr_update.md)
to download to user cache.

### Platform Support

Works on any platform where Odiff is available:

- macOS (ARM64 and x64)
- Linux (ARM64 and x64)
- Windows (ARM64 and x64)
