# Display odiff Configuration Information

Display odiff Configuration Information

## Usage

``` r
odiff_info()
```

## Value

A list with components:

- os:

  Operating system (darwin, linux, windows)

- arch:

  Architecture (arm64, x64)

- path:

  Path to the odiff binary

- version:

  odiff version string

- source:

  Source of the binary (option, system, cached)

- shim:

  Path of the npm launcher script found on the PATH that `path` was
  resolved from, or `NA` if the binary is used directly. See
  [`find_odiff()`](https://benwolst.github.io/odiffr/reference/find_odiff.md).

## Examples

``` r
if (FALSE) { # \dontrun{
odiff_info()
} # }
```
