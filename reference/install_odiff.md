# Install odiff

Downloads the odiff binary for your platform from the odiff GitHub
releases to the odiffr user cache
([`odiffr_cache_path()`](https://benwolst.github.io/odiffr/reference/odiffr_cache_path.md)),
where
[`find_odiff()`](https://benwolst.github.io/odiffr/reference/find_odiff.md)
finds it. This is the easiest way to install odiff: it needs neither
Node.js nor npm, nor administrator rights.

## Usage

``` r
install_odiff(version = "latest", force = FALSE)
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

The path to the installed binary (invisibly).

## Details

`install_odiff()` is a user-facing wrapper around
[`odiffr_update()`](https://benwolst.github.io/odiffr/reference/odiffr_update.md):
it downloads the binary (see
[`odiffr_update()`](https://benwolst.github.io/odiffr/reference/odiffr_update.md)
for details, e.g. on GitHub API rate limits), clears odiffr's cached
binary lookups so that
[`find_odiff()`](https://benwolst.github.io/odiffr/reference/find_odiff.md)
and
[`odiff_version()`](https://benwolst.github.io/odiffr/reference/odiff_version.md)
use the new binary straight away, and reports the installed version and
path.

The cached binary is used only when no binary is set via
`options(odiffr.path)` and no odiff is found on the PATH; a message says
so when another binary takes precedence.

odiffr never downloads anything on its own: the binary is only
downloaded when `install_odiff()` (or
[`odiffr_update()`](https://benwolst.github.io/odiffr/reference/odiffr_update.md))
is called, or when you accept the offer
[`find_odiff()`](https://benwolst.github.io/odiffr/reference/find_odiff.md)
makes in interactive sessions.

## See also

[`odiffr_update()`](https://benwolst.github.io/odiffr/reference/odiffr_update.md),
[`odiffr_clear_cache()`](https://benwolst.github.io/odiffr/reference/odiffr_clear_cache.md),
[`odiff_info()`](https://benwolst.github.io/odiffr/reference/odiff_info.md)

## Examples

``` r
if (FALSE) { # \dontrun{
install_odiff()

# A specific version
install_odiff(version = "4.5.0", force = TRUE)
} # }
```
