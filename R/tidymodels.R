#' Foundry Embedding Recipe Step
#'
#' Create text embeddings using an Azure AI Foundry model as part of a tidymodels
#' recipe. This step converts text columns into embedding features for downstream
#' modeling tasks such as classification, regression, or clustering.
#'
#' @param recipe A recipe object. The step will be added to the sequence of
#'   operations for this recipe.
#' @param ... One or more text column selectors. See [recipes::selections()] for
#'   details on how to specify columns. Only columns containing character,
#'   string, or factor data types are supported.
#' @param role Character. Role for the new embedding variables.
#'   Default: `"predictor"`.
#' @param trained Logical. Internal use only. Indicates whether the step has been
#'   trained.
#' @param model Character. The deployment name of an Azure AI Foundry embedding
#'   model (e.g., "text-embedding-ada-002", "text-embedding-3-small"). If `NULL`,
#'   defaults to the `AZURE_FOUNDRY_EMBED_MODEL` environment variable.
#' @param dimensions Integer or NULL. The number of dimensions for the output
#'   embeddings. Only supported by some models (e.g., text-embedding-3-*).
#'   If `NULL`, uses the model's default dimensionality.
#' @param prefix Character. Prefix for the new embedding column names.
#'   Default: `"emb_"`. Columns will be named `{prefix}{original_col}_{1}`,
#'   `{prefix}{original_col}_{2}`, etc.
#' @param keep_original Logical. Should the original text column(s) be retained?
#'   Default: `FALSE`.
#' @param cache Character. Embedding cache mode. `"none"` (default) always calls
#'   the API; `"disk"` caches each text's embedding on disk (keyed on the text,
#'   model, and dimensions) so cross-validation folds and repeated bakes reuse
#'   embeddings instead of re-calling the API.
#' @param cache_dir Character. Directory for the disk cache. Defaults to
#'   `tools::R_user_dir("foundryR", "cache")`. Clear it with
#'   [foundry_cache_clear()].
#' @param columns Character vector. Internal use only. Stores column names after
#'   training.
#' @param skip Logical. Should the step be skipped when the recipe is baked?
#'   While all operations are baked when [recipes::prep()] is run, some
#'   operations may not be applicable to new data (e.g., processing the
#'   outcome variable). Default: `FALSE`.
#' @param id Character. Unique identifier for this step. Automatically generated
#'   if not provided.
#'
#' @return An updated recipe object with the new step appended to the sequence
#'   of existing steps.
#'
#' @details
#' This step uses [foundry_embed()] to generate embeddings for each text column
#' specified. During the `bake` phase, each text value is sent to the Azure AI
#' Foundry API, and the resulting embedding vector is expanded into multiple
#' numeric columns.
#'
#' ## Column naming
#' For a text column named `"description"` with 1536-dimensional embeddings and
#' the default prefix `"emb_"`, the output columns will be named:
#' `emb_description_1`, `emb_description_2`, ..., `emb_description_1536`.
#'
#' ## Handling failures
#' If an embedding request fails for a particular row (e.g., due to API errors),
#' the corresponding embedding columns will be filled with `NA` values for that
#' row.
#'
#' ## Performance considerations
#' Embedding generation requires API calls for each unique text value. For large
#' datasets or resampling, consider:
#' - Setting `cache = "disk"` so repeated bakes and cross-validation folds reuse
#'   embeddings instead of re-calling the API
#' - Using `skip = TRUE` during cross-validation to avoid redundant API calls
#' - Using batch processing strategies for very large datasets
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(recipes)
#'
#' # Sample data
#' df <- data.frame(
#'   text = c("Hello world", "Machine learning is great", "R is awesome"),
#'   category = c("greeting", "tech", "tech")
#' )
#'
#' # Create a recipe with Foundry embeddings
#' rec <- recipe(~ text, data = df) %>%
#'   step_foundry_embed(text, model = "text-embedding-ada-002")
#'
#' # Prepare and bake the recipe
#' prepped <- prep(rec, training = df)
#' baked <- bake(prepped, new_data = df)
#'
#' # With custom dimensions (model-dependent)
#' rec_custom <- recipe(~ text, data = df) %>%
#'   step_foundry_embed(
#'     text,
#'     model = "text-embedding-3-small",
#'     dimensions = 256,
#'     prefix = "vec_"
#'   )
#'
#' # Keep original text column
#' rec_keep <- recipe(~ text, data = df) %>%
#'   step_foundry_embed(text, model = "text-embedding-ada-002", keep_original = TRUE)
#'
#' # Use in a tidymodels workflow
#' library(tidymodels)
#'
#' wf <- workflow() %>%
#'   add_recipe(rec) %>%
#'   add_model(logistic_reg()) %>%
#'   fit(data = train_data)
#' }
#'
#' @seealso [foundry_embed()] for the underlying embedding function,
#'   [recipes::recipe()] for creating recipes,
#'   [recipes::prep()] and [recipes::bake()] for processing recipes.
#'
#' @family preprocessing steps
step_foundry_embed <- function(recipe,
                                ...,
                                role = "predictor",
                                trained = FALSE,
                                model = NULL,
                                dimensions = NULL,
                                prefix = "emb_",
                                keep_original = FALSE,
                                cache = c("none", "disk"),
                                cache_dir = NULL,
                                columns = NULL,
                                skip = FALSE,
                                id = recipes::rand_id("foundry_embed")) {

  if (!requireNamespace("recipes", quietly = TRUE)) {
    stop("Package 'recipes' required. Install with: install.packages('recipes')",
         call. = FALSE)
  }

  cache <- rlang::arg_match(cache)

  recipes::add_step(
    recipe,
    step_foundry_embed_new(
      terms = recipes::ellipse_check(...),
      role = role,
      trained = trained,
      model = model,
      dimensions = dimensions,
      prefix = prefix,
      keep_original = keep_original,
      cache = cache,
      cache_dir = cache_dir,
      columns = columns,
      skip = skip,
      id = id
    )
  )
}


