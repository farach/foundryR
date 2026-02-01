#' Detect Groundedness of LLM Responses
#'
#' Check whether an LLM-generated response is grounded in the provided source
#' documents using the Azure AI Content Safety groundedness detection API.
#' This helps identify hallucinations or unsupported claims in AI-generated text.
#'
#' @param text Character. The LLM-generated response text to check for groundedness.
#' @param grounding_sources Character vector. One or more source documents that
#'   the response should be grounded in.
#' @param query Character. Optional. The user's original question. Required when
#'   `task = "QnA"`.
#' @param domain Character. The domain context for groundedness detection.
#'
#'   - `"Generic"` (default): General-purpose groundedness detection.
#'   - `"Medical"`: Optimized for medical/healthcare content.
#' @param task Character. The type of task being evaluated.
#'
#'   - `"QnA"` (default): Question-and-answer task. Requires `query` parameter.
#'   - `"Summarization"`: Text summarization task. `query` is optional.
#' @param reasoning Logical. If `TRUE`, includes reasoning for ungrounded
#'   segments in the response. Default: `FALSE`.
#' @param endpoint Character. Optional. The Azure Content Safety endpoint URL.
#'
#'   Defaults to the `AZURE_CONTENT_SAFETY_ENDPOINT` environment variable.
#' @param api_key Character. Optional. The Azure Content Safety API key.
#'
#'   Defaults to the `AZURE_CONTENT_SAFETY_KEY` environment variable.
#' @param api_version Character. The API version to use. Default: `"2024-09-15-preview"`.
#'
#' @return A tibble with one row containing:
#'   \describe{
#'     \item{grounded}{Logical. `TRUE` if the text is fully grounded (no ungrounded content detected).
#'       `FALSE` if any ungrounded segments were found.}
#'     \item{grounded_pct}{Numeric. The percentage of text that is grounded (1 - ungroundedPercentage).
#'       Value between 0 and 1.}
#'     \item{ungrounded_pct}{Numeric. The percentage of text that is ungrounded.
#'       Value between 0 and 1.}
#'     \item{ungrounded_segments}{List. A character vector of text segments identified as ungrounded.
#'       Empty character vector if fully grounded.
#'     }
#'   }
#'
#' @details
#' ## Authentication
#'
#' This function uses Azure Content Safety credentials, which are separate from
#' the Azure AI Foundry (OpenAI) credentials used by other foundryR functions.
#'
#' Set environment variables:
#' ```
#' AZURE_CONTENT_SAFETY_ENDPOINT=https://your-resource.cognitiveservices.azure.com
#' AZURE_CONTENT_SAFETY_KEY=your-api-key
#' ```
#'
#' Or pass `endpoint` and `api_key` directly to the function.
#'
#' ## Task Types
#'
#' - **QnA**: Use when checking an answer to a specific question. The `query`
#'   parameter provides context about what question was being answered.
#' - **Summarization**: Use when checking a summary of source documents.
#'   The `query` parameter is optional.
#'
#' ## Domain Settings
#'
#' - **Generic**: Default setting for most use cases.
#' - **Medical**: Use for healthcare-related content. May apply stricter
#'   groundedness requirements.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Check groundedness of a QnA response
#' result <- foundry_groundedness(
#'   text = "The capital of France is Paris. It has a population of 12 million.",
#'   grounding_sources = c("Paris is the capital and largest city of France."),
#'   query = "What is the capital of France?",
#'   task = "QnA"
#' )
#'
#' # Check if fully grounded
#' result$grounded
#'
#' # See what percentage is grounded
#' result$grounded_pct
#'
#' # View ungrounded segments
#' result$ungrounded_segments[[1]]
#'
#' # Check groundedness of a summarization
#' summary_result <- foundry_groundedness(
#'   text = "The study found significant improvements in patient outcomes.",
#'   grounding_sources = c(
#'     "A clinical trial showed 40% improvement in recovery time.",
#'     "Patient satisfaction increased by 25% compared to control group."
#'   ),
#'   task = "Summarization",
#'   domain = "Medical"
#' )
#'
#' # With reasoning enabled
#' detailed_result <- foundry_groundedness(
#'   text = "The product was released in 2020 and has sold millions of units.",
#'   grounding_sources = c("The product launched in 2021 with strong initial sales."),
#'   query = "When was the product released?",
#'   reasoning = TRUE
#' )
#' }
foundry_groundedness <- function(text,
                                  grounding_sources,
                                  query = NULL,
                                  domain = c("Generic", "Medical"),
                                  task = c("QnA", "Summarization"),
                                  reasoning = FALSE,
                                  endpoint = NULL,
                                  api_key = NULL,
                                  api_version = "2024-09-15-preview") {

  # Match arguments
  domain <- match.arg(domain)
  task <- match.arg(task)

  # Validate required inputs
  if (missing(text) || is.null(text) || !is.character(text)) {
    cli::cli_abort("{.arg text} must be a character string.")
  }

  if (length(text) != 1 || is.na(text)) {
    cli::cli_abort("{.arg text} must be a single non-NA character string.")
  }

  if (missing(grounding_sources) || is.null(grounding_sources) || !is.character(grounding_sources)) {
    cli::cli_abort("{.arg grounding_sources} must be a character vector.")
  }

  if (length(grounding_sources) == 0 || all(is.na(grounding_sources))) {
    cli::cli_abort("{.arg grounding_sources} must contain at least one non-NA source document.")
  }

  # Remove NA values from grounding_sources
  grounding_sources <- grounding_sources[!is.na(grounding_sources)]

  # Validate query requirement for QnA task
  if (task == "QnA") {
    if (is.null(query) || !is.character(query) || length(query) != 1 || is.na(query) || query == "") {
      cli::cli_abort(c(
        "{.arg query} is required when {.code task = \"QnA\"}.",
        "i" = "Provide the user's original question, or use {.code task = \"Summarization\"} if no query is needed."
      ))
    }
  }

  # Get endpoint
  if (is.null(endpoint)) {
    endpoint <- Sys.getenv("AZURE_CONTENT_SAFETY_ENDPOINT")
    if (endpoint == "") {
      cli::cli_abort(c(
        "Azure Content Safety endpoint is required.",
        "i" = "Set the {.envvar AZURE_CONTENT_SAFETY_ENDPOINT} environment variable or pass {.arg endpoint} directly."
      ))
    }
  }

  # Remove trailing slash from endpoint
  endpoint <- sub("/$", "", endpoint)

  # Get API key
  if (is.null(api_key)) {
    api_key <- Sys.getenv("AZURE_CONTENT_SAFETY_KEY")
    if (api_key == "") {
      cli::cli_abort(c(
        "Azure Content Safety API key is required.",
        "i" = "Set the {.envvar AZURE_CONTENT_SAFETY_KEY} environment variable or pass {.arg api_key} directly."
      ))
    }
  }

  # Validate reasoning parameter
  if (!is.logical(reasoning) || length(reasoning) != 1 || is.na(reasoning)) {
    cli::cli_abort("{.arg reasoning} must be TRUE or FALSE.")
  }

  # Build request body
  body <- list(
    domain = domain,
    task = task,
    text = text,
    groundingSources = as.list(grounding_sources),
    reasoning = reasoning
  )

  # Add qna object if query is provided
  if (!is.null(query) && query != "") {
    body$qna <- list(query = query)
  }

  # Construct URL
  url <- paste0(
    endpoint,
    "/contentsafety/text:detectGroundedness"
  )

  # Build and perform request
  req <- httr2::request(url) %>%
    httr2::req_url_query(`api-version` = api_version) %>%
    httr2::req_headers(`Ocp-Apim-Subscription-Key` = api_key) %>%
    httr2::req_body_json(body) %>%
    httr2::req_retry(max_tries = 3, backoff = ~ 2) %>%
    httr2::req_error(body = groundedness_error_body)

  # Perform request
  resp <- tryCatch(
    httr2::req_perform(req),
    error = function(e) {
      cli::cli_abort(c(
        "Groundedness detection request failed.",
        "x" = conditionMessage(e)
      ))
    }
  )

  # Parse response
  result <- httr2::resp_body_json(resp)

  # Extract values with defaults
  ungrounded_detected <- result$ungroundedDetected %||% FALSE
  ungrounded_pct <- result$ungroundedPercentage %||% 0

  # Extract ungrounded segments
  ungrounded_segments <- character(0)
  if (!is.null(result$ungroundedDetails) && length(result$ungroundedDetails) > 0) {
    ungrounded_segments <- vapply(result$ungroundedDetails, function(detail) {
      detail$text %||% NA_character_
    }, character(1))
    ungrounded_segments <- ungrounded_segments[!is.na(ungrounded_segments)]
  }

  # Build result tibble
  tibble::tibble(
    grounded = !ungrounded_detected,
    grounded_pct = 1 - ungrounded_pct,
    ungrounded_pct = ungrounded_pct,
    ungrounded_segments = list(ungrounded_segments)
  )
}


