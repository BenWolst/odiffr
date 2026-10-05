# Odiffr: Fast Pixel-by-Pixel Image Comparison

R bindings to the Odiff command-line tool for blazing-fast,
pixel-by-pixel image comparison. Ideal for visual regression testing,
quality assurance, and validated environments.

## Main Functions

- [`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md):

  High-level image comparison returning a tibble/data.frame. Accepts
  file paths, magick-image objects and plots.

- [`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md),
  [`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md):

  Compare many image pairs or two directories of images.

- [`compare_pdfs()`](https://benwolst.github.io/odiffr/reference/compare_pdfs.md),
  [`compare_pdf_dirs()`](https://benwolst.github.io/odiffr/reference/compare_pdf_dirs.md):

  Compare PDF files page by page.

- [`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md):

  Low-level CLI wrapper with full control over all Odiff options.
  Returns a detailed result list.

- [`ignore_region()`](https://benwolst.github.io/odiffr/reference/ignore_region.md):

  Helper to create ignore region specifications.

## Testing

- [`expect_images_match()`](https://benwolst.github.io/odiffr/reference/expect_images.md),
  [`expect_images_differ()`](https://benwolst.github.io/odiffr/reference/expect_images.md):

  testthat expectations for images and plots.

- [`expect_snapshot_image()`](https://benwolst.github.io/odiffr/reference/expect_snapshot_image.md):

  testthat snapshot expectation compared with odiff.

- [`compare_file_odiff()`](https://benwolst.github.io/odiffr/reference/compare_file_odiff.md),
  [`odiff_preset()`](https://benwolst.github.io/odiffr/reference/odiff_preset.md):

  Compare function and presets for
  [`testthat::expect_snapshot_file()`](https://testthat.r-lib.org/reference/expect_snapshot_file.html)
  and 'shinytest2' screenshots.

## Reviewing and Reporting

- [`batch_report()`](https://benwolst.github.io/odiffr/reference/batch_report.md),
  [`batch_markdown()`](https://benwolst.github.io/odiffr/reference/batch_markdown.md),
  [`batch_junit()`](https://benwolst.github.io/odiffr/reference/batch_junit.md):

  HTML, Markdown and JUnit reports of batch results.

- [`snapshot_report()`](https://benwolst.github.io/odiffr/reference/snapshot_report.md):

  Report of changed image snapshots.

- [`use_odiffr_ci()`](https://benwolst.github.io/odiffr/reference/use_odiffr_ci.md):

  Add a GitHub Actions workflow for visual tests.

- [`approve_changes()`](https://benwolst.github.io/odiffr/reference/approve_changes.md):

  Accept current images as new baselines.

- [`diff_image()`](https://benwolst.github.io/odiffr/reference/diff_image.md),
  [`plot.odiff_result()`](https://benwolst.github.io/odiffr/reference/plot.odiff_result.md):

  View diff images.

- [`audit_record()`](https://benwolst.github.io/odiffr/reference/audit_record.md):

  Machine-readable record of comparisons.

## Binary Management

- [`install_odiff()`](https://benwolst.github.io/odiffr/reference/install_odiff.md):

  Download Odiff to the user cache (no Node.js needed).

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
    [`install_odiff()`](https://benwolst.github.io/odiffr/reference/install_odiff.md)
    or
    [`odiffr_update()`](https://benwolst.github.io/odiffr/reference/odiffr_update.md)

## Supported Image Formats

- Input:

  PNG, JPEG, WEBP, TIFF (`.tiff`; `.tif` is not accepted by odiff) and
  BMP. Cross-format comparison is supported.

- Output:

  PNG only

## Exit Codes

- 0:

  Images match

- 21:

  Layout difference (different dimensions)

- 22:

  Pixel differences found

- 1:

  Error (e.g. an image could not be read)

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

- <https://benwolst.github.io/odiffr/>

- <https://github.com/BenWolst/odiffr>

- Report bugs at <https://github.com/BenWolst/odiffr/issues>

## Author

**Maintainer**: Ben Wolstenholme <odiffr@benwolst.dev>

Authors:

- Ben Wolstenholme <odiffr@benwolst.dev>
