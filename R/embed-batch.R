#' Generate Text Embeddings in Parallel Batches
#'
#' Generate embedding vectors for a large collection of texts using parallel
#' batch processing. This function is optimized for high-throughput embedding
#' generation, using `httr2::req_perform_parallel()` to process multiple
#' batches concurrently while tracking errors gracefully.
#'
#' @param text Character vector. The texts to embed.
#' @param model Character. The deployment name of an embedding model.
#'   Defaults to the environment variable `AZURE_FOUNDRY_EMBED_MODEL`.
#' @param dimensions Integer. Optional. The number of dimensions for the output
#'   embeddings. Only supported by some models (e.g., text-embedding-3).
#' @param batch_size Integer. Number of texts to include in each batch request.
#'   Default: 100.
#' @param max_active Integer. Maximum number of concurrent requests. Default: 2.
#' @param progress Logical. Whether to show a progress bar. Defaults to
#'   `getOption("foundryR.progress", interactive())`.
#' @param api Character. Endpoint style. `"v1"` (default) sends requests to
#'   `/openai/v1/embeddings` with `model` in the JSON body. `"deployment"` keeps
#'   the legacy deployment-path endpoint.
#' @param api_key Character. Optional API key override.
#' @param api_version Character. Optional API version override.
#'
#' @return A tibble with columns:
#'   \describe{
#'     \item{.input_idx}{Integer. The original index of each text in the input vector.}
#'     \item{text}{Character. The original input text.}
#'     \item{embedding}{List. A numeric vector containing the embedding, or NULL if failed.
#'       May contain multiple embeddings per batch response.}
#'     \item{n_dims}{Integer. The dimensionality of the embedding, or NA if failed.}
#'     \item{.error}{Logical. TRUE if the request for this text failed.}
#'     \item{.error_msg}{Character. Error message if failed, NA otherwise.}
#'     \item{raw_response}{List. Raw parsed response payload for successful rows,
#'       or NULL for failed rows.}
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Requires a configured Azure endpoint and credentials,
#' # plus an embedding deployment.
#' # Embed many texts in parallel
#' texts <- c("Hello, world!", "Data science is fun", "R is great")
#' embeddings <- foundry_embed_batch(texts, model = "text-embedding-ada-002")
#'
#' # With custom batch size and concurrency
#' large_texts <- rep("Sample text", 1000)
#' embeddings <- foundry_embed_batch(
#'   large_texts,
#'   model = "text-embedding-ada-002",
#'   batch_size = 50,
#'   max_active = 2
#' )
#'
#' # Filter successful embeddings
#' successful <- embeddings[!embeddings$.error, ]
#'
#' # Check for errors
#' failed <- embeddings[embeddings$.error, ]
#' if (nrow(failed) > 0) {
#'   message("Some embeddings failed:")
#'   print(failed[, c(".input_idx", ".error_msg")])
#' }
#' }
foundry_embed_batch <- function(text,
                                 model = NULL,
                                 dimensions = NULL,
                                 batch_size = 100L,
                                 max_active = 2L,
                                 progress = getOption("foundryR.progress", interactive()),
                                 api = c("v1", "deployment"),
                                 api_key = NULL,
                                 api_version = NULL) {

  # Get model/deployment
  if (is.null(model)) {
    model <- Sys.getenv("AZURE_FOUNDRY_EMBED_MODEL")
    if (model == "") {
      cli::cli_abort(c(
        "Embedding model/deployment name is required.",
        "i" = "Specify {.arg model} or set the {.envvar AZURE_FOUNDRY_EMBED_MODEL} environment variable."
      ))
    }
  }

  # Warn if model name looks like a chat model
  warn_if_chat_model(model, "foundry_embed_batch")

  # Validate inputs
  if (!is.character(text)) {
    cli::cli_abort("{.arg text} must be a character vector.")
  }

  batch_size <- as.integer(batch_size)
  max_active <- as.integer(max_active)
  api <- match.arg(api)

  if (batch_size < 1L) {
    cli::cli_abort("{.arg batch_size} must be at least 1.")
  }

  if (max_active < 1L) {
    cli::cli_abort("{.arg max_active} must be at least 1.")
  }

  # Handle empty input
  if (length(text) == 0) {
    return(tibble::tibble(
      .input_idx = integer(),
      text = character(),
      embedding = list(),
      n_dims = integer(),
      .error = logical(),
      .error_msg = character(),
      raw_response = list()
    ))
  }

  # Split text into batches with their original indices
  valid_idx <- which(!is.na(text) & nzchar(text))
  invalid_idx <- which(is.na(text) | !nzchar(text))
  batches <- batch_indexed_vector(text, valid_idx, batch_size)

  # Build requests for each batch
  requests <- purrr::map(batches, function(batch_info) {
    # Build request body - Azure OpenAI accepts array of inputs
    body <- list(input = batch_info$values)
    if (identical(api, "v1")) {
    body$model <- model
    }
    if (!is.null(dimensions)) {
    body$dimensions <- dimensions
    }

    if (identical(api, "v1")) {
    foundry_build_v1_request(
      path = "embeddings",
      body = body,
      api_key = api_key,
      api_version = api_version
    )
    } else {
    body$model <- NULL
    foundry_build_request(
      deployment = model,
      endpoint_path = "embeddings",
      body = body,
      api_key = api_key,
      api_version = api_version
    )
    }
  })

  # Perform all requests, capturing per-request errors (see
  # foundry_req_perform_many for the parallel/sequential switch).
  responses <- foundry_req_perform_many(
    requests,
    progress = progress,
    max_active = max_active
  )
  if (length(responses) != length(batches)) {
    cli::cli_abort("Expected one embedding response per request batch.")
  }

  # Fill output columns by original position, without one-row tibble allocation.
  n <- length(text)
  embeddings <- vector("list", n)
  n_dims <- rep(NA_integer_, n)
  errors <- rep(FALSE, n)
  error_msg <- rep(NA_character_, n)
  raw_response <- vector("list", n)

  for (batch_idx in seq_along(responses)) {
    resp <- responses[[batch_idx]]
    indices <- batches[[batch_idx]]$indices

    # Check if response is an error (check class first, before calling resp_is_error)
    is_error_obj <- inherits(resp, "error") || inherits(resp, "httr2_failure")
    is_http_error <- !is_error_obj && httr2::resp_is_error(resp)

    if (is_error_obj || is_http_error) {
      message <- if (is_error_obj) {
        conditionMessage(resp)
      } else {
        foundry_error_message(resp)
      }

      errors[indices] <- TRUE
      error_msg[indices] <- message
      next
    }

    # Parse successful response
    result <- tryCatch(
      httr2::resp_body_json(resp),
      error = function(e) NULL
    )

    if (is.null(result) || is.null(result$data)) {
      errors[indices] <- TRUE
      error_msg[indices] <- "Failed to parse response"
      next
    }

    emb_data <- result$data
    # Match the zero-based indices once. Repeated detect() scans were quadratic
    # in batch size; match() also preserves the first match for duplicate indices.
    response_indices <- vapply(emb_data, function(entry) {
      index <- entry$index
      if (is.numeric(index) && length(index) == 1L) index else NA_real_
    }, numeric(1), USE.NAMES = FALSE)
    matches <- match(seq_along(indices) - 1L, response_indices)
    entries <- emb_data[matches]
    vectors <- lapply(entries, function(entry) unlist(entry$embedding))
    missing <- is.na(matches)
    embeddings[indices] <- vectors
    n_dims[indices] <- lengths(vectors)
    n_dims[indices[missing]] <- NA_integer_
    errors[indices] <- missing
    error_msg[indices[missing]] <- "Embedding not found in response"
    raw_response[indices] <- lapply(entries, foundry_embedding_row_response, result = result)
  }

  if (length(invalid_idx) > 0L) {
    invalid_msg <- vapply(text[invalid_idx], function(value) {
      if (is.na(value)) "Input text is NA." else "Input text is empty."
    }, character(1), USE.NAMES = FALSE)
    errors[invalid_idx] <- TRUE
    error_msg[invalid_idx] <- invalid_msg
  }

  tibble::tibble(
    .input_idx = seq_along(text),
    text = text,
    embedding = embeddings,
    n_dims = n_dims,
    .error = errors,
    .error_msg = error_msg,
    raw_response = raw_response
  )
}


