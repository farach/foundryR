#' Create a response with the Azure OpenAI Responses API
#'
#' Use Microsoft Foundry's newer `/openai/v1/responses` API to generate model
#' responses, chain stateful turns with `previous_response_id`, call built-in
#' tools such as web search, and request schema-constrained structured output.
#'
#' @param input Character scalar or list. The user input for the response. A
#'   character scalar is sent directly. A list can contain Responses API input
#'   items for advanced use cases.
#' @param model Character. The model deployment name. Defaults to the
#'   `AZURE_FOUNDRY_MODEL` environment variable.
#' @param instructions Character. Optional system/developer instructions.
#' @param previous_response_id Character. Optional response ID to continue a
#'   stored conversation.
#' @param tools List. Optional Responses API tools, for example
#'   `list(list(type = "web_search"))`.
#' @param text_format List. Optional Responses API text format object. Use
#'   `list(type = "json_object")` for JSON mode or
#'   `list(type = "json_schema", name = ..., schema = ..., strict = TRUE)` for
#'   structured outputs.
#' @param max_output_tokens Integer. Optional maximum generated output tokens.
#' @param temperature Numeric. Optional sampling temperature. Do not use with
#'   reasoning-only models that reject sampling parameters.
#' @param top_p Numeric. Optional nucleus sampling parameter. Do not use with
#'   reasoning-only models that reject sampling parameters.
#' @param reasoning_effort Character. Optional reasoning effort (`"low"`,
#'   `"medium"`, `"high"`, or a newer value supported by your model). Sent as
#'   `reasoning = list(effort = ...)`.
#' @param store Logical or NULL. Whether the service should store the response.
#'   The API stores responses by default when this is omitted. Set `FALSE` for
#'   stateless calls; use `TRUE` or omit it when chaining with
#'   `previous_response_id`.
#' @param metadata List. Optional metadata to attach to the response.
#' @param include Character vector. Optional additional response fields to
#'   include.
#' @param parse_json Logical. Whether to parse `output_text` as JSON into the
#'   `structured` list-column. Defaults to `TRUE` when `text_format` is supplied.
#' @param api_key Character. Optional API key override.
#' @param endpoint Character. Optional endpoint override.
#' @param ... Additional request body parameters passed to the Responses API.
#'
#' @return A one-row tibble with response metadata, generated text, parsed
#'   structured output (if requested), citations, tool calls, token usage, and
#'   the raw response as a list-column.
#'
#' @details
#' The Responses API uses the v1 endpoint style:
#' `https://<resource>.openai.azure.com/openai/v1/responses`. Unlike the older
#' chat-completions API, the model deployment is supplied in the JSON body as
#' `model`.
#'
#' **Stored responses and privacy:** Microsoft Foundry stores Responses API
#' objects by default. Set `store = FALSE` for stateless calls when you do not
#' need server-side conversation state. To use `previous_response_id` chaining,
#' the previous response must have been stored.
#'
#' @references
#' - Azure OpenAI Responses API:
#'   <https://learn.microsoft.com/azure/foundry/openai/how-to/responses>
#' - Azure OpenAI REST API reference:
#'   <https://learn.microsoft.com/azure/foundry/openai/reference>
#'
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_response("Summarize retrieval-augmented generation.", model = "gpt-4.1")
#'
#' first <- foundry_response("Define catastrophic forgetting.", model = "gpt-4.1")
#' foundry_response(
#'   "Explain it for a college freshman.",
#'   model = "gpt-4.1",
#'   previous_response_id = first$response_id
#' )
#' }
foundry_response <- function(input,
                             model = NULL,
                             instructions = NULL,
                             previous_response_id = NULL,
                             tools = NULL,
                             text_format = NULL,
                             max_output_tokens = NULL,
                             temperature = NULL,
                             top_p = NULL,
                             reasoning_effort = NULL,
                             store = NULL,
                             metadata = NULL,
                             include = NULL,
                             parse_json = !is.null(text_format),
                             api_key = NULL,
                             endpoint = NULL,
                             ...) {

  input <- foundry_validate_response_input(input)
  model <- foundry_resolve_model(model)

  body <- list(
    model = model,
    input = input
  )

  if (!is.null(instructions)) {
    foundry_check_character_scalar(instructions, "instructions")
    body$instructions <- instructions
  }

  if (!is.null(previous_response_id)) {
    foundry_check_character_scalar(previous_response_id, "previous_response_id")
    body$previous_response_id <- previous_response_id
  }

  if (!is.null(tools)) {
    if (!is.list(tools)) {
      cli::cli_abort("{.arg tools} must be a list.")
    }
    body$tools <- tools
  }

  if (!is.null(text_format)) {
    if (!is.list(text_format)) {
      cli::cli_abort("{.arg text_format} must be a list.")
    }
    body$text <- list(format = foundry_preserve_schema_arrays(text_format))
  }

  if (!is.null(max_output_tokens)) {
    max_output_tokens <- as.integer(max_output_tokens)
    if (is.na(max_output_tokens) || max_output_tokens < 1L) {
      cli::cli_abort("{.arg max_output_tokens} must be a positive integer.")
    }
    body$max_output_tokens <- max_output_tokens
  }

  if (!is.null(temperature)) body$temperature <- temperature
  if (!is.null(top_p)) body$top_p <- top_p

  if (!is.null(reasoning_effort)) {
    foundry_check_character_scalar(reasoning_effort, "reasoning_effort")
    body$reasoning <- list(effort = reasoning_effort)
  }

  if (!is.null(store)) {
    if (!is.logical(store) || length(store) != 1L || is.na(store)) {
      cli::cli_abort("{.arg store} must be TRUE, FALSE, or NULL.")
    }
    body$store <- store
  }

  if (!is.null(metadata)) {
    if (!is.list(metadata)) {
      cli::cli_abort("{.arg metadata} must be a list.")
    }
    body$metadata <- metadata
  }

  if (!is.null(include)) {
    body$include <- as.list(include)
  }

  dots <- list(...)
  if (length(dots) > 0L) {
    if (is.null(names(dots)) || any(names(dots) == "")) {
      cli::cli_abort("Additional body parameters in {.arg ...} must be named.")
    }
    for (nm in names(dots)) {
      body[[nm]] <- dots[[nm]]
    }
  }

  req <- foundry_build_v1_request(
    path = "responses",
    body = body,
    method = "POST",
    api_key = api_key,
    endpoint = endpoint
  )

  result <- foundry_perform(req)
  foundry_parse_response(result, parse_json = parse_json)
}


