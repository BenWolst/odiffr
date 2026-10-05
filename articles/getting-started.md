# Getting Started with Odiffr

## Introduction

Odiffr provides R bindings to
[Odiff](https://github.com/dmtrKovalenko/odiff), a blazing-fast
pixel-by-pixel image comparison tool. It’s designed for:

- Visual regression testing of Shiny apps and reports
- Quality assurance in validated pharmaceutical environments
- Automated image analysis workflows

## Installation

``` r

# From CRAN
install.packages("odiffr")

# Development version
pak::pak("BenWolst/odiffr")
```

## System Requirements

Odiffr requires the Odiff binary (\>= 4.1.1). The easiest way to install
it is from R:
[`install_odiff()`](https://benwolst.github.io/odiffr/reference/install_odiff.md)
downloads the binary for your platform from the Odiff GitHub releases to
your user cache, with no need for Node.js or administrator rights:

``` r

odiffr::install_odiff()
```

In interactive sessions, odiffr also offers to do this the first time
Odiff is needed (for example, by
[`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md)).
It never prompts or downloads anything in non-interactive sessions,
tests, R Markdown documents or `R CMD check`; set
`options(odiffr.ask_install = FALSE)` to turn the offer off.

Alternatively, install Odiff system-wide:

``` bash
# npm (cross-platform)
npm install -g odiff-bin

# Or download binaries from GitHub releases
# https://github.com/dmtrKovalenko/odiff/releases
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
#> Path:     /opt/hostedtoolcache/node/22.23.3/x64/lib/node_modules/odiff-bin/node_modules/@odiff/linux-x64/odiff 
#> Version:  4.5.0 
#> Source:   system 
#> Via npm:  /opt/hostedtoolcache/node/22.23.3/x64/lib/node_modules/odiff-bin/bin/odiff
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

The threshold parameter (0-1) controls colour sensitivity. Lower values
are more precise:

``` r

# Very strict comparison
result <- compare_images("img1.png", "img2.png", threshold = 0.01)

# More lenient (ignore minor colour variations)
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

| Column | Type | Description |
|----|----|----|
| `pair_id` | integer | Sequential comparison ID |
| `match` | logical | `TRUE` if images match |
| `reason` | character | `"match"`, `"pixel-diff"`, `"layout-diff"`, `"missing"` or `"error"` |
| `diff_count` | integer | Number of different pixels (`0` for a match, `NA` if unknown) |
| `diff_percentage` | numeric | Percentage of pixels different (`0` for a match, `NA` if unknown) |
| `diff_output` | character | Path to diff image, or `NA` |
| `img1` | character | Path to baseline image |
| `img2` | character | Path to current image |
| `error` | character | Error message when `reason` is `"missing"` or `"error"`, otherwise `NA` |

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
  show_all = TRUE,     # Include all comparisons, not just failures
  images = "all"       # Baseline, current and diff side by side
)
```

Reports include: - Pass/fail statistics with visual cards - Failure
reason breakdown - Diff statistics (min, median, mean, max) - Worst
offenders table with thumbnails (only the diff image by default;
baseline, current and diff side by side with `images = "all"`; click a
thumbnail to see the full-size image)

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

### Approving Changes

When differences are intentional, accept the current images as the new
baselines with
[`approve_changes()`](https://benwolst.github.io/odiffr/reference/approve_changes.md):

``` r

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
[`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md)
again afterwards should report only matches.

### Viewing a Diff

``` r

# Baseline, current and diff image side by side (base graphics)
result <- odiff_run("baseline.png", "current.png", diff_output = "diff.png")
plot(result)
plot(result, which = "diff")

# Get the diff image of a compare_images() result or a batch row
img <- diff_image(compare_images("baseline.png", "current.png",
                                 diff_output = TRUE))  # magick-image
plot(diff_image(failed_pairs(results)[1, ], as = "raster"))  # no magick
```

### CI Integration

For a package with image snapshot tests,
[`use_odiffr_ci()`](https://benwolst.github.io/odiffr/reference/use_odiffr_ci.md)
writes a ready-to-use GitHub Actions workflow to
`.github/workflows/odiffr.yaml`. It installs Odiff with
[`install_odiff()`](https://benwolst.github.io/odiffr/reference/install_odiff.md),
runs the testthat tests, adds a
[`snapshot_report()`](https://benwolst.github.io/odiffr/reference/snapshot_report.md)
summary of changed snapshots to the job summary and, if tests fail,
uploads the new snapshots and diff images as an artifact:

``` r

use_odiffr_ci()
```

For comparisons outside testthat, the
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

### CI Outputs

Two functions write batch results in formats that CI systems understand:

- [`batch_markdown()`](https://benwolst.github.io/odiffr/reference/batch_markdown.md)
  produces a GitHub-flavoured Markdown summary (pass/fail line, failure
  reasons and a worst offenders table). When the `GITHUB_STEP_SUMMARY`
  environment variable is set, as it is in GitHub Actions, the summary
  is appended to that file and shows up on the job’s summary page.
  Elsewhere it returns the Markdown as a string.
- [`batch_junit()`](https://benwolst.github.io/odiffr/reference/batch_junit.md)
  writes a JUnit XML report with one test case per comparison.
  Differences and missing files are failures, comparisons that could not
  be run are errors. Most CI test reporters can display it.

``` r

results <- compare_image_dirs("baseline/", "current/", diff_dir = "diffs/")

batch_markdown(results)                    # GitHub job summary
batch_junit(results, "odiffr-junit.xml")   # JUnit XML
batch_report(results, "diffs/report.html", images = "all", embed = TRUE)
```

A complete GitHub Actions step:

``` yaml
- name: Compare images
  run: |
    library(odiffr)
    results <- compare_image_dirs("baseline/", "current/", diff_dir = "diffs/")
    batch_markdown(results)
    batch_junit(results, "odiffr-junit.xml")
    batch_report(results, "diffs/report.html", images = "all",
                 embed = TRUE)
    if (any(!results$match)) stop("Visual regression detected!")
  shell: Rscript {0}

- name: Upload diffs and report
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: visual-diffs
    path: |
      diffs/
      odiffr-junit.xml
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
  enable_asm = TRUE,
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

### Install or Update the Binary

Download the latest Odiff binary to your user cache:

``` r

# Latest version
install_odiff()

# Specific version, replacing the cached binary
install_odiff(version = "v4.1.2", force = TRUE)
```

[`odiffr_update()`](https://benwolst.github.io/odiffr/reference/odiffr_update.md)
is the lower-level function behind
[`install_odiff()`](https://benwolst.github.io/odiffr/reference/install_odiff.md).

### Custom Binary Path

Use a specific binary (useful for validated environments):

``` r

options(odiffr.path = "/validated/bin/odiff-4.1.2")
```

### Faster comparisons with npm installs

Since odiff 4.4, the npm package `odiff-bin` installs a Node.js launcher
that starts Node before running the native binary, which adds tens of
milliseconds to each comparison. Odiffr detects such a launcher on the
PATH automatically and runs the native binary from the npm installation
directly (falling back to the launcher if the binary cannot be found).
Nothing needs configuring:

``` r

info <- odiff_info()
info$path  # the native binary
info$shim  # the npm launcher it was resolved from (NA if none)

# Opt out and use the PATH entry as-is
options(odiffr.resolve_npm = FALSE)
```

A path set with `options(odiffr.path = ...)` is always used exactly as
given.

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

### Testing Plots

Plots can be passed anywhere an image is accepted: a ggplot object, a
function of no arguments that draws a plot (base or grid graphics), or a
recorded plot from
[`grDevices::recordPlot()`](https://rdrr.io/r/grDevices/recordplot.html).
Plots are rendered to a temporary PNG with
[`ragg::agg_png()`](https://ragg.r-lib.org/reference/agg_png.html) if
ragg is installed (recommended, for consistent output across platforms),
otherwise with
[`grDevices::png()`](https://rdrr.io/r/grDevices/png.html). Control the
size, resolution and background with
[`plot_options()`](https://benwolst.github.io/odiffr/reference/plot_options.md):

``` r

library(ggplot2)

test_that("scatter plot matches baseline", {
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()

  expect_images_match(
    p,
    test_path("baselines/scatter.png"),
    plot_options = plot_options(width = 6, height = 4, res = 96)
  )
})

# compare_images() accepts plots too; they are labelled "<plot>"
compare_images("baseline_hist.png", function() hist(mtcars$mpg))
```

The baseline must be rendered with the same
[`plot_options()`](https://benwolst.github.io/odiffr/reference/plot_options.md)
(and graphics device) as the plot being tested.

### Snapshot Testing with expect_snapshot_image()

Instead of managing baseline files yourself,
[`expect_snapshot_image()`](https://benwolst.github.io/odiffr/reference/expect_snapshot_image.md)
builds on testthat’s snapshot workflow: the first run saves the image to
`tests/testthat/_snaps/<test-file>/<name>.png`, and later runs compare
against it with odiff, so differences below `threshold` (or inside
`ignore_regions`) do not fail the test. It accepts image files,
magick-image objects and plots.

``` r

test_that("plots are stable", {
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  expect_snapshot_image(p)  # snapshot name: "p.png"

  expect_snapshot_image(
    function() hist(mtcars$mpg),
    name = "mpg-hist",          # required for inline expressions
    antialiasing = TRUE,
    variant = Sys.info()[["sysname"]]  # separate snapshots per OS
  )
})
```

When a snapshot changes, the new image is saved next to it as
`<name>.new.png`. Review the changes side by side and accept the
intended ones:

``` r

testthat::snapshot_review()
testthat::snapshot_accept()
```

Like
[`testthat::expect_snapshot_file()`](https://testthat.r-lib.org/reference/expect_snapshot_file.html),
[`expect_snapshot_image()`](https://benwolst.github.io/odiffr/reference/expect_snapshot_image.md)
is skipped on CRAN. To use odiff comparison for image files you write
yourself, pass
[`compare_file_odiff()`](https://benwolst.github.io/odiffr/reference/compare_file_odiff.md)
as the `compare` argument of
[`testthat::expect_snapshot_file()`](https://testthat.r-lib.org/reference/expect_snapshot_file.html).

### Diff Images on Failure

When
[`expect_images_match()`](https://benwolst.github.io/odiffr/reference/expect_images.md)
fails, a diff image is automatically saved to `tests/testthat/_odiffr/`
for debugging. Control this behaviour with options:

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

Use vdiffr for SVG snapshots of R plots; use odiffr for testing
screenshots of Shiny apps, web pages, PDFs, rendered (raster) plots, or
any raster image comparison.

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

### Audit records

[`audit_record()`](https://benwolst.github.io/odiffr/reference/audit_record.md)
turns comparison results into a documented, machine-readable evidence
record that supports audit trails. For every comparison it records the
image paths with their hashes and sizes, the diff image (if any) and its
hash, and the outcome (`match`, `reason`, `diff_count`,
`diff_percentage`, `error`). A header records the schema version
(`"odiffr-audit/1"`), a UTC timestamp, the odiffr and odiff versions,
the odiff binary path and hash, the R version, platform and user, and
the comparison parameters.

``` r

# odiff_run() results carry their parameters
result <- odiff_run("baseline.png", "current.png", "diff.png",
                    threshold = 0.05)
rec <- audit_record(result)
rec$header$odiff_version
rec$comparisons[, c("img1_hash", "img2_hash", "match")]

# Write a JSON evidence file (requires jsonlite)
audit_record(result, file = "validation/comparison-audit.json")

# Batch results: pass the parameters you used; CSV has one row per pair
results <- compare_image_dirs("baseline/", "current/", threshold = 0.05)
audit_record(results, file = "validation/audit.csv", format = "csv",
             params = list(threshold = 0.05))
```

SHA-256 hashing uses the openssl or digest package; use `hash = "md5"`
to rely on base R only. Files are hashed when
[`audit_record()`](https://benwolst.github.io/odiffr/reference/audit_record.md)
is called, so create the record straight after the comparison. See
[`?audit_record`](https://benwolst.github.io/odiffr/reference/audit_record.md)
for the full schema.
