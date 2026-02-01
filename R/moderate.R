#' Set Azure Content Safety API Key
#'
#' Set or update your Azure Content Safety API key for authentication.
#' The key can be obtained from the Azure Portal under your Content Safety resource.
#'
#' @param key Character string containing your API key, or NULL to set interactively.
#'   If NULL in an interactive session, will prompt for input.
#' @param store Logical. If TRUE, stores the key in `.Renviron` for future sessions.
#'   Default: FALSE (key only available for current session).
#'
#' @return Invisibly returns TRUE if key was set successfully.
#' @export
#'
#' @examples
#' \dontrun{
#' # Set key for current session only
#' foundry_set_content_safety_key("your-api-key-here")
#'
#' # Set key interactively and store permanently
#' foundry_set_content_safety_key(store = TRUE)
#' }
foundry_set_content_safety_key <- function(key = NULL, store = FALSE) {

  # Interactive input if key is NULL
  if (is.null(key)) {
    if (!interactive()) {
      cli::cli_abort("API key must be provided in non-interactive sessions.")
    }
    key <- readline(prompt = "Enter your Azure Content Safety API key: ")
    key <- trimws(key)
  }

  if (key == "" || is.na(key)) {
    cli::cli_abort("API key cannot be empty.")
  }

  # Set for current session
  Sys.setenv(AZURE_CONTENT_SAFETY_KEY = key)
  cli::cli_alert_success("Content Safety API key set for current session.")

  # Optionally persist to .Renviron
  if (store) {
    renviron_path <- file.path(Sys.getenv("HOME"), ".Renviron")

    # Read existing .Renviron if it exists
    if (file.exists(renviron_path)) {
      renviron_lines <- readLines(renviron_path, warn = FALSE)
      # Remove any existing AZURE_CONTENT_SAFETY_KEY line
      renviron_lines <- renviron_lines[!grepl("^AZURE_CONTENT_SAFETY_KEY=", renviron_lines)]
    } else {
      renviron_lines <- character()
    }

    # Add new key
    renviron_lines <- c(renviron_lines, paste0("AZURE_CONTENT_SAFETY_KEY=", key))

    # Write back
    writeLines(renviron_lines, renviron_path)
    cli::cli_alert_success("Content Safety API key stored in {.file {renviron_path}}")
  }

  invisible(TRUE)
}


#' Set Azure Content Safety Endpoint
#'
#' Set the base endpoint URL for your Azure Content Safety resource.
#'
#' @param endpoint Character string containing the endpoint URL.
#'   Example: "https://your-resource.cognitiveservices.azure.com"
#' @param store Logical. If TRUE, stores the endpoint in `.Renviron` for future sessions.
#'   Default: FALSE (endpoint only available for current session).
#'
#' @return Invisibly returns TRUE if endpoint was set successfully.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_set_content_safety_endpoint("https://my-resource.cognitiveservices.azure.com")
#'
#' # Store permanently
#' foundry_set_content_safety_endpoint("https://my-resource.cognitiveservices.azure.com", store = TRUE)
#' }
foundry_set_content_safety_endpoint <- function(endpoint, store = FALSE) {

  if (missing(endpoint) || is.null(endpoint) || endpoint == "") {
    cli::cli_abort("Endpoint URL is required.")
  }

  # Remove trailing slash if present
  endpoint <- sub("/$", "", endpoint)

  # Set for current session
  Sys.setenv(AZURE_CONTENT_SAFETY_ENDPOINT = endpoint)
  cli::cli_alert_success("Content Safety endpoint set to {.url {endpoint}}")

  # Optionally persist to .Renviron
  if (store) {
    renviron_path <- file.path(Sys.getenv("HOME"), ".Renviron")

    if (file.exists(renviron_path)) {
      renviron_lines <- readLines(renviron_path, warn = FALSE)
      renviron_lines <- renviron_lines[!grepl("^AZURE_CONTENT_SAFETY_ENDPOINT=", renviron_lines)]
    } else {
      renviron_lines <- character()
    }

    renviron_lines <- c(renviron_lines, paste0("AZURE_CONTENT_SAFETY_ENDPOINT=", endpoint))
    writeLines(renviron_lines, renviron_path)
    cli::cli_alert_success("Content Safety endpoint stored in {.file {renviron_path}}")
  }

  invisible(TRUE)
}