foundry_embedding_row_response <- function(result, emb_entry) {
  row_data <- emb_entry %||% list()
  row_data$embedding <- NULL
  list(
    object = result$object %||% NA_character_,
    model = result$model %||% NA_character_,
    usage = result$usage %||% NULL,
    data = list(row_data)
  )
}


#' Split Vector into Batches with Indices
#'
#' Internal helper function to split a vector into batches, preserving
#' the original indices of each element.
#'
#' @param x A vector to split into batches.
#' @param batch_size Integer. The maximum size of each batch.
#'
#' @return A list of lists, where each element contains:
#'   \describe{
#'     \item{indices}{Integer vector of original indices for this batch.}
#'     \item{values}{The corresponding values from the input vector.}
#'   }
#'
#' @keywords internal
#' @noRd
batch_vector <- function(x, batch_size) {
  n <- length(x)
  if (n == 0) {
    return(list())
  }

  # Calculate number of batches
  n_batches <- ceiling(n / batch_size)

  # Create batch list
  purrr::map(seq_len(n_batches), function(i) {
    start_idx <- (i - 1) * batch_size + 1
    end_idx <- min(i * batch_size, n)
    indices <- seq(start_idx, end_idx)

    list(
      indices = indices,
      values = x[indices]
    )
  })
}


batch_indexed_vector <- function(x, indices, batch_size) {
  if (length(indices) == 0L) {
    return(list())
  }

  n_batches <- ceiling(length(indices) / batch_size)
  purrr::map(seq_len(n_batches), function(i) {
    start_idx <- (i - 1L) * batch_size + 1L
    end_idx <- min(i * batch_size, length(indices))
    batch_indices <- indices[seq.int(start_idx, end_idx)]
    list(
      indices = batch_indices,
      values = x[batch_indices]
    )
  })
}
