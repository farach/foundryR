#' Build Microsoft Foundry Request
#'
#' Internal function to construct httr2 requests for Microsoft Foundry API.
#'
#' @param deployment Character. The deployment name.
#' @param endpoint_path Character. The API endpoint path (e.g., "chat/completions").
#' @param body List. The request body.
#' @param api_key Character. Optional API key override.
#' @param token Character. Optional bearer token override.
#' @param api_version Character. Optional API version override.
#'
#' @return An httr2 request object (not yet performed).
#' @keywords internal
foundry_build_request <- function(deployment,
                                   endpoint_path,
                                   body,
                                   api_key = NULL,
                                   token = NULL,
                                   api_version = NULL) {

  base_url <- foundry_get_endpoint(required = TRUE)
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
    foundry_authenticate_request(
      api_key = api_key,
      token = token,
      token_scope = "resource"
    ) %>%
    httr2::req_body_json(body) %>%
    httr2::req_retry(max_tries = 3, backoff = ~ 2) %>%
    httr2::req_error(body = foundry_error_body)
}


#' Build Microsoft Foundry v1 Request
#'
#' Internal function to construct httr2 requests for Azure OpenAI in Microsoft
#' Foundry's v1 data-plane API.
#'
#' @param path Character. The v1 API path, relative to `/openai/v1/`.
#' @param body List. Optional request body.
#' @param method Character. HTTP method. Default: `"POST"`.
#' @param api_key Character. Optional API key override.
#' @param token Character. Optional bearer token override.
#' @param endpoint Character. Optional endpoint override.
#' @param api_version Character. Optional API version query value. Usually not
#'   required for v1 endpoints.
#' @param key_getter Function used to resolve API keys. Defaults to
#'   `foundry_get_key()`.
#'
#' @return An httr2 request object (not yet performed).
#' @keywords internal
foundry_build_v1_request <- function(path,
                                     body = NULL,
                                     method = "POST",
                                     api_key = NULL,
                                     token = NULL,
                                     endpoint = NULL,
                                     api_version = NULL,
                                     key_getter = foundry_get_key) {

  base_url <- foundry_get_endpoint(endpoint = endpoint, required = TRUE)

  path <- sub("^/+", "", path)
  url <- paste0(base_url, "/openai/v1/", path)

  req <- httr2::request(url) %>%
    httr2::req_method(method) %>%
    foundry_authenticate_request(
      api_key = api_key,
      token = token,
      key_getter = key_getter,
      token_scope = "resource"
    ) %>%
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


foundry_build_project_request <- function(path,
                                          body = NULL,
                                          method = "POST",
                                          api_key = NULL,
                                          token = NULL,
                                          endpoint = NULL,
                                          api_version = "v1",
                                          allow_key = TRUE) {
  if (!allow_key && !is.null(api_key)) {
    cli::cli_abort(c(
      "Evaluations on a Foundry project endpoint need a Microsoft Entra ID token, not an API key.",
      "i" = "The service answers HTTP 403 to API keys there.",
      "i" = "Drop {.arg api_key} and authenticate with {.code foundry_set_token_provider(foundry_token_azure_cli(\"https://ai.azure.com\"), scope = \"project\")}, {.fn foundry_token_azure_identity}, or {.code foundry_set_token(scope = \"project\")}."
    ))
  }
  base_url <- foundry_get_project_endpoint(endpoint = endpoint, required = TRUE)

  path <- sub("^/+", "", path)
  url <- paste0(base_url, "/", path)

  req <- httr2::request(url) |>
    httr2::req_method(method) |>
    foundry_authenticate_request(
      api_key = api_key,
      token = token,
      token_scope = "project",
      allow_key = allow_key
    ) |>
    httr2::req_retry(max_tries = 3, backoff = ~ 2) |>
    httr2::req_error(body = foundry_error_body)

  if (!is.null(api_version)) {
    req <- req |>
      httr2::req_url_query(`api-version` = api_version)
  }

  if (!is.null(body)) {
    req <- req |>
      httr2::req_body_json(body)
  }

  req
}


foundry_authenticate_request <- function(req,
                                         api_key = NULL,
                                         token = NULL,
                                         required = TRUE,
                                         key_header = "api-key",
                                         key_getter = foundry_get_key,
                                         token_getter = foundry_get_token,
                                         token_scope = NULL,
                                         allow_key = TRUE) {
  explicit_token <- NULL
  if (!is.null(token)) {
    explicit_token <- foundry_resolve_token(
      token_getter,
      token = token,
      required = FALSE,
      scope = token_scope
    )
  }
  if (!is.null(explicit_token)) {
    return(req %>%
      httr2::req_headers(Authorization = paste("Bearer", explicit_token)))
  }

  explicit_key <- NULL
  if (allow_key && !is.null(api_key)) {
    explicit_key <- key_getter(key = api_key, required = FALSE)
  }
  if (!is.null(explicit_key)) {
    headers <- list(explicit_key)
    names(headers) <- key_header
    return(do.call(httr2::req_headers, c(list(req), headers)))
  }

  provider_token <- foundry_token_from_provider(
    required = FALSE,
    scope = token_scope %||% "resource"
  )
  if (!is.null(provider_token)) {
    return(req %>%
      httr2::req_headers(Authorization = paste("Bearer", provider_token)))
  }

  env_token <- foundry_resolve_token(
    token_getter,
    token = NULL,
    required = FALSE,
    scope = token_scope
  )
  if (!is.null(env_token)) {
    return(req %>%
      httr2::req_headers(Authorization = paste("Bearer", env_token)))
  }

  env_key <- if (allow_key) key_getter(key = NULL, required = FALSE) else NULL
  if (!is.null(env_key)) {
    headers <- list(env_key)
    names(headers) <- key_header
    return(do.call(httr2::req_headers, c(list(req), headers)))
  }

  if (required && !allow_key) {
    cli::cli_abort(c(
      "Evaluations on a Foundry project endpoint need a Microsoft Entra ID token.",
      "i" = "The service answers HTTP 403 to API keys there.",
      "i" = "Use {.code foundry_set_token_provider(foundry_token_azure_cli(\"https://ai.azure.com\"), scope = \"project\")}, {.fn foundry_token_azure_identity}, or {.code foundry_set_token(scope = \"project\")}."
    ))
  }
  if (required) {
    scope <- token_scope %||% "resource"
    cli::cli_abort(c(
      "Azure AI Foundry authentication is required.",
      "i" = "Set an API key with {.code foundry_set_key()}, set a {scope} bearer token with {.code foundry_set_token(scope = \"{scope}\")}, or configure a {scope} provider with {.code foundry_set_token_provider(..., scope = \"{scope}\")}."
    ))
  }

  req
}


foundry_resolve_token <- function(token_getter,
                                  token,
                                  required,
                                  scope = NULL) {
  args <- list(token = token, required = required)
  if (!is.null(scope)) {
    args$scope <- scope
  }
  do.call(token_getter, args)
}


#' Parse API Error Response
#'
#' Internal function that turns a failed response into the lines shown under
#' httr2's `HTTP <status>` error. The HTTP status picks the category, the
#' service's own message is always kept, and a hint depends on the status and
#' the endpoint that was called.
#'
#' @param resp An httr2 response object.
#'
#' @return A named character vector of message lines.
#' @keywords internal
foundry_error_body <- function(resp) {
  foundry_classify_error(resp, service = "foundry")
}


# Shared classifier behind foundry_error_body() and the Content Safety error
# bodies. `service` selects the credential and endpoint hints.
foundry_classify_error <- function(resp, service = c("foundry", "content_safety")) {
  service <- match.arg(service)
  status <- httr2::resp_status(resp)
  details <- foundry_error_details(resp)
  message <- details$message
  label <- if (identical(service, "content_safety")) "Content Safety API error" else "API error"

  if (grepl("content_filter", details$code, ignore.case = TRUE)) {
    filtered <- foundry_content_filter_summary(details$body$error$innererror)
    lead <- if (length(filtered) > 0L) {
      paste0("Content filtered: ", paste(filtered, collapse = ", "), ".")
    } else {
      "Content filtered by the Azure AI safety system."
    }
    return(c(i = lead, i = paste0(label, ": ", message)))
  }

  hints <- foundry_error_hints(
    status = status,
    message = message,
    url = resp$url %||% "",
    service = service,
    auth = foundry_error_auth_kind(resp)
  )
  c(
    i = paste0(label, ": ", message),
    stats::setNames(hints, rep("i", length(hints)))
  )
}


# One-line form of foundry_error_body() for per-row error columns.
foundry_error_message <- function(resp, service = "foundry") {
  lines <- tryCatch(
    foundry_classify_error(resp, service = service),
    error = function(e) "API error: (could not read the error response)"
  )
  paste0("HTTP ", httr2::resp_status(resp), ". ", paste(lines, collapse = " "))
}


# Read the message and code from an error body without failing on empty
# bodies, non-JSON text, or a string-valued `error` field.
foundry_error_details <- function(resp) {
  text <- if (httr2::resp_has_body(resp)) {
    tryCatch(httr2::resp_body_string(resp), error = function(e) "")
  } else {
    ""
  }
  body <- tryCatch(
    jsonlite::fromJSON(text, simplifyVector = FALSE),
    error = function(e) NULL
  )
  code <- ""
  message <- NULL
  if (is.list(body)) {
    error <- body$error
    if (is.list(error)) {
      message <- error$message
      code <- error$code %||% ""
    } else if (is.character(error)) {
      message <- error
    }
    message <- message %||% body$message %||% body$detail
  }
  if (is.null(message)) {
    message <- if (nzchar(trimws(text))) text else "(no response body)"
  }
  if (is.list(message)) {
    message <- paste(unlist(message, use.names = FALSE), collapse = " ")
  }
  list(
    message = paste(as.character(message), collapse = " "),
    code = paste(as.character(code), collapse = " "),
    body = if (is.list(body)) body else list()
  )
}


foundry_content_filter_summary <- function(inner) {
  results <- inner$content_filter_result
  if (!is.list(results) || length(results) == 0L) {
    return(character())
  }
  flagged <- vapply(names(results), function(category) {
    result <- results[[category]]
    if (is.list(result) && isTRUE(result$filtered)) {
      paste0(category, " (", result$severity %||% "unknown", ")")
    } else {
      NA_character_
    }
  }, character(1))
  unname(flagged[!is.na(flagged)])
}


# Which credential the failed request carried, when httr2 kept the request.
foundry_error_auth_kind <- function(resp) {
  headers <- tolower(names(resp$request$headers %||% list()))
  if ("authorization" %in% headers) {
    return("token")
  }
  if (any(headers %in% c("api-key", "ocp-apim-subscription-key"))) {
    return("key")
  }
  "unknown"
}


foundry_error_hints <- function(status, message, url, service, auth) {
  project <- grepl("/api/projects/", url, fixed = TRUE)
  content_safety <- identical(service, "content_safety")

  if (status == 401L) {
    key_hint <- if (content_safety) {
      "Check AZURE_CONTENT_SAFETY_KEY, or set it with foundry_set_content_safety_key()."
    } else {
      "Check the API key for this endpoint, or set it with foundry_set_key()."
    }
    token_hint <- paste(
      "Check that the Microsoft Entra ID token is current and issued for the",
      "right audience: https://cognitiveservices.azure.com for resource",
      "endpoints, https://ai.azure.com for project endpoints."
    )
    return(switch(auth, key = key_hint, token = token_hint, c(key_hint, token_hint)))
  }
  if (status == 403L) {
    return(paste(
      "The credential was accepted but lacks permission. Check the identity's",
      "role on the resource or project (for example Cognitive Services OpenAI",
      "User or Azure AI User)."
    ))
  }
  if (status == 404L) {
    if (content_safety) {
      return("Check AZURE_CONTENT_SAFETY_ENDPOINT and the resource or blocklist name.")
    }
    if (grepl("/deployments/", url, fixed = TRUE) ||
        grepl("deployment", message, ignore.case = TRUE)) {
      return("Check the deployment name in the Foundry portal.")
    }
    if (project) {
      return(paste(
        "Check the project endpoint, and whether the object was created on this",
        "project rather than on the resource endpoint."
      ))
    }
    return(paste(
      "Objects created on a Foundry project endpoint are not visible from the",
      "resource endpoint. Pass project_endpoint, or call",
      "foundry_set_route(\"project\"), if you created it there."
    ))
  }
  if (status == 429L) {
    return("The service is rate limiting requests. Wait and retry, lower max_active, or raise the deployment's quota.")
  }
  if (status >= 500L) {
    return("The service reported an internal error. Retry later.")
  }
  if (status == 400L && grepl("not supported for CheckAccess", message, fixed = TRUE)) {
    return(paste(
      "This operation does not accept Microsoft Entra ID tokens. Call it on the",
      "resource endpoint with an API key."
    ))
  }
  if (status == 400L && content_safety &&
      grepl("too long|exceed.*limit|10000|10K", message, ignore.case = TRUE)) {
    return("Content Safety accepts at most 10,000 characters of text per request.")
  }
  character()
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


foundry_perform_raw <- function(req) {
  resp <- httr2::req_perform(req)
  httr2::resp_body_raw(resp)
}


#' Perform Many Requests
#'
#' Internal helper that performs a list of httr2 requests. By default it uses
#' `httr2::req_perform_parallel()` for speed. When the option
#' `foundryR.sequential_requests` is `TRUE`, the requests are performed one at a
#' time with `httr2::req_perform()` instead.
#'
#' Parallel requests bypass httr2's mocking hook, so the sequential path is what
#' lets httptest2 record and replay documentation fixtures for batched calls such
#' as `foundry_embed()` and `foundry_extract()` (see
#' `inst/httptest2/start-vignette.R`). Both paths return a list, in request order,
#' whose elements are either an httr2 response or the error condition raised for
#' that request, mirroring `req_perform_parallel(on_error = "continue")`.
#'
#' @param reqs A list of httr2 request objects.
#' @param progress Passed to `httr2::req_perform_parallel()`.
#' @param max_active Passed to `httr2::req_perform_parallel()`.
#'
#' @return A list of responses or error conditions, in the order of `reqs`.
#' @keywords internal
foundry_req_perform_many <- function(reqs, progress = FALSE, max_active = 2L) {
  if (length(reqs) == 0L) {
    return(list())
  }
  if (isTRUE(getOption("foundryR.sequential_requests", FALSE))) {
    return(lapply(reqs, function(req) {
      tryCatch(httr2::req_perform(req), error = function(e) e)
    }))
  }
  httr2::req_perform_parallel(
    reqs,
    on_error = "continue",
    progress = progress,
    max_active = max_active
  )
}


foundry_write_raw_response <- function(req, path, overwrite = FALSE) {
  if (file.exists(path) && !isTRUE(overwrite)) {
    cli::cli_abort(c(
      "File already exists: {.file {path}}.",
      "i" = "Use {.code overwrite = TRUE} to replace it."
    ))
  }

  bytes <- foundry_perform_raw(req)
  writeBin(bytes, path)
  tibble::tibble(
    path = normalizePath(path, winslash = "/", mustWork = FALSE),
    bytes = length(bytes)
  )
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


foundry_multipart_add <- function(parts, name, values) {
  if (is.null(values)) {
    return(parts)
  }
  values <- as.list(as.character(values))
  names(values) <- rep(name, length(values))
  c(parts, values)
}
