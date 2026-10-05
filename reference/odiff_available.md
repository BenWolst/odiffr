# Check if odiff is Available

A silent check: unlike
[`find_odiff()`](https://benwolst.github.io/odiffr/reference/find_odiff.md),
it never offers to install odiff, so it is safe to use in skip
conditions and scripts.

## Usage

``` r
odiff_available()
```

## Value

Logical `TRUE` if odiff is found and executable, `FALSE` otherwise.

## Examples

``` r
odiff_available()
#> [1] TRUE
```
