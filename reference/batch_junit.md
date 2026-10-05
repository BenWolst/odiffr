# Write Batch Comparison Results as JUnit XML

Converts batch image comparison results to a JUnit XML report, the
format understood by most CI systems (GitHub Actions test reporters,
GitLab, Jenkins, Azure Pipelines, ...). Each comparison becomes one test
case.

## Usage

``` r
batch_junit(
  object,
  output_file = NULL,
  suite_name = "odiffr",
  include_passed = TRUE
)
```

## Arguments

- object:

  An `odiffr_batch` object from
  [`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md)
  or
  [`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md).

- output_file:

  Path to write the XML file. If NULL (default), the XML is returned as
  a character string. The file is written as UTF-8 and its parent
  directory is created if it does not exist.

- suite_name:

  Name of the test suite, also used as the `classname` of every test
  case. Default: "odiffr".

- include_passed:

  If TRUE (default), passing comparisons are included as successful test
  cases. If FALSE, only failures and errors are written.

## Value

If `output_file` is NULL, the XML as a character string (invisibly);
otherwise the file path (invisibly).

## Details

The report contains a single `<testsuite>` (inside a `<testsuites>`
root) whose `tests`, `failures` and `errors` attributes count the test
cases written. Test cases are named after the current image file
(`img2`), or the baseline (`img1`) when `img2` is not a file (for
example `"<magick-image>"`), or `"pair N"` otherwise.

- Pixel and layout differences are reported as `<failure>` elements
  whose `type` is the comparison reason, e.g.
  `message="pixel-diff: 1.26% (126 pixels)" type="pixel-diff"`.

- Baseline images without a current counterpart are failures of type
  `"missing"`.

- Comparisons that could not be run (`reason == "error"`) are reported
  as `<error>` elements carrying the error message.

The failure body lists the baseline, current and diff image paths. Text
is XML-escaped and characters that are not allowed in XML 1.0 are
removed.

## See also

[`batch_markdown()`](https://benwolst.github.io/odiffr/reference/batch_markdown.md),
[`batch_report()`](https://benwolst.github.io/odiffr/reference/batch_report.md),
[`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md)

## Examples

``` r
if (FALSE) { # \dontrun{
results <- compare_image_dirs("baseline/", "current/", diff_dir = "diffs/")
batch_junit(results, "odiffr-junit.xml")
} # }
```
