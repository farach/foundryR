#' Generate Text Embeddings
#'
#' Generate embedding vectors for one or more text inputs using an Azure AI
#' Foundry deployed embedding model. Returns a tibble with the input text
#' and corresponding embedding vectors stored as a list-column.
#'
#' @param text Character vector. The text(s) to embed.
#' @param model Character. The deployment name of an embedding model.
#'   Defaults to the environment variable `AZURE_FOUNDRY_EMBED_MODEL`.
#' @param dimensions Integer. Optional. The number of dimensions for the output
#'   embeddings. Only supported by some models (e.g., text-embedding-3).
#' @param api_key Character. Optional API key override.
#' @param api_version Character. Optional API version override.
#'
#' @return A tibble with columns:
#'   \describe{
#'     \item{text}{Character. The original input text.}
#'     \item{embedding}{List. A numeric vector containing the embedding.}
#'     \item{n_dims}{Integer. The dimensionality of the embedding.}
#'   }
#'
#' @details
#' **Important**: The `model` parameter must be a deployment of an **embedding model**,
#' not a chat model. Common embedding models include:
#' - `text-embedding-ada-002`
#' - `text-embedding-3-small`
#' - `text-embedding-3-large`
#'
#' Chat models (GPT-4, Claude, Llama, etc.) cannot generate embeddings.
#' If you only have chat models deployed, you'll need to deploy an embedding
#' model in Azure AI Foundry first.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Single text
#' foundry_embed("Hello, world!", model = "text-embedding-ada-002")
#'
#' # Multiple texts
#' texts <- c("Data science is fun", "R is great for statistics")
#' foundry_embed(texts, model = "text-embedding-ada-002")
#'
#' # With reduced dimensions (model-dependent)
#' foundry_embed("Hello", model = "text-embedding-3-small", dimensions = 256)
#' }
foundry_embed <- function(text,
                           model = NULL,
                           dimensions = NULL,
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

  warn_if_chat_model(model, "foundry_embed")

  # Handle empty input
  if (length(text) == 0) {
    return(tibble::tibble(
      text = character(),
      embedding = list(),
      n_dims = integer()
    ))
  }

  # Vectorize over inputs
  purrr::map_dfr(seq_along(text), function(i) {
    single_text <- text[i]

    # Handle NA values
    if (is.na(single_text)) {
      return(tibble::tibble(
        text = NA_character_,
        embedding = list(NULL),
        n_dims = NA_integer_
      ))
    }

    # Build request body
    body <- list(input = single_text)
    if (!is.null(dimensions)) {
      body$dimensions <- dimensions
    }

    # Build and perform request
    req <- foundry_build_request(
      deployment = model,
      endpoint_path = "embeddings",
      body = body,
      api_key = api_key,
      api_version = api_version
    )

    result <- tryCatch(
      foundry_perform(req),
      error = function(e) {
        cli::cli_warn("Failed to embed text at index {i}: {conditionMessage(e)}")
        return(NULL)
      }
    )

    if (is.null(result)) {
      return(tibble::tibble(
        text = single_text,
        embedding = list(NULL),
        n_dims = NA_integer_
      ))
    }

    # Extract embedding vector
    emb_data <- result$data[[1]]
    emb_vec <- unlist(emb_data$embedding)

    tibble::tibble(
      text = single_text,
      embedding = list(emb_vec),
      n_dims = length(emb_vec)
    )
  })
}


#' Compute Cosine Similarity Between Embeddings
#'
#' Compute pairwise cosine similarity between all embeddings in a tibble.
#' Useful for finding semantically similar texts.
#'
#' @param data A tibble from `foundry_embed()` containing an `embedding` list-column.
#' @param text_col Character. Name of the column containing text labels. Default: "text".
#'
#' @return A tibble with columns:
#'   \describe{
#'     \item{text_1}{Character. First text.}
#'     \item{text_2}{Character. Second text.}
#'     \item{similarity}{Numeric. Cosine similarity between -1 and 1.}
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' texts <- c("I love R", "R is my favorite language", "Python is also good")
#' embeddings <- foundry_embed(texts, model = "text-embedding-ada-002")
#' foundry_similarity(embeddings)
#' }
foundry_similarity <- function(data, text_col = "text") {

  if (!inherits(data, "data.frame")) {
    cli::cli_abort("{.arg data} must be a data frame or tibble.")
  }

  if (!"embedding" %in% names(data)) {
    cli::cli_abort("{.arg data} must contain an {.field embedding} column from {.fun foundry_embed}.")
  }

  if (!text_col %in% names(data)) {
    cli::cli_abort("Column {.field {text_col}} not found in data.")
  }

  n <- nrow(data)
  if (n < 2) {
    cli::cli_abort("Need at least 2 rows to compute similarity.")
  }

  # Filter out rows with NULL embeddings
  valid_idx <- vapply(data$embedding, function(x) !is.null(x) && length(x) > 0, logical(1))
  if (sum(valid_idx) < 2) {
    cli::cli_abort("Need at least 2 valid embeddings to compute similarity.")
  }

  data <- data[valid_idx, ]
  n <- nrow(data)

  # All embeddings must share the same dimensionality to be comparable.
  dims <- lengths(data$embedding)
  if (length(unique(dims)) > 1) {
    cli::cli_abort(c(
      "All embeddings must have the same dimensionality.",
      "i" = "Found embeddings with {length(unique(dims))} different lengths."
    ))
  }

  # Stack embeddings into an n x d matrix (rows = texts) and compute all
  # pairwise cosine similarities with a single matrix product. This replaces
  # the O(n^2) nested R loop and per-pair tibble allocation.
  mat <- matrix(unlist(data$embedding, use.names = FALSE), nrow = n, byrow = TRUE)

  norms <- sqrt(rowSums(mat^2))
  unit <- mat / norms
  sim_mat <- tcrossprod(unit)

  # Extract the upper triangle (i < j) as the unique pairs.
  pairs <- which(upper.tri(sim_mat), arr.ind = TRUE)
  labels <- data[[text_col]]

  tibble::tibble(
    text_1 = labels[pairs[, "row"]],
    text_2 = labels[pairs[, "col"]],
    similarity = sim_mat[pairs]
  ) %>%
    dplyr::arrange(dplyr::desc(similarity))
}
