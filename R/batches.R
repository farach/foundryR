#' Write JSONL requests for the Batch API
#'
#' Convert a data frame of prompts into a JSON Lines file that can be uploaded
#' with `foundry_file_upload(..., purpose = "batch")` and submitted with
#' `foundry_batch_create()`.
#'
#' @param data Data frame containing input rows.
#' @param input Character. Name of the column containing prompt/input text.
#' @param path Character. Path to write the JSONL file.
#' @param model Character. Model deployment name to include in each request.
#' @param endpoint Character. Batch endpoint path. Defaults to `"/v1/responses"`.
#' @param custom_id Character. Optional column name for custom IDs. If omitted,
#'   IDs are generated as `row-1`, `row-2`, and so on.
#' @param body List. Additional request body fields added to each request.
#' @param overwrite Logical. Whether to overwrite an existing file.
#'
#' @return A tibble with the JSONL path, request count, and endpoint.
#' @export
#'
#' @examples
#' jobs <- data.frame(text = c("Summarize this.", "Extract entities."))
#' path <- tempfile(fileext = ".jsonl")
#' foundry_batch_requests(jobs, input = "text", path = path, model = "gpt-4.1")
foundry_batch_requests <- function(data,
                                   input,
                                   path,
                                   model,
                                   endpoint = "/v1/responses",
                                   custom_id = NULL,
                                   body = list(),
                                   overwrite = FALSE) {
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame.")
  }
  foundry_check_character_scalar(input, "input")
  foundry_check_character_scalar(path, "path")
  model <- foundry_resolve_model(model)
  foundry_check_character_scalar(endpoint, "endpoint")
  if (!is.list(body)) {
    cli::cli_abort("{.arg body} must be a list.")
  }
  if (!input %in% names(data)) {
    cli::cli_abort("Column {.field {input}} was not found in {.arg data}.")
  }
  if (!is.null(custom_id) && !custom_id %in% names(data)) {
    cli::cli_abort("Column {.field {custom_id}} was not found in {.arg data}.")
  }
  if (file.exists(path) && !isTRUE(overwrite)) {
    cli::cli_abort(c(
      "File already exists: {.file {path}}.",
      "i" = "Use {.code overwrite = TRUE} to replace it."
    ))
  }

  prompts <- as.character(data[[input]])
  ids <- if (is.null(custom_id)) {
    paste0("row-", seq_along(prompts))
  } else {
    as.character(data[[custom_id]])
  }

  lines <- purrr::map2_chr(ids, prompts, function(id, prompt) {
    request_body <- c(list(model = model, input = prompt), body)
    request <- list(
      custom_id = id,
      method = "POST",
      url = endpoint,
      body = request_body
    )
    jsonlite::toJSON(request, auto_unbox = TRUE, null = "null")
  })

  writeLines(lines, path, useBytes = TRUE)
  tibble::tibble(
    path = normalizePath(path, winslash = "/", mustWork = FALSE),
    requests = length(lines),
    endpoint = endpoint
  )
}


#' Create a Microsoft Foundry batch
#'
#' @param input_file_id Character. File ID for an uploaded JSONL batch file.
#' @param endpoint Character. Endpoint path for the batch requests.
#' @param completion_window Character. Batch completion window, usually `"24h"`.
#' @param metadata List. Optional metadata attached to the batch.
#' @param api_key Character. Optional API key override.
#' @param token Character. Optional bearer token override.
#' @param endpoint_url Character. Optional Foundry endpoint override.
#' @param api_version Character. Optional API version query value.
#'
#' @return A one-row tibble with batch metadata.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_batch_create("file_abc123", endpoint = "/v1/responses")
#' }
foundry_batch_create <- function(input_file_id,
                                 endpoint = "/v1/responses",
                                 completion_window = "24h",
                                 metadata = NULL,
                                 api_key = NULL,
                                 token = NULL,
                                 endpoint_url = NULL,
                                 api_version = NULL) {
  foundry_check_character_scalar(input_file_id, "input_file_id")
  foundry_check_character_scalar(endpoint, "endpoint")
  foundry_check_character_scalar(completion_window, "completion_window")

  body <- list(
    input_file_id = input_file_id,
    endpoint = endpoint,
    completion_window = completion_window
  )
  if (!is.null(metadata)) body$metadata <- metadata

  req <- foundry_build_v1_request(
    path = "batches",
    body = body,
    method = "POST",
    api_key = api_key,
    token = token,
    endpoint = endpoint_url,
    api_version = api_version
  )

  foundry_parse_batch(foundry_perform(req))
}


