#' Build Azure AI Foundry Request
#'
#' Internal function to construct httr2 requests for Azure AI Foundry API.
#'
#' @param deployment Character. The deployment name.
#' @param endpoint_path Character. The API endpoint path (e.g., "chat/completions").
#' @param body List. The request body.
#' @param api_key Character. Optional API key override.
#' @param api_version Character. Optional API version override.
#'
#' @return An httr2 request object (not yet performed).
#' @keywords internal
foundry_build_request <- function(deployment,
                                   endpoint_path,
                                   body,
                                   api_key = NULL,
                                   api_version = NULL) {

  base_url <- foundry_get_endpoint(required = TRUE)
  api_key <- foundry_get_key(key = api_key, required = TRUE)
  api_version <- foundry_get_api_version(api_version)

  # Construct full URL
  # Pattern: {base}/openai/deployments/{deployment}/{endpoint}?api-version={version}
  url <- paste0(
    base_url,
    "/openai/deployments/",
    deployment,
    "/",
    endpoint_path
  )

  httr2::request(url) %>%
    httr2::req_url_query(`api-version` = api_version) %>%
    httr2::req_headers(`api-key` = api_key) %>%
    httr2::req_body_json(body) %>%
    httr2::req_retry(max_tries = 3, backoff = ~ 2) %>%
    httr2::req_error(body = foundry_error_body)
}


#' Build Azure AI Foundry v1 Request
#'
#' Internal function to construct httr2 requests for Azure OpenAI in Microsoft
#' Foundry's v1 data-plane API.
#'
#' @param path Character. The v1 API path, relative to `/openai/v1/`.
#' @param body List. Optional request body.
#' @param method Character. HTTP method. Default: `"POST"`.
#' @param api_key Character. Optional API key override.
#' @param endpoint Character. Optional endpoint override.
#' @param api_version Character. Optional API version query value. Usually not
#'   required for v1 endpoints.
#'
#' @return An httr2 request object (not yet performed).
#' @keywords internal
foundry_build_v1_request <- function(path,
                                     body = NULL,
                                     method = "POST",
                                     api_key = NULL,
                                     endpoint = NULL,
                                     api_version = NULL) {

  base_url <- foundry_get_endpoint(endpoint = endpoint, required = TRUE)
  api_key <- foundry_get_key(key = api_key, required = TRUE)

  path <- sub("^/+", "", path)
  url <- paste0(base_url, "/openai/v1/", path)

  req <- httr2::request(url) %>%
    httr2::req_method(method) %>%
    httr2::req_headers(`api-key` = api_key) %>%
    httr2::req_retry(max_tries = 3, backoff = ~ 2) %>%
    httr2::req_error(body = foundry_error_body)

  if (!is.null(api_version)) {
    req <- req %>%
      httr2::req_url_query(`api-version` = api_version)
  }

  if (!is.null(body)) {
    req <- req %>%
      httr2::req_body_json(body)
  }

  req
}


#' Parse API Error Response
#'
#' Internal function to extract user-friendly error messages from API responses.
#'
#' @param resp An httr2 response object.
#'
#' @return Character string with error message.
#' @keywords internal
foundry_error_body <- function(resp) {
  body <- tryCatch(
    httr2::resp_body_json(resp),
    error = function(e) list(error = list(message = httr2::resp_body_string(resp)))
  )

  # Azure OpenAI error format
  error_msg <- body$error$message %||%
    body$error %||%
    body$message %||%
    "Unknown API error"

  error_code <- body$error$code %||% ""

  # Content filter handling
  if (grepl("content_filter", error_code, ignore.case = TRUE)) {
    inner <- body$error$innererror
    if (!is.null(inner$content_filter_result)) {
      filter_info <- vapply(names(inner$content_filter_result), function(cat) {
        result <- inner$content_filter_result[[cat]]
        if (isTRUE(result$filtered)) {
          paste0(cat, " (", result$severity, ")")
        } else {
          NA_character_
        }
      }, character(1))
      filter_info <- filter_info[!is.na(filter_info)]
      if (length(filter_info) > 0) {
        return(paste0(
          "Content filtered: ",
          paste(filter_info, collapse = ", "),
          ". ",
          error_msg
        ))
      }
    }
    return(paste0("Content filtered by Azure AI safety system. ", error_msg))
  }

  # Authentication errors
  if (grepl("401|unauthorized|invalid.*key", error_msg, ignore.case = TRUE)) {
    return("Invalid API key. Check your AZURE_FOUNDRY_KEY or use foundry_set_key().")
  }

  # Deployment not found
  if (grepl("404|not found|deployment", error_msg, ignore.case = TRUE)) {
    return(paste0(
      "Deployment not found. Verify the deployment name exists in your Azure AI Foundry resource. ",
      error_msg
    ))
  }

  # Rate limiting
  if (grepl("429|rate limit|too many requests", error_msg, ignore.case = TRUE)) {
    return("Rate limit exceeded. Please wait and retry, or increase your quota in Azure Portal.")
  }

  paste0("API error: ", error_msg)
}


#' Perform Request and Parse Response
#'
#' Internal function to execute a request and handle the response.
#'
#' @param req An httr2 request object.
#'
#' @return The parsed JSON response as a list.
#' @keywords internal
foundry_perform <- function(req) {
  resp <- httr2::req_perform(req)
  httr2::resp_body_json(resp)
}


#' Warn if Model Looks Like a Chat Model
#'
#' Internal function to warn users if they appear to be using a chat model
#' for embedding operations.
#'
#' @param model Character. The model/deployment name.
#' @param calling_fn Character. The function name for the warning message.
#'
#' @return NULL (invisibly). Called for side effect of warning.
#' @keywords internal
warn_if_chat_model <- function(model, calling_fn = "foundry_embed") {
  # Common chat model patterns (case-insensitive)
  chat_patterns <- c(
    "gpt-",
    "gpt4",
    "gpt3",
    "gpt5",
    "claude",
    "llama",
    "mistral",
    "mixtral",
    "gemini",
    "palm",
    "command",
    "chat",
    "turbo",
    "davinci",
    "curie",
    "babbage"
  )

 # Check if model name matches any chat pattern
  model_lower <- tolower(model)
  is_likely_chat <- any(vapply(chat_patterns, function(p) {
    grepl(p, model_lower, fixed = TRUE)
  }, logical(1)))

  # Also check it's NOT an embedding model
  embed_patterns <- c("embed", "ada-002", "e5-", "bge-")
  is_likely_embed <- any(vapply(embed_patterns, function(p) {
    grepl(p, model_lower, fixed = TRUE)
  }, logical(1)))

  if (is_likely_chat && !is_likely_embed) {
    cli::cli_warn(c(
      "!" = "Model {.val {model}} looks like a chat model, not an embedding model.",
      "i" = "Embedding requires a dedicated embedding model deployment (e.g., {.val text-embedding-ada-002}, {.val text-embedding-3-small}).",
      "i" = "Chat models like GPT-4, Claude, and Llama cannot generate embeddings.",
      "i" = "Deploy an embedding model in Azure AI Foundry, then use that deployment name."
    ))
  }

  invisible(NULL)
}
