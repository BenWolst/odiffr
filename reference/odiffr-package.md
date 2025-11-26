# Odiffr: Fast Pixel-by-Pixel Image Comparison

R bindings to the Odiff command-line tool for blazing-fast,
pixel-by-pixel image comparison. Ideal for visual regression testing,
quality assurance, and validated environments.

## Main Functions

- [`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md):

  High-level image comparison returning a tibble/data.frame. Accepts
  file paths or magick-image objects.

- [`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md):

  Low-level CLI wrapper with full control over all Odiff options.
  Returns a detailed result list.

- [`ignore_region()`](https://benwolst.github.io/odiffr/reference/ignore_region.md):

  Helper to create ignore region specifications.

## Binary Management

- [`find_odiff()`](https://benwolst.github.io/odiffr/reference/find_odiff.md):

  Locate the Odiff binary using priority search.

- [`odiff_available()`](https://benwolst.github.io/odiffr/reference/odiff_available.md):

  Check if Odiff is available.

- [`odiff_version()`](https://benwolst.github.io/odiffr/reference/odiff_version.md):

  Get the Odiff version string.

- [`odiff_info()`](https://benwolst.github.io/odiffr/reference/odiff_info.md):

  Display full configuration information.

- [`odiffr_update()`](https://benwolst.github.io/odiffr/reference/odiffr_update.md):

  Download latest Odiff binary to user cache. Useful for updating
  between package releases.

- [`odiffr_cache_path()`](https://benwolst.github.io/odiffr/reference/odiffr_cache_path.md):

  Get the cache directory path.

- [`odiffr_clear_cache()`](https://benwolst.github.io/odiffr/reference/odiffr_clear_cache.md):

  Remove cached binaries.

## Binary Detection Priority

The package searches for the Odiff binary in this order:

1.  User-specified path via `options(odiffr.path = "/path/to/odiff")`

2.  System PATH (`Sys.which("odiff")`)

3.  Cached binary from
    [`odiffr_update()`](https://benwolst.github.io/odiffr/reference/odiffr_update.md)

## Supported Image Formats

- Input:

  PNG, JPEG, WEBP, TIFF (cross-format comparison supported)

- Output:

  PNG only

## Exit Codes

- 0:

  Images match

- 21:

  Layout difference (different dimensions)

- 22:

  Pixel differences found

## For Validated Environments

The package is designed for use in validated pharmaceutical and clinical
research environments:

- Pin specific binary versions with
  `options(odiffr.path = "/validated/odiff")`

- Zero external runtime dependencies (base R only for core functions)

- Use
  [`odiff_version()`](https://benwolst.github.io/odiffr/reference/odiff_version.md)
  to document binary version for audit trails

## Author

Ben Wolstenholme

## See Also

- <https://github.com/dmtrKovalenko/odiff> - Odiff project

- <https://github.com/BenWolst/odiffr> - Odiffr package

## See also

Useful links:

- <https://github.com/BenWolst/odiffr>

- Report bugs at <https://github.com/BenWolst/odiffr/issues>

## Author

**Maintainer**: Ben Wolstenholme <BenWolst@users.noreply.github.com>
