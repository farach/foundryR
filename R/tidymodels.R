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
#' Embedding generation requires API calls for each row of data. For large
#' datasets, consider:
#' - Using `skip = TRUE` during cross-validation to avoid redundant API calls
#' - Pre-computing embeddings for training data and caching the results
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
                                columns = NULL,
                                skip = FALSE,
                                id = recipes::rand_id("foundry_embed")) {

  if (!requireNamespace("recipes", quietly = TRUE)) {
    stop("Package 'recipes' required. Install with: install.packages('recipes')",
         call. = FALSE)
  }

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

  for (col_name in col_names) {
    # Convert factor to character (recipes formula interface converts char to factor)
    text_data <- as.character(new_data[[col_name]])

    # Generate embeddings using foundry_embed()
    embeddings_df <- foundry_embed(
      text = text_data,
      model = object$model,
      dimensions = object$dimensions
    )

    # Determine which rows have valid embeddings
    valid_idx <- vapply(
      embeddings_df$embedding,
      function(e) !is.null(e) && length(e) > 0,
      logical(1)
    )

    if (sum(valid_idx) == 0) {
      cli::cli_abort(
        "No valid embeddings generated for column {.field {col_name}}."
      )
    }

    # Get the dimensionality from the first valid embedding
    first_valid <- which(valid_idx)[1]
    n_dims <- length(embeddings_df$embedding[[first_valid]])

    # Create column names: {prefix}{col_name}_{1}, {prefix}{col_name}_{2}, ...
    emb_col_names <- paste0(object$prefix, col_name, "_", seq_len(n_dims))

    # Initialize all embedding columns with NA
    for (i in seq_len(n_dims)) {
      new_data[[emb_col_names[i]]] <- NA_real_
    }

    # Fill in valid embeddings
    for (row_idx in which(valid_idx)) {
      emb_vec <- embeddings_df$embedding[[row_idx]]
      for (i in seq_len(n_dims)) {
        new_data[[emb_col_names[i]]][row_idx] <- emb_vec[i]
      }
    }

    # Remove original text column if not keeping
    if (!object$keep_original) {
      new_data[[col_name]] <- NULL
    }
  }

  new_data
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
