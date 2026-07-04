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
#' @param schema List. Optional JSON Schema for structured Responses API output.
#' @param schema_name Character. Name for `schema` when supplied.
#' @param strict Logical. Whether structured output should be strict.
#' @param instructions Character. Optional instructions for Responses API
#'   requests.
#' @param body_columns Character vector. Optional column names whose per-row
#'   values should be added to each request body.
#' @param overwrite Logical. Whether to overwrite an existing file.
#'
#' @return A tibble with the JSONL path, request count, and endpoint.
#' @export
#'
#' @examples
#' jobs <- data.frame(text = c("Summarize this.", "Extract entities."))
#' path <- tempfile(fileext = ".jsonl")
#' foundry_batch_requests(jobs, input = "text", path = path, model = "gpt-5-nano")
foundry_batch_requests <- function(data,
                                   input,
                                   path,
                                   model,
                                   endpoint = "/v1/responses",
                                   custom_id = NULL,
                                   body = list(),
                                   schema = NULL,
                                   schema_name = "ExtractedData",
                                   strict = TRUE,
                                   instructions = NULL,
                                   body_columns = NULL,
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
  if (!is.null(schema) && !is.list(schema)) {
    cli::cli_abort("{.arg schema} must be a JSON Schema represented as an R list.")
  }
  if (!is.null(schema)) {
    foundry_check_character_scalar(schema_name, "schema_name")
    if (!is.logical(strict) || length(strict) != 1L || is.na(strict)) {
      cli::cli_abort("{.arg strict} must be TRUE or FALSE.")
    }
  }
  if (!is.null(instructions)) {
    foundry_check_character_scalar(instructions, "instructions")
  }
  if (!is.null(body_columns)) {
    if (!is.character(body_columns) || any(is.na(body_columns))) {
      cli::cli_abort("{.arg body_columns} must be a character vector.")
    }
    missing_cols <- setdiff(body_columns, names(data))
    if (length(missing_cols) > 0L) {
      cli::cli_abort("Column(s) {.field {missing_cols}} were not found in {.arg data}.")
    }
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

  text_format <- NULL
  if (!is.null(schema)) {
    text_format <- foundry_json_schema_format(
      schema = as_foundry_schema(schema),
      schema_name = schema_name,
      strict = strict
    )
  }

  lines <- purrr::map2_chr(ids, seq_along(prompts), function(id, row_idx) {
    prompt <- prompts[[row_idx]]
    request_body <- c(list(model = model, input = prompt), body)
    if (!is.null(instructions)) {
      request_body$instructions <- instructions
    }
    if (!is.null(text_format)) {
      request_body$text <- list(format = text_format)
    }
    if (!is.null(body_columns)) {
      for (col in body_columns) {
        request_body[[col]] <- data[[col]][[row_idx]]
      }
    }
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


#' Parse completed Microsoft Foundry batch results
#'
#' Retrieve a batch, download its output and error JSONL files, and parse each
#' request result into a tibble. Responses, chat-completions, and embeddings
#' payloads are parsed into endpoint-specific columns when possible.
#'
#' @param batch_id Character. Batch ID to retrieve.
#' @param keep_raw Logical. Whether to keep the raw JSONL result object in a
#'   `raw_batch_result` list-column.
#' @inheritParams foundry_batch_create
#'
#' @return A tibble with one row per batch request.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_batch_results("batch_abc123")
#' }
foundry_batch_results <- function(batch_id,
                                  keep_raw = FALSE,
                                  api_key = NULL,
                                  token = NULL,
                                  endpoint_url = NULL,
                                  api_version = NULL) {
  batch <- foundry_batch_get(
    batch_id,
    api_key = api_key,
    token = token,
    endpoint_url = endpoint_url,
    api_version = api_version
  )

  endpoint <- batch$endpoint[[1]] %||% NA_character_
  rows <- list()

  output_file_id <- batch$output_file_id[[1]]
  if (!is.na(output_file_id) && nzchar(output_file_id)) {
    output_lines <- foundry_file_content_lines(
      output_file_id,
      api_key = api_key,
      token = token,
      endpoint = endpoint_url,
      api_version = api_version
    )
    rows <- c(rows, foundry_parse_batch_lines(output_lines, endpoint, keep_raw))
  }

  error_file_id <- batch$error_file_id[[1]]
  if (!is.na(error_file_id) && nzchar(error_file_id)) {
    error_lines <- foundry_file_content_lines(
      error_file_id,
      api_key = api_key,
      token = token,
      endpoint = endpoint_url,
      api_version = api_version
    )
    rows <- c(rows, foundry_parse_batch_lines(error_lines, endpoint, keep_raw))
  }

  if (length(rows) == 0L) {
    return(foundry_empty_batch_results(keep_raw = keep_raw))
  }

  out <- dplyr::bind_rows(rows)
  row_num <- suppressWarnings(as.integer(sub("^row-", "", out$custom_id)))
  if (!all(is.na(row_num))) {
    out <- out[order(is.na(row_num), row_num, out$custom_id), , drop = FALSE]
  }
  tibble::as_tibble(out)
}


#' Wait for a Microsoft Foundry batch to finish
#'
#' Poll a batch until it reaches a terminal state.
#'
#' @param batch_id Character. Batch ID to poll.
#' @param interval Numeric. Seconds between polling attempts.
#' @param timeout Numeric. Maximum seconds to wait. Use `Inf` to wait
#'   indefinitely.
#' @inheritParams foundry_batch_create
#'
#' @return The final one-row batch tibble.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_batch_wait("batch_abc123", interval = 60)
#' }
foundry_batch_wait <- function(batch_id,
                               interval = 60,
                               timeout = Inf,
                               api_key = NULL,
                               token = NULL,
                               endpoint_url = NULL,
                               api_version = NULL) {
  foundry_check_character_scalar(batch_id, "batch_id")
  if (!is.numeric(interval) || length(interval) != 1L || is.na(interval) ||
      interval < 0) {
    cli::cli_abort("{.arg interval} must be a non-negative number.")
  }
  if (!is.numeric(timeout) || length(timeout) != 1L || is.na(timeout) ||
      timeout < 0) {
    cli::cli_abort("{.arg timeout} must be a non-negative number or Inf.")
  }

  started <- Sys.time()
  terminal <- c("completed", "failed", "expired", "cancelled")
  repeat {
    batch <- foundry_batch_get(
      batch_id,
      api_key = api_key,
      token = token,
      endpoint_url = endpoint_url,
      api_version = api_version
    )
    status <- batch$status[[1]]
    if (!is.na(status) && status %in% terminal) {
      return(batch)
    }
    if (is.finite(timeout) &&
        as.numeric(difftime(Sys.time(), started, units = "secs")) >= timeout) {
      cli::cli_abort("Timed out waiting for batch {.val {batch_id}}.")
    }
    if (interval > 0) Sys.sleep(interval)
  }
}


#' Extract structured data with the Batch API
#'
#' Prepare JSONL requests for structured extraction, upload them, and create a
#' batch. With `wait = TRUE`, waits for completion and returns parsed results
#' joined back to the input rows.
#'
#' @param data Data frame containing input rows.
#' @param text_col Character. Name of the column containing input text.
#' @param schema List. JSON Schema object for structured extraction.
#' @param wait Logical. Whether to block until the batch reaches a terminal
#'   state and parse results.
#' @param path Character. Optional JSONL path. Defaults to a temporary file.
#' @inheritParams foundry_batch_requests
#' @inheritParams foundry_batch_create
#'
#' @return A batch tibble when `wait = FALSE`, or parsed result rows when
#'   `wait = TRUE`.
#' @export
#'
#' @examples
#' \dontrun{
#' jobs <- data.frame(text = c("Great service.", "Slow support."))
#' schema <- foundry_schema(sentiment = schema_string())
#' foundry_extract_batch(jobs, text_col = "text", schema = schema, model = "gpt-5-nano")
#' }
foundry_extract_batch <- function(data,
                                  text_col,
                                  schema,
                                  model,
                                  wait = FALSE,
                                  path = tempfile(fileext = ".jsonl"),
                                  schema_name = "ExtractedData",
                                  strict = TRUE,
                                  instructions = NULL,
                                  completion_window = "24h",
                                  api_key = NULL,
                                  token = NULL,
                                  endpoint_url = NULL,
                                  api_version = NULL) {
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame.")
  }
  if (!is.logical(wait) || length(wait) != 1L || is.na(wait)) {
    cli::cli_abort("{.arg wait} must be TRUE or FALSE.")
  }

  request_info <- foundry_batch_requests(
    data = data,
    input = text_col,
    path = path,
    model = model,
    schema = schema,
    schema_name = schema_name,
    strict = strict,
    instructions = instructions,
    overwrite = TRUE
  )

  file <- foundry_file_upload(
    request_info$path,
    purpose = "batch",
    api_key = api_key,
    token = token,
    endpoint = endpoint_url,
    api_version = api_version
  )
  batch <- foundry_batch_create(
    file$file_id,
    endpoint = request_info$endpoint,
    completion_window = completion_window,
    api_key = api_key,
    token = token,
    endpoint_url = endpoint_url,
    api_version = api_version
  )

  if (!isTRUE(wait)) {
    return(batch)
  }

  final <- foundry_batch_wait(
    batch$batch_id,
    api_key = api_key,
    token = token,
    endpoint_url = endpoint_url,
    api_version = api_version
  )
  results <- foundry_batch_results(
    final$batch_id,
    api_key = api_key,
    token = token,
    endpoint_url = endpoint_url,
    api_version = api_version
  )
  row_idx <- suppressWarnings(as.integer(sub("^row-", "", results$custom_id)))
  if (all(!is.na(row_idx))) {
    return(dplyr::bind_cols(tibble::as_tibble(data)[row_idx, , drop = FALSE], results))
  }
  results
}


#' Summarise token usage for foundryR results
#'
#' Sum token columns returned by foundryR chat, Responses, extraction, and batch
#' helpers. Pass your own `rates` to compute spend; foundryR does not hardcode
#' Azure prices because they change over time.
#'
#' @param x Data frame with foundryR token columns.
#' @param rates Optional named numeric vector with any of `input`,
#'   `cached_input`, and `output` rates per token.
#'
#' @return A one-row tibble with token totals and optional `cost`.
#' @export
#'
#' @examples
#' responses <- data.frame(
#'   input_tokens = c(10, 20),
#'   cached_input_tokens = c(0, 5),
#'   output_tokens = c(3, 7)
#' )
#' foundry_usage(responses)
#' foundry_usage(
#'   responses,
#'   rates = c(input = 0.000001, cached_input = 0.0000001, output = 0.000004)
#' )
foundry_usage <- function(x, rates = NULL) {
  if (!is.data.frame(x)) {
    cli::cli_abort("{.arg x} must be a data frame.")
  }
  if (!is.null(rates) && (!is.numeric(rates) || is.null(names(rates)))) {
    cli::cli_abort("{.arg rates} must be a named numeric vector.")
  }

  input_tokens <- foundry_sum_columns(x, c("input_tokens", "prompt_tokens"))
  cached_input_tokens <- foundry_sum_columns(x, "cached_input_tokens")
  output_tokens <- foundry_sum_columns(x, c("output_tokens", "completion_tokens"))
  total_tokens <- foundry_sum_columns(x, "total_tokens")
  if (is.na(total_tokens)) {
    total_tokens <- sum(input_tokens, output_tokens, na.rm = TRUE)
  }

  out <- tibble::tibble(
    input_tokens = input_tokens,
    cached_input_tokens = cached_input_tokens,
    output_tokens = output_tokens,
    total_tokens = total_tokens
  )

  if (!is.null(rates)) {
    cost <- 0
    if ("input" %in% names(rates)) cost <- cost + input_tokens * rates[["input"]]
    if ("cached_input" %in% names(rates)) {
      cost <- cost + cached_input_tokens * rates[["cached_input"]]
    }
    if ("output" %in% names(rates)) cost <- cost + output_tokens * rates[["output"]]
    out$cost <- cost
  }

  out
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


foundry_file_content_lines <- function(file_id,
                                       api_key = NULL,
                                       token = NULL,
                                       endpoint = NULL,
                                       api_version = NULL) {
  req <- foundry_build_v1_request(
    path = paste0("files/", file_id, "/content"),
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )
  raw <- foundry_perform_raw(req)
  text <- rawToChar(raw)
  lines <- strsplit(text, "\r?\n", perl = TRUE)[[1]]
  lines[nzchar(lines)]
}


foundry_parse_batch_lines <- function(lines, endpoint, keep_raw) {
  purrr::map(lines, function(line) {
    item <- jsonlite::fromJSON(line, simplifyVector = FALSE)
    foundry_parse_batch_item(item, endpoint, keep_raw)
  })
}


foundry_parse_batch_item <- function(item, endpoint, keep_raw) {
  response <- item$response %||% list()
  body <- response$body %||% list()
  error <- item$error %||% response$error %||% body$error
  status_code <- as.integer(response$status_code %||% NA_integer_)
  is_error <- !is.null(error) || (!is.na(status_code) && status_code >= 400L)
  error_msg <- if (is.null(error)) {
    NA_character_
  } else {
    foundry_batch_error_message(error)
  }

  base <- tibble::tibble(
    custom_id = item$custom_id %||% NA_character_,
    .status_code = status_code,
    .error = is_error,
    .error_msg = error_msg
  )
  if (keep_raw) {
    base$raw_batch_result <- list(item)
  }

  if (length(body) == 0L || isTRUE(is_error)) {
    base$raw_response <- list(body)
    return(base)
  }

  parsed <- foundry_parse_batch_body(body, endpoint)
  dplyr::bind_cols(base, parsed)
}


foundry_parse_batch_body <- function(body, endpoint) {
  endpoint <- endpoint %||% ""
  if (grepl("responses", endpoint, fixed = TRUE)) {
    return(foundry_parse_response(body, parse_json = TRUE))
  }
  if (grepl("chat/completions", endpoint, fixed = TRUE)) {
    out <- foundry_parse_chat_response(body, body$model %||% NA_character_)
    out$raw_response <- list(body)
    return(out)
  }
  if (grepl("embeddings", endpoint, fixed = TRUE)) {
    data <- body$data %||% list()
    first <- if (length(data) == 0L) list() else data[[1]]
    embedding <- unlist(first$embedding %||% list(), use.names = FALSE)
    return(tibble::tibble(
      embedding = list(embedding),
      n_dims = length(embedding),
      prompt_tokens = as.integer(body$usage$prompt_tokens %||% NA_integer_),
      total_tokens = as.integer(body$usage$total_tokens %||% NA_integer_),
      raw_response = list(body)
    ))
  }

  tibble::tibble(raw_response = list(body))
}


foundry_batch_error_message <- function(error) {
  if (is.list(error)) {
    return(error$message %||% error$code %||% "Batch request failed.")
  }
  as.character(error)
}


foundry_empty_batch_results <- function(keep_raw = FALSE) {
  out <- tibble::tibble(
    custom_id = character(),
    .status_code = integer(),
    .error = logical(),
    .error_msg = character(),
    raw_response = list()
  )
  if (keep_raw) out$raw_batch_result <- list()
  out
}


foundry_sum_columns <- function(x, cols) {
  present <- intersect(cols, names(x))
  if (length(present) == 0L) {
    return(NA_real_)
  }
  sum(unlist(x[present], use.names = FALSE), na.rm = TRUE)
}
