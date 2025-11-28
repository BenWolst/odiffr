#!/usr/bin/env Rscript
# Generate visual benchmark corpus for odiffr CI
# Run once to create baseline/ and current/ directories with test images
#
# Usage: Rscript inst/ci-bench/generate-corpus.R
#        (run from package root)

library(png)

# Deterministic generation
set.seed(42)

# --- Configuration ---
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

BASELINE_DIR <- file.path(SCRIPT_DIR, "baseline")
CURRENT_DIR <- file.path(SCRIPT_DIR, "current")

# Track files that have intentional diffs (relative paths from ci-bench root)
diff_manifest <- character(0)

# --- Color Palette ---
COLORS <- list(
  red     = c(1.0, 0.0, 0.0),
  green   = c(0.0, 1.0, 0.0),
  blue    = c(0.0, 0.0, 1.0),
  yellow  = c(1.0, 1.0, 0.0),
  cyan    = c(0.0, 1.0, 1.0),
  magenta = c(1.0, 0.0, 1.0),
  white   = c(1.0, 1.0, 1.0),
  black   = c(0.0, 0.0, 0.0),
  gray    = c(0.5, 0.5, 0.5),
  orange  = c(1.0, 0.5, 0.0)
)

# --- Image Generation Helpers ---

create_solid_image <- function(width, height, color_rgb) {
  img <- array(0, dim = c(height, width, 3))
  img[, , 1] <- color_rgb[1]
  img[, , 2] <- color_rgb[2]
  img[, , 3] <- color_rgb[3]
  img
}

create_gradient_image <- function(width, height, from_rgb, to_rgb,
                                   direction = "horizontal") {

  img <- array(0, dim = c(height, width, 3))
  if (direction == "horizontal") {
    for (x in seq_len(width)) {
      t <- (x - 1) / max(width - 1, 1)
      img[, x, 1] <- from_rgb[1] * (1 - t) + to_rgb[1] * t
      img[, x, 2] <- from_rgb[2] * (1 - t) + to_rgb[2] * t
      img[, x, 3] <- from_rgb[3] * (1 - t) + to_rgb[3] * t
    }
  } else {
    for (y in seq_len(height)) {
      t <- (y - 1) / max(height - 1, 1)
      img[y, , 1] <- from_rgb[1] * (1 - t) + to_rgb[1] * t
      img[y, , 2] <- from_rgb[2] * (1 - t) + to_rgb[2] * t
      img[y, , 3] <- from_rgb[3] * (1 - t) + to_rgb[3] * t
    }
  }
  img
}

create_checkerboard <- function(width, height, cell_size, color1_rgb, color2_rgb) {
  img <- array(0, dim = c(height, width, 3))
  for (y in seq_len(height)) {
    for (x in seq_len(width)) {
      cell_x <- ((x - 1) %/% cell_size) %% 2
      cell_y <- ((y - 1) %/% cell_size) %% 2
      color <- if ((cell_x + cell_y) %% 2 == 0) color1_rgb else color2_rgb
      img[y, x, ] <- color
    }
  }
  img
}

create_complex_image <- function(width, height, seed_variant) {

  # Create multi-region composition based on variant number
  img <- array(0.5, dim = c(height, width, 3))  # gray background

  # Divide into regions with different colors based on variant
  color_names <- names(COLORS)
  n_colors <- length(color_names)

  # Top-left quadrant
  c1 <- COLORS[[color_names[((seed_variant - 1) %% n_colors) + 1]]]
  img[1:(height %/% 2), 1:(width %/% 2), 1] <- c1[1]
  img[1:(height %/% 2), 1:(width %/% 2), 2] <- c1[2]
  img[1:(height %/% 2), 1:(width %/% 2), 3] <- c1[3]


  # Top-right quadrant
  c2 <- COLORS[[color_names[((seed_variant) %% n_colors) + 1]]]
  img[1:(height %/% 2), (width %/% 2 + 1):width, 1] <- c2[1]
  img[1:(height %/% 2), (width %/% 2 + 1):width, 2] <- c2[2]
  img[1:(height %/% 2), (width %/% 2 + 1):width, 3] <- c2[3]

  # Bottom-left quadrant
  c3 <- COLORS[[color_names[((seed_variant + 1) %% n_colors) + 1]]]
  img[(height %/% 2 + 1):height, 1:(width %/% 2), 1] <- c3[1]
  img[(height %/% 2 + 1):height, 1:(width %/% 2), 2] <- c3[2]
  img[(height %/% 2 + 1):height, 1:(width %/% 2), 3] <- c3[3]

  # Bottom-right quadrant
  c4 <- COLORS[[color_names[((seed_variant + 2) %% n_colors) + 1]]]
  img[(height %/% 2 + 1):height, (width %/% 2 + 1):width, 1] <- c4[1]
  img[(height %/% 2 + 1):height, (width %/% 2 + 1):width, 2] <- c4[2]
  img[(height %/% 2 + 1):height, (width %/% 2 + 1):width, 3] <- c4[3]

  img
}