#' List Microsoft Foundry batches
#'
#' @param limit Integer. Optional maximum number of batches to return.
#' @param after Character. Optional pagination cursor.
#' @inheritParams foundry_batch_create
#'
#' @return A tibble with one row per batch.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_batches(limit = 10)
#' }
foundry_batches <- function(limit = NULL,
                            after = NULL,
                            api_key = NULL,
                            token = NULL,
                            endpoint_url = NULL,
                            api_version = NULL) {
  req <- foundry_build_v1_request(
    path = "batches",
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint_url,
    api_version = api_version
  )

  req <- req |>
    httr2::req_url_query(limit = limit, after = after)

  result <- foundry_perform(req)
  batches <- result$data %||% list()
  if (length(batches) == 0L) {
    return(foundry_batch_tibble(list()))
  }
  purrr::map_dfr(batches, foundry_batch_tibble)
}


#' Retrieve a Microsoft Foundry batch
#'
#' @param batch_id Character. Batch ID to retrieve.
#' @inheritParams foundry_batch_create
#'
#' @return A one-row tibble with batch metadata.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_batch_get("batch_abc123")
#' }
foundry_batch_get <- function(batch_id,
                              api_key = NULL,
                              token = NULL,
                              endpoint_url = NULL,
                              api_version = NULL) {
  foundry_check_character_scalar(batch_id, "batch_id")

  req <- foundry_build_v1_request(
    path = paste0("batches/", batch_id),
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint_url,
    api_version = api_version
  )

  foundry_parse_batch(foundry_perform(req))
}


#' Cancel a Microsoft Foundry batch
#'
#' @param batch_id Character. Batch ID to cancel.
#' @inheritParams foundry_batch_create
#'
#' @return A one-row tibble with batch metadata after cancellation.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_batch_cancel("batch_abc123")
#' }
foundry_batch_cancel <- function(batch_id,
                                 api_key = NULL,
                                 token = NULL,
                                 endpoint_url = NULL,
                                 api_version = NULL) {
  foundry_check_character_scalar(batch_id, "batch_id")

  req <- foundry_build_v1_request(
    path = paste0("batches/", batch_id, "/cancel"),
    method = "POST",
    api_key = api_key,
    token = token,
    endpoint = endpoint_url,
    api_version = api_version
  )

  foundry_parse_batch(foundry_perform(req))
}


foundry_parse_batch <- function(result) {
  foundry_batch_tibble(result)
}


foundry_batch_tibble <- function(batch) {
  if (length(batch) == 0L) {
    return(tibble::tibble(
      batch_id = character(),
      status = character(),
      endpoint = character(),
      input_file_id = character(),
      output_file_id = character(),
      error_file_id = character(),
      completion_window = character(),
      request_counts_total = integer(),
      request_counts_completed = integer(),
      request_counts_failed = integer(),
      created_at = as.POSIXct(character()),
      raw_batch = list()
    ))
  }

  counts <- batch$request_counts %||% list()
  tibble::tibble(
    batch_id = batch$id %||% NA_character_,
    status = batch$status %||% NA_character_,
    endpoint = batch$endpoint %||% NA_character_,
    input_file_id = batch$input_file_id %||% NA_character_,
    output_file_id = batch$output_file_id %||% NA_character_,
    error_file_id = batch$error_file_id %||% NA_character_,
    completion_window = batch$completion_window %||% NA_character_,
    request_counts_total = as.integer(counts$total %||% NA_integer_),
    request_counts_completed = as.integer(counts$completed %||% NA_integer_),
    request_counts_failed = as.integer(counts$failed %||% NA_integer_),
    created_at = foundry_response_created_at(batch$created_at %||% NA_real_),
    raw_batch = list(batch)
  )
}
