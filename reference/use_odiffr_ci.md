# Add a GitHub Actions Workflow for Visual Tests

Writes a ready-to-use GitHub Actions workflow that runs your package's
testthat tests, including image snapshot tests, with odiff. The workflow
installs odiff with
[`install_odiff()`](https://benwolst.github.io/odiffr/reference/install_odiff.md)
(no Node.js needed), adds a
[`snapshot_report()`](https://benwolst.github.io/odiffr/reference/snapshot_report.md)
summary of changed image snapshots to the job summary and, when tests
fail, uploads the new snapshots (`*.new.png`) and diff images
(`tests/testthat/_odiffr/`) as an artifact.

## Usage

``` r
use_odiffr_ci(
  path = ".github/workflows/odiffr.yaml",
  overwrite = FALSE,
  open = FALSE
)
```

## Arguments

- path:

  Path of the workflow file, relative to the working directory (which
  should be the root of your package). Default:
  `".github/workflows/odiffr.yaml"`. Parent directories are created as
  needed.

- overwrite:

  Logical; if `TRUE`, replace an existing file at `path`. Default is
  `FALSE`, in which case an existing file is an error.

- open:

  Logical; if `TRUE` and the session is interactive, open the new file
  with [`utils::file.edit()`](https://rdrr.io/r/utils/file.edit.html).
  Default is `FALSE`.

## Value

The path of the written file (invisibly).

## Details

The workflow is written only when you call this function; odiffr never
writes it by itself. It runs on every push and pull request on
`ubuntu-latest`, so record image snapshots on Linux or use a tolerant
preset (see
[`odiff_preset()`](https://benwolst.github.io/odiffr/reference/odiff_preset.md)).
The template is installed with odiffr, see
`system.file("templates", "odiffr-ci.yaml", package = "odiffr")`; edit
the written file as needed.

The tests run with `NOT_CRAN=true`, as snapshot tests are skipped on
CRAN.

## See also

[`install_odiff()`](https://benwolst.github.io/odiffr/reference/install_odiff.md),
[`snapshot_report()`](https://benwolst.github.io/odiffr/reference/snapshot_report.md),
[`expect_snapshot_image()`](https://benwolst.github.io/odiffr/reference/expect_snapshot_image.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# From the root of your package
use_odiffr_ci()
} # }

# In a temporary directory
dir <- tempfile()
dir.create(dir)
path <- use_odiffr_ci(file.path(dir, ".github", "workflows", "odiffr.yaml"))
#> Wrote GitHub Actions workflow: /tmp/RtmpIaIBy0/file1cd16449a903/.github/workflows/odiffr.yaml
#> Next steps:
#>   - Commit it and push to GitHub to run your tests with odiff.
#>   - Commit your image snapshots (tests/testthat/_snaps/), recorded on Linux or with a tolerant preset.
#>   - Changed snapshots are listed in the job summary and uploaded as the 'image-snapshots' artifact.
unlink(dir, recursive = TRUE)
```
