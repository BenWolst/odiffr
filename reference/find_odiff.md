# Find the odiff Binary

Locates the odiff executable using a priority-based search:

1.  User-specified path via `options(odiffr.path = "...")`

2.  System PATH (`Sys.which("odiff")`)

3.  Cached binary from
    [`odiffr_update()`](https://benwolst.github.io/odiffr/reference/odiffr_update.md)

## Usage

``` r
find_odiff()
```

## Value

Character string with the absolute path to the odiff executable.

## Examples

``` r
if (FALSE) { # \dontrun{
find_odiff()
} # }
```
