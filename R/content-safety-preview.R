#' Detect protected material in code
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Check source code for matches against public code repositories using the
#' Azure AI Content Safety protected-material-for-code detector. This is the
#' code counterpart to [foundry_protected_material()], useful for flagging
#' LLM-generated code that reproduces licensed material.
#'
#' @section Preview API:
#' This operation is documented only in the Azure AI Content Safety Learn
#' quickstarts and has no published OpenAPI specification. It requires the
#' `2024-09-15-preview` api-version and its contract may change.
#'
#' @param code Character vector. One or more code snippets to check.
#' @param endpoint Character. Optional Content Safety endpoint. Defaults to the
#'   `AZURE_CONTENT_SAFETY_ENDPOINT` environment variable.
#' @param api_key Character. Optional Content Safety key. Defaults to the
#'   `AZURE_CONTENT_SAFETY_KEY` environment variable.
#' @param api_version Character. API version. Defaults to
#'   `"2024-09-15-preview"`.
#'
#' @return A tibble with one row per input snippet:
#'   \describe{
#'     \item{code}{Character. The input snippet.}
#'     \item{detected}{Logical. `TRUE` when protected material was detected.}
#'     \item{citations}{List. A tibble of `license` and `source_urls` for each
#'       matched code citation.}
#'     \item{raw_response}{List. The parsed API response.}
#'   }
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_protected_code("import pygame\npygame.init()")
#' }
foundry_protected_code <- function(code,
                                   endpoint = NULL,
                                   api_key = NULL,
                                   api_version = "2024-09-15-preview") {
  if (!is.character(code)) {
    cli::cli_abort("{.arg code} must be a character vector.")
  }

  purrr::map_dfr(seq_along(code), function(i) {
    if (is.na(code[[i]])) {
      return(tibble::tibble(
        code = NA_character_,
        detected = NA,
        citations = list(foundry_code_citations_tibble(list())),
        raw_response = list(NULL)
      ))
    }

    req <- foundry_content_safety_request(
      "text:detectProtectedMaterialForCode",
      body = list(code = code[[i]]),
      endpoint = endpoint,
      api_key = api_key,
      api_version = api_version
    )
    result <- foundry_perform(req)

    analysis <- result$protectedMaterialAnalysis %||% list()
    detected <- analysis$detected %||% result$detected %||% FALSE
    citations <- analysis$codeCitations %||% list()

    tibble::tibble(
      code = code[[i]],
      detected = detected,
      citations = list(foundry_code_citations_tibble(citations)),
      raw_response = list(result)
    )
  })
}


# Flatten codeCitations (list of {license, sourceUrls}) into a tidy tibble.
foundry_code_citations_tibble <- function(citations) {
  if (length(citations) == 0L) {
    return(tibble::tibble(
      license = character(),
      source_urls = list()
    ))
  }
  purrr::map_dfr(citations, function(citation) {
    urls <- citation$sourceUrls %||% list()
    tibble::tibble(
      license = citation$license %||% NA_character_,
      source_urls = list(unlist(urls, use.names = FALSE))
    )
  })
}


