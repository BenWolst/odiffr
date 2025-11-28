# Compare Images in Two Directories

Compare all images in a baseline directory against corresponding images
in a current directory. Files are matched by relative path (including
subdirectories when `recursive = TRUE`).

## Usage

``` r
compare_image_dirs(
  baseline_dir,
  current_dir,
  pattern = "\\.(png|jpe?g|webp|tiff?)$",
  recursive = FALSE,
  diff_dir = NULL,
  parallel = FALSE,
  ...
)
```

## Arguments

- baseline_dir:

  Path to the directory containing baseline images.

- current_dir:

  Path to the directory containing current images to compare against
  baseline.

- pattern:

  Regular expression pattern to match image files. Default matches
  common image formats (PNG, JPEG, WEBP, TIFF).

- recursive:

  Logical; if `TRUE`, search subdirectories recursively. Default is
  `FALSE`.

- diff_dir:

  Directory to save diff images. If `NULL`, no diff images are created.

- parallel:

  Logical; if `TRUE`, compare images in parallel. See
  [`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md)
  for details.

- ...:

  Additional arguments passed to
  [`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md).

## Value

A tibble (if available) or data.frame with one row per comparison,
containing all columns from
[`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md)
plus a `pair_id` column.

## Details

The baseline directory is the source of truth. For each image found in
`baseline_dir` matching `pattern`:

- If a corresponding file exists in `current_dir` (same relative path),
  it is included in the comparison.

- If the file is missing from `current_dir`, a warning is issued and the
  file is excluded from results.

Files that exist only in `current_dir` (not in `baseline_dir`) are not
compared, but a message is emitted noting how many such files were
found.

## See also

[`compare_images_batch()`](https://benwolst.github.io/odiffr/reference/compare_images_batch.md)
for comparing explicit pairs,
[`compare_images()`](https://benwolst.github.io/odiffr/reference/compare_images.md)
for single comparisons.

## Examples

``` r
if (FALSE) { # \dontrun{
# Compare all images in two directories
results <- compare_image_dirs("baseline/", "current/")

# Only compare PNG files
results <- compare_image_dirs("baseline/", "current/", pattern = "\\.png$")

# Include subdirectories and save diff images
results <- compare_image_dirs(
  "baseline/",
  "current/",
  recursive = TRUE,
  diff_dir = "diffs/"
)

# Check which comparisons failed
results[!results$match, ]
} # }
```
