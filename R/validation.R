#' Compute agreement metrics for LLM annotation
#'
#' Compare model labels with reference labels using accuracy, macro
#' precision/recall/F1, Cohen's kappa, and nominal Krippendorff's alpha for two
#' coders. These metrics describe agreement with the reference labels; they do
#' not establish that the reference labels are valid.
#'
#' Rows with missing labels in either column are dropped and reported; `n` is
#' the number of complete pairs. If the estimate and truth label sets differ,
#' a warning reports the labels only seen on one side. Macro metrics use the
#' union of labels in both columns and follow the yardstick convention: classes
#' whose per-class denominator is undefined for a given metric are dropped from
#' that macro average with a warning. If only one category occurs across both
#' columns, kappa and alpha are returned as `NA_real_` with a warning.
#'
#' @param data Data frame containing estimates and truth.
#' @param estimate Character. Column name with model labels.
#' @param truth Character. Column name with reference labels.
#'
#' @return A tibble with one row per metric.
#' @export
#'
#' @examples
#' labels <- data.frame(
#'   model = c("yes", "no", "yes"),
#'   human = c("yes", "no", "no")
#' )
#' foundry_agreement(labels, estimate = "model", truth = "human")
foundry_agreement <- function(data, estimate, truth) {
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame.")
  }
  foundry_check_character_scalar(estimate, "estimate")
  foundry_check_character_scalar(truth, "truth")
  if (!estimate %in% names(data)) {
    cli::cli_abort("Column {.field {estimate}} was not found in {.arg data}.")
  }
  if (!truth %in% names(data)) {
    cli::cli_abort("Column {.field {truth}} was not found in {.arg data}.")
  }

  estimate_values <- as.character(data[[estimate]])
  truth_values <- as.character(data[[truth]])
  keep <- !is.na(estimate_values) & !is.na(truth_values)
  dropped <- sum(!keep)
  estimate_values <- estimate_values[keep]
  truth_values <- truth_values[keep]
  if (length(estimate_values) == 0L) {
    cli::cli_abort("No complete estimate/truth pairs were found.")
  }
  if (dropped > 0L) {
    cli::cli_warn(
      "{dropped} incomplete estimate/truth pair{?s} {?was/were} dropped."
    )
  }

  estimate_labels <- sort(unique(estimate_values))
  truth_labels <- sort(unique(truth_values))
  estimate_only <- setdiff(estimate_labels, truth_labels)
  truth_only <- setdiff(truth_labels, estimate_labels)
  if (length(estimate_only) > 0L || length(truth_only) > 0L) {
    cli::cli_warn(c(
      "Estimate and truth label sets differ.",
      "i" = "Only in {.arg estimate}: {foundry_label_list(estimate_only)}.",
      "i" = "Only in {.arg truth}: {foundry_label_list(truth_only)}."
    ))
  }

  classes <- sort(unique(c(estimate_values, truth_values)))
  one_category <- length(classes) == 1L
  if (one_category) {
    cli::cli_warn(
      "Kappa and alpha are undefined because only one category occurs."
    )
  }

  tibble::tibble(
    metric = c("accuracy", "precision_macro", "recall_macro", "f1_macro", "cohen_kappa", "krippendorff_alpha"),
    value = c(
      mean(estimate_values == truth_values),
      foundry_macro_precision(estimate_values, truth_values, classes),
      foundry_macro_recall(estimate_values, truth_values, classes),
      foundry_macro_f1(estimate_values, truth_values, classes),
      if (one_category) NA_real_ else foundry_cohen_kappa(estimate_values, truth_values, classes),
      if (one_category) NA_real_ else foundry_krippendorff_alpha(estimate_values, truth_values)
    ),
    n = length(estimate_values)
  )
}


#' Measure repeated-extraction consistency
#'
#' Run the same extraction multiple times and summarize how often each input
#' receives the same structured result. Use batch execution externally for large
#' jobs; this helper intentionally keeps the local loop simple.
#'
#' The comparison covers the whole structured record after canonical JSON
#' serialization: object names are sorted recursively, arrays keep their order,
#' and numbers are serialized with `digits = NA`. Only successful runs count
#' toward `modal_share` and entropy; failed runs are reported separately. With
#' `n` runs, `modal_share` can only take values `k / n`. Entropy is the plug-in
#' estimate in bits, has maximum `log2(n)`, and is biased low for small `n`.
#' Sampling settings passed through `...` define what a repeat means. Stability
#' is not accuracy: a model can be consistently wrong.
#'
#' @param text Character vector of inputs.
#' @param schema List. JSON Schema object.
#' @param n Integer. Number of repeated extractions.
#' @param ... Additional arguments passed to [foundry_extract()].
#'
#' @return A tibble with one row per input.
#' @export
#'
#' @examples
#' \dontrun{
#' # Requires a configured Azure endpoint, credentials, and AZURE_FOUNDRY_MODEL
#' # naming a deployment that supports structured outputs.
#' schema <- foundry_schema(label = schema_enum(c("yes", "no")))
#' foundry_consistency(c("Example text"), schema, n = 3)
#' }
foundry_consistency <- function(text, schema, n = 3L, ...) {
  if (!is.character(text)) {
    cli::cli_abort("{.arg text} must be a character vector.")
  }
  n <- foundry_check_positive_integer(n, "n")
  schema <- as_foundry_schema(schema)

  runs <- purrr::map(seq_len(n), function(run) {
    out <- foundry_extract(text, schema = schema, flatten = FALSE, ...)
    out$.run <- run
    out
  })
  combined <- dplyr::bind_rows(runs)

  purrr::map_dfr(seq_along(text), function(i) {
    input_rows <- combined[combined$.input_idx == i, , drop = FALSE]
    rows <- input_rows[!input_rows$.error, , drop = FALSE]
    values <- vapply(rows$.data, function(value) {
      foundry_canonical_record_json(value)
    }, character(1))
    tab <- sort(table(values), decreasing = TRUE)
    modal_share <- if (length(tab) == 0L) NA_real_ else as.numeric(tab[[1]]) / length(values)
    probs <- as.numeric(tab) / sum(tab)
    entropy <- if (length(probs) == 0L) NA_real_ else -sum(probs * log2(probs))
    tibble::tibble(
      .input_idx = i,
      .input_text = text[[i]],
      n = n,
      successful_runs = length(values),
      failed_runs = sum(input_rows$.error),
      modal_share = modal_share,
      entropy = entropy,
      values = list(values)
    )
  })
}