# --- Diff Application Helpers ---

apply_pixel_diff <- function(img, x = NULL, y = NULL) {
  # Single pixel change
  if (is.null(x)) x <- dim(img)[2] %/% 2

  if (is.null(y)) y <- dim(img)[1] %/% 2
  # Invert the pixel

  img[y, x, ] <- 1 - img[y, x, ]
  img
}

apply_region_diff <- function(img, x1, y1, x2, y2) {
  # Invert a rectangular region
  img[y1:y2, x1:x2, ] <- 1 - img[y1:y2, x1:x2, ]
  img
}

# --- Write Image Helper ---

write_pair <- function(img_baseline, img_current, category, filename) {
  baseline_path <- file.path(BASELINE_DIR, category, filename)
  current_path <- file.path(CURRENT_DIR, category, filename)
  writePNG(img_baseline, baseline_path)
  writePNG(img_current, current_path)
}

# --- Generate SOLID Images (20 total, 2 with pixel diffs) ---

message("Generating solid images...")

solid_count <- 0

# 10 colors at 100x100
for (color_name in names(COLORS)) {
  solid_count <- solid_count + 1
  filename <- sprintf("solid-%s-100x100.png", color_name)

  img <- create_solid_image(100, 100, COLORS[[color_name]])

  if (solid_count <= 2) {
    # Apply single-pixel diff
    img_current <- apply_pixel_diff(img, 50, 50)
    diff_manifest <- c(diff_manifest, file.path("solid", filename))
  } else {
    img_current <- img

  }

  write_pair(img, img_current, "solid", filename)
}

# 10 more at various sizes (no diffs)
sizes <- c(50, 75, 120, 150, 200)
for (size in sizes) {
  for (color_name in c("gray", "white")) {
    solid_count <- solid_count + 1
    if (solid_count > 20) break
    filename <- sprintf("solid-%s-%dx%d.png", color_name, size, size)
    img <- create_solid_image(size, size, COLORS[[color_name]])
    write_pair(img, img, "solid", filename)
  }
  if (solid_count > 20) break
}

message(sprintf("  Created %d solid images", solid_count))

# --- Generate GRADIENT Images (20 total, 2 with region diffs) ---

message("Generating gradient images...")

gradient_specs <- list(
  list(from = "red",    to = "blue",   dir = "horizontal"),
  list(from = "green",  to = "yellow", dir = "horizontal"),
  list(from = "blue",   to = "cyan",   dir = "horizontal"),
  list(from = "red",    to = "yellow", dir = "horizontal"),
  list(from = "magenta", to = "cyan",  dir = "horizontal"),
  list(from = "black",  to = "white",  dir = "horizontal"),
  list(from = "red",    to = "blue",   dir = "vertical"),
  list(from = "green",  to = "yellow", dir = "vertical"),
  list(from = "blue",   to = "cyan",   dir = "vertical"),
  list(from = "black",  to = "white",  dir = "vertical")
)

gradient_count <- 0

for (i in seq_along(gradient_specs)) {
  gradient_count <- gradient_count + 1
  spec <- gradient_specs[[i]]
  filename <- sprintf("gradient-%s-%s-%s-200x100.png", spec$dir, spec$from, spec$to)

  img <- create_gradient_image(200, 100, COLORS[[spec$from]], COLORS[[spec$to]], spec$dir)

  if (i <= 2) {
    # Apply 20x20 region diff in center
    img_current <- apply_region_diff(img, 90, 40, 110, 60)
    diff_manifest <- c(diff_manifest, file.path("gradient", filename))
  } else {
    img_current <- img
  }

  write_pair(img, img_current, "gradient", filename)
}

