# Compare PDF Files in Two Directories

Compare every PDF file in a baseline directory with the PDF file of the
same relative path in a current directory, page by page, using
[`compare_pdfs()`](https://benwolst.github.io/odiffr/reference/compare_pdfs.md).
Useful for re-running a full set of outputs (for example all tables,
listings and figures of a study) after an R or package upgrade and
checking that nothing changed visually.

## Usage

``` r
compare_pdf_dirs(
  baseline_dir,
  current_dir,
  pattern = "\\.pdf$",
  recursive = FALSE,
  pages = NULL,
  dpi = 150,
  diff_dir = NULL,
  parallel = FALSE,
  ...
)
```

## Arguments

- baseline_dir:

  Path to the directory containing the baseline PDFs.

- current_dir:

  Path to the directory containing the current PDFs.

- pattern:

  Regular expression matched (case-insensitively) against file names.
  Default matches `.pdf` files.

- recursive:

  Logical; if `TRUE`, search subdirectories recursively. Default is
  `FALSE`.

- pages, dpi:

  Passed to
  [`compare_pdfs()`](https://benwolst.github.io/odiffr/reference/compare_pdfs.md)
  for every file.

- diff_dir:

  Directory to save diff images and rendered pages. Each PDF gets its
  own subdirectory, named after its relative path. If `NULL` (default),
  no diff images are created.

- parallel:

  Logical; if `TRUE`, compare the pages of each file in parallel. See
  [`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md)
  for details.

- ...:

  Additional arguments passed to
  [`compare_pdfs()`](https://benwolst.github.io/odiffr/reference/compare_pdfs.md)
  (e.g. `threshold`, `antialiasing`, `ignore_regions`,
  `fail_on_layout`).

## Value

A tibble (if available) or data.frame with class `odiffr_batch`,
combining the results for all files (in baseline file order) with a
sequential `pair_id`, the columns of
[`compare_pdfs()`](https://benwolst.github.io/odiffr/reference/compare_pdfs.md)
(including `page`) and a trailing `file` column giving the relative path
of the PDF.

## Details

The baseline directory is the source of truth, as in
[`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md):

- A PDF missing from `current_dir` triggers a warning and is reported as
  a single row with `match = FALSE`, `reason = "missing"`, `page = NA`
  and the error `"File not found in current_dir"`.

- A PDF that cannot be read (e.g. corrupt or password-protected) is
  reported as a single row with `reason = "error"`, `page = NA` and the
  error message, instead of aborting the whole comparison.

- PDFs that exist only in `current_dir` are not compared, but a message
  notes how many were found.

Differences in page counts are reported per file as described in
[`compare_pdfs()`](https://benwolst.github.io/odiffr/reference/compare_pdfs.md).

An error is raised if `baseline_dir` contains no files matching
`pattern`.

## See also

[`compare_pdfs()`](https://benwolst.github.io/odiffr/reference/compare_pdfs.md),
[`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md),
[`batch_report()`](https://benwolst.github.io/odiffr/reference/batch_report.md)

## Examples

``` r
if (FALSE) { # \dontrun{
res <- compare_pdf_dirs("outputs-r4.3/", "outputs-r4.4/",
                        diff_dir = "pdf-diffs", recursive = TRUE)
summary(res)
unique(res$file[!res$match])
batch_report(res, output_file = "pdf-diffs/report.html")
} # }
```