#' Capture model and schema provenance
#'
#' Create a one-row tibble that records the model, schema hash, package version,
#' and UTC timestamp for a reproducible annotation run. The schema hash is a
#' SHA-256 digest of the same canonical JSON serialization used by
#' [foundry_codebook()].
#'
#' @param model Character. Model or deployment name.
#' @param schema List. JSON Schema object.
#' @param metadata List. Optional additional metadata.
#'
#' @return A one-row tibble.
#' @export
#'
#' @examples
#' schema <- foundry_schema(label = schema_string())
#' foundry_provenance(
#'   model = "gpt-5-nano",
#'   schema = schema,
#'   metadata = list(run = "pilot")
#' )
foundry_provenance <- function(model, schema, metadata = NULL) {
  foundry_check_character_scalar(model, "model")
  schema <- as_foundry_schema(schema)
  if (!is.null(metadata) && !is.list(metadata)) {
    cli::cli_abort("{.arg metadata} must be a list or NULL.")
  }

  tibble::tibble(
    model = model,
    schema_hash = digest::digest(
      enc2utf8(foundry_canonical_json(schema)),
      algo = "sha256",
      serialize = FALSE
    ),
    package_version = as.character(utils::packageVersion("foundryR")),
    captured_at = foundry_utc_now(),
    metadata = list(metadata %||% list())
  )
}


foundry_macro_precision <- function(estimate, truth, classes) {
  values <- vapply(classes, function(class) {
    tp <- sum(estimate == class & truth == class)
    fp <- sum(estimate == class & truth != class)
    if (tp + fp == 0L) return(NA_real_)
    tp / (tp + fp)
  }, numeric(1))
  foundry_macro_average(values, "precision_macro")
}


foundry_macro_recall <- function(estimate, truth, classes) {
  values <- vapply(classes, function(class) {
    tp <- sum(estimate == class & truth == class)
    fn <- sum(estimate != class & truth == class)
    if (tp + fn == 0L) return(NA_real_)
    tp / (tp + fn)
  }, numeric(1))
  foundry_macro_average(values, "recall_macro")
}


foundry_macro_f1 <- function(estimate, truth, classes) {
  values <- vapply(classes, function(class) {
    tp <- sum(estimate == class & truth == class)
    fp <- sum(estimate == class & truth != class)
    fn <- sum(estimate != class & truth == class)
    if (tp + fp == 0L || tp + fn == 0L) return(NA_real_)
    if (2 * tp + fp + fn == 0L) return(NA_real_)
    precision <- tp / (tp + fp)
    recall <- tp / (tp + fn)
    if (precision + recall == 0) return(0)
    2 * precision * recall / (precision + recall)
  }, numeric(1))
  foundry_macro_average(values, "f1_macro")
}


foundry_macro_average <- function(values, metric) {
  dropped <- names(values)[is.na(values)]
  if (length(dropped) > 0L) {
    cli::cli_warn(
      "{.field {metric}} dropped class{?es} with undefined values: {foundry_label_list(dropped)}."
    )
  }
  mean(values, na.rm = TRUE)
}


foundry_cohen_kappa <- function(estimate, truth, classes) {
  observed <- mean(estimate == truth)
  estimate_prop <- table(factor(estimate, levels = classes)) / length(estimate)
  truth_prop <- table(factor(truth, levels = classes)) / length(truth)
  expected <- sum(estimate_prop * truth_prop)
  as.numeric((observed - expected) / (1 - expected))
}


foundry_krippendorff_alpha <- function(estimate, truth) {
  n_units <- length(estimate)
  n <- 2L * n_units
  values <- c(estimate, truth)
  value_counts <- table(values)
  disagreements <- sum(estimate != truth)
  denominator <- n^2 - sum(as.numeric(value_counts)^2)
  if (denominator == 0) return(NA_real_)
  1 - (n - 1) * (2 * disagreements) / denominator
}


foundry_label_list <- function(x) {
  if (length(x) == 0L) {
    return("(none)")
  }
  paste(x, collapse = ", ")
}


foundry_canonical_record_json <- function(x) {
  as.character(jsonlite::toJSON(
    foundry_sort_record(x),
    auto_unbox = TRUE,
    digits = NA,
    null = "null"
  ))
}


foundry_sort_record <- function(x) {
  if (!is.list(x)) {
    return(x)
  }
  if (!is.null(names(x)) && all(nzchar(names(x)))) {
    x <- x[sort(names(x))]
  }
  lapply(x, foundry_sort_record)
}
