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