#' Get Azure Content Safety API Key
#'
#' Retrieve the Content Safety API key from the environment or a provided value.
#' This is primarily an internal function used by other foundryR functions.
#'
#' @param key Character. Optional key to use instead of environment variable.
#' @param required Logical. If TRUE, throws an error when no key is found.
#'
#' @return The API key string, or NULL if not found and not required.
#' @keywords internal
get_content_safety_key <- function(key = NULL, required = FALSE) {
  if (is.null(key)) {
    key <- Sys.getenv("AZURE_CONTENT_SAFETY_KEY")
    if (key == "") key <- NULL
  }

  if (required && is.null(key)) {
    cli::cli_abort(c(
      "Azure Content Safety API key is required.",
      "i" = "Set one with {.code foundry_set_content_safety_key()} or set the {.envvar AZURE_CONTENT_SAFETY_KEY} environment variable."
    ))
  }

  key
}


#' Get Azure Content Safety Endpoint
#'
#' Retrieve the Content Safety endpoint URL from the environment or a provided value.
#'
#' @param endpoint Character. Optional endpoint to use instead of environment variable.
#' @param required Logical. If TRUE, throws an error when no endpoint is found.
#'
#' @return The endpoint URL string, or NULL if not found and not required.
#' @keywords internal
get_content_safety_endpoint <- function(endpoint = NULL, required = FALSE) {
  if (is.null(endpoint)) {
    endpoint <- Sys.getenv("AZURE_CONTENT_SAFETY_ENDPOINT")
    if (endpoint == "") endpoint <- NULL
  }

  # Remove trailing slash if present
  if (!is.null(endpoint)) {
    endpoint <- sub("/$", "", endpoint)
  }

  if (required && is.null(endpoint)) {
    cli::cli_abort(c(
      "Azure Content Safety endpoint is required.",
      "i" = "Set one with {.code foundry_set_content_safety_endpoint()} or set the {.envvar AZURE_CONTENT_SAFETY_ENDPOINT} environment variable."
    ))
  }

  endpoint
}


#' Convert Severity Score to Label
#'
#' Internal function to convert numeric severity scores to human-readable labels.
#'
#' @param severity Numeric. The severity score (0-7 for EightSeverityLevels,
#'   0-6 for FourSeverityLevels where values are 0, 2, 4, 6).
#' @param output_type Character. The output type used in the API call.
#'
#' @return Character. One of "safe", "low", "medium", or "high".
#' @keywords internal
severity_to_label <- function(severity, output_type = "FourSeverityLevels") {
  if (is.na(severity)) {
    return(NA_character_)
  }

  # For both output types, the mapping is based on severity ranges
  # FourSeverityLevels returns: 0, 2, 4, 6
  # EightSeverityLevels returns: 0, 1, 2, 3, 4, 5, 6, 7
  #
  # Label mapping:
  # - safe: 0
  # - low: 1-2
  # - medium: 3-4
  # - high: 5-7
  if (severity == 0) {
    "safe"
  } else if (severity <= 2) {
    "low"
  } else if (severity <= 4) {
    "medium"
  } else {
    "high"
  }
}


