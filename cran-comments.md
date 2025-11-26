# CRAN Submission Comments

## R CMD check results

0 errors | 0 warnings | 0 notes

## SystemRequirements: odiff

This package requires the odiff binary for image comparison functionality.
odiff is a pixel-by-pixel image comparison tool written in OCaml.

**Important for CRAN checks:**
- The package never downloads anything automatically during R CMD check
- All tests skip gracefully when odiff is not available
- Vignettes build without odiff (examples use `eval = odiff_available()`)

Installation instructions for users:
- npm (cross-platform): `npm install -g odiff-bin`
- Manual: Download from https://github.com/dmtrKovalenko/odiff/releases
- From R: `odiffr::odiffr_update()` downloads to user cache directory

This follows the pattern of packages like pdftools, tesseract, and magick
that wrap external binaries.

## Test environments

* Local: macOS ARM64, R 4.5.1
* GitHub Actions: macOS (latest), Windows (latest), Ubuntu (devel, release, oldrel-1)
* win-builder: R-devel (pending)

## Downstream dependencies

This is a new package with no reverse dependencies.
