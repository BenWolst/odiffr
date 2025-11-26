# CRAN Submission Comments

## R CMD check results

0 errors | 0 warnings | 1 note

### Note: SystemRequirements

This package requires the odiff binary to be installed on the user's system.
odiff is a pixel-by-pixel image comparison tool written in OCaml.

Installation instructions for users:
- npm (cross-platform): `npm install -g odiff-bin`
- Manual: Download from https://github.com/dmtrKovalenko/odiff/releases

The package also provides `odiffr_update()` as a fallback to download the binary
to the user cache directory.

This follows the pattern of similar packages (e.g., pdftools, tesseract, magick)
that require system libraries.

## Test environments

* Local: macOS ARM64, R 4.5.1
* GitHub Actions: macOS (latest), Windows (latest), Ubuntu (devel, release, oldrel-1)

## Downstream dependencies

This is a new package with no reverse dependencies.
