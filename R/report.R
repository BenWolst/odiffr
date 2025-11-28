#' Generate HTML Report for Batch Comparison Results
#'
#' Creates a standalone HTML report summarizing batch image comparison results.
#' Includes pass/fail statistics, failure reasons, diff statistics, and
#' thumbnails of the worst offenders.
#'
#' @param object An `odiffr_batch` object from [compare_images_batch()] or
#'   [compare_image_dirs()].
#' @param output_file Path to write the HTML file. If NULL, returns HTML as
#'   a character string.
#' @param title Report title. Default: "odiffr Comparison Report".
#' @param embed If TRUE, embed diff images as base64 data URIs for a fully
#'   self-contained file. If FALSE (default), link to image files on disk.
#' @param n_worst Number of worst offenders to display. Default: 10.
#' @param show_all If TRUE, include a table of all comparisons. Default: FALSE.
#' @param ... Additional arguments passed to [summary.odiffr_batch()].
#'
#' @return If `output_file` is NULL, returns the HTML as a character string
#'   (invisibly). If `output_file` is specified, writes the file and returns
#'   the file path (invisibly).
#'
#' @details
#' Diff image thumbnails (or embedded images when `embed = TRUE`) are only
#' shown for comparisons where a `diff_output` file was created. This requires
#' using `diff_dir` in [compare_images_batch()] or [compare_image_dirs()].
#' Comparisons without diff images will show "No diff" in the preview column.
#'
#' @seealso [compare_images_batch()], [compare_image_dirs()],
#'   [summary.odiffr_batch()]
#'
#' @export
#'
#' @examples
#' \dontrun{
#' results <- compare_image_dirs("baseline/", "current/", diff_dir = "diffs/")
#'
#' # Generate report file
#' batch_report(results, output_file = "report.html")
#'
#' # Self-contained report with embedded images
#' batch_report(results, output_file = "report.html", embed = TRUE)
#'
#' # Get HTML as string
#' html <- batch_report(results)
#' }
batch_report <- function(object,
                         output_file = NULL,
                         title = "odiffr Comparison Report",
                         embed = FALSE,
                         n_worst = 10,
                         show_all = FALSE,
                         ...) {
  stopifnot(inherits(object, "odiffr_batch"))


  n_worst <- suppressWarnings(as.integer(n_worst))
  if (is.na(n_worst) || n_worst < 0) {
    stop("n_worst must be a non-negative integer.", call. = FALSE)
  }


  summ <- summary(object, n_worst = n_worst, ...)


  html <- .build_html_report(
    batch = object,
    summ = summ,
    title = title,
    embed = embed,
    show_all = show_all
  )


  if (!is.null(output_file)) {
    writeLines(html, output_file)
    invisible(output_file)
  } else {
    invisible(html)
  }
}


.build_html_report <- function(batch, summ, title, embed, show_all) {
  paste0(
    .html_head(title),
    "<body>\n",
    .html_header(title),
    .html_summary_section(summ),
    .html_worst_section(summ, embed),
    if (show_all) .html_all_results_section(batch, embed) else "",
    .html_footer(),
    "</body>\n</html>"
  )
}