#' Retrieve a stored Responses API response
#'
#' @param response_id Character. The response ID to retrieve.
#' @param api_key Character. Optional API key override.
#' @param endpoint Character. Optional endpoint override.
#'
#' @return A one-row tibble parsed like `foundry_response()`.
#' @export
#'
#' @examples
#' \dontrun{
#' response <- foundry_response("Hello", model = "gpt-4.1")
#' foundry_response_retrieve(response$response_id)
#' }
foundry_response_retrieve <- function(response_id,
                                      api_key = NULL,
                                      endpoint = NULL) {
  foundry_check_character_scalar(response_id, "response_id")

  req <- foundry_build_v1_request(
    path = paste0("responses/", response_id),
    method = "GET",
    api_key = api_key,
    endpoint = endpoint
  )

  result <- foundry_perform(req)
  foundry_parse_response(result, parse_json = FALSE)
}


#' Delete a stored Responses API response
#'
#' @param response_id Character. The response ID to delete.
#' @param api_key Character. Optional API key override.
#' @param endpoint Character. Optional endpoint override.
#'
#' @return A tibble with deletion status.
#' @export
#'
#' @examples
#' \dontrun{
#' response <- foundry_response("Hello", model = "gpt-4.1")
#' foundry_response_delete(response$response_id)
#' }
foundry_response_delete <- function(response_id,
                                    api_key = NULL,
                                    endpoint = NULL) {
  foundry_check_character_scalar(response_id, "response_id")

  req <- foundry_build_v1_request(
    path = paste0("responses/", response_id),
    method = "DELETE",
    api_key = api_key,
    endpoint = endpoint
  )

  result <- foundry_perform(req)

  tibble::tibble(
    response_id = result$id %||% response_id,
    deleted = result$deleted %||% NA
  )
}


