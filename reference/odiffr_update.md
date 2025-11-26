# Download Latest odiff Binary

Downloads the odiff binary from GitHub releases to the user's cache
directory. The downloaded binary will be used by
[`find_odiff()`](https://benwolst.github.io/odiffr/reference/find_odiff.md)
if no system-wide installation or user-specified path is found.

## Usage

``` r
odiffr_update(version = "latest", force = FALSE)
```

## Arguments

- version:

  Character string specifying the version to download. Use `"latest"`
  (default) to download the most recent release, or specify a version
  tag like `"v4.1.2"`.

- force:

  Logical; if `TRUE`, re-download even if the binary already exists in
  the cache. Default is `FALSE`.

## Value

Character string with the path to the downloaded binary.

## Examples

``` r
if (FALSE) { # \dontrun{
# Download latest version
odiffr_update()

# Download specific version
odiffr_update(version = "v4.1.2")

# Force re-download
odiffr_update(force = TRUE)
} # }
```
