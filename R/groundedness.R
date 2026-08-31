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
#' @param correction Logical. If `TRUE`, requests corrected text that is
#'   consistent with the grounding sources (the Content Safety "mitigating"
#'   feature). Requires `llm_resource` and `api_version >= "2024-09-15-preview"`.
#'   The corrected text is returned in the `correction_text` column. Default:
#'   `FALSE`.
#' @param llm_resource List or `NULL`. Connection details for a bring-your-own
#'   Azure OpenAI deployment, used when `correction = TRUE`. Build it with
#'   [foundry_llm_resource()]. Default: `NULL`.
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
#'     \item{ungrounded_reasons}{List. A character vector, aligned with
#'       `ungrounded_segments`, holding the model's explanation for each
#'       segment when `reasoning = TRUE`. `NA` entries appear when no
#'       explanation was returned.}
#'     \item{correction_text}{Character. The corrected, grounding-consistent
#'       text returned when `correction = TRUE`, otherwise `NA`.}
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
#' AZURE_CONTENT_SAFETY_ENDPOINT=<your Content Safety endpoint URL>
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
#'
#' # Request corrected text (requires a bring-your-own Azure OpenAI deployment)
#' corrected <- foundry_groundedness(
#'   text = "The patient name is Kevin.",
#'   grounding_sources = "The patient name is Jane.",
#'   task = "Summarization",
#'   domain = "Medical",
#'   correction = TRUE,
#'   llm_resource = foundry_llm_resource(
#'     endpoint = "https://your-openai.openai.azure.com",
#'     deployment_name = "gpt-5-nano"
#'   )
#' )
#' corrected$correction_text
#' }
foundry_groundedness <- function(text,
                                  grounding_sources,
                                  query = NULL,
                                  domain = c("Generic", "Medical"),
                                  task = c("QnA", "Summarization"),
                                  reasoning = FALSE,
                                  correction = FALSE,
                                  llm_resource = NULL,
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

  endpoint <- get_content_safety_endpoint(endpoint, required = TRUE)
  api_key <- get_content_safety_key(api_key, required = TRUE)

  # Validate reasoning parameter
  if (!is.logical(reasoning) || length(reasoning) != 1 || is.na(reasoning)) {
    cli::cli_abort("{.arg reasoning} must be TRUE or FALSE.")
  }

  # Validate correction parameter
  if (!is.logical(correction) || length(correction) != 1 || is.na(correction)) {
    cli::cli_abort("{.arg correction} must be TRUE or FALSE.")
  }

  # Validate llm_resource, and require it for correction
  if (!is.null(llm_resource)) {
    llm_resource <- foundry_validate_llm_resource(llm_resource)
  }
  if (correction && is.null(llm_resource)) {
    cli::cli_abort(c(
      "Groundedness correction requires an Azure OpenAI resource.",
      "i" = "Pass {.arg llm_resource = foundry_llm_resource(endpoint, deployment_name)}."
    ))
  }

  # Build request body
  body <- list(
    domain = domain,
    task = task,
    text = text,
    groundingSources = as.list(grounding_sources),
    reasoning = reasoning
  )

  if (correction) {
    body$mitigating <- TRUE
  }

  if (!is.null(llm_resource)) {
    body$llmResource <- llm_resource
  }

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

  # Extract ungrounded segments and their reasons, aligned by index
  details <- result$ungroundedDetails %||% list()
  segment_text <- vapply(
    details,
    function(detail) detail$text %||% NA_character_,
    character(1)
  )
  segment_reason <- vapply(
    details,
    function(detail) detail$reason %||% NA_character_,
    character(1)
  )
  keep <- !is.na(segment_text)
  ungrounded_segments <- segment_text[keep]
  ungrounded_reasons <- segment_reason[keep]

  # Corrected text is a top-level sibling, present only when correction is on
  correction_text <- result$correctionText %||% NA_character_

  # Build result tibble
  tibble::tibble(
    grounded = !ungrounded_detected,
    grounded_pct = 1 - ungrounded_pct,
    ungrounded_pct = ungrounded_pct,
    ungrounded_segments = list(ungrounded_segments),
    ungrounded_reasons = list(ungrounded_reasons),
    correction_text = correction_text
  )
}


#' Describe a bring-your-own Azure OpenAI resource for groundedness
#'
#' Build the `llm_resource` argument for [foundry_groundedness()]. Reasoning and
#' correction both rely on an Azure OpenAI deployment (typically a provisioned
#' GPT-4o) that Content Safety calls on your behalf.
#'
#' @param endpoint Character. The Azure OpenAI resource endpoint, for example
#'   `"https://your-openai.openai.azure.com"`.
#' @param deployment_name Character. The Azure OpenAI deployment name to use.
#' @param resource_type Character. The resource type. Only `"AzureOpenAI"` is
#'   currently supported.
#'
#' @return A named list matching the Content Safety `LLMResource` schema.
#' @export
#'
#' @examples
#' foundry_llm_resource(
#'   endpoint = "https://your-openai.openai.azure.com",
#'   deployment_name = "gpt-5-nano"
#' )
foundry_llm_resource <- function(endpoint,
                                 deployment_name,
                                 resource_type = "AzureOpenAI") {
  foundry_check_character_scalar(endpoint, "endpoint")
  foundry_check_character_scalar(deployment_name, "deployment_name")
  foundry_check_character_scalar(resource_type, "resource_type")

  list(
    resourceType = resource_type,
    azureOpenAIEndpoint = endpoint,
    azureOpenAIDeploymentName = deployment_name
  )
}


# Coerce and validate a user-supplied llm_resource into the API's LLMResource
# shape. Accepts the output of foundry_llm_resource() or an equivalent raw list.
foundry_validate_llm_resource <- function(llm_resource) {
  if (!is.list(llm_resource) || is.null(names(llm_resource))) {
    cli::cli_abort(c(
      "{.arg llm_resource} must be a named list.",
      "i" = "Build it with {.fn foundry_llm_resource}."
    ))
  }

  endpoint <- llm_resource$azureOpenAIEndpoint
  deployment <- llm_resource$azureOpenAIDeploymentName

  if (is.null(endpoint) || !is.character(endpoint) || length(endpoint) != 1L ||
      is.na(endpoint) || endpoint == "") {
    cli::cli_abort(c(
      "{.arg llm_resource} must include a non-empty {.field azureOpenAIEndpoint}.",
      "i" = "Build it with {.fn foundry_llm_resource}."
    ))
  }
  if (is.null(deployment) || !is.character(deployment) ||
      length(deployment) != 1L || is.na(deployment) || deployment == "") {
    cli::cli_abort(c(
      "{.arg llm_resource} must include a non-empty {.field azureOpenAIDeploymentName}.",
      "i" = "Build it with {.fn foundry_llm_resource}."
    ))
  }

  llm_resource
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