#' Parse Content Safety Error Response
#'
#' Internal function to extract user-friendly error messages from Content Safety API responses.
#'
#' @param resp An httr2 response object.
#'
#' @return Character string with error message.
#' @keywords internal
content_safety_error_body <- function(resp) {
  body <- tryCatch(
    httr2::resp_body_json(resp),
    error = function(e) list(error = list(message = httr2::resp_body_string(resp)))
  )

  # Azure Content Safety error format
  error_msg <- body$error$message %||%
    body$error %||%
    body$message %||%
    "Unknown API error"

  error_code <- body$error$code %||% ""

  # Authentication errors
  if (grepl("401|unauthorized|invalid.*key", error_msg, ignore.case = TRUE) ||
      grepl("401|Unauthorized", error_code, ignore.case = TRUE)) {
    return("Invalid API key. Check your AZURE_CONTENT_SAFETY_KEY or use foundry_set_content_safety_key().")
  }

  # Resource not found
  if (grepl("404|not found", error_msg, ignore.case = TRUE)) {
    return(paste0(
      "Resource not found. Verify your Content Safety endpoint is correct. ",
      error_msg
    ))
  }

  # Rate limiting
  if (grepl("429|rate limit|too many requests", error_msg, ignore.case = TRUE)) {
    return("Rate limit exceeded. Please wait and retry, or increase your quota in Azure Portal.")
  }

  # Text too long
  if (grepl("text.*too long|exceed.*limit|10000|10K", error_msg, ignore.case = TRUE)) {
    return("Text exceeds maximum length of 10,000 characters. Please shorten your input.")
  }

  paste0("Content Safety API error: ", error_msg)
}


