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
#' @param batch_size Integer. Number of texts to include in each request.
#'   Default: 100.
#' @param api Character. Endpoint style. `"v1"` (default) sends requests to
#'   `/openai/v1/embeddings` with `model` in the JSON body. `"deployment"` keeps
#'   the legacy deployment-path endpoint.
#' @param api_key Character. Optional API key override.
#' @param api_version Character. Optional API version override.
#'
#' @return A tibble with columns:
#'   \describe{
#'     \item{text}{Character. The original input text.}
#'     \item{embedding}{List. A numeric vector containing the embedding.}
#'     \item{n_dims}{Integer. The dimensionality of the embedding.}
#'     \item{.input_idx}{Integer. Original input index.}
#'     \item{.error}{Logical. Whether the row failed.}
#'     \item{.error_msg}{Character. Error message for failed rows.}
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
                           batch_size = 100L,
                           api = c("v1", "deployment"),
                           api_key = NULL,
                           api_version = NULL) {
  foundry_embed_batch(
    text = text,
    model = model,
    dimensions = dimensions,
    batch_size = batch_size,
    max_active = 1L,
    progress = FALSE,
    api = api,
    api_key = api_key,
    api_version = api_version
  )
}


#' Compute Cosine Similarity Between Embeddings
#'
#' Compute pairwise cosine similarity between all embeddings in a tibble.
#' Useful for finding semantically similar texts.
#'
#' @param data A tibble from `foundry_embed()` containing an `embedding` list-column.
#' @param text_col Character. Name of the column containing text labels. Default: "text".
#' @param top_k Integer. Optional maximum number of most-similar pairs to return.
#' @param as_matrix Logical. If `TRUE`, return the full cosine-similarity matrix
#'   instead of a long pairwise tibble.
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
foundry_similarity <- function(data,
                               text_col = "text",
                               top_k = NULL,
                               as_matrix = FALSE) {

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
  if (!is.logical(as_matrix) || length(as_matrix) != 1L || is.na(as_matrix)) {
    cli::cli_abort("{.arg as_matrix} must be TRUE or FALSE.")
  }
  if (!is.null(top_k)) {
    top_k <- as.integer(top_k)
    if (is.na(top_k) || top_k < 1L) {
      cli::cli_abort("{.arg top_k} must be a positive integer or NULL.")
    }
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
  labels <- data[[text_col]]
  sim_mat <- tcrossprod(unit)
  dimnames(sim_mat) <- list(labels, labels)

  if (isTRUE(as_matrix)) {
    return(sim_mat)
  }

  # Extract the upper triangle (i < j) as the unique pairs.
  pairs <- which(upper.tri(sim_mat), arr.ind = TRUE)

  out <- tibble::tibble(
    text_1 = labels[pairs[, "row"]],
    text_2 = labels[pairs[, "col"]],
    similarity = sim_mat[pairs]
  ) |>
    dplyr::arrange(dplyr::desc(similarity))

  if (!is.null(top_k)) {
    out <- utils::head(out, top_k)
  }

  out
}
