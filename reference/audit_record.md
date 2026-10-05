# Create an Audit Record of Image Comparisons

Builds a machine-readable evidence record of one or more image
comparisons: which files were compared (with cryptographic hashes and
sizes), the outcome of each comparison, the parameters used, and the
software environment (odiffr and odiff versions, the odiff binary and
its hash, R version, platform and user). The record can be written to a
JSON or CSV file and kept alongside validation documentation. This
supports audit trails in validated environments; it does not by itself
make a process compliant with any regulation.

## Usage

``` r
audit_record(
  x,
  file = NULL,
  format = c("json", "csv"),
  hash = c("sha256", "md5"),
  params = NULL
)
```

## Arguments

- x:

  The comparison result(s) to record: an `odiff_result` from
  [`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md),
  a data.frame/tibble from
  [`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md),
  or an `odiffr_batch` from
  [`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md)
  or
  [`compare_image_dirs()`](https://benwolst.github.io/odiffr/reference/compare_image_dirs.md).

- file:

  Path of the file to write, or `NULL` (default) to only return the
  record.

- format:

  Output file format, `"json"` (default) or `"csv"`. Only used when
  `file` is given. JSON requires the jsonlite package.

- hash:

  Hash algorithm for files: `"sha256"` (default) or `"md5"`. SHA-256
  requires the openssl or digest package; MD5 uses base R
  ([`tools::md5sum()`](https://rdrr.io/r/tools/md5sum.html)).

- params:

  Optional named list of the comparison parameters (e.g.
  `list(threshold = 0.1, antialiasing = TRUE)`). Results of
  [`odiff_run()`](https://benwolst.github.io/odiffr/reference/odiff_run.md)
  carry their parameters, which are used when `params` is `NULL`.
  [`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md)
  and batch results do not, so pass the parameters used here to record
  them; otherwise they are recorded as unknown (`null` in JSON, `NA` in
  CSV).

## Value

The record, a list with elements `header` and `comparisons` (see
Details). If `file` is given, the record is written to it and the
normalised file path is returned invisibly instead.

## Details

**Record structure.** The returned list has two elements:

`header`, a named list:

- schema:

  Character; schema identifier, currently `"odiffr-audit/1"`.

- created:

  Character; creation time in UTC, ISO 8601 (`"YYYY-MM-DDTHH:MM:SSZ"`).

- odiffr_version:

  Character; version of the odiffr package.

- odiff_version:

  Character; version of the odiff binary, or `NA`.

- odiff_path:

  Character; path of the odiff binary that
  [`find_odiff()`](https://benwolst.github.io/odiffr/reference/find_odiff.md)
  currently selects, or `NA`.

- odiff_hash:

  Character; hash of that binary, or `NA`.

- hash_algorithm:

  Character; `"sha256"` or `"md5"`.

- r_version:

  Character; R version, e.g. `"4.4.1"`.

- platform:

  Character; `R.version$platform`.

- sysname, release, machine:

  Character; from [`Sys.info()`](https://rdrr.io/r/base/Sys.info.html).

- user:

  Character; `Sys.info()[["user"]]`.

- n_comparisons:

  Integer; number of comparisons recorded.

- params:

  Named list of comparison parameters, or `NULL` if unknown.

`comparisons`, a data.frame with one row per comparison and columns:

- pair_id:

  Integer; the batch `pair_id`, or the row number.

- img1, img2:

  Character; image paths as recorded in the result.

- img1_hash, img2_hash:

  Character; file hashes, `NA` if the file does not exist (e.g.
  `"missing"` rows) or is not a file (e.g. `"<magick-image>"`).

- img1_size, img2_size:

  Numeric; file sizes in bytes, or `NA`.

- diff_output:

  Character; diff image path, or `NA`.

- diff_output_hash:

  Character; hash of the diff image, or `NA`.

- diff_output_size:

  Numeric; size of the diff image, or `NA`.

- match:

  Logical; whether the images matched.

- reason:

  Character; `"match"`, `"pixel-diff"`, `"layout-diff"`, `"error"` or
  `"missing"`.

- diff_count:

  Integer; number of different pixels, or `NA`.

- diff_percentage:

  Numeric; percentage of different pixels, or `NA`.

- error:

  Character; error message, or `NA`.

Files are hashed when `audit_record()` is called, so call it right after
the comparison, before any of the files can change.

**JSON** files contain an object with `header` and `comparisons` (an
array of row objects); missing values are written as `null`.

**CSV** files contain one row per comparison with the `comparisons`
columns, preceded by the header fields repeated on every row (except
`params`) and followed by one `param_<name>` column per parameter. The
standard parameters (`threshold`, `antialiasing`, `fail_on_layout`,
`ignore_regions`, `diff_mask`, `diff_overlay`, `diff_color`,
`reduce_ram`, `enable_asm`) always have a column (`NA` when unknown);
other parameters passed in `params` are added after them.

## See also

[`odiff_info()`](https://benwolst.github.io/odiffr/reference/odiff_info.md),
[`odiff_version()`](https://benwolst.github.io/odiffr/reference/odiff_version.md)

## Examples

``` r
if (FALSE) { # \dontrun{
result <- odiff_run("baseline.png", "current.png", "diff.png",
                    threshold = 0.05)
rec <- audit_record(result)
rec$header$odiff_version
rec$comparisons$img1_hash

# Write a JSON evidence file
audit_record(result, file = "comparison-audit.json")

# Batch results: pass the parameters used, write CSV
results <- compare_image_dirs("baseline/", "current/", threshold = 0.05)
audit_record(results, file = "audit.csv", format = "csv",
             params = list(threshold = 0.05))
} # }
```
