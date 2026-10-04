# odiffr (development version)

## New Features

* `odiff_run()` gains an `enable_asm` parameter to enable AVX-512 optimised
  assembly for ~12% faster comparisons on supported x86_64 CPUs. Requires
  odiff >= 4.1.1.
* `odiff_run()` gains a `diff_cols` parameter (`--output-diff-cols`) that
  returns the column numbers containing differences. Requires odiff >= 4.5.0.
* `odiff_run()` results gain an `error` element, and `compare_images()`,
  `compare_images_batch()` and `compare_image_dirs()` results gain an `error`
  column (last), holding odiff's error message when `reason == "error"`.
  Error messages are also shown by `print()`, in testthat failure messages and
  in `batch_report()`.

## Bug Fixes

* Image paths containing spaces (or other shell-special characters) now work.
  Previously every comparison involving such a path failed with
  `reason = "error"`.
* `odiff_run(diff_lines = TRUE)` now returns correct `diff_count`,
  `diff_percentage` and `diff_lines`. Previously the count and percentage were
  `NA` and the line numbers included unrelated digits.
* odiff is now always run with `--parsable-stdout` and its machine-readable
  output is parsed strictly. stdout and stderr are captured separately, so the
  `stderr` element is now populated.
* `diff_count` and `diff_percentage` are now `0` (rather than `NA`) for
  matching images. `NA` now means "unknown" (layout difference or error).
* `compare_image_dirs()` now reports files missing from `current_dir` as
  failing rows with `reason = "missing"` instead of silently dropping them
  (the warning is still emitted), so a disappearing screenshot fails CI.
* `compare_images_batch()` no longer aborts when a single pair fails
  (including a nonexistent path, or a parallel worker crash); that pair is
  reported as a `reason = "error"` row. Empty input returns an empty
  `odiffr_batch`, and malformed list input gives a clear error.
* `_R_CHECK_LIMIT_CORES_=false` no longer limits parallel workers to 2.
* The default `compare_image_dirs()` pattern now matches `.bmp` (supported by
  odiff) and no longer matches `.tif` (rejected by odiff; use `.tiff`).
* `expect_images_differ()` now fails, rather than passes, when the images
  cannot be compared.
* `expect_images_match()` uses deterministic diff file names, so re-runs
  overwrite the previous diff instead of accumulating files in `_odiffr/`, and
  a stale diff is removed once the expectation passes.
* A `diff_output` path without an extension now gets `.png` appended
  (previously odiff failed to write the diff).
* `timeout` values below one second are rounded up to one second instead of
  silently disabling the timeout; `0` or `Inf` means no timeout. Timeouts are
  reported via `error`.
* `threshold`, `diff_color` and `diff_overlay` are validated up front, and
  small thresholds are no longer passed in scientific notation.
* `odiff_version()` is cached per binary, so `enable_asm`/`diff_cols` no
  longer spawn `odiff --version` on every comparison.
* `batch_report()`: image links are proper `file:///` URIs (or
  percent-encoded relative URLs), fixing broken images on Windows and for
  paths containing spaces, `#`, `?` or `%`. Rows without pixel statistics show
  "-" instead of `NA%`, empty batches produce a valid report, reports are
  written as UTF-8, the output directory is created if needed, and embedding
  images is much faster.
* `summary()` of an empty batch returns `pass_rate = NA` instead of `NaN`.
* `odiffr_update()` accepts versions with or without the `v` prefix, uses
  `GITHUB_PAT`/`GITHUB_TOKEN` for the GitHub API, never leaves a partial
  binary behind after a failed download, gives a clearer error for releases
  without binaries (e.g. v4.3.8, v4.4.0), and allows at least 300 seconds for
  the download.

# odiffr 0.5.1

## Bug Fixes

* `odiff_version()` now correctly parses the version from `odiff --version`
  output instead of `--help`, which did not contain version information.
* `batch_report()` with `relative_paths = TRUE` now produces correct relative
  paths on Windows by normalizing path separators before computing relative
  paths.