#' Internal constructor for step_foundry_embed
#'
#' @param terms The terms from the recipe step
#' @param role Role for new variables
#' @param trained Whether the step has been trained
#' @param model Model deployment name
#' @param dimensions Number of embedding dimensions
#' @param prefix Column name prefix
#' @param keep_original Whether to keep original columns
#' @param columns Column names (after training)
#' @param skip Whether to skip during baking
#' @param id Unique step identifier
#'
#' @return A step_foundry_embed object
#' @noRd
step_foundry_embed_new <- function(terms,
                                    role,
                                    trained,
                                    model,
                                    dimensions,
                                    prefix,
                                    keep_original,
                                    cache,
                                    cache_dir,
                                    columns,
                                    skip,
                                    id) {
  recipes::step(
    subclass = "foundry_embed",
    terms = terms,
    role = role,
    trained = trained,
    model = model,
    dimensions = dimensions,
    prefix = prefix,
    keep_original = keep_original,
    cache = cache,
    cache_dir = cache_dir,
    columns = columns,
    skip = skip,
    id = id
  )
}


#' Prepare the Foundry embedding step
#'
#' @param x A `step_foundry_embed` object
#' @param training A tibble containing the training data
#' @param info A tibble with column metadata
#' @param ... Not used
#'
#' @return An updated `step_foundry_embed` object with `trained = TRUE`
#' @exportS3Method recipes::prep
prep.step_foundry_embed <- function(x, training, info = NULL, ...) {

  col_names <- recipes::recipes_eval_select(x$terms, training, info)

  # Validate that selected columns are text-like
  recipes::check_type(
    training[, col_names, drop = FALSE],
    types = c("string", "character", "factor", "nominal")
  )

  step_foundry_embed_new(
    terms = x$terms,
    role = x$role,
    trained = TRUE,
    model = x$model,
    dimensions = x$dimensions,
    prefix = x$prefix,
    keep_original = x$keep_original,
    cache = x$cache %||% "none",
    cache_dir = x$cache_dir,
    columns = col_names,
    skip = x$skip,
    id = x$id
  )
}


#' Apply the Foundry embedding step to new data
#'
#' @param object A trained `step_foundry_embed` object
#' @param new_data A tibble to apply the step to
#' @param ... Not used
#'
#' @return A tibble with embedding columns added (and optionally original
#'   text columns removed)
#' @exportS3Method recipes::bake
bake.step_foundry_embed <- function(object, new_data, ...) {

  col_names <- object$columns
  cache <- object$cache %||% "none"
  cache_dir <- object$cache_dir

  for (col_name in col_names) {
    # Convert factor to character (recipes formula interface converts char to factor)
    text_data <- as.character(new_data[[col_name]])

    # Generate embeddings (one array call per API request, disk cache optional)
    embeddings <- foundry_embed_cached(
      text = text_data,
      model = object$model,
      dimensions = object$dimensions,
      cache = cache,
      cache_dir = cache_dir
    )

    valid_idx <- vapply(
      embeddings,
      function(e) !is.null(e) && length(e) > 0,
      logical(1)
    )

    if (!any(valid_idx)) {
      cli::cli_abort(
        "No valid embeddings generated for column {.field {col_name}}."
      )
    }

    # Build the embedding matrix in one shot instead of a per-scalar fill loop.
    n_dims <- length(embeddings[[which(valid_idx)[1]]])
    emb_matrix <- matrix(NA_real_, nrow = length(text_data), ncol = n_dims)
    emb_matrix[valid_idx, ] <- do.call(rbind, embeddings[valid_idx])

    emb_col_names <- paste0(object$prefix, col_name, "_", seq_len(n_dims))
    colnames(emb_matrix) <- emb_col_names
    new_data <- dplyr::bind_cols(new_data, tibble::as_tibble(emb_matrix))

    # Remove original text column if not keeping
    if (!object$keep_original) {
      new_data[[col_name]] <- NULL
    }
  }

  new_data
}


