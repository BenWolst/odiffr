# Image-level tolerance: design

Date: 2026-10-07
Status: draft for review

## Problem

odiffr decides pass/fail purely on whether odiff found any differing pixels
(after `threshold`, `antialiasing` and `ignore_regions`). There is no way to
accept an image whose differences are small overall.

A downstream validation package (openval.snapshot) needs this. Its baselines
are recorded in validated Docker images (Ubuntu, Rocky) and checked on
customer hosts whose fonts and libraries differ. Customers cannot record their
own baselines, so per-platform `variant` snapshots do not help. Today it wraps
`compare_images()` in its own compare function and applies a percentage
tolerance itself, so it cannot use `expect_snapshot_image()` or
`compare_pdfs()`.

Their calibration (640 cross-platform pairs, 2100x2100 plots, threshold 0.1):

| | % of pixels differing |
|---|---|
| Median | 0.002% |
| 95th percentile | 2.78% |
| Worst | 18.65% |

The noise is glyph shape and position, not colour: `preset = "cross_platform"`
(threshold 0.2) leaves it almost unchanged and hides a real colour regression
(437 px to 0 px). Real regressions on a 700x500 plot are small: a dropped point
is 16 px (0.0046%), an axis label edit about 0.1%, `theme_bw()` 0.42%. Any
tolerance that absorbs the noise also hides these, so they use it only in a
separate "cross-environment" mode and require an exact match otherwise.

## Goals

- An opt-in, image-level tolerance as a percentage of pixels (primary) and as
  a pixel count (secondary).
- Available to the testthat helpers and to the batch, directory and PDF
  functions, with consistent verdicts across all of them.
- Every result still says what actually happened, and records (including
  audit records) show which passes relied on a tolerance.
- A change in image size always fails, whatever the tolerance.

## Non-goals

- Tolerance in `odiff_preset()` presets. Adding it to `cross_platform` would
  silently loosen existing tests.
- A global option (e.g. `odiffr.max_diff_percent`). A setting that changes
  verdicts at a distance is risky in validated settings. It can be added later
  without breaking anything, and is the most likely follow-up request.
- Any change to `odiff_run()`, which stays a factual low-level wrapper.
- Smarter noise handling (e.g. masking text). Out of scope.

## Design

### Where it applies

Tolerance is a verdict, not a measurement, so it is applied in
`compare_images()`, after `odiff_run()`. Everything built on `compare_images()`
inherits it:

- Named, documented arguments on `compare_images()`, `expect_images_match()`,
  `compare_file_odiff()` and `expect_snapshot_image()`. In the two snapshot
  helpers they come after `...` (like `preset` and `diff_dir`), so they must
  be named and existing positional arguments keep their meaning.
- Through `...` (documented in their `...` descriptions):
  `compare_images_batch()`, `compare_image_dirs()`, `compare_pdfs()`,
  `compare_pdf_dirs()`, `snapshot_report()`.
- `expect_images_differ()` also accepts them through `...`, meaning "differs by
  more than the tolerance". No named argument.

### Arguments

- `max_diff_percent`: `NULL` (default, off) or a single number in `[0, 100]`,
  on the same scale as `diff_percentage`.
- `max_diff_pixels`: `NULL` (default, off) or a single non-negative whole
  number.

Each is a ceiling, inclusive (`<=`). If both are given, both must hold.
Invalid values error up front, like `threshold`.

### The rule

A comparison is tolerated when all of these hold:

1. at least one of `max_diff_percent`, `max_diff_pixels` is set;
2. `reason == "pixel-diff"` and `diff_count` is not `NA`;
3. both images' dimensions are known and equal;
4. `diff_count <= max_diff_pixels` (if set) and
   `diff_percentage <= max_diff_percent` (if set).

Rule 3 makes a size change always fail. It is needed because with
`fail_on_layout = FALSE` and odiff >= 4.3.5 a size change is reported as a
`pixel-diff` with a count: 1000x1000 to 1000x1010 is only 0.99%. Dimensions are
read with `.image_dimensions()` (a 24-byte header read for PNG). If they cannot
be read, the comparison is not tolerated (fail safe). Layout differences,
errors and missing images are never tolerated.