#' Extract structured data from text using JSON Schema
#'
#' Apply a JSON Schema to one or more text inputs and return model-extracted
#' fields as a tidy tibble. This is useful for research coding tasks such as
#' sentiment annotation, entity extraction, study abstraction, and converting
#' free-text records into analyzable variables.
#'
#' @param text Character vector. Texts to extract from.
#' @param schema List. JSON Schema object describing the fields to extract.
#' @param instructions Character. Optional extraction instructions. If omitted,
#'   a concise default extraction instruction is used.
#' @param schema_name Character. Name for the JSON Schema format.
#' @param strict Logical. Whether the model must strictly follow the schema.
#' @param model Character. The model deployment name. Defaults to
#'   `AZURE_FOUNDRY_MODEL`.
#' @param flatten Logical. If `TRUE`, top-level schema fields are returned as
#'   tibble columns. Nested objects and arrays become list-columns. If `FALSE`,
#'   parsed data is returned in a `.data` list-column.
#' @param store Logical. Whether to store Responses API objects. Defaults to
#'   `FALSE` because bulk extraction often processes sensitive research data.
#' @param api_key Character. Optional API key override.
#' @param endpoint Character. Optional endpoint override.
#' @param ... Additional parameters passed to `foundry_response()`.
#'
#' @return A tibble with one row per input text. Metadata columns are prefixed
#'   with `.`, followed by extracted schema fields when `flatten = TRUE`.
#'
#' @references
#' - Structured outputs:
#'   <https://learn.microsoft.com/azure/foundry/openai/how-to/structured-outputs>
#'
#' @export
#'
#' @examples
#' \dontrun{
#' schema <- list(
#'   type = "object",
#'   properties = list(
#'     sentiment = list(type = "string", enum = c("positive", "negative", "neutral")),
#'     entities = list(type = "array", items = list(type = "string"))
#'   ),
#'   required = c("sentiment", "entities"),
#'   additionalProperties = FALSE
#' )
#'
#' foundry_extract(
#'   c("I love using R with Azure.", "The workflow was slow and confusing."),
#'   schema = schema,
#'   model = "gpt-4.1"
#' )
#' }
foundry_extract <- function(text,
                            schema,
                            instructions = NULL,
                            schema_name = "ExtractedData",
                            strict = TRUE,
                            model = NULL,
                            flatten = TRUE,
                            store = FALSE,
                            api_key = NULL,
                            endpoint = NULL,
                            ...) {

  if (missing(text) || is.null(text) || !is.character(text)) {
    cli::cli_abort("{.arg text} must be a character vector.")
  }
  if (missing(schema) || is.null(schema) || !is.list(schema)) {
    cli::cli_abort("{.arg schema} must be a JSON Schema represented as an R list.")
  }
  foundry_check_character_scalar(schema_name, "schema_name")
  if (!is.logical(strict) || length(strict) != 1L || is.na(strict)) {
    cli::cli_abort("{.arg strict} must be TRUE or FALSE.")
  }
  if (!is.logical(flatten) || length(flatten) != 1L || is.na(flatten)) {
    cli::cli_abort("{.arg flatten} must be TRUE or FALSE.")
  }

  if (is.null(instructions)) {
    instructions <- paste(
      "Extract the requested structured data from the input text.",
      "Return values that conform exactly to the supplied JSON Schema."
    )
  } else {
    foundry_check_character_scalar(instructions, "instructions")
  }

  if (length(text) == 0L) {
    out <- tibble::tibble(
      .input_idx = integer(),
      .input_text = character(),
      .response_id = character(),
      .status = character(),
      .output_text = character(),
      .error = logical(),
      .error_msg = character()
    )
    if (!flatten) out$.data <- list()
    return(out)
  }

  text_format <- foundry_json_schema_format(
    schema = schema,
    schema_name = schema_name,
    strict = strict
  )

  rows <- purrr::map(seq_along(text), function(i) {
    single_text <- text[i]

    if (is.na(single_text)) {
      base <- tibble::tibble(
        .input_idx = i,
        .input_text = NA_character_,
        .response_id = NA_character_,
        .status = "skipped",
        .output_text = NA_character_,
        .error = TRUE,
        .error_msg = "Input text is NA."
      )
      if (!flatten) base$.data <- list(NULL)
      return(base)
    }

    response <- foundry_response(
      input = single_text,
      model = model,
      instructions = instructions,
      text_format = text_format,
      store = store,
      parse_json = TRUE,
      api_key = api_key,
      endpoint = endpoint,
      ...
    )

    if (!is.na(response$structured_error)) {
      cli::cli_abort(c(
        "Failed to parse structured output for input {i}.",
        "x" = response$structured_error
      ))
    }

    base <- tibble::tibble(
      .input_idx = i,
      .input_text = single_text,
      .response_id = response$response_id,
      .status = response$status,
      .output_text = response$output_text,
      .error = FALSE,
      .error_msg = NA_character_
    )

    data <- response$structured[[1]]
    if (!flatten) {
      base$.data <- list(data)
      return(base)
    }

    dplyr::bind_cols(base, foundry_list_to_row(data))
  })

  dplyr::bind_rows(rows)
}