# 10 more gradients at different sizes (no diffs)
extra_sizes <- list(
  c(100, 50), c(100, 100), c(150, 50), c(150, 100), c(150, 150),
  c(250, 50), c(250, 100), c(250, 150), c(300, 100), c(300, 150)
)

for (size in extra_sizes) {
  gradient_count <- gradient_count + 1
  if (gradient_count > 20) break
  w <- size[1]
  h <- size[2]
  filename <- sprintf("gradient-horiz-gray-%dx%d.png", w, h)
  img <- create_gradient_image(w, h, c(0.2, 0.2, 0.2), c(0.8, 0.8, 0.8), "horizontal")
  write_pair(img, img, "gradient", filename)
}

message(sprintf("  Created %d gradient images", min(gradient_count, 20)))

# --- Generate PATTERN Images (30 total, 3 with region diffs) ---

message("Generating pattern images...")

pattern_count <- 0
cell_sizes <- c(4, 8, 16, 24, 32)
color_pairs <- list(
  c("black", "white"),
  c("red", "blue"),
  c("green", "yellow"),
  c("cyan", "magenta"),
  c("gray", "white"),
  c("orange", "blue")
)

diff_applied <- 0

for (cell in cell_sizes) {
  for (pair in color_pairs) {
    pattern_count <- pattern_count + 1
    if (pattern_count > 30) break

    filename <- sprintf("pattern-checker-%dpx-%s-%s-150x150.png", cell, pair[1], pair[2])
    img <- create_checkerboard(150, 150, cell, COLORS[[pair[1]]], COLORS[[pair[2]]])

    if (diff_applied < 3) {
      # Apply 30x30 region diff
      img_current <- apply_region_diff(img, 60, 60, 90, 90)
      diff_manifest <- c(diff_manifest, file.path("pattern", filename))
      diff_applied <- diff_applied + 1
    } else {
      img_current <- img
    }

    write_pair(img, img_current, "pattern", filename)
  }
  if (pattern_count >= 30) break
}

message(sprintf("  Created %d pattern images", pattern_count))

# --- Generate COMPLEX Images (30 total, 3 with diffs: 2 layout + 1 region) ---

message("Generating complex images...")

complex_count <- 0

for (variant in 1:30) {
  complex_count <- complex_count + 1
  w <- 300
  h <- 200
  filename <- sprintf("complex-variant%02d-%dx%d.png", variant, w, h)

  img_baseline <- create_complex_image(w, h, variant)

  if (variant == 1) {
    # Layout diff: different width
    img_current <- create_complex_image(320, h, variant)
    diff_manifest <- c(diff_manifest, file.path("complex", filename))
  } else if (variant == 2) {
    # Layout diff: different height
    img_current <- create_complex_image(w, 220, variant)
    diff_manifest <- c(diff_manifest, file.path("complex", filename))
  } else if (variant == 3) {
    # Large region diff: 100x100
    img_current <- apply_region_diff(img_baseline, 100, 50, 200, 150)
    diff_manifest <- c(diff_manifest, file.path("complex", filename))
  } else {
    img_current <- img_baseline
  }

  write_pair(img_baseline, img_current, "complex", filename)
}

message(sprintf("  Created %d complex images", complex_count))

# --- Write expected-diffs.txt ---

manifest_path <- file.path(SCRIPT_DIR, "expected-diffs.txt")
writeLines(diff_manifest, manifest_path)

# --- Summary ---

total_images <- solid_count + min(gradient_count, 20) + pattern_count + complex_count

message("")
message("=== Corpus Generation Complete ===")
message(sprintf("Total image pairs: %d", total_images))
message(sprintf("Intentional diffs: %d", length(diff_manifest)))
message("")
message("Expected diffs (written to expected-diffs.txt):")
for (d in diff_manifest) {
  message(sprintf("  - %s", d))
}
