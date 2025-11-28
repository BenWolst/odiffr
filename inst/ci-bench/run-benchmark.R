#!/usr/bin/env Rscript
# Visual Benchmark for odiffr CI
#
# Exit codes:
#   0 = success (all failures are expected)
#   1 = unexpected failures detected (regression)
#   2 = setup error (missing odiff, directories, etc.)
#
# Usage: Rscript inst/ci-bench/run-benchmark.R
#        (run from package root)

suppressPackageStartupMessages(library(odiffr))

# --- Section 1: Setup and Validation ---

message("=== odiffr Visual Benchmark ===")
message("")

# Check odiff availability
if (!odiff_available()) {
  message("ERROR: odiff binary not found")
  message("Install with: npm install -g odiff-bin")
  message("Or use: odiffr_update()")
  quit(status = 2L, save = "no")
}

message("odiff version: ", odiff_info()$version)
message("")

# Locate script directory
SCRIPT_DIR <- if (interactive()) {
  "inst/ci-bench"
} else {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    dirname(sub("--file=", "", file_arg))
  } else {
    "inst/ci-bench"
  }
}

baseline_dir <- file.path(SCRIPT_DIR, "baseline")
current_dir <- file.path(SCRIPT_DIR, "current")
diff_dir <- file.path(SCRIPT_DIR, "diffs")
expected_file <- file.path(SCRIPT_DIR, "expected-diffs.txt")

# Validate directories
if (!dir.exists(baseline_dir)) {
  message("ERROR: baseline directory not found: ", baseline_dir)
  quit(status = 2L, save = "no")
}
if (!dir.exists(current_dir)) {
  message("ERROR: current directory not found: ", current_dir)
  quit(status = 2L, save = "no")
}

message("Baseline: ", normalizePath(baseline_dir))
message("Current:  ", normalizePath(current_dir))
message("Diffs:    ", diff_dir)
message("")

# Load expected failures manifest
if (file.exists(expected_file)) {
  expected_diffs <- trimws(readLines(expected_file, warn = FALSE))
  expected_diffs <- expected_diffs[nzchar(expected_diffs)]  # Remove empty lines
} else {
  message("WARNING: expected-diffs.txt not found")
  message("         All failures will be treated as unexpected")
  expected_diffs <- character(0)
}
message("Expected failures: ", length(expected_diffs))
message("")

# --- Section 2: Run Comparison ---

message("Running comparison (parallel = TRUE, recursive = TRUE)...")
message("")

start_time <- Sys.time()

results <- compare_dirs_report(
  baseline_dir = baseline_dir,
  current_dir = current_dir,
  diff_dir = diff_dir,
  parallel = TRUE,
  show_all = TRUE,
  relative_paths = TRUE,
  recursive = TRUE
)

elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

# --- Section 3: Report Results ---

message("")
message(sprintf("Benchmark completed in %.2f seconds", elapsed))
message("")

# Print summary
summ <- summary(results)
print(summ)

# --- Section 4: Determine Exit Status ---

failed <- failed_pairs(results)
n_failed <- nrow(failed)
n_total <- nrow(results)
n_passed <- n_total - n_failed

message("")
message(sprintf("Results: %d passed, %d failed out of %d total", n_passed, n_failed, n_total))

if (n_failed == 0) {
  message("")
  message("SUCCESS: All ", n_total, " image pairs match")

  if (length(expected_diffs) > 0) {
    message("")
    message("WARNING: Expected ", length(expected_diffs),
            " failures but found none")
    message("         Corpus may need regeneration or expected-diffs.txt is stale")
  }
  quit(status = 0L, save = "no")
}

# Extract relative paths from img2 (strip current_dir prefix)
# img2 contains paths like "inst/ci-bench/current/solid/img.png"
# We need just "solid/img.png" to match against manifest
current_dir_norm <- normalizePath(current_dir, mustWork = FALSE)
failing_paths <- vapply(failed$img2, function(p) {
  p_norm <- normalizePath(p, mustWork = FALSE)
  # Remove current_dir prefix and leading slash
  rel <- sub(paste0("^", gsub("([\\\\])", "\\\\\\1", current_dir_norm), "[/\\\\]?"),
             "", p_norm)
  # Also try without normalization for robustness
  if (rel == p_norm) {
    rel <- sub(paste0("^", gsub("([\\\\])", "\\\\\\1", current_dir), "[/\\\\]?"),
               "", p)
  }
  # Normalize path separators to forward slash
  gsub("\\\\", "/", rel)
}, character(1), USE.NAMES = FALSE)

# Compare against manifest
# F = set of failed relative paths
# M = set of manifest entries
F_set <- failing_paths
M_set <- expected_diffs

unexpected <- setdiff(F_set, M_set)
healed <- setdiff(M_set, F_set)
expected_found <- intersect(F_set, M_set)

message("")
message("--- Failure Analysis ---")
message(sprintf("Expected failures found: %d of %d", length(expected_found), length(M_set)))
message(sprintf("Unexpected failures:     %d", length(unexpected)))
message(sprintf("Healed (expected but passed): %d", length(healed)))

if (length(healed) > 0) {
  message("")
  message("WARNING: Some expected diffs are now passing:")
  for (name in head(healed, 5)) {
    message("  - ", name)
  }
  if (length(healed) > 5) {
    message("  ... and ", length(healed) - 5, " more")
  }
}

if (length(unexpected) > 0) {
  message("")
  message("FAILURE: Unexpected visual differences detected!")
  message("")
  message("Unexpected failures (", length(unexpected), "):")
  for (name in head(unexpected, 10)) {
    message("  - ", name)
  }
  if (length(unexpected) > 10) {
    message("  ... and ", length(unexpected) - 10, " more")
  }

  message("")
  message("Diff images saved to: ", diff_dir)
  message("See report at: ", file.path(diff_dir, "report.html"))

  quit(status = 1L, save = "no")
} else {
  message("")
  message("SUCCESS: All ", n_failed, " failures are expected test cases")
  quit(status = 0L, save = "no")
}