### How a tolerated comparison is recorded

- `match = TRUE`
- `reason = "within-tolerance"` (new value)
- `diff_count`, `diff_percentage` and `diff_output` unchanged

A new reason, rather than `match = TRUE` with `reason = "pixel-diff"`, keeps the
invariant that `reason` explains `match`, and stops code that selects rows by
`reason` (notably `approve_changes()`) from acting on passes. A separate
`tolerated` column was considered and rejected: it adds a column to every batch,
report and audit output for the same information.

`"within-tolerance"` only ever appears when a tolerance is set, so existing
behaviour does not change.

### Consumers

| Consumer | Change |
|---|---|
| `expect_images_match()` | Passes. Removes the diff image it wrote to `_odiffr/` (a passing expectation leaves no artefacts). |
| `compare_file_odiff()` / `expect_snapshot_image()` | Returns `TRUE`, so testthat keeps the original baseline and writes no `.new.png`. The diff image is removed, as for a match. Baselines never move within tolerance, so differences cannot accumulate. |
| `summary()` / `print()` | Tolerated rows count as passed. New `tolerated` count; the print shows "Within tolerance: n" when n > 0. |
| `batch_report()`, `batch_junit()`, `batch_markdown()` | Tolerated rows are passes. The HTML "all results" table shows the reason. The Markdown summary line notes "n within tolerance" when n > 0. |
| `approve_changes()` | Not selected by default; reported as skipped by the existing `reasons` filter (detail "reason 'within-tolerance' not in `reasons`"). Can be approved with `which` or by adding it to `reasons`. |
| `audit_record()` | The `reason` column shows `within-tolerance`. `max_diff_percent` and `max_diff_pixels` are added to the standard parameter names, so CSV output always has a column for them (`NA` when unset). |
| `failed_pairs()` / `passed_pairs()` | Unchanged (by `match`). Tolerated rows are passed pairs. |

### Implementation outline

- One internal function, `.apply_tolerance(result, max_diff_percent,
  max_diff_pixels)`, taking an `odiff_run()` result (whose `img1`/`img2`
  give the image paths) and returning it with `match`/`reason` updated. It is pure apart from
  `.image_dimensions()`, so it is unit-testable with hand-built results.
- Argument validation in `utils.R` alongside `.validate_threshold()`.
- `compare_images()` calls `.validate_*()` and `.apply_tolerance()`; the
  helpers pass the arguments through.
- Docs: `reason` lists in `compare_images()` and the batch functions, a
  "Tolerance" section in `compare_images()` that states the trade-off (a
  tolerance that absorbs cross-platform font noise also hides small real
  regressions) and recommends using it only for cross-environment runs.
- NEWS entry under New features.

## Testing

- `.apply_tolerance()` unit tests: each rule, inclusive ceilings, both limits,
  `NULL` limits, `NA` count, unknown dimensions, different dimensions, and each
  non-pixel-diff reason untouched.
- Validation errors for bad values.
- Real-binary tests: a 1000x1000 image with one changed pixel passes with
  `max_diff_pixels = 1` or `max_diff_percent = 1e-4` and fails with 0; a size
  change with `fail_on_layout = FALSE` fails with a 100% tolerance.
- Snapshot: within tolerance passes, keeps the baseline, leaves no `.new.png`
  and no diff image; beyond tolerance fails as before.
- `expect_images_match()` passes and leaves no diff image.
- Batch/PDF: tolerance flows through `...`; summary count and print line;
  report, JUnit and Markdown show passes; `approve_changes()` skips by default
  and approves with `which`; audit CSV has the new columns.
- The full suite on odiff 4.2.1 and 4.5.0; `R CMD check --as-cran`.

## Follow-ups (separate)

- The `cross_platform` preset docs claim it suits cross-platform noise. The
  calibration shows it barely helps with font noise and costs colour
  sensitivity. The docs should say so.
- A global tolerance option, if requested.