#' Search the web with the Responses API
#'
#' Ask a model to use Microsoft Foundry's `web_search` tool and return a tidy
#' response with extracted citations and tool-call metadata.
#'
#' @param query Character. The question or task that needs current web
#'   information.
#' @param model Character. The model deployment name. Defaults to
#'   `AZURE_FOUNDRY_MODEL`.
#' @param instructions Character. Optional instructions for how to use and cite
#'   web results.
#' @param search_context_size Character. Search context budget: `"low"`,
#'   `"medium"`, or `"high"`.
#' @param country,city,region,timezone Optional approximate user location fields
#'   for localized results.
#' @param reasoning_effort Character. Optional reasoning effort for reasoning
#'   models.
#' @param store Logical. Whether to store the response. Defaults to `FALSE`.
#' @param api_key Character. Optional API key override.
#' @param endpoint Character. Optional endpoint override.
#' @param ... Additional parameters passed to `foundry_response()`.
#'
#' @return A one-row tibble parsed like `foundry_response()`, including
#'   `citations` and `tool_calls` list-columns.
#'
#' @details
#' Web search uses Grounding with Bing Search and/or Grounding with Bing Custom
#' Search. Microsoft documents that the Data Protection Addendum does not apply
#' to data sent to these services, data can leave compliance and geographic
#' boundaries, and tool usage can incur additional costs.
#'
#' @references
#' - Web search with the Responses API:
#'   <https://learn.microsoft.com/azure/foundry/openai/how-to/web-search>
#'
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_web_search(
#'   "What are the latest Azure AI Foundry Responses API updates?",
#'   model = "gpt-4.1"
#' )
#' }
foundry_web_search <- function(query,
                               model = NULL,
                               instructions = NULL,
                               search_context_size = c("medium", "low", "high"),
                               country = NULL,
                               city = NULL,
                               region = NULL,
                               timezone = NULL,
                               reasoning_effort = NULL,
                               store = FALSE,
                               api_key = NULL,
                               endpoint = NULL,
                               ...) {

  foundry_check_character_scalar(query, "query")
  search_context_size <- match.arg(search_context_size)
  foundry_warn_web_search()

  tool <- list(
    type = "web_search",
    search_context_size = search_context_size
  )

  location <- list(
    country = country,
    city = city,
    region = region,
    timezone = timezone
  )
  location <- location[!vapply(location, is.null, logical(1))]
  if (length(location) > 0L) {
    tool$user_location <- c(list(type = "approximate"), location)
  }

  if (is.null(instructions)) {
    instructions <- paste(
      "Use web search when it helps answer the question.",
      "Cite sources and avoid unsupported claims."
    )
  }

  foundry_response(
    input = query,
    model = model,
    instructions = instructions,
    tools = list(tool),
    reasoning_effort = reasoning_effort,
    store = store,
    api_key = api_key,
    endpoint = endpoint,
    ...
  )
}


#' Parse Responses API response
#'
#' @param result List. Parsed JSON response.
#' @param parse_json Logical. Whether to parse `output_text` as JSON.
#'
#' @return A one-row tibble.
#' @keywords internal
foundry_parse_response <- function(result, parse_json = FALSE) {
  output_text <- foundry_response_output_text(result)
  structured <- NULL
  structured_error <- NA_character_

  if (isTRUE(parse_json) && !is.na(output_text) && nzchar(output_text)) {
    parsed <- foundry_parse_json_output(output_text)
    structured <- parsed$value
    structured_error <- parsed$error
  }

  usage <- result$usage %||% list()
  created_at <- result$created_at %||% result$created

  tibble::tibble(
    response_id = result$id %||% NA_character_,
    status = result$status %||% NA_character_,
    model = result$model %||% NA_character_,
    output_text = output_text,
    structured = list(structured),
    structured_error = structured_error,
    citations = list(foundry_response_citations(result)),
    tool_calls = list(foundry_response_tool_calls(result)),
    refusal = foundry_response_refusal(result),
    incomplete_reason = result$incomplete_details$reason %||% NA_character_,
    created_at = foundry_response_created_at(created_at),
    input_tokens = usage$input_tokens %||% usage$prompt_tokens %||% NA_integer_,
    output_tokens = usage$output_tokens %||% usage$completion_tokens %||% NA_integer_,
    reasoning_tokens = usage$output_tokens_details$reasoning_tokens %||% NA_integer_,
    total_tokens = usage$total_tokens %||% NA_integer_,
    raw_response = list(result)
  )
}


foundry_resolve_model <- function(model) {
  if (is.null(model)) {
    model <- Sys.getenv("AZURE_FOUNDRY_MODEL")
    if (model == "") {
      cli::cli_abort(c(
        "Model/deployment name is required.",
        "i" = "Specify {.arg model} or set the {.envvar AZURE_FOUNDRY_MODEL} environment variable."
      ))
    }
  }
  foundry_check_character_scalar(model, "model")
  model
}


foundry_check_character_scalar <- function(x, arg) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || x == "") {
    cli::cli_abort("{.arg {arg}} must be a single non-empty character string.")
  }
  invisible(x)
}