#' Parse Groundedness API Error Response
#'
#' Internal function to extract user-friendly error messages from Content Safety API responses.
#'
#' @param resp An httr2 response object.
#'
#' @return Character string with error message.
#' @keywords internal
groundedness_error_body <- function(resp) {
  body <- tryCatch(
    httr2::resp_body_json(resp),
    error = function(e) list(error = list(message = httr2::resp_body_string(resp)))
  )

  # Azure Content Safety error format
  error_msg <- body$error$message %||%
    body$message %||%
    body$error %||%
    "Unknown API error"

  error_code <- body$error$code %||% ""

  # Authentication errors
  if (grepl("401|unauthorized|invalid.*key|Unauthorized", error_msg, ignore.case = TRUE)) {
    return("Invalid API key. Check your AZURE_CONTENT_SAFETY_KEY.")
  }

  # Not found errors
  if (grepl("404|not found", error_msg, ignore.case = TRUE)) {
    return(paste0(
      "Endpoint not found. Verify your AZURE_CONTENT_SAFETY_ENDPOINT is correct. ",
      error_msg
    ))
  }

  # Rate limiting
  if (grepl("429|rate limit|too many requests|throttl", error_msg, ignore.case = TRUE)) {
    return("Rate limit exceeded. Please wait and retry.")
  }

  # Bad request (validation errors)
  if (grepl("400|bad request|invalid", error_msg, ignore.case = TRUE)) {
    return(paste0("Invalid request: ", error_msg))
  }

  paste0("Content Safety API error: ", error_msg)
}
