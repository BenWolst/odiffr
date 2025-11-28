# Changelog

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
