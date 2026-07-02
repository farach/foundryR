#' Compute agreement metrics for LLM annotation
#'
#' Compare model labels with human or gold-standard labels using common
#' publication-friendly metrics.
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
  estimate_values <- estimate_values[keep]
  truth_values <- truth_values[keep]
  if (length(estimate_values) == 0L) {
    cli::cli_abort("No complete estimate/truth pairs were found.")
  }

  tibble::tibble(
    metric = c("accuracy", "precision_macro", "recall_macro", "f1_macro", "cohen_kappa"),
    value = c(
      mean(estimate_values == truth_values),
      foundry_macro_precision(estimate_values, truth_values),
      foundry_macro_recall(estimate_values, truth_values),
      foundry_macro_f1(estimate_values, truth_values),
      foundry_cohen_kappa(estimate_values, truth_values)
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
#' schema <- foundry_schema(label = schema_enum(c("yes", "no")))
#' foundry_consistency(c("Example text"), schema, n = 3, model = "gpt-4.1")
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
    rows <- combined[combined$.input_idx == i & !combined$.error, , drop = FALSE]
    values <- vapply(rows$.data, function(value) {
      jsonlite::toJSON(value, auto_unbox = TRUE, null = "null")
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
      modal_share = modal_share,
      entropy = entropy,
      values = list(values)
    )
  })
}


#' Capture model and schema provenance
#'
#' Create a one-row tibble that records the model, schema hash, package version,
#' and timestamp for a reproducible annotation run.
#'
#' @param model Character. Model or deployment name.
#' @param schema List. JSON Schema object.
#' @param metadata List. Optional additional metadata.
#'
#' @return A one-row tibble.
#' @export
foundry_provenance <- function(model, schema, metadata = NULL) {
  foundry_check_character_scalar(model, "model")
  schema <- as_foundry_schema(schema)
  if (!is.null(metadata) && !is.list(metadata)) {
    cli::cli_abort("{.arg metadata} must be a list or NULL.")
  }

  tibble::tibble(
    model = model,
    schema_hash = rlang::hash(schema),
    package_version = as.character(utils::packageVersion("foundryR")),
    captured_at = Sys.time(),
    metadata = list(metadata %||% list())
  )
}


foundry_macro_precision <- function(estimate, truth) {
  classes <- sort(unique(c(estimate, truth)))
  mean(vapply(classes, function(class) {
    tp <- sum(estimate == class & truth == class)
    fp <- sum(estimate == class & truth != class)
    if (tp + fp == 0L) return(NA_real_)
    tp / (tp + fp)
  }, numeric(1)), na.rm = TRUE)
}


foundry_macro_recall <- function(estimate, truth) {
  classes <- sort(unique(c(estimate, truth)))
  mean(vapply(classes, function(class) {
    tp <- sum(estimate == class & truth == class)
    fn <- sum(estimate != class & truth == class)
    if (tp + fn == 0L) return(NA_real_)
    tp / (tp + fn)
  }, numeric(1)), na.rm = TRUE)
}


foundry_macro_f1 <- function(estimate, truth) {
  classes <- sort(unique(c(estimate, truth)))
  mean(vapply(classes, function(class) {
    tp <- sum(estimate == class & truth == class)
    fp <- sum(estimate == class & truth != class)
    fn <- sum(estimate != class & truth == class)
    if (tp == 0L && (fp > 0L || fn > 0L)) return(0)
    precision <- tp / (tp + fp)
    recall <- tp / (tp + fn)
    if (is.na(precision) || is.na(recall) || precision + recall == 0) {
      return(NA_real_)
    }
    2 * precision * recall / (precision + recall)
  }, numeric(1)), na.rm = TRUE)
}


foundry_cohen_kappa <- function(estimate, truth) {
  observed <- mean(estimate == truth)
  classes <- sort(unique(c(estimate, truth)))
  estimate_prop <- table(factor(estimate, levels = classes)) / length(estimate)
  truth_prop <- table(factor(truth, levels = classes)) / length(truth)
  expected <- sum(estimate_prop * truth_prop)
  if (expected == 1) return(NA_real_)
  as.numeric((observed - expected) / (1 - expected))
}