#' Moderate Text Content
#'
#' Analyze text content for potentially harmful material using the Azure Content
#' Safety API. Returns severity scores for multiple harm categories including
#' hate speech, sexual content, self-harm, and violence.
#'
#' @param text Character vector. The text(s) to analyze. Each text must be
#'   10,000 characters or less.
#' @param categories Character vector. Categories to analyze. Must be a subset of
#'   `c("Hate", "Sexual", "SelfHarm", "Violence")`. Default: all four categories.
#' @param output_type Character. Severity level granularity. One of
#'   `"FourSeverityLevels"` (returns 0, 2, 4, 6) or `"EightSeverityLevels"`
#'   (returns 0-7). Default: `"FourSeverityLevels"`.
#' @param endpoint Character. Optional endpoint URL override. If NULL, uses the
#'   `AZURE_CONTENT_SAFETY_ENDPOINT` environment variable.
#' @param api_key Character. Optional API key override. If NULL, uses the
#'   `AZURE_CONTENT_SAFETY_KEY` environment variable.
#' @param api_version Character. API version to use. Default: `"2024-09-01"`.
#'
#' @return A tibble with columns:
#'   \describe{
#'     \item{text}{Character. The input text (truncated to 50 chars if longer).}
#'     \item{category}{Character. The harm category: "Hate", "Sexual", "SelfHarm", or "Violence".}
#'     \item{severity}{Integer. Severity score. Range depends on `output_type`:
#'       0-6 for FourSeverityLevels (values: 0, 2, 4, 6) or 0-7 for EightSeverityLevels.}
#'     \item{label}{Character. Human-readable severity label: "safe", "low", "medium", or "high".}
#'   }
#'
#' @details
#' The Azure Content Safety API analyzes text for four types of harmful content:
#'
#' \itemize{
#'   \item **Hate**: Content that attacks or discriminates against individuals
#'     or groups based on protected attributes.
#'   \item **Sexual**: Sexually explicit or adult content.
#'   \item **SelfHarm**: Content that promotes or describes self-harm behaviors.
#'   \item **Violence**: Content that describes or promotes violence.
#' }
#'
#' **Severity Labels:**
#' \itemize{
#'   \item **safe** (0): No harmful content detected.
#'   \item **low** (1-2): Mildly concerning content.
#'   \item **medium** (3-4): Moderately harmful content.
#'   \item **high** (5+): Severely harmful content.
#' }
#'
#' @section Authentication:
#' You need an Azure Content Safety resource to use this function. Set up
#' credentials using either:
#' \itemize{
#'   \item Environment variables: `AZURE_CONTENT_SAFETY_ENDPOINT` and `AZURE_CONTENT_SAFETY_KEY`
#'   \item Helper functions: `foundry_set_content_safety_endpoint()` and `foundry_set_content_safety_key()`
#' }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Analyze a single text
#' foundry_moderate("This is a friendly message.")
#'
#' # Analyze multiple texts
#' texts <- c(
#'   "Hello, how are you today?",
#'   "This is another message to check."
#' )
#' results <- foundry_moderate(texts)
#'
#' # Filter for specific categories
#' foundry_moderate("Some text", categories = c("Hate", "Violence"))
#'
#' # Use finer-grained severity levels
#' foundry_moderate("Some text", output_type = "EightSeverityLevels")
#'
#' # Check results
#' library(dplyr)
#' results %>%
#'   filter(severity > 0) %>%
#'   arrange(desc(severity))
#' }
foundry_moderate <- function(text,
                              categories = c("Hate", "Sexual", "SelfHarm", "Violence"),
                              output_type = c("FourSeverityLevels", "EightSeverityLevels"),
                              endpoint = NULL,
                              api_key = NULL,
                              api_version = "2024-09-01") {

  # Validate output_type
  output_type <- match.arg(output_type)

  # Validate categories
  valid_categories <- c("Hate", "Sexual", "SelfHarm", "Violence")
  if (!all(categories %in% valid_categories)) {
    invalid <- setdiff(categories, valid_categories)
    cli::cli_abort(c(
      "Invalid categories: {.val {invalid}}",
      "i" = "Valid categories are: {.val {valid_categories}}"
    ))
  }

  # Get endpoint and key
  endpoint <- get_content_safety_endpoint(endpoint, required = TRUE)
  api_key <- get_content_safety_key(api_key, required = TRUE)

  # Handle empty input
  if (length(text) == 0) {
    return(tibble::tibble(
      text = character(),
      category = character(),
      severity = integer(),
      label = character()
    ))
  }

  # Vectorize over inputs using purrr::map_dfr
  purrr::map_dfr(seq_along(text), function(i) {
    single_text <- text[i]

    # Handle NA values
    if (is.na(single_text)) {
      return(tibble::tibble(
        text = NA_character_,
        category = categories,
        severity = NA_integer_,
        label = NA_character_
      ))
    }

    # Validate text length
    if (nchar(single_text) > 10000) {
      cli::cli_warn(
        "Text at index {i} exceeds 10,000 character limit ({nchar(single_text)} chars). Truncating."
      )
      single_text <- substr(single_text, 1, 10000)
    }

    # Truncate text for display in results
    display_text <- if (nchar(single_text) > 50) {
      paste0(substr(single_text, 1, 47), "...")
    } else {
      single_text
    }

    # Build request body
    body <- list(
      text = single_text,
      categories = as.list(categories),
      outputType = output_type
    )

    # Build URL
    url <- paste0(endpoint, "/contentsafety/text:analyze")

    # Build request
    req <- httr2::request(url) %>%
      httr2::req_url_query(`api-version` = api_version) %>%
      httr2::req_headers(`Ocp-Apim-Subscription-Key` = api_key) %>%
      httr2::req_body_json(body) %>%
      httr2::req_retry(max_tries = 3, backoff = ~ 2) %>%
      httr2::req_error(body = content_safety_error_body)

    # Perform request
    result <- tryCatch(
      {
        resp <- httr2::req_perform(req)
        httr2::resp_body_json(resp)
      },
      error = function(e) {
        cli::cli_warn("Failed to moderate text at index {i}: {conditionMessage(e)}")
        return(NULL)
      }
    )

    # Handle failed request
    if (is.null(result)) {
      return(tibble::tibble(
        text = display_text,
        category = categories,
        severity = NA_integer_,
        label = NA_character_
      ))
    }

    # Parse response
    categories_analysis <- result$categoriesAnalysis

    if (is.null(categories_analysis) || length(categories_analysis) == 0) {
      cli::cli_warn("Unexpected response format at index {i}. No categoriesAnalysis found.")
      return(tibble::tibble(
        text = display_text,
        category = categories,
        severity = NA_integer_,
        label = NA_character_
      ))
    }

    # Extract results for each category
    purrr::map_dfr(categories_analysis, function(cat_result) {
      category <- cat_result$category %||% NA_character_
      severity <- cat_result$severity %||% NA_integer_

      tibble::tibble(
        text = display_text,
        category = category,
        severity = as.integer(severity),
        label = severity_to_label(severity, output_type)
      )
    })
  })
}
