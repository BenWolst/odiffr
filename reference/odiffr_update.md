# Download Latest odiff Binary

Downloads the odiff binary from GitHub releases to the user's cache
directory. The downloaded binary will be used by
[`find_odiff()`](https://benwolst.github.io/odiffr/reference/find_odiff.md)
if no system-wide installation or user-specified path is found.
[`install_odiff()`](https://benwolst.github.io/odiffr/reference/install_odiff.md)
is the recommended, user-facing way to do this.

## Usage

``` r
odiffr_update(version = "latest", force = FALSE)
```

## Arguments

- version:

  Character string specifying the version to download. Use `"latest"`
  (default) to download the most recent release, or specify a version
  like `"v4.1.2"` or `"4.1.2"` (the `v` prefix is optional).

- force:

  Logical; if `TRUE`, re-download even if the binary already exists in
  the cache. Default is `FALSE`.

## Value

Character string with the path to the downloaded binary.

## Details

The latest release is looked up via the GitHub API. If the `GITHUB_PAT`
or `GITHUB_TOKEN` environment variable is set, it is sent as a bearer
token to avoid API rate limits.

The binary is downloaded to a temporary file next to its final location
and only moved into place once the download has succeeded, so an
interrupted download never leaves a broken binary behind. The download
timeout (`getOption("timeout")`) is temporarily raised to at least 300
seconds. The downloaded version is recorded in a `CACHED_VERSION` file
next to the binary.

Note that some odiff releases were published without binary assets; if
the download fails with HTTP 404, try another version.

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
