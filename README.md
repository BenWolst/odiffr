# Odiffr <img src="man/figures/logo.png" align="right" height="139" alt="Odiffr logo" />

<!-- badges: start -->

[![CRAN status](https://www.r-pkg.org/badges/version/odiffr)](https://CRAN.R-project.org/package=odiffr)
[![R-CMD-check](https://github.com/BenWolst/odiffr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/BenWolst/odiffr/actions/workflows/R-CMD-check.yaml)
[![Codecov](https://codecov.io/gh/BenWolst/odiffr/branch/main/graph/badge.svg)](https://app.codecov.io/gh/BenWolst/odiffr)

<!-- badges: end -->

Fast pixel-by-pixel image comparison for R, powered by [odiff](https://github.com/dmtrKovalenko/odiff).

## Features

- **Blazing fast**: ~6x faster than ImageMagick, optimized with SIMD (SSE2, AVX2, AVX512, NEON)
- **Cross-platform**: Works on Windows, macOS (Intel & Apple Silicon), and Linux
- **Flexible**: Accepts file paths, magick-image objects, or plots (ggplot2, base graphics)
- **Configurable**: Threshold, antialiasing detection, region ignoring
- **HTML reports**: Generate standalone QA reports with `batch_report()`
- **CI outputs**: GitHub job summaries with `batch_markdown()` and JUnit XML with `batch_junit()`
- **testthat integration**: `expect_images_match()`, `expect_images_differ()` and `expect_snapshot_image()` for visual regression testing

## Installation

### System Requirements

Odiffr requires the Odiff binary to be installed on your system:

```bash
# npm (cross-platform, recommended)
npm install -g odiff-bin

# Or download binaries from GitHub releases
# https://github.com/dmtrKovalenko/odiff/releases
```

### Install Odiffr

```r
# Install from CRAN (when available)
install.packages("odiffr")

# Or install the development version from GitHub
# install.packages("pak")
pak::pak("BenWolst/odiffr")
```

### Alternative: Download via R

If you cannot install Odiff system-wide:

```r
odiffr::odiffr_update()  # Downloads to user cache
```

## Quick Start

```r
library(odiffr)

# Compare two images
result <- compare_images("baseline.png", "current.png")
result$match
#> [1] FALSE

result$diff_percentage
#> [1] 2.45

# Generate a diff image
result <- compare_images("baseline.png", "current.png", diff_output = "diff.png")
```

## Usage

### Basic Comparison

```r
# High-level API (returns tibble if available)
result <- compare_images("img1.png", "img2.png")

# Low-level API (returns detailed list)
result <- odiff_run("img1.png", "img2.png")
```

### With Options

```r
# Adjust sensitivity threshold (0-1, lower = more precise)
result <- compare_images("img1.png", "img2.png", threshold = 0.05)

# Ignore antialiased pixels
result <- compare_images("img1.png", "img2.png", antialiasing = TRUE)

# Fail immediately if dimensions differ
result <- compare_images("img1.png", "img2.png", fail_on_layout = TRUE)
```

### Ignore Regions

```r
# Ignore specific areas (e.g., timestamps, dynamic content)
result <- compare_images("img1.png", "img2.png",
  ignore_regions = list(
    ignore_region(0, 0, 200, 50),     # Header
    ignore_region(0, 500, 800, 600)   # Footer
  )
)
```

### Batch Comparison

```r
# Compare multiple image pairs
pairs <- data.frame(
  img1 = c("baseline/page1.png", "baseline/page2.png"),
  img2 = c("current/page1.png", "current/page2.png")
)

results <- compare_images_batch(pairs, diff_dir = "diffs/")

# Extract failures or passes
failed_pairs(results)
passed_pairs(results)

# Compare entire directories
results <- compare_image_dirs("baseline/", "current/", recursive = TRUE)

# Get summary statistics
summary(results)
#> odiffr batch comparison: 50 pairs
#> Passed: 42 (84.0%)
#> Failed: 8 (16.0%)

# Use parallel processing (Unix only)
results <- compare_images_batch(pairs, parallel = TRUE)
```

### HTML Reports

```r
# One-liner: compare directories and generate HTML report
compare_dirs_report("baseline/", "current/")
# -> Creates diffs/ directory with diff images and report.html

# Or step-by-step for more control
results <- compare_image_dirs("baseline/", "current/", diff_dir = "diffs/")
batch_report(results, output_file = "qa-report.html")

# Self-contained report with embedded images
batch_report(results, output_file = "qa-report.html", embed = TRUE)

# Portable report with relative image paths
batch_report(results, output_file = "output/report.html", relative_paths = TRUE)

# Baseline, current and diff thumbnails side by side
batch_report(results, output_file = "qa-report.html", images = "all")
```

### CI Outputs

Besides the HTML report, batch results can be written in formats that CI
systems display natively:

```r
# GitHub-flavoured Markdown; appended to the job summary page when
# GITHUB_STEP_SUMMARY is set, otherwise returned as a string
batch_markdown(results)

# JUnit XML for test reporters (one test case per comparison)
batch_junit(results, "odiffr-junit.xml")
```

A GitHub Actions step using all three:

```yaml
      - name: Compare images
        run: |
          library(odiffr)
          results <- compare_image_dirs("baseline/", "current/", diff_dir = "diffs/")
          batch_markdown(results)                       # job summary
          batch_junit(results, "odiffr-junit.xml")      # test report
          batch_report(results, "diffs/report.html", images = "all",
                       embed = TRUE)                    # HTML report
          if (any(!results$match)) stop("Visual regression detected!")
        shell: Rscript {0}
```

### Approving Changes

When differences are intentional, accept the current images as the new
baselines with `approve_changes()`:

```r
results <- compare_image_dirs("baseline/", "current/", diff_dir = "diffs/")

# Review the differences first
batch_report(results, "diffs/report.html")

# Preview what would change, then copy current images over the baselines
approve_changes(results, dry_run = TRUE)
approve_changes(results)

# Approve selected images only, keeping a backup of the old baselines
approve_changes(results, which = "home.png", backup_dir = "baseline-backup/")

# Also delete baselines whose screenshot was intentionally removed
approve_changes(results, reasons = "missing", remove_missing = TRUE)
```

Rows with `reason = "error"` are never approved. Running
`compare_image_dirs()` again afterwards should report only matches.

### Viewing a Diff

```r
# Baseline, current and diff image side by side (base graphics)
result <- odiff_run("baseline.png", "current.png", diff_output = "diff.png")
plot(result)
plot(result, which = "diff")

# Get the diff image of a compare_images() result or a batch row
img <- diff_image(compare_images("baseline.png", "current.png",
                                 diff_output = TRUE))  # magick-image
plot(diff_image(failed_pairs(results)[1, ], as = "raster"))  # no magick
```

### Comparing PDFs

Compare PDF documents (e.g. clinical tables and figures, or rendered Quarto /
R Markdown documents) page by page. Requires the
[pdftools](https://docs.ropensci.org/pdftools/) package.

```r
# One row per page; differing pages get a diff image
res <- compare_pdfs("before/report.pdf", "after/report.pdf",
                    dpi = 150, diff_dir = "pdf-diffs")
summary(res)
failed_pairs(res)[, c("page", "reason", "diff_percentage")]

# Compare all PDFs in two directories (e.g. outputs before/after an R upgrade)
res <- compare_pdf_dirs("outputs-old/", "outputs-new/", diff_dir = "pdf-diffs")
batch_report(res, output_file = "pdf-diffs/report.html")
```

Pages missing from the current PDF are reported as `"missing"`, extra pages
as `"error"`. `ignore_regions` coordinates are pixels at the chosen `dpi`.
Only PDF is supported: convert RTF/DOCX outputs to PDF first (e.g.
`soffice --headless --convert-to pdf`). See
`vignette("pdf-outputs", package = "odiffr")`.

### CI Integration

Run visual regression tests in GitHub Actions and upload diff artifacts:

```yaml
# .github/workflows/visual-regression.yaml
name: Visual Regression

on: [push, pull_request]

jobs:
  visual-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: r-lib/actions/setup-r@v2

      - name: Install dependencies
        run: |
          install.packages(c("odiffr", "webshot2"))
          odiffr::odiffr_update()
        shell: Rscript {0}

      - name: Generate screenshots
        run: Rscript scripts/generate-screenshots.R

      - name: Compare images
        run: |
          library(odiffr)
          results <- compare_dirs_report("baseline/", "current/")
          if (any(!results$match)) stop("Visual regression detected!")
        shell: Rscript {0}

      - name: Upload diffs
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: visual-diffs
          path: diffs/
```

### With magick Package

```r
library(magick)

# Compare magick-image objects directly
img1 <- image_read("baseline.png") |> image_resize("800x600")
img2 <- image_read("current.png") |> image_resize("800x600")

result <- compare_images(img1, img2)
```

### Visual Regression Testing

```r
library(testthat)
library(odiffr)

test_that("dashboard renders correctly", {

  expect_images_match(
    "screenshots/current.png",
    "screenshots/baseline.png",
    threshold = 0.1
  )
})

test_that("button changes on hover", {
  expect_images_differ(
    "button_normal.png",
    "button_hover.png"
  )
})
```

On failure, diff images are automatically saved to `tests/testthat/_odiffr/`.

### Testing Plots

`compare_images()` and the expectations also accept plots: ggplot objects,
functions that draw a base/grid plot, and recorded plots. They are rendered
to a temporary PNG (with ragg if installed, otherwise `grDevices::png()`)
using `plot_options()`.

```r
library(ggplot2)

test_that("scatter plot matches baseline", {
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  expect_images_match(p, test_path("baselines/scatter.png"),
                      plot_options = plot_options(width = 6, height = 4))
})
```

Or let testthat manage the baselines with `expect_snapshot_image()`, which
stores snapshots in `tests/testthat/_snaps/` and compares them with odiff
(so small, sub-threshold differences don't fail):

```r
test_that("plots are stable", {
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  expect_snapshot_image(p)  # _snaps/<file>/p.png
  expect_snapshot_image(function() hist(mtcars$mpg), name = "mpg-hist",
                        antialiasing = TRUE)
})

# After an intended change, review and accept the new images
testthat::snapshot_review()
testthat::snapshot_accept()
```

Like other file snapshots, these are skipped on CRAN. Use
`variant = Sys.info()[["sysname"]]` if rendering differs across platforms.
When a snapshot fails, a diff image is written to `tests/testthat/_odiffr/`.
On CI, `snapshot_report()` writes an HTML, Markdown or JUnit report of all
changed snapshots.

### Shiny Apps (shinytest2)

Use odiff for shinytest2 screenshots to tolerate browser anti-aliasing noise
and get a diff image when a screenshot changes:

```r
app$expect_screenshot(compare = compare_file_odiff(preset = "screenshot"))
```

See `vignette("shinytest2")` for presets, a project-wide helper, CI reports
and platform variants, and `vignette("web-pages")` for web pages and
htmlwidgets.

## Binary Management

```r
# Check if Odiff is available
odiff_available()

# Get version and configuration info
odiff_info()

# Update to latest version (downloads to user cache)
odiffr_update()

# Use a specific binary
options(odiffr.path = "/path/to/odiff")
```

### Binary Detection Priority

1. `options(odiffr.path = "...")` - User override
2. System PATH (`Sys.which("odiff")`)
3. Cached binary from `odiffr_update()`

### Faster comparisons with npm installs

Since odiff 4.4, `npm install -g odiff-bin` puts a Node.js launcher on the
PATH that starts Node before running the native binary, adding tens of
milliseconds to every comparison. Odiffr detects this automatically and calls
the native binary inside the npm installation directly, falling back to the
launcher if it cannot be found. `odiff_info()` shows the launcher it was
resolved from. To use the PATH entry as-is, set
`options(odiffr.resolve_npm = FALSE)`; a binary set with
`options(odiffr.path = ...)` is always used exactly as given.

## Supported Formats

| Type   | Formats               |
| ------ | --------------------- |
| Input  | PNG, JPEG, WEBP, TIFF |
| Output | PNG only              |

Cross-format comparison is supported (e.g., compare JPEG to PNG).

## For Validated Environments

Odiffr is designed for use in validated pharmaceutical and clinical research:

- **Pinnable**: Lock to specific validated binary with `options(odiffr.path = ...)`
- **Auditable**: Use `odiff_version()` to document binary version for audit trails
- **Base R core**: Zero external runtime dependencies for core functions

```r
# Pin to a specific validated binary
options(odiffr.path = "/validated/bin/odiff-4.1.2")

# Document in validation scripts
info <- odiff_info()
sprintf("Using odiff %s from %s", info$version, info$source)
```

### Audit records

`audit_record()` creates a machine-readable evidence record of comparisons,
supporting audit trails: SHA-256 (or MD5) hashes and sizes of every input and
diff image, the outcome of each comparison, the parameters used, and the
environment (odiffr and odiff versions, odiff binary path and hash, R
version, platform, user and a UTC timestamp).

```r
result <- odiff_run("baseline.png", "current.png", "diff.png", threshold = 0.05)
audit_record(result, file = "audit.json")   # parameters recorded automatically

# Batch results: pass the parameters used; CSV has one row per comparison
results <- compare_image_dirs("baseline/", "current/", threshold = 0.05)
audit_record(results, file = "audit.csv", format = "csv",
             params = list(threshold = 0.05))
```

JSON output needs the jsonlite package and SHA-256 hashing needs openssl or
digest (`hash = "md5"` works with base R alone). See `?audit_record` for the
full schema.

## Performance

Odiff is approximately 6x faster than ImageMagick for pixel comparison, thanks to SIMD optimizations. Performance scales well with image size.

On x86_64 systems with AVX-512, pass `enable_asm = TRUE` to `odiff_run()` for
~12% faster comparisons (requires odiff >= 4.1.1).

## Related

- [odiff](https://github.com/dmtrKovalenko/odiff) - The underlying CLI tool
- [magick](https://cran.r-project.org/package=magick) - R wrapper for ImageMagick
- [testthat](https://cran.r-project.org/package=testthat) - For visual regression tests

## License

MIT
