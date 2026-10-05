# Compare Two PDF Files Page by Page

Render each page of two PDF files to PNG and compare them page by page
with odiff. This is useful for checking that rendered documents (for
example clinical tables, listings and figures, or Quarto/R Markdown
documents rendered to PDF) still look the same after a code, package or
R upgrade.

## Usage

``` r
compare_pdfs(
  baseline,
  current,
  pages = NULL,
  dpi = 150,
  diff_dir = NULL,
  threshold = 0.1,
  antialiasing = FALSE,
  ignore_regions = NULL,
  parallel = FALSE,
  ...
)
```

## Arguments

- baseline:

  Path to the baseline (reference) PDF file.

- current:

  Path to the current PDF file to compare against `baseline`.

- pages:

  Integer vector of page numbers to compare, or `NULL` (default) to
  compare all pages of both files (the union of their page ranges).
  Pages that do not exist in either file raise an error.

- dpi:

  Resolution, in dots per inch, used to render the pages. Default
  is 150. Higher values detect smaller differences but take longer and
  produce larger images.

- diff_dir:

  Directory to save diff images. If `NULL` (default), no diff images are
  created. When given, the rendered pages are also kept under
  `file.path(diff_dir, "pages")` (in `baseline/` and `current/`
  subdirectories).

- threshold:

  Numeric; colour difference threshold between 0.0 and 1.0. Default is
  0.1.

- antialiasing:

  Logical; if `TRUE`, ignore antialiased pixels. Default is `FALSE`.

- ignore_regions:

  Regions to ignore on every compared page, as accepted by
  [`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md)
  (see
  [`ignore_region()`](https://benwolst.github.io/odiffr/reference/ignore_region.md)).
  Coordinates are in pixels of the rendered page, so they depend on
  `dpi`: a point at `x` inches from the left edge is at pixel `x * dpi`.

- parallel:

  Logical; if `TRUE`, compare pages in parallel. See
  [`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md)
  for details.

- ...:

  Additional arguments passed to
  [`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md)
  via
  [`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md),
  e.g. `fail_on_layout = TRUE`.

## Value

A tibble (if available) or data.frame with class `odiffr_batch`, with
one row per compared page, containing the same columns as
[`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md)
(including `error`) plus a trailing integer `page` column. `img1` and
`img2` are the paths of the rendered page images. The result can be
passed to [`summary()`](https://rdrr.io/r/base/summary.html),
[`batch_report()`](https://benwolst.github.io/odiffr/reference/batch_report.md)
and the other functions that accept an `odiffr_batch`.

## Details

Requires the pdftools package (and therefore the poppler library) for
rendering. Only PDF input is supported: convert RTF or DOCX outputs to
PDF first, for example with LibreOffice
(`soffice --headless --convert-to pdf file.rtf`).

Pages are rendered with
[`pdftools::pdf_convert()`](https://docs.ropensci.org/pdftools//reference/pdf_render_page.html)
to files named `<pdf name>_p001.png`, `<pdf name>_p002.png`, ... in
separate `baseline/` and `current/` directories. If `diff_dir` is
`NULL`, they are written to a new directory inside
[`tempdir()`](https://rdrr.io/r/base/tempfile.html), which persists
until the R session ends, so that reports showing the rendered pages can
still be created after `compare_pdfs()` returns.

When the two files have a different number of pages, a message is
emitted and the pages present in only one file are reported using the
existing reasons, so that summaries and reports work unchanged:

- A page present in `baseline` but not in `current` is reported with
  `match = FALSE`, `reason = "missing"` and the error
  `"Page N not present in current PDF"` (like a file missing from the
  current directory in
  [`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md)).

- A page present in `current` but not in `baseline` is reported with
  `match = FALSE`, `reason = "error"` and the error
  `"Page N not present in baseline PDF"`.

In both cases `img1`/`img2` point to the rendered page that exists and
to the (nonexistent) path the other page would have had.

Pages with different sizes (e.g. portrait versus landscape) are compared
as images of different dimensions; by default odiff reports the
differing pixels, and with `fail_on_layout = TRUE` such pages are
reported with `reason = "layout-diff"`.

An error is raised if a file does not exist or cannot be read as a PDF
(for example a corrupt or password-protected file).

## See also

[`compare_pdf_dirs()`](https://benwolst.github.io/odiffr/reference/compare_pdf_dirs.md)
for comparing directories of PDF files,
[`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md),
[`batch_report()`](https://benwolst.github.io/odiffr/reference/batch_report.md).

## Examples

``` r
if (FALSE) { # \dontrun{
res <- compare_pdfs("qc/t_demog.pdf", "prod/t_demog.pdf",
                    diff_dir = "pdf-diffs")
summary(res)
res[!res$match, c("page", "reason", "diff_percentage")]

# Only the first two pages, at a higher resolution
compare_pdfs("old.pdf", "new.pdf", pages = 1:2, dpi = 300)

# Ignore a run-date footer: bottom 0.5 inch of a US Letter page at 150 dpi
compare_pdfs("old.pdf", "new.pdf", dpi = 150,
             ignore_regions = ignore_region(0, 1575, 1275, 1650))
} # }
```