foundry_validate_response_input <- function(input) {
  if (missing(input) || is.null(input)) {
    cli::cli_abort("{.arg input} is required.")
  }

  if (is.character(input)) {
    if (length(input) != 1L || is.na(input) || input == "") {
      cli::cli_abort("{.arg input} must be a single non-empty character string.")
    }
    return(input)
  }

  if (is.list(input)) {
    return(input)
  }

  cli::cli_abort("{.arg input} must be a character string or list of Responses API input items.")
}


foundry_json_schema_format <- function(schema, schema_name, strict = TRUE) {
  list(
    type = "json_schema",
    name = schema_name,
    schema = foundry_preserve_schema_arrays(schema),
    strict = strict
  )
}


foundry_preserve_schema_arrays <- function(x, name = NULL) {
  if (is.list(x)) {
    nms <- names(x)
    for (i in seq_along(x)) {
      child_name <- NULL
      if (!is.null(nms) && nzchar(nms[[i]] %||% "")) {
        child_name <- nms[[i]]
      }
      x[[i]] <- foundry_preserve_schema_arrays(x[[i]], child_name)
    }
    return(x)
  }

  if (!is.null(name) && name %in% c("required", "enum") && is.atomic(x)) {
    return(I(x))
  }

  x
}


foundry_response_output_text <- function(result) {
  output <- result$output %||% list()
  text_parts <- character()

  for (item in output) {
    if (!identical(item$type %||% NA_character_, "message")) next
    content <- item$content %||% list()
    for (part in content) {
      part_type <- part$type %||% NA_character_
      if (part_type %in% c("output_text", "text") && !is.null(part$text)) {
        text_parts <- c(text_parts, part$text)
      }
    }
  }

  if (length(text_parts) > 0L) {
    return(paste(text_parts, collapse = "\n"))
  }

  result$output_text %||% NA_character_
}


foundry_response_refusal <- function(result) {
  output <- result$output %||% list()
  refusals <- character()

  for (item in output) {
    if (!identical(item$type %||% NA_character_, "message")) next
    content <- item$content %||% list()
    for (part in content) {
      if (identical(part$type %||% NA_character_, "refusal")) {
        refusals <- c(refusals, part$refusal %||% part$text %||% NA_character_)
      }
    }
  }

  refusals <- refusals[!is.na(refusals)]
  if (length(refusals) == 0L) NA_character_ else paste(refusals, collapse = "\n")
}