.html_head <- function(title) {
  sprintf('<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>%s</title>
  <style>
%s
  </style>
</head>
', .html_escape(title), .report_css())
}


.report_css <- function() {
  paste0(
    "* { box-sizing: border-box; }\n",
    "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; ",
    "line-height: 1.6; max-width: 1200px; margin: 0 auto; padding: 20px; color: #333; }\n",
    "h1 { border-bottom: 2px solid #333; padding-bottom: 10px; }\n",
    "h2 { color: #555; margin-top: 30px; }\n",
    "h3 { color: #666; margin-top: 20px; font-size: 1em; }\n",
    ".timestamp { color: #888; font-size: 0.9em; }\n",
    ".stats { display: flex; gap: 20px; margin: 20px 0; }\n",
    ".stat { padding: 20px; border-radius: 8px; text-align: center; min-width: 150px; }\n",
    ".stat.passed { background: #d4edda; border: 1px solid #c3e6cb; }\n",
    ".stat.failed { background: #f8d7da; border: 1px solid #f5c6cb; }\n",
    ".stat .value { font-size: 2em; font-weight: bold; display: block; }\n",
    ".stat .label { font-size: 0.9em; color: #666; }\n",
    "table { width: 100%; border-collapse: collapse; margin: 15px 0; }\n",
    "th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }\n",
    "th { background: #f5f5f5; font-weight: 600; }\n",
    "tr:hover { background: #f9f9f9; }\n",
    ".pass { color: #28a745; }\n",
    ".fail { color: #dc3545; }\n",
    ".diff-preview { max-width: 200px; max-height: 150px; border: 1px solid #ddd; }\n",
    ".no-image { color: #888; font-style: italic; }\n",
    ".reasons ul { margin: 10px 0; padding-left: 20px; }\n",
    ".diff-stats table { width: auto; }\n",
    ".diff-stats td:first-child { font-weight: 600; padding-right: 20px; }\n",
    "footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; color: #888; font-size: 0.85em; }"
  )
}


.html_header <- function(title) {
  sprintf('<h1>%s</h1>\n<p class="timestamp">Generated: %s</p>\n',
          .html_escape(title),
          format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
}


.html_summary_section <- function(summ) {
  fail_rate <- (1 - summ$pass_rate) * 100
  pass_rate <- summ$pass_rate * 100

  stats_html <- sprintf(
    '<div class="stats">
  <div class="stat passed">
    <span class="value">%d</span>
    <span class="label">Passed (%.1f%%)</span>
  </div>

  <div class="stat failed">
    <span class="value">%d</span>
    <span class="label">Failed (%.1f%%)</span>
  </div>
</div>\n',
    summ$passed, pass_rate, summ$failed, fail_rate
  )

  reasons_html <- ""
  if (!is.null(summ$reason_counts) && length(summ$reason_counts) > 0) {
    reason_items <- vapply(names(summ$reason_counts), function(reason) {
      sprintf("  <li>%s: %d</li>", .html_escape(reason), summ$reason_counts[[reason]])
    }, character(1))

    reasons_html <- sprintf(
      '<div class="reasons">\n<h3>Failure Reasons</h3>\n<ul>\n%s\n</ul>\n</div>\n',
      paste(reason_items, collapse = "\n")
    )
  }

  diff_stats_html <- ""
  if (!is.null(summ$diff_stats)) {
    diff_stats_html <- sprintf(
      '<div class="diff-stats">
<h3>Diff Statistics</h3>
<table>
  <tr><td>Min</td><td>%.2f%%</td></tr>
  <tr><td>Median</td><td>%.2f%%</td></tr>
  <tr><td>Mean</td><td>%.2f%%</td></tr>
  <tr><td>Max</td><td>%.2f%%</td></tr>
</table>
</div>\n',
      summ$diff_stats$min,
      summ$diff_stats$median,
      summ$diff_stats$mean,
      summ$diff_stats$max
    )
  }

  paste0(
    '<section class="summary">\n<h2>Summary</h2>\n',
    stats_html,
    reasons_html,
    diff_stats_html,
    '</section>\n'
  )
}


.html_worst_section <- function(summ, embed) {
  if (is.null(summ$worst) || nrow(summ$worst) == 0) {
    return('<section class="worst-offenders">\n<h2>Worst Offenders</h2>\n<p>No failures to display.</p>\n</section>\n')
  }

  rows <- vapply(seq_len(nrow(summ$worst)), function(i) {
    row <- summ$worst[i, ]
    img_label <- if (!is.na(row$img2) && row$img2 != "<magick-image>") {
      basename(row$img2)
    } else {
      paste0("pair ", row$pair_id)
    }
    img_html <- .format_diff_image(row$diff_output, embed)

    sprintf(
      '<tr>\n  <td>%d</td>\n  <td>%s</td>\n  <td>%.2f%%</td>\n  <td>%d</td>\n  <td>%s</td>\n  <td>%s</td>\n</tr>',
      i,
      .html_escape(img_label),
      row$diff_percentage,
      row$diff_count,
      .html_escape(row$reason),
      img_html
    )
  }, character(1))

  paste0(
    '<section class="worst-offenders">\n<h2>Worst Offenders</h2>\n<table>\n',
    '<thead><tr><th>#</th><th>Image</th><th>Diff %</th><th>Pixels</th><th>Reason</th><th>Preview</th></tr></thead>\n',
    '<tbody>\n',
    paste(rows, collapse = "\n"),
    '\n</tbody>\n</table>\n</section>\n'
  )
}


.html_all_results_section <- function(batch, embed) {
  rows <- vapply(seq_len(nrow(batch)), function(i) {
    row <- batch[i, ]
    status_class <- if (row$match) "pass" else "fail"
    status_text <- if (row$match) "PASS" else "FAIL"

    img_label <- if (!is.na(row$img2) && row$img2 != "<magick-image>") {
      basename(row$img2)
    } else {
      paste0("pair ", row$pair_id)
    }

    diff_pct <- if (is.na(row$diff_percentage)) "-" else sprintf("%.2f%%", row$diff_percentage)
    diff_cnt <- if (is.na(row$diff_count)) "-" else as.character(row$diff_count)
    reason <- if (is.na(row$reason)) "-" else .html_escape(row$reason)
    img_html <- .format_diff_image(row$diff_output, embed)

    sprintf(
      '<tr>\n  <td>%d</td>\n  <td class="%s">%s</td>\n  <td>%s</td>\n  <td>%s</td>\n  <td>%s</td>\n  <td>%s</td>\n  <td>%s</td>\n</tr>',
      row$pair_id,
      status_class, status_text,
      .html_escape(img_label),
      diff_pct,
      diff_cnt,
      reason,
      img_html
    )
  }, character(1))

  paste0(
    '<section class="all-results">\n<h2>All Comparisons</h2>\n<table>\n',
    '<thead><tr><th>#</th><th>Status</th><th>Image</th><th>Diff %</th><th>Pixels</th><th>Reason</th><th>Preview</th></tr></thead>\n',
    '<tbody>\n',
    paste(rows, collapse = "\n"),
    '\n</tbody>\n</table>\n</section>\n'
  )
}


.format_diff_image <- function(path, embed) {
  if (is.na(path) || !file.exists(path)) {
    return('<span class="no-image">No diff</span>')
  }

  if (embed) {
    raw_data <- readBin(path, "raw", file.info(path)$size)
    b64 <- .base64_encode(raw_data)
    sprintf('<img class="diff-preview" src="data:image/png;base64,%s" alt="diff" />', b64)
  } else {
    sprintf('<img class="diff-preview" src="%s" alt="diff" />', .html_escape(path))
  }
}


.html_escape <- function(x) {
  if (is.na(x)) return("")
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)

  x
}


.html_footer <- function() {
  version <- tryCatch(
    as.character(utils::packageVersion("odiffr")),
    error = function(e) "dev"
  )
  sprintf('<footer>\n<p>Generated by odiffr %s</p>\n</footer>\n', version)
}


.base64_encode <- function(raw_data) {
  if (length(raw_data) == 0) return("")

  b64_chars <- c(LETTERS, letters, 0:9, "+", "/")

  n <- length(raw_data)
  padding <- (3 - n %% 3) %% 3
  raw_data <- c(raw_data, rep(as.raw(0), padding))

  result <- character(length(raw_data) / 3 * 4)
  j <- 1
  for (i in seq(1, length(raw_data), 3)) {
    chunk <- as.integer(raw_data[i:(i + 2)])
    result[j]     <- b64_chars[(chunk[1] %/% 4) + 1]
    result[j + 1] <- b64_chars[((chunk[1] %% 4) * 16 + chunk[2] %/% 16) + 1]
    result[j + 2] <- b64_chars[((chunk[2] %% 16) * 4 + chunk[3] %/% 64) + 1]
    result[j + 3] <- b64_chars[(chunk[3] %% 64) + 1]
    j <- j + 4
  }

  if (padding > 0) {
    result[(length(result) - padding + 1):length(result)] <- "="
  }

  paste(result, collapse = "")
}
