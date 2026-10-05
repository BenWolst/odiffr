# Find the odiff Binary

Locates the odiff executable using a priority-based search:

1.  User-specified path via `options(odiffr.path = "...")`

2.  System PATH (`Sys.which("odiff")`)

3.  Cached binary from
    [`install_odiff()`](https://benwolst.github.io/odiffr/reference/install_odiff.md)
    (or
    [`odiffr_update()`](https://benwolst.github.io/odiffr/reference/odiffr_update.md))

## Usage

``` r
find_odiff()
```

## Value

Character string with the absolute path to the odiff executable.

## Details

**Installing odiff.** If odiff cannot be found and the R session is
interactive, `find_odiff()` (and so
[`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md),
[`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md)
and the other functions that need the binary) offers once per session to
download the latest odiff release to the user cache with
[`install_odiff()`](https://benwolst.github.io/odiffr/reference/install_odiff.md).
Nothing is ever downloaded without asking: the offer is never made in
non-interactive sessions, while running tests with testthat, while
knitting, or during `R CMD check`. Set
`options(odiffr.ask_install = FALSE)` to turn the offer off. If the
offer is declined, `find_odiff()` signals an error explaining how to
install odiff.
[`odiff_available()`](https://benwolst.github.io/odiffr/reference/odiff_available.md)
never makes the offer.

**npm installs.** Since odiff 4.4, `npm install -g odiff-bin` puts a
small Node.js launcher script on the PATH, which starts Node and then
spawns the native binary shipped in an `@odiff/<platform>-<arch>`
package. Starting Node adds tens of milliseconds to every comparison, so
when the odiff found on the PATH is such a launcher (a `#!` script that
runs `node`, or an npm `.cmd`/`.ps1` wrapper on Windows), `find_odiff()`
looks for the native binary inside the npm installation and returns it
instead. For older `odiff-bin` releases, the native `bin/odiff.exe`
inside the package is used. If no native binary can be found, the
launcher itself is returned, so a working setup is never broken. The
lookup is cached per launcher path and redone when the launcher file
changes.

Set `options(odiffr.resolve_npm = FALSE)` to disable this and always use
the PATH entry as-is. A path given via `options(odiffr.path = ...)` is
always used exactly as specified and is never resolved.

## See also

[`odiff_info()`](https://benwolst.github.io/odiffr/reference/odiff_info.md)
to see which binary is used and whether it was resolved from an npm
launcher.

## Examples

``` r
if (FALSE) { # \dontrun{
find_odiff()

# Use the npm launcher on the PATH as-is
options(odiffr.resolve_npm = FALSE)
find_odiff()
} # }
```
