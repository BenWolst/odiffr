# Get odiff Version

The version is cached per binary: repeated calls do not spawn
`odiff --version` again unless the binary path (or the file itself)
changes.

## Usage

``` r
odiff_version()
```

## Value

Character string with the odiff version, or `NA_character_` if
unavailable.

## Examples

``` r
if (FALSE) { # \dontrun{
odiff_version()
} # }
```