# Odiffr 0.5.0

## New Features

* `batch_report()` gains a `relative_paths` parameter. When `TRUE`, image
  paths in HTML reports are relative to the report location, making reports
  portable without embedding images.
* `compare_image_dirs()` now emits a message when files in `current_dir`
  have no corresponding baseline, helping catch missing or extra images early.
* New accessor functions `failed_pairs()` and `passed_pairs()` make it
  easy to filter batch comparison results.

## Documentation

* Expanded README and vignette coverage for batch workflows, HTML reports,
  and CI/testthat integration, including examples using `embed = TRUE`,
  `show_all = TRUE`, and `relative_paths = TRUE`.

# Odiffr 0.4.1

## New Features

* `compare_dirs_report()` convenience function combines `compare_image_dirs()`
  and `batch_report()` into a single call for the common QA workflow of
  comparing two directories and generating an HTML report.

## Documentation

* Added CI integration examples showing how to run visual regression tests
  in GitHub Actions and upload diff artifacts on failure.

# Odiffr 0.4.0

## HTML Diff Reports

* `batch_report()`: Generate standalone HTML reports from batch comparison
  results. Reports include pass/fail statistics, failure reason breakdown,
  diff statistics, and thumbnails of worst offenders.
* Configurable image embedding: Use `embed = TRUE` for self-contained reports
  with base64-encoded images, or `embed = FALSE` (default) to link to files.
* Customizable: Set report title, number of worst offenders to display, and
  optionally include all comparisons (not just failures) with `show_all = TRUE`.

# Odiffr 0.3.0

## Directory Comparison

* `compare_image_dirs()`: Compare all images in two directories by matching
  relative paths. Baseline directory is source of truth; missing files in
  current directory trigger warnings and are excluded from results.

## Batch Results Summary

* `summary()` method for batch results: Get aggregate statistics including
  pass/fail counts, failure reason breakdown, diff statistics (min, median,
  mean, max), and worst offenders ranked by diff percentage.
* `compare_images_batch()` and `compare_image_dirs()` now return objects with
  class `odiffr_batch` for S3 method dispatch.

## Parallel Batch Processing

* New `parallel` parameter for `compare_images_batch()` and `compare_image_dirs()`:
  Set `parallel = TRUE` to compare images using multiple CPU cores.
* Uses `parallel::mclapply` on Unix systems (macOS, Linux) for faster batch
  comparisons.
* Automatically falls back to sequential processing on Windows.

# Odiffr 0.2.0

## testthat Integration

* `expect_images_match()`: Assert two images are visually identical
* `expect_images_differ()`: Assert two images are visually different
* Automatic diff image saving to `tests/testthat/_odiffr/` on failure
* Configurable via `options(odiffr.save_diff)` and `options(odiffr.diff_dir)`

# Odiffr 0.1.0

Initial release.

## Features

* `compare_images()`: High-level image comparison returning tibble/data.frame
* `compare_images_batch()`: Batch comparison of multiple image pairs
* `odiff_run()`: Low-level CLI wrapper with full option control
* `ignore_region()`: Helper for creating ignore region specifications

## Binary Management

* `find_odiff()`: Locate Odiff binary with priority-based search
* `odiff_available()`: Check if Odiff is available
* `odiff_version()`: Get Odiff version string
* `odiff_info()`: Display full configuration information
* `odiffr_update()`: Download Odiff binary to user cache (fallback option)
* `odiffr_cache_path()`: Get cache directory path
* `odiffr_clear_cache()`: Remove cached binaries

## System Requirements

Requires Odiff (>= 3.0.0) to be installed. Install via:

* npm (cross-platform): `npm install -g odiff-bin`
* Manual: Download from https://github.com/dmtrKovalenko/odiff/releases

Alternatively, use `odiffr_update()` to download to user cache.

## Platform Support

Works on any platform where Odiff is available:

* macOS (ARM64 and x64)
* Linux (ARM64 and x64)
* Windows (ARM64 and x64)
