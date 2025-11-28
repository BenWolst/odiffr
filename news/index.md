# Changelog

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
