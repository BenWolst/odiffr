# Construct an odiffr_batch by hand (no odiff needed).
# `error` is only added when supplied, mimicking older objects without it.
make_batch <- function(match = logical(0),
                       reason = character(0),
                       diff_count = rep(NA_integer_, length(match)),
                       diff_percentage = rep(NA_real_, length(match)),
                       diff_output = rep(NA_character_, length(match)),
                       img1 = sprintf("baseline/img%d.png", seq_along(match)),
                       img2 = sprintf("current/img%d.png", seq_along(match)),
                       error = NULL,
                       tibble = FALSE) {
  df <- data.frame(
    pair_id = seq_along(match),
    match = as.logical(match),
    reason = as.character(reason),
    diff_count = as.integer(diff_count),
    diff_percentage = as.numeric(diff_percentage),
    diff_output = as.character(diff_output),
    img1 = as.character(img1),
    img2 = as.character(img2),
    stringsAsFactors = FALSE
  )
  if (!is.null(error)) df$error <- as.character(error)
  if (tibble) df <- tibble::as_tibble(df)
  class(df) <- c("odiffr_batch", class(df))
  df
}
