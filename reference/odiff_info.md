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

## Examples

``` r
if (FALSE) { # \dontrun{
odiff_info()
} # }
```