#' Resolve the foundryR embedding cache directory
#'
#' @param cache_dir Character or NULL. Explicit cache directory.
#'
#' @return An absolute path to the cache directory.
#' @keywords internal
foundry_cache_dir <- function(cache_dir = NULL) {
  cache_dir %||% tools::R_user_dir("foundryR", "cache")
}


foundry_embed_cached <- function(text, model, dimensions, cache = "none", cache_dir = NULL) {
  if (!identical(cache, "disk")) {
    result <- foundry_embed(text = text, model = model, dimensions = dimensions)
    return(result$embedding)
  }

  cache_dir <- foundry_cache_dir(cache_dir)
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  }

  keys <- vapply(
    text,
    function(t) rlang::hash(list(t, model, dimensions)),
    character(1)
  )
  paths <- file.path(cache_dir, paste0(keys, ".rds"))

  embeddings <- vector("list", length(text))
  cached <- file.exists(paths)
  for (i in which(cached)) {
    embeddings[[i]] <- readRDS(paths[[i]])
  }

  missing_idx <- which(!cached)
  if (length(missing_idx) > 0) {
    unique_missing <- unique(text[missing_idx])
    fetched <- foundry_embed(
      text = unique_missing,
      model = model,
      dimensions = dimensions
    )
    fetched_by_text <- stats::setNames(fetched$embedding, fetched$text)
    for (i in missing_idx) {
      emb <- fetched_by_text[[text[[i]]]]
      embeddings[[i]] <- emb
      if (!is.null(emb) && length(emb) > 0) {
        saveRDS(emb, paths[[i]])
      }
    }
  }

  embeddings
}


#' Clear the foundryR embedding cache
#'
#' Delete cached embeddings written by [step_foundry_embed()] with
#' `cache = "disk"`.
#'
#' @param cache_dir Character. Cache directory. Defaults to
#'   `tools::R_user_dir("foundryR", "cache")`.
#'
#' @return Invisibly, the number of cache files removed.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_cache_clear()
#' }
foundry_cache_clear <- function(cache_dir = NULL) {
  cache_dir <- foundry_cache_dir(cache_dir)
  if (!dir.exists(cache_dir)) {
    return(invisible(0L))
  }
  files <- list.files(cache_dir, pattern = "\\.rds$", full.names = TRUE)
  removed <- sum(file.remove(files))
  cli::cli_inform("Removed {removed} cached embedding{?s} from {.path {cache_dir}}.")
  invisible(removed)
}


#' Print method for step_foundry_embed
#'
#' @param x A `step_foundry_embed` object
#' @param width Maximum width for printing
#' @param ... Not used
#'
#' @return Invisibly returns `x`
#' @export
print.step_foundry_embed <- function(x, width = max(20, options()$width - 30), ...) {
  title <- "Foundry embeddings for "

  if (recipes::is_trained(x)) {
    recipes::print_step(x$columns, x$terms, x$trained, title, width)
  } else {
    recipes::print_step(NULL, x$terms, x$trained, title, width)
  }

  invisible(x)
}


#' Tidy method for step_foundry_embed
#'
#' @param x A `step_foundry_embed` object
#' @param ... Not used
#'
#' @return A tibble with columns: `terms`, `model`, `dimensions`, `id`
#' @rdname step_foundry_embed
#' @exportS3Method generics::tidy
tidy.step_foundry_embed <- function(x, ...) {
  if (recipes::is_trained(x)) {
    res <- tibble::tibble(
      terms = x$columns,
      model = x$model %||% NA_character_,
      dimensions = x$dimensions %||% NA_integer_
    )
  } else {
    term_names <- recipes::sel2char(x$terms)
    res <- tibble::tibble(
      terms = term_names,
      model = x$model %||% NA_character_,
      dimensions = x$dimensions %||% NA_integer_
    )
  }
  res$id <- x$id
  res
}


#' Required packages for step_foundry_embed
#'
#' @param x A `step_foundry_embed` object
#' @param ... Not used
#'
#' @return A character vector of required package names
#' @exportS3Method recipes::required_pkgs
required_pkgs.step_foundry_embed <- function(x, ...) {
  c("foundryR")
}