#' Moderate an image together with its text
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Analyze an image and optional accompanying text in a single multimodal
#' Content Safety call. Optical character recognition can read text embedded in
#' the image so that harmful captions or overlays are caught alongside the
#' picture.
#'
#' @section Preview API:
#' This operation is documented only in the Azure AI Content Safety Learn
#' quickstarts and has no published OpenAPI specification. It requires the
#' `2024-09-15-preview` api-version and, at time of writing, is available only
#' in a subset of Azure regions.
#'
#' @param image Character. Local image path or HTTPS Azure Blob Storage URL.
#' @param text Character. Optional text shown with the image (max 1,000 code
#'   points).
#' @param categories Character vector of harm categories. Defaults to all four.
#' @param enable_ocr Logical. When `TRUE`, run OCR on the image to recognize
#'   embedded text. Default `TRUE`.
#' @param endpoint Character. Optional Content Safety endpoint.
#' @param api_key Character. Optional Content Safety key.
#' @param api_version Character. API version. Defaults to
#'   `"2024-09-15-preview"`.
#'
#' @return A tibble with one row per harm category, matching
#'   [foundry_moderate_image()]: `source`, `category`, `severity`, `label`, and
#'   `raw_response`. Multimodal analysis returns four-level severities
#'   (0, 2, 4, 6).
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_moderate_multimodal(
#'   image = "meme.png",
#'   text = "caption under the image",
#'   enable_ocr = TRUE
#' )
#' }
foundry_moderate_multimodal <- function(image,
                                        text = NULL,
                                        categories = c("Hate", "Sexual", "SelfHarm", "Violence"),
                                        enable_ocr = TRUE,
                                        endpoint = NULL,
                                        api_key = NULL,
                                        api_version = "2024-09-15-preview") {
  foundry_check_character_scalar(image, "image")
  foundry_check_logical_scalar(enable_ocr, "enable_ocr")

  valid_categories <- c("Hate", "Sexual", "SelfHarm", "Violence")
  if (!all(categories %in% valid_categories)) {
    invalid <- setdiff(categories, valid_categories)
    cli::cli_abort(c(
      "Invalid categories: {.val {invalid}}",
      "i" = "Valid categories are: {.val {valid_categories}}"
    ))
  }
  if (!is.null(text)) {
    foundry_check_character_scalar(text, "text")
  }

  body <- list(
    image = foundry_image_body(image),
    categories = as.list(categories),
    enableOcr = enable_ocr
  )
  if (!is.null(text)) {
    body$text <- text
  }

  req <- foundry_content_safety_request(
    "imageWithText:analyze",
    body = body,
    endpoint = endpoint,
    api_key = api_key,
    api_version = api_version
  )
  result <- foundry_perform(req)
  foundry_parse_safety_categories(result, image, "FourSeverityLevels")
}


#' Check an agent transcript for task adherence
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Evaluate whether an agent's tool calls and responses stayed aligned with the
#' user's request using the Azure AI Content Safety task-adherence detector.
#' This flags agents that take unrequested or unsafe actions.
#'
#' @section Preview API:
#' This operation is documented only in the Azure AI Content Safety Learn
#' quickstart and has no published OpenAPI specification. It requires the
#' `2025-09-15-preview` api-version and its contract may change.
#'
#' @param messages List. The conversation turns to analyze. Build each turn with
#'   [foundry_agent_message()], or supply raw lists matching the Content Safety
#'   schema.
#' @param tools List. Optional tool definitions available to the agent. Build
#'   each with [foundry_agent_tool()], or supply raw lists. Default `NULL`.
#' @param endpoint Character. Optional Content Safety endpoint.
#' @param api_key Character. Optional Content Safety key.
#' @param api_version Character. API version. Defaults to
#'   `"2025-09-15-preview"`.
#'
#' @return A tibble with one row:
#'   \describe{
#'     \item{task_risk_detected}{Logical. `TRUE` when misaligned tool use was
#'       detected.}
#'     \item{details}{Character. Explanation of the detected risk, or `NA` when
#'       none.}
#'     \item{raw_response}{List. The parsed API response.}
#'   }
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_task_adherence(
#'   tools = list(
#'     foundry_agent_tool("get_credit_card_limit", "Get the user's credit limit")
#'   ),
#'   messages = list(
#'     foundry_agent_message("Prompt", "User", "What is my limit?"),
#'     foundry_agent_message(
#'       "Completion", "Assistant", "Checking now",
#'       tool_calls = list(
#'         foundry_agent_tool_call("get_credit_card_limit", id = "call_001")
#'       )
#'     )
#'   )
#' )
#' }
foundry_task_adherence <- function(messages,
                                   tools = NULL,
                                   endpoint = NULL,
                                   api_key = NULL,
                                   api_version = "2025-09-15-preview") {
  if (!is.list(messages) || length(messages) == 0L) {
    cli::cli_abort("{.arg messages} must be a non-empty list of message turns.")
  }
  if (!is.null(tools) && !is.list(tools)) {
    cli::cli_abort("{.arg tools} must be a list of tool definitions or {.code NULL}.")
  }

  body <- list(messages = messages)
  if (!is.null(tools)) {
    body$tools <- tools
  }

  req <- foundry_content_safety_request(
    "agent:analyzeTaskAdherence",
    body = body,
    endpoint = endpoint,
    api_key = api_key,
    api_version = api_version
  )
  result <- foundry_perform(req)

  tibble::tibble(
    task_risk_detected = result$taskRiskDetected %||% NA,
    details = result$details %||% NA_character_,
    raw_response = list(result)
  )
}


#' Describe an agent tool for task adherence
#'
#' Build a single tool definition for the `tools` argument of
#' [foundry_task_adherence()].
#'
#' @param name Character. The tool (function) name.
#' @param description Character. What the tool does.
#'
#' @return A named list matching the task-adherence tool schema.
#' @export
#'
#' @examples
#' foundry_agent_tool("order_car", "Buy a particular car model")
foundry_agent_tool <- function(name, description) {
  foundry_check_character_scalar(name, "name")
  foundry_check_character_scalar(description, "description")
  list(
    type = "function",
    "function" = list(
      name = name,
      description = description
    )
  )
}


#' Describe an agent tool call for task adherence
#'
#' Build a single tool-call entry for the `tool_calls` argument of
#' [foundry_agent_message()].
#'
#' @param name Character. The called function name.
#' @param id Character. The tool-call identifier, referenced later by a `Tool`
#'   message's `tool_call_id`.
#' @param arguments Character. The serialized call arguments. Default `""`.
#'
#' @return A named list matching the task-adherence tool-call schema.
#' @export
#'
#' @examples
#' foundry_agent_tool_call("get_credit_card_limit", id = "call_001")
foundry_agent_tool_call <- function(name, id, arguments = "") {
  foundry_check_character_scalar(name, "name")
  foundry_check_character_scalar(id, "id")
  if (!is.character(arguments) || length(arguments) != 1L || is.na(arguments)) {
    cli::cli_abort("{.arg arguments} must be a single character string.")
  }
  list(
    type = "function",
    "function" = list(
      name = name,
      arguments = arguments
    ),
    id = id
  )
}


#' Describe an agent message for task adherence
#'
#' Build a single conversation turn for the `messages` argument of
#' [foundry_task_adherence()].
#'
#' @param source Character. `"Prompt"` for the original user request or
#'   `"Completion"` for anything the agent produced.
#' @param role Character. `"User"`, `"Assistant"`, or `"Tool"`.
#' @param contents Character. Optional message text.
#' @param tool_calls List. Optional tool calls issued by an assistant turn.
#'   Build each with [foundry_agent_tool_call()].
#' @param tool_call_id Character. Optional identifier tying a `Tool` turn back to
#'   the tool call it answers.
#'
#' @return A named list matching the task-adherence message schema.
#' @export
#'
#' @examples
#' foundry_agent_message("Prompt", "User", "How many can I buy?")
foundry_agent_message <- function(source,
                                  role,
                                  contents = NULL,
                                  tool_calls = NULL,
                                  tool_call_id = NULL) {
  source <- match.arg(source, c("Prompt", "Completion"))
  role <- match.arg(role, c("User", "Assistant", "Tool"))
  if (!is.null(contents)) {
    foundry_check_character_scalar(contents, "contents")
  }
  if (!is.null(tool_calls) && !is.list(tool_calls)) {
    cli::cli_abort("{.arg tool_calls} must be a list of tool calls or {.code NULL}.")
  }
  if (!is.null(tool_call_id)) {
    foundry_check_character_scalar(tool_call_id, "tool_call_id")
  }

  message <- list(source = source, role = role)
  if (!is.null(contents)) {
    message$contents <- contents
  }
  if (!is.null(tool_calls)) {
    message$toolCalls <- tool_calls
  }
  if (!is.null(tool_call_id)) {
    message$toolCallId <- tool_call_id
  }
  message
}