foundry_response_citations <- function(result) {
  output <- result$output %||% list()
  rows <- list()

  for (item in output) {
    if (!identical(item$type %||% NA_character_, "message")) next
    content <- item$content %||% list()
    for (part in content) {
      annotations <- part$annotations %||% list()
      if (length(annotations) == 0L) next
      for (annotation in annotations) {
        if (!identical(annotation$type %||% NA_character_, "url_citation")) next
        rows[[length(rows) + 1L]] <- tibble::tibble(
          url = annotation$url %||% NA_character_,
          title = annotation$title %||% NA_character_,
          start_index = as.integer(annotation$start_index %||% NA_integer_),
          end_index = as.integer(annotation$end_index %||% NA_integer_)
        )
      }
    }
  }

  if (length(rows) == 0L) {
    return(tibble::tibble(
      url = character(),
      title = character(),
      start_index = integer(),
      end_index = integer()
    ))
  }

  dplyr::bind_rows(rows)
}


foundry_response_tool_calls <- function(result) {
  output <- result$output %||% list()
  rows <- list()

  for (item in output) {
    type <- item$type %||% NA_character_
    if (is.na(type) || !(grepl("_call$", type) || identical(type, "function_call"))) {
      next
    }

    action <- item$action %||% list()
    rows[[length(rows) + 1L]] <- tibble::tibble(
      id = item$id %||% NA_character_,
      type = type,
      status = item$status %||% NA_character_,
      name = item$name %||% NA_character_,
      call_id = item$call_id %||% NA_character_,
      action_type = action$type %||% NA_character_,
      query = action$query %||% NA_character_,
      arguments = item$arguments %||% NA_character_
    )
  }

  if (length(rows) == 0L) {
    return(tibble::tibble(
      id = character(),
      type = character(),
      status = character(),
      name = character(),
      call_id = character(),
      action_type = character(),
      query = character(),
      arguments = character()
    ))
  }

  dplyr::bind_rows(rows)
}


foundry_parse_json_output <- function(output_text) {
  tryCatch(
    list(
      value = jsonlite::fromJSON(output_text, simplifyVector = FALSE),
      error = NA_character_
    ),
    error = function(e) {
      list(
        value = NULL,
        error = conditionMessage(e)
      )
    }
  )
}


foundry_response_created_at <- function(created_at) {
  if (is.null(created_at) || is.na(created_at)) {
    return(as.POSIXct(NA_real_, origin = "1970-01-01", tz = "UTC"))
  }

  as.POSIXct(as.numeric(created_at), origin = "1970-01-01", tz = "UTC")
}


foundry_list_to_row <- function(x) {
  if (is.null(x)) {
    return(tibble::tibble())
  }

  if (!is.list(x) || is.null(names(x))) {
    return(tibble::tibble(value = list(x)))
  }

  fields <- lapply(x, function(value) {
    value <- foundry_simplify_json_value(value)
    if (is.null(value)) {
      list(NULL)
    } else if (is.atomic(value) && length(value) == 1L) {
      value
    } else {
      list(value)
    }
  })

  tibble::as_tibble(fields)
}


foundry_simplify_json_value <- function(value) {
  if (!is.list(value) || !is.null(names(value))) {
    return(value)
  }

  is_scalar_atomic <- vapply(value, function(item) {
    is.atomic(item) && length(item) == 1L
  }, logical(1))

  if (length(value) > 0L && all(is_scalar_atomic)) {
    return(unlist(value, use.names = FALSE))
  }

  value
}


foundry_warn_web_search <- function() {
  if (isTRUE(getOption("foundryR.web_search_warning", FALSE))) {
    return(invisible(NULL))
  }

  cli::cli_warn(c(
    "!" = "Web search sends query data to Grounding with Bing services.",
    "i" = "Microsoft documents that this can leave compliance/geographic boundaries and incur additional costs.",
    "i" = "Set {.code options(foundryR.web_search_warning = TRUE)} to suppress this warning."
  ))
  options(foundryR.web_search_warning = TRUE)
  invisible(NULL)
}
