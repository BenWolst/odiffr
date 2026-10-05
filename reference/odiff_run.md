# Run odiff Command (Low-Level)

Direct wrapper around the odiff CLI with zero external dependencies.
Returns a structured list with comparison results.

## Usage

``` r
odiff_run(
  img1,
  img2,
  diff_output = NULL,
  threshold = 0.1,
  antialiasing = FALSE,
  fail_on_layout = FALSE,
  diff_mask = FALSE,
  diff_overlay = NULL,
  diff_color = NULL,
  diff_lines = FALSE,
  reduce_ram = FALSE,
  enable_asm = FALSE,
  ignore_regions = NULL,
  timeout = 60,
  diff_cols = FALSE
)
```

## Arguments

- img1:

  Character; path to the first (baseline) image file.

- img2:

  Character; path to the second (comparison) image file.

- diff_output:

  Character or `NULL`; optional path for the diff output image. odiff
  only writes PNG: a path with a different extension has it replaced by
  `.png`, and a path with no extension gets `.png` appended (both with a
  warning). If `NULL`, no diff image is created. No diff image is
  written when the images match.

- threshold:

  Numeric; colour difference threshold between 0.0 and 1.0. Lower values
  are more precise. Default is 0.1.

- antialiasing:

  Logical; if `TRUE`, ignore antialiased pixels. Default is `FALSE`.

- fail_on_layout:

  Logical; if `TRUE`, fail immediately if images have different
  dimensions. Default is `FALSE`.

- diff_mask:

  Logical; if `TRUE`, output only the changed pixels in the diff image.
  Default is `FALSE`.

- diff_overlay:

  Logical or numeric; if `TRUE` or a number between 0 and 1, add a white
  shaded overlay to the diff image for easier reading. Default is `NULL`
  (no overlay).

- diff_color:

  Character; hex color for highlighting differences, in the form
  `"#RRGGBB"` or `"RRGGBB"` (e.g., `"#FF0000"`). Default is `NULL` (uses
  odiff default, red).

- diff_lines:

  Logical; if `TRUE`, include line numbers containing different pixels
  in the output. Default is `FALSE`.

- reduce_ram:

  Logical; if `TRUE`, use less memory but run slower. Useful for very
  large images. Default is `FALSE`.

- enable_asm:

  Logical; if `TRUE`, pass `--enable-asm` to the underlying `odiff`
  binary to enable assembly-optimised code paths (e.g. AVX-512) on
  supported CPUs. Requires odiff \>= 4.1.1. Default is `FALSE`.

- ignore_regions:

  A list of regions to ignore during comparison. Each region should be a
  list with `x1`, `y1`, `x2`, `y2` components, or use
  [`ignore_region()`](https://benwolst.github.io/odiffr/reference/ignore_region.md)
  to create them. Can also be a data.frame with these columns.

- timeout:

  Numeric; timeout in seconds for the odiff process. Default is 60.
  Positive values below one second are rounded up to one second (the
  resolution of [`system2()`](https://rdrr.io/r/base/system2.html)); `0`
  or `Inf` means no timeout. If the timeout is reached, the result has
  `reason = "error"` and an `error` message.

- diff_cols:

  Logical; if `TRUE`, include column numbers containing different pixels
  in the output (`--output-diff-cols`). Requires odiff \>= 4.5.0;
  ignored with a warning for older versions. Default is `FALSE`.

## Value

A list with the following components:

- match:

  Logical; `TRUE` if images match, `FALSE` otherwise.

- reason:

  Character; one of `"match"`, `"pixel-diff"`, `"layout-diff"`, or
  `"error"`.

- diff_count:

  Integer; number of different pixels (`0` for a match), or `NA` if
  unknown (layout difference or error).

- diff_percentage:

  Numeric; percentage of different pixels (`0` for a match), or `NA` if
  unknown.

- diff_lines:

  Integer vector of line numbers with differences, or `NULL`.

- exit_code:

  Integer; odiff exit code (0 = match, 21 = layout diff, 22 = pixel
  diff, other values = error).

- stdout:

  Character; raw stdout output (odiff's parsable output).

- stderr:

  Character; raw stderr output.

- error:

  Character; `NA` if no error occurred, otherwise the error message
  reported by odiff (or by odiffr, e.g. on timeout).

- img1:

  Character; path to first image.

- img2:

  Character; path to second image.

- diff_output:

  Character or `NULL`; path to diff image if created.

- duration:

  Numeric; time elapsed in seconds.

- diff_cols:

  Integer vector of column numbers with differences, or `NULL`. Only
  present when `diff_cols = TRUE`.

- params:

  Named list of the effective comparison parameters (after version
  guards): `threshold`, `antialiasing`, `fail_on_layout`,
  `ignore_regions` (formatted as `"x1:y1-x2:y2,..."`, or `NA`),
  `diff_mask`, `diff_overlay` (`NA` if unset), `diff_color` (`NA` if
  unset), `reduce_ram` and `enable_asm`. Used by
  [`audit_record()`](https://benwolst.github.io/odiffr/reference/audit_record.md).

## Details

The `enable_asm` option is an advanced, platform-specific optimisation
flag. For odiff \< 4.1.1, odiffr ignores `enable_asm` with a warning.
Behaviour on unsupported CPUs is determined by odiff itself.

odiff is always invoked with `--parsable-stdout`, and its
machine-readable output is parsed to fill `diff_count`,
`diff_percentage`, `diff_lines` and `diff_cols`.

## See also

[`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md)
for a higher-level interface,
[`ignore_region()`](https://benwolst.github.io/odiffr/reference/ignore_region.md)
for creating ignore regions.

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic comparison
result <- odiff_run("baseline.png", "current.png")
result$match

# With diff output
result <- odiff_run("baseline.png", "current.png", "diff.png")

# With threshold and antialiasing
result <- odiff_run("baseline.png", "current.png",
                    threshold = 0.05, antialiasing = TRUE)

# Ignoring specific regions
result <- odiff_run("baseline.png", "current.png",
                    ignore_regions = list(
                      ignore_region(10, 10, 100, 50),
                      ignore_region(200, 200, 300, 300)
                    ))
} # }
```
