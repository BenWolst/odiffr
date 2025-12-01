# Getting Started with Odiffr

## Introduction

Odiffr provides R bindings to
[Odiff](https://github.com/dmtrKovalenko/odiff), a blazing-fast
pixel-by-pixel image comparison tool. It’s designed for:

- Visual regression testing of Shiny apps and reports
- Quality assurance in validated pharmaceutical environments
- Automated image analysis workflows

## System Requirements

Odiffr requires the Odiff binary to be installed on your system:

``` bash
# npm (cross-platform, recommended)
npm install -g odiff-bin

# Or download binaries from GitHub releases
# https://github.com/dmtrKovalenko/odiff/releases
```

If you cannot install Odiff system-wide, use
[`odiffr_update()`](https://benwolst.github.io/odiffr/reference/odiffr_update.md)
after installing the package to download a binary to your user cache.

## Installation

``` r
# From CRAN (when available)
install.packages("odiffr")

# Development version
pak::pak("BenWolst/odiffr")
```

## Basic Usage

``` r
library(odiffr)
```

### Check Configuration

``` r
# Verify Odiff is available
odiff_available()
#> [1] TRUE

# View configuration details
odiff_info()
#> odiffr configuration
#> --------------------
#> OS:       linux 
#> Arch:     x64 
#> Path:     /opt/hostedtoolcache/node/20.19.5/x64/lib/node_modules/odiff-bin/bin/odiff.exe 
#> Version:  4.3.2 
#> Source:   system
```

### Compare Images

The main function is
[`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md),
which returns a tibble (or data.frame):

``` r
result <- compare_images("baseline.png", "current.png")
result
#> # A tibble: 1 × 7
#>   match reason     diff_count diff_percentage diff_output img1         img2
#>   <lgl> <chr>           <int>           <dbl> <chr>       <chr>        <chr>
#> 1 FALSE pixel-diff       1234            2.45 NA          baseline.png current.png
```

### Generate Diff Images

``` r
# Specify output path
result <- compare_images("baseline.png", "current.png",
                         diff_output = "diff.png")

# Or use TRUE for auto-generated temp file
result <- compare_images("baseline.png", "current.png",
                         diff_output = TRUE)
result$diff_output
#> [1] "/tmp/RtmpXXXXXX/file12345.png"
```

## Advanced Options

### Threshold

The threshold parameter (0-1) controls color sensitivity. Lower values
are more precise:

``` r
# Very strict comparison
result <- compare_images("img1.png", "img2.png", threshold = 0.01)

# More lenient (ignore minor color variations)
result <- compare_images("img1.png", "img2.png", threshold = 0.2)
```

### Antialiasing

Ignore antialiased pixels that often differ between renders:

``` r
result <- compare_images("img1.png", "img2.png", antialiasing = TRUE)
```

### Ignore Regions

Exclude specific areas from comparison (useful for timestamps, dynamic
content):

``` r
result <- compare_images("img1.png", "img2.png",
  ignore_regions = list(
    ignore_region(x1 = 0, y1 = 0, x2 = 200, y2 = 50),    # Header
    ignore_region(x1 = 0, y1 = 900, x2 = 1920, y2 = 1080) # Footer
  )
)
```

## Batch Processing

Compare multiple image pairs efficiently:

``` r
pairs <- data.frame(
  img1 = c("baseline/page1.png", "baseline/page2.png", "baseline/page3.png"),
  img2 = c("current/page1.png", "current/page2.png", "current/page3.png")
)

results <- compare_images_batch(pairs, diff_dir = "diffs/")

# View failures
results[!results$match, ]
```

### Directory Comparison

Compare all images in two directories by matching filenames:

``` r
# Compare baseline/ vs current/ directories
results <- compare_image_dirs("baseline/", "current/")

# Include subdirectories
results <- compare_image_dirs("baseline/", "current/", recursive = TRUE)

# Only compare PNG files
results <- compare_image_dirs("baseline/", "current/", pattern = "\\.png$")
```

Note:
[`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md)
matches files by name in both directories. If there are files in
`current/` with no matching baseline, a message is printed showing which
files were skipped.

### Accessor Functions

Extract passing or failing pairs from batch results:

``` r
results <- compare_image_dirs("baseline/", "current/")

# Get only failures
failures <- failed_pairs(results)
nrow(failures)
#> [1] 8

# Get only passes
passes <- passed_pairs(results)
nrow(passes)
#> [1] 42
```

### Batch Summary

Get aggregate statistics for batch results:

``` r
results <- compare_image_dirs("baseline/", "current/")
summary(results)
#> odiffr batch comparison: 50 pairs
#> ───────────────────────────────────
#> Passed: 42 (84.0%)
#> Failed: 8 (16.0%)
#>   - pixel-diff: 6
#>   - layout-diff: 2
#>
#> Diff statistics (failed pairs):
#>   Min:    0.15%
#>   Median: 2.34%
#>   Mean:   3.21%
#>   Max:    12.45%
#>
#> Worst offenders:
#>   1. page_a.png (12.45%, 1245 pixels)
#>   2. page_b.png (8.32%, 832 pixels)
```

### Column Reference

The `odiffr_batch` object returned by
[`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md)
and
[`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md)
contains these columns:

| Column            | Type      | Description                                   |
|-------------------|-----------|-----------------------------------------------|
| `pair_id`         | integer   | Sequential comparison ID                      |
| `match`           | logical   | `TRUE` if images match                        |
| `reason`          | character | `"match"`, `"pixel-diff"`, or `"layout-diff"` |
| `diff_count`      | integer   | Number of different pixels                    |
| `diff_percentage` | numeric   | Percentage of pixels different                |
| `diff_output`     | character | Path to diff image, or `NA`                   |
| `img1`            | character | Path to baseline image                        |
| `img2`            | character | Path to current image                         |

### Parallel Processing

Speed up batch comparisons using multiple CPU cores (Unix only):

``` r
# Compare in parallel on macOS/Linux
results <- compare_images_batch(pairs, parallel = TRUE)

# Also works with directory comparison
results <- compare_image_dirs("baseline/", "current/", parallel = TRUE)
```

Note: On Windows, `parallel = TRUE` falls back to sequential processing.

### HTML Reports

Generate standalone HTML reports for QA review:

``` r
# Run batch comparison with diff images
results <- compare_image_dirs(
  "baseline/",
  "current/",
  diff_dir = "diffs/"
)

# Generate HTML report (links to diff images)
batch_report(results, output_file = "qa-report.html")

# Self-contained report with embedded images (for sharing)
batch_report(results, output_file = "qa-report.html", embed = TRUE)

# Portable report with relative paths (move report + diffs together)
batch_report(results, output_file = "output/report.html", relative_paths = TRUE)

# Customize the report
batch_report(
  results,
  output_file = "report.html",
  title = "Dashboard Visual Regression",
  n_worst = 20,        # Show top 20 failures
  show_all = TRUE      # Include all comparisons, not just failures
)
```

Reports include: - Pass/fail statistics with visual cards - Failure
reason breakdown - Diff statistics (min, median, mean, max) - Worst
offenders table with thumbnails

The `relative_paths` option is useful when you want to move or share the
report along with the diff images folder. With relative paths, the
report will find the images regardless of where the files are moved.

### One-Liner Workflow

For the common workflow of comparing directories and generating a
report, use
[`compare_dirs_report()`](https://benwolst.github.io/odiffr/reference/compare_dirs_report.md):

``` r
# Compare and generate report in one step
compare_dirs_report("baseline/", "current/")
# -> Creates diffs/ directory with diff images and report.html

# Self-contained report with embedded images (recommended for sharing)
compare_dirs_report("baseline/", "current/", embed = TRUE)

# See all comparisons, not just failures
compare_dirs_report("baseline/", "current/", show_all = TRUE)

# Portable report with relative image paths
compare_dirs_report("baseline/", "current/", relative_paths = TRUE)

# Combine options: parallel processing with embedded report
compare_dirs_report("baseline/", "current/", parallel = TRUE, embed = TRUE)
```

### CI Integration

The
[`compare_dirs_report()`](https://benwolst.github.io/odiffr/reference/compare_dirs_report.md)
one-liner is ideal for CI pipelines:

``` r
# In your CI script
results <- compare_dirs_report("baseline/", "current/")

# Fail the build if any images differ
if (any(!results$match)) {
  stop("Visual regression detected! See diffs/ for details.")
}
```

For GitHub Actions, upload `diffs/` as an artifact on failure:

``` yaml
- name: Upload diffs
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: visual-diffs
    path: diffs/
```

## Working with magick

Odiffr integrates with the
[magick](https://cran.r-project.org/package=magick) package for
preprocessing:

``` r
library(magick)

# Read and preprocess images
img1 <- image_read("baseline.png") |>
  image_resize("800x600") |>
  image_convert(colorspace = "sRGB")

img2 <- image_read("current.png") |>
  image_resize("800x600") |>
  image_convert(colorspace = "sRGB")

# Compare directly
result <- compare_images(img1, img2)
```

## Low-Level API

For full control, use
[`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md):

``` r
result <- odiff_run(
  img1 = "baseline.png",
  img2 = "current.png",
  diff_output = "diff.png",
  threshold = 0.1,
  antialiasing = TRUE,
  fail_on_layout = TRUE,
  diff_mask = FALSE,
  diff_overlay = 0.5,
  diff_color = "#FF00FF",
  diff_lines = TRUE,
  reduce_ram = FALSE,
  ignore_regions = list(ignore_region(10, 10, 100, 50)),
  timeout = 60
)

# Detailed result
result$match
result$reason
result$diff_count
result$diff_percentage
result$diff_lines
result$exit_code
result$duration
```

## Binary Management

### Update Binary

Download the latest Odiff binary to your user cache:

``` r
# Latest version
odiffr_update()

# Specific version
odiffr_update(version = "v4.1.2")
```

### Custom Binary Path

Use a specific binary (useful for validated environments):

``` r
options(odiffr.path = "/validated/bin/odiff-4.1.2")
```

### Cache Management

``` r
# View cache location
odiffr_cache_path()
#> [1] "/home/runner/.cache/R/odiffr"
```

``` r
# Clear cached binaries
odiffr_clear_cache()
```

## Visual Regression Testing with testthat

Odiffr provides dedicated testthat expectations for visual regression
testing:

``` r
library(testthat)
library(odiffr)

test_that("dashboard renders correctly", {
  skip_if_no_odiff()

  # Generate current screenshot (using your preferred method)
  webshot2::webshot("http://localhost:3838/dashboard", "current.png")

  # Compare to baseline using expect_images_match()
  expect_images_match(
    "current.png",
    "baselines/dashboard.png",
    threshold = 0.1,
    antialiasing = TRUE
  )
})

test_that("button changes on hover", {
  skip_if_no_odiff()

  # Assert that images are different
  expect_images_differ(
    "button_normal.png",
    "button_hover.png"
  )
})
```

### Diff Images on Failure

When
[`expect_images_match()`](https://benwolst.github.io/odiffr/reference/expect_images.md)
fails, a diff image is automatically saved to `tests/testthat/_odiffr/`
for debugging. Control this behavior with options:

``` r
# Disable diff image saving
options(odiffr.save_diff = FALSE)

# Use a custom directory
options(odiffr.diff_dir = "my_diffs/")
```

### Comparison with vdiffr

Odiffr and [vdiffr](https://vdiffr.r-lib.org/) are complementary
tools: - **vdiffr** uses SVG-based comparison for ggplot2/grid graphics
snapshots - **odiffr** uses pixel-based comparison for screenshots,
rendered images, and bitmaps

Use vdiffr for testing R plots; use odiffr for testing screenshots of
Shiny apps, web pages, PDFs, or any raster image comparison.

## For Validated Environments

Odiffr is designed for validated pharmaceutical/clinical research:

1.  **Pinnable**: Lock to a specific validated binary with
    `options(odiffr.path = ...)`
2.  **Auditable**: Use
    [`odiff_version()`](https://benwolst.github.io/odiffr/reference/odiff_version.md)
    to document binary version for audit trails
3.  **Base R core**: Zero external runtime dependencies for core
    functions

``` r
# Pin to a specific validated binary
options(odiffr.path = "/validated/bin/odiff-4.1.2")

# Document version for validation
info <- odiff_info()
sprintf("Using odiff %s from %s", info$version, info$source)
```
