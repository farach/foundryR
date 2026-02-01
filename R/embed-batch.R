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
#' @param max_active Integer. Maximum number of concurrent requests. Default: 10.
#' @param progress Logical. Whether to show a progress bar. Default: TRUE.
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
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
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
#'   max_active = 5
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
                                 max_active = 10L,
                                 progress = TRUE,
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
      .error_msg = character()
    ))
  }

  # Split text into batches with their original indices
  batches <- batch_vector(text, batch_size)

  # Build requests for each batch
  requests <- purrr::map(batches, function(batch_info) {
    # Build request body - Azure OpenAI accepts array of inputs
    body <- list(input = batch_info$values)
    if (!is.null(dimensions)) {
      body$dimensions <- dimensions
    }

    foundry_build_request(
      deployment = model,
      endpoint_path = "embeddings",
      body = body,
      api_key = api_key,
      api_version = api_version
    )
  })

  # Perform all requests in parallel
  responses <- httr2::req_perform_parallel(
    requests,
    on_error = "continue",
    progress = progress
  )

  # Process responses and combine results
  results <- purrr::imap_dfr(responses, function(resp, batch_idx) {
    batch_info <- batches[[batch_idx]]
    indices <- batch_info$indices
    values <- batch_info$values

    # Check if response is an error (check class first, before calling resp_is_error)
    is_error_obj <- inherits(resp, "error") || inherits(resp, "httr2_failure")
    is_http_error <- !is_error_obj && httr2::resp_is_error(resp)

    if (is_error_obj || is_http_error) {
      error_msg <- if (is_error_obj) {
        conditionMessage(resp)
      } else {
        tryCatch(
          foundry_error_body(resp),
          error = function(e) "Unknown error"
        )
      }

      # Return error rows for all texts in this batch
      return(tibble::tibble(
        .input_idx = indices,
        text = values,
        embedding = replicate(length(indices), NULL, simplify = FALSE),
        n_dims = rep(NA_integer_, length(indices)),
        .error = rep(TRUE, length(indices)),
        .error_msg = rep(error_msg, length(indices))
      ))
    }

    # Parse successful response
    result <- tryCatch(
      httr2::resp_body_json(resp),
      error = function(e) NULL
    )

    if (is.null(result) || is.null(result$data)) {
      return(tibble::tibble(
        .input_idx = indices,
        text = values,
        embedding = replicate(length(indices), NULL, simplify = FALSE),
        n_dims = rep(NA_integer_, length(indices)),
        .error = rep(TRUE, length(indices)),
        .error_msg = rep("Failed to parse response", length(indices))
      ))
    }

    # Extract embeddings from response
    # Azure returns embeddings in order with index field
    emb_data <- result$data

    # Create output tibble for this batch
    purrr::map_dfr(seq_along(indices), function(i) {
      idx <- indices[i]
      txt <- values[i]

      # Find matching embedding by index (Azure returns 0-based index)
      emb_entry <- purrr::detect(emb_data, ~ .x$index == (i - 1))

      if (is.null(emb_entry)) {
        return(tibble::tibble(
          .input_idx = idx,
          text = txt,
          embedding = list(NULL),
          n_dims = NA_integer_,
          .error = TRUE,
          .error_msg = "Embedding not found in response"
        ))
      }

      emb_vec <- unlist(emb_entry$embedding)

      tibble::tibble(
        .input_idx = idx,
        text = txt,
        embedding = list(emb_vec),
        n_dims = length(emb_vec),
        .error = FALSE,
        .error_msg = NA_character_
      )
    })
  })

  # Sort by original index and return
  results %>%
    dplyr::arrange(.input_idx)
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
#'
#' @examples
#' \dontrun{
#' x <- letters[1:7]
#' batches <- batch_vector(x, batch_size = 3)
#' # Returns:
#' # [[1]] list(indices = 1:3, values = c("a", "b", "c"))
#' # [[2]] list(indices = 4:6, values = c("d", "e", "f"))
#' # [[3]] list(indices = 7, values = "g")
#' }
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
