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
#' @param conversation Character. Optional conversation ID for server-side
#'   conversation state.
#' @param tools List. Optional Responses API tools, for example
#'   `list(list(type = "web_search"))` or a list of [foundry_tool()] objects.
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
#' @param reasoning_summary Character. Optional reasoning summary mode for
#'   models that support it.
#' @param store Logical or NULL. Whether the service should store the response.
#'   The API stores responses by default when this is omitted. Set `FALSE` for
#'   stateless calls; use `TRUE` or omit it when chaining with
#'   `previous_response_id`.
#' @param background Logical. Whether to run the response in the background.
#' @param prompt_cache_key,prompt_cache_retention Optional prompt-cache controls.
#' @param parallel_tool_calls Logical. Whether the service may call tools in
#'   parallel.
#' @param max_tool_calls Integer. Optional maximum number of tool calls.
#' @param safety_identifier Character. Optional stable end-user identifier for
#'   safety monitoring.
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
                             reasoning_summary = NULL,
                             store = NULL,
                             background = NULL,
                             conversation = NULL,
                             prompt_cache_key = NULL,
                             prompt_cache_retention = NULL,
                             parallel_tool_calls = NULL,
                             max_tool_calls = NULL,
                             safety_identifier = NULL,
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

  if (!is.null(conversation)) {
    foundry_check_character_scalar(conversation, "conversation")
    body$conversation <- conversation
  }

  if (!is.null(tools)) {
    if (!is.list(tools)) {
      cli::cli_abort("{.arg tools} must be a list.")
    }
    body$tools <- foundry_tool_schemas(tools)
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
  if (!is.null(reasoning_summary)) {
    foundry_check_character_scalar(reasoning_summary, "reasoning_summary")
    body$reasoning <- body$reasoning %||% list()
    body$reasoning$summary <- reasoning_summary
  }

  if (!is.null(store)) {
    if (!is.logical(store) || length(store) != 1L || is.na(store)) {
      cli::cli_abort("{.arg store} must be TRUE, FALSE, or NULL.")
    }
    body$store <- store
  }

  if (!is.null(background)) {
    foundry_check_logical_scalar(background, "background")
    body$background <- background
  }
  if (!is.null(prompt_cache_key)) {
    foundry_check_character_scalar(prompt_cache_key, "prompt_cache_key")
    body$prompt_cache_key <- prompt_cache_key
  }
  if (!is.null(prompt_cache_retention)) {
    foundry_check_character_scalar(prompt_cache_retention, "prompt_cache_retention")
    body$prompt_cache_retention <- prompt_cache_retention
  }
  if (!is.null(parallel_tool_calls)) {
    foundry_check_logical_scalar(parallel_tool_calls, "parallel_tool_calls")
    body$parallel_tool_calls <- parallel_tool_calls
  }
  if (!is.null(max_tool_calls)) {
    body$max_tool_calls <- foundry_check_positive_integer(max_tool_calls, "max_tool_calls")
  }
  if (!is.null(safety_identifier)) {
    foundry_check_character_scalar(safety_identifier, "safety_identifier")
    body$safety_identifier <- safety_identifier
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


#' Define an R function as a Responses API tool
#'
#' Create a tool definition for `foundry_response()` or `foundry_agent()`. The
#' request sent to Azure uses the Responses API function-tool contract, while
#' the returned object also keeps the R function needed for local dispatch.
#'
#' @param fun Function. The R function to run when the model calls the tool.
#' @param name Character. Tool name exposed to the model. If omitted and `fun`
#'   is a named function object, the object name is used.
#' @param description Character. Short description of what the tool does.
#' @param parameters List. JSON Schema object describing function arguments.
#'
#' @return A `foundry_tool` object. It is a list containing the JSON tool schema
#'   and the R function used by `foundry_agent()`.
#' @export
#'
#' @examples
#' get_weather <- function(location) {
#'   list(location = location, temperature = "70 F")
#' }
#'
#' weather_tool <- foundry_tool(
#'   get_weather,
#'   description = "Get weather for a location",
#'   parameters = list(
#'     type = "object",
#'     properties = list(location = list(type = "string")),
#'     required = "location"
#'   )
#' )
foundry_tool <- function(fun,
                         name = NULL,
                         description,
                         parameters) {
  if (!is.function(fun)) {
    cli::cli_abort("{.arg fun} must be an R function.")
  }

  fun_expr <- substitute(fun)
  if (is.null(name)) {
    if (is.call(fun_expr) && identical(fun_expr[[1]], quote(`function`))) {
      cli::cli_abort("{.arg name} is required for anonymous functions.")
    }
    name <- deparse(fun_expr, nlines = 1L)
  }
  foundry_check_character_scalar(name, "name")
  if (!grepl("^[A-Za-z0-9_-]{1,64}$", name)) {
    cli::cli_abort("{.arg name} must contain only letters, numbers, underscores, or hyphens, and be 64 characters or fewer.")
  }
  foundry_check_character_scalar(description, "description")
  if (missing(parameters) || is.null(parameters) || !is.list(parameters)) {
    cli::cli_abort("{.arg parameters} must be a JSON Schema represented as an R list.")
  }

  structure(
    list(
      type = "function",
      name = name,
      description = description,
      parameters = foundry_preserve_schema_arrays(parameters),
      .fn = fun
    ),
    class = "foundry_tool"
  )
}


#' Run a bounded Responses API tool-calling loop
#'
#' `foundry_agent()` sends a prompt to the Responses API with user-defined R
#' tools, executes any returned function calls locally, sends matching
#' `function_call_output` items back to the service, and repeats until the model
#' returns a final answer or `max_iterations` is reached.
#'
#' @param input Character scalar or list. Initial user input for the response.
#' @param tools A [foundry_tool()] object or list of `foundry_tool` objects.
#' @param model Character. The model deployment name. Defaults to the
#'   `AZURE_FOUNDRY_MODEL` environment variable.
#' @param instructions Character. Optional system/developer instructions.
#' @param max_iterations Integer. Maximum number of model responses in the loop.
#' @param store Logical. Whether Responses API objects should be stored.
#'   Defaults to `TRUE` because the loop uses `previous_response_id`.
#' @param reasoning_effort Character. Optional reasoning effort for reasoning
#'   models.
#' @param max_output_tokens,temperature,top_p Optional generation controls passed
#'   to `foundry_response()`.
#' @param api_key Character. Optional API key override.
#' @param endpoint Character. Optional endpoint override.
#' @param ... Additional request body parameters passed to `foundry_response()`.
#'
#' @return A tibble with one row per model response. It includes the standard
#'   `foundry_response()` columns plus `iteration`, `final`, and `tool_results`
#'   list-columns for executed R tools.
#' @export
#'
#' @references
#' - Responses API function calling:
#'   <https://learn.microsoft.com/azure/foundry/openai/how-to/responses#function-calling>
#'
#' @examples
#' \dontrun{
#' get_weather <- function(location) {
#'   list(location = location, temperature = "70 F")
#' }
#'
#' weather_tool <- foundry_tool(
#'   get_weather,
#'   description = "Get weather for a location",
#'   parameters = list(
#'     type = "object",
#'     properties = list(location = list(type = "string")),
#'     required = "location"
#'   )
#' )
#'
#' foundry_agent(
#'   "What is the weather in San Francisco?",
#'   tools = list(weather_tool),
#'   model = "gpt-4.1"
#' )
#' }
foundry_agent <- function(input,
                          tools,
                          model = NULL,
                          instructions = NULL,
                          max_iterations = 8L,
                          store = TRUE,
                          reasoning_effort = NULL,
                          max_output_tokens = NULL,
                          temperature = NULL,
                          top_p = NULL,
                          api_key = NULL,
                          endpoint = NULL,
                          ...) {

  tools <- foundry_validate_agent_tools(tools)
  max_iterations <- foundry_check_positive_integer(max_iterations, "max_iterations")
  if (!is.logical(store) || length(store) != 1L || is.na(store)) {
    cli::cli_abort("{.arg store} must be TRUE or FALSE.")
  }

  turns <- list()
  current_input <- input
  previous_response_id <- NULL

  for (iteration in seq_len(max_iterations)) {
    response <- foundry_response(
      input = current_input,
      model = model,
      instructions = instructions,
      previous_response_id = previous_response_id,
      tools = tools,
      max_output_tokens = max_output_tokens,
      temperature = temperature,
      top_p = top_p,
      reasoning_effort = reasoning_effort,
      store = store,
      api_key = api_key,
      endpoint = endpoint,
      ...
    )

    tool_calls <- response$tool_calls[[1]]
    has_tool_calls <- nrow(tool_calls) > 0L &&
      any(identical(tool_calls$type, "function_call") | tool_calls$type == "function_call")

    if (!has_tool_calls) {
      response$iteration <- iteration
      response$final <- TRUE
      response$tool_results <- list(foundry_empty_tool_results())
      turns[[length(turns) + 1L]] <- response
      return(dplyr::bind_rows(turns))
    }

    if (iteration >= max_iterations) {
      cli::cli_abort(c(
        "Maximum tool iterations reached before a final response.",
        "i" = "Increase {.arg max_iterations} if the model needs more tool calls."
      ))
    }

    tool_results <- foundry_execute_tool_calls(tool_calls, tools)
    response$iteration <- iteration
    response$final <- FALSE
    response$tool_results <- list(tool_results$results)
    turns[[length(turns) + 1L]] <- response

    previous_response_id <- response$response_id
    current_input <- tool_results$input
  }
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


#' Cancel a background Responses API response
#'
#' @param response_id Character. The response ID to cancel.
#' @param api_key Character. Optional API key override.
#' @param endpoint Character. Optional endpoint override.
#'
#' @return A one-row tibble parsed like `foundry_response()`.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_response_cancel("resp_abc123")
#' }
foundry_response_cancel <- function(response_id,
                                    api_key = NULL,
                                    endpoint = NULL) {
  foundry_check_character_scalar(response_id, "response_id")

  req <- foundry_build_v1_request(
    path = paste0("responses/", response_id, "/cancel"),
    method = "POST",
    api_key = api_key,
    endpoint = endpoint
  )

  foundry_parse_response(foundry_perform(req), parse_json = FALSE)
}


#' List input items for a Responses API response
#'
#' @param response_id Character. The response ID.
#' @param api_key Character. Optional API key override.
#' @param endpoint Character. Optional endpoint override.
#'
#' @return A tibble with one row per input item and the raw item in a list-column.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_response_input_items("resp_abc123")
#' }
foundry_response_input_items <- function(response_id,
                                         api_key = NULL,
                                         endpoint = NULL) {
  foundry_check_character_scalar(response_id, "response_id")

  req <- foundry_build_v1_request(
    path = paste0("responses/", response_id, "/input_items"),
    method = "GET",
    api_key = api_key,
    endpoint = endpoint
  )

  result <- foundry_perform(req)
  items <- result$data %||% list()
  if (length(items) == 0L) {
    return(tibble::tibble(
      item_id = character(),
      type = character(),
      role = character(),
      content = list(),
      raw_item = list()
    ))
  }

  purrr::map_dfr(items, function(item) {
    tibble::tibble(
      item_id = item$id %||% NA_character_,
      type = item$type %||% NA_character_,
      role = item$role %||% NA_character_,
      content = list(item$content %||% NULL),
      raw_item = list(item)
    )
  })
}


#' Extract structured data from text using JSON Schema
#'
#' Apply a JSON Schema to one or more text inputs and return model-extracted
#' fields as a tidy tibble. This is useful for research coding tasks such as
#' sentiment annotation, entity extraction, study abstraction, and converting
#' free-text records into analyzable variables.
#'
#' @param text Character vector or data frame. Texts to extract from, or a data
#'   frame containing a text column.
#' @param schema List. JSON Schema object describing the fields to extract.
#' @param text_col Character. Column name containing text when `text` is a data
#'   frame.
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
#' @param max_active Integer. Maximum number of concurrent requests.
#' @param progress Logical. Whether to show a progress bar for parallel
#'   extraction.
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
                            schema = NULL,
                            text_col = NULL,
                            instructions = NULL,
                            schema_name = "ExtractedData",
                            strict = TRUE,
                            model = NULL,
                            flatten = TRUE,
                            store = FALSE,
                            max_active = 5L,
                            progress = TRUE,
                            api_key = NULL,
                            endpoint = NULL,
                            ...) {

  if (is.data.frame(text) && is.character(schema) && length(schema) == 1L &&
      is.list(instructions)) {
    text_col <- schema
    schema <- instructions
    instructions <- NULL
  }
  if (is.data.frame(text) && is.character(schema) && length(schema) == 1L &&
      is.list(text_col)) {
    schema_input <- text_col
    text_col <- schema
    schema <- schema_input
  }

  data_input <- is.data.frame(text)
  input_data <- NULL
  if (data_input) {
    input_data <- tibble::as_tibble(text)
    if (is.null(text_col)) {
      cli::cli_abort("{.arg text_col} is required when {.arg text} is a data frame.")
    }
    foundry_check_character_scalar(text_col, "text_col")
    if (!text_col %in% names(input_data)) {
      cli::cli_abort("Column {.field {text_col}} was not found in {.arg text}.")
    }
    text_values <- as.character(input_data[[text_col]])
  } else {
    if (missing(text) || is.null(text) || !is.character(text)) {
      cli::cli_abort("{.arg text} must be a character vector or data frame.")
    }
    text_values <- text
  }

  if (is.null(schema) || !is.list(schema)) {
    cli::cli_abort("{.arg schema} must be a JSON Schema represented as an R list.")
  }
  schema <- as_foundry_schema(schema)
  foundry_check_character_scalar(schema_name, "schema_name")
  if (!is.logical(strict) || length(strict) != 1L || is.na(strict)) {
    cli::cli_abort("{.arg strict} must be TRUE or FALSE.")
  }
  if (!is.logical(flatten) || length(flatten) != 1L || is.na(flatten)) {
    cli::cli_abort("{.arg flatten} must be TRUE or FALSE.")
  }
  if (!is.logical(store) || length(store) != 1L || is.na(store)) {
    cli::cli_abort("{.arg store} must be TRUE or FALSE.")
  }
  max_active <- foundry_check_positive_integer(max_active, "max_active")
  if (!is.logical(progress) || length(progress) != 1L || is.na(progress)) {
    cli::cli_abort("{.arg progress} must be TRUE or FALSE.")
  }

  if (is.null(instructions)) {
    instructions <- paste(
      "Extract the requested structured data from the input text.",
      "Return values that conform exactly to the supplied JSON Schema."
    )
  } else {
    foundry_check_character_scalar(instructions, "instructions")
  }

  if (length(text_values) == 0L) {
    out <- tibble::tibble(
      .input_idx = integer(),
      .input_text = character(),
      .response_id = character(),
      .status = character(),
      .output_text = character(),
      .error = logical(),
      .error_msg = character(),
      raw_response = list()
    )
    if (!flatten) out$.data <- list()
    if (data_input) {
      return(dplyr::bind_cols(input_data[0, , drop = FALSE], out))
    }
    return(out)
  }

  text_format <- foundry_json_schema_format(
    schema = schema,
    schema_name = schema_name,
    strict = strict
  )

  model <- foundry_resolve_model(model)
  valid_idx <- which(!is.na(text_values))
  rows <- vector("list", length(text_values))
  na_idx <- which(is.na(text_values))
  for (i in na_idx) {
    rows[[i]] <- foundry_extract_error_row(
      i,
      text_values[i],
      "skipped",
      "Input text is NA.",
      flatten = flatten
    )
  }

  dots <- list(...)
  requests <- purrr::map(valid_idx, function(i) {
    body <- list(
      model = model,
      input = text_values[i],
      instructions = instructions,
      text = list(format = text_format),
      store = store
    )
    for (nm in names(dots)) {
      body[[nm]] <- dots[[nm]]
    }
    foundry_build_v1_request(
      path = "responses",
      body = body,
      api_key = api_key,
      endpoint = endpoint
    )
  })

  responses <- if (length(requests) == 0L) {
    list()
  } else {
    httr2::req_perform_parallel(
      requests,
      on_error = "continue",
      progress = progress,
      max_active = max_active
    )
  }

  for (j in seq_along(responses)) {
    i <- valid_idx[j]
    rows[[i]] <- foundry_extract_parse_parallel_response(
      responses[[j]],
      i = i,
      input_text = text_values[i],
      flatten = flatten
    )
  }

  out <- dplyr::bind_rows(rows)
  if (data_input) {
    out <- dplyr::bind_cols(input_data, out)
  }
  out
}


foundry_extract_parse_parallel_response <- function(resp,
                                                    i,
                                                    input_text,
                                                    flatten) {
  is_error_obj <- inherits(resp, "error") || inherits(resp, "httr2_failure")
  is_http_error <- !is_error_obj && httr2::resp_is_error(resp)

  if (is_error_obj || is_http_error) {
    error_msg <- if (is_error_obj) {
      conditionMessage(resp)
    } else {
      tryCatch(
        foundry_error_body(resp),
        error = function(e) "Unknown API error"
      )
    }
    return(foundry_extract_error_row(
      i,
      input_text,
      "failed",
      error_msg,
      flatten = flatten
    ))
  }

  result <- tryCatch(
    httr2::resp_body_json(resp),
    error = function(e) {
      return(structure(list(message = conditionMessage(e)), class = "foundry_parse_error"))
    }
  )
  if (inherits(result, "foundry_parse_error")) {
    return(foundry_extract_error_row(
      i,
      input_text,
      "failed",
      result$message,
      flatten = flatten
    ))
  }

  response <- foundry_parse_response(result, parse_json = TRUE)
  structured_error <- response$structured_error[[1]]
  if (!is.na(structured_error)) {
    return(foundry_extract_error_row(
      i,
      input_text,
      response$status,
      structured_error,
      flatten = flatten,
      raw_response = response$raw_response[[1]]
    ))
  }

  base <- tibble::tibble(
    .input_idx = i,
    .input_text = input_text,
    .response_id = response$response_id,
    .status = response$status,
    .output_text = response$output_text,
    .error = FALSE,
    .error_msg = NA_character_,
    raw_response = response$raw_response
  )

  data <- response$structured[[1]]
  if (!flatten) {
    base$.data <- list(data)
    return(base)
  }

  dplyr::bind_cols(base, foundry_list_to_row(data))
}


foundry_extract_error_row <- function(i,
                                      input_text,
                                      status,
                                      error_msg,
                                      flatten,
                                      raw_response = NULL) {
  out <- tibble::tibble(
    .input_idx = i,
    .input_text = input_text,
    .response_id = NA_character_,
    .status = status,
    .output_text = NA_character_,
    .error = TRUE,
    .error_msg = error_msg,
    raw_response = list(raw_response)
  )
  if (!flatten) out$.data <- list(NULL)
  out
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
    reasoning_tokens = usage$output_tokens_details$reasoning_tokens %||%
      usage$completion_tokens_details$reasoning_tokens %||% NA_integer_,
    cached_input_tokens = usage$input_tokens_details$cached_tokens %||%
      usage$prompt_tokens_details$cached_tokens %||% NA_integer_,
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


foundry_check_logical_scalar <- function(x, arg) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    cli::cli_abort("{.arg {arg}} must be TRUE or FALSE.")
  }
  invisible(x)
}


foundry_tool_schemas <- function(tools) {
  if (inherits(tools, "foundry_tool")) {
    return(list(foundry_tool_schema(tools)))
  }

  lapply(tools, function(tool) {
    if (inherits(tool, "foundry_tool")) {
      foundry_tool_schema(tool)
    } else {
      tool
    }
  })
}


foundry_tool_schema <- function(tool) {
  tool$.fn <- NULL
  class(tool) <- NULL
  tool
}


foundry_validate_agent_tools <- function(tools) {
  if (inherits(tools, "foundry_tool")) {
    return(list(tools))
  }
  if (!is.list(tools) || length(tools) == 0L) {
    cli::cli_abort("{.arg tools} must be a foundry tool or a non-empty list of foundry tools.")
  }
  valid <- vapply(tools, inherits, logical(1), "foundry_tool")
  if (!all(valid)) {
    cli::cli_abort("{.arg tools} must contain only objects created by {.fun foundry_tool}.")
  }
  tool_names <- vapply(tools, function(tool) tool$name, character(1))
  if (anyDuplicated(tool_names)) {
    cli::cli_abort("{.arg tools} must not contain duplicate tool names.")
  }
  tools
}


foundry_execute_tool_calls <- function(tool_calls, tools) {
  function_calls <- tool_calls[tool_calls$type == "function_call", , drop = FALSE]
  tool_lookup <- stats::setNames(
    lapply(tools, function(tool) tool$.fn),
    vapply(tools, function(tool) tool$name, character(1))
  )

  input_items <- vector("list", nrow(function_calls))
  result_rows <- vector("list", nrow(function_calls))

  for (i in seq_len(nrow(function_calls))) {
    call <- function_calls[i, , drop = FALSE]
    name <- call$name[[1]]
    call_id <- call$call_id[[1]]

    if (is.na(call_id) || call_id == "") {
      cli::cli_abort("Function call {.val {name}} did not include a {.field call_id}.")
    }
    if (!name %in% names(tool_lookup)) {
      cli::cli_abort("No R function is registered for tool {.val {name}}.")
    }

    args <- foundry_parse_tool_arguments(call$arguments[[1]], name)
    value <- tryCatch(
      do.call(tool_lookup[[name]], args),
      error = function(e) {
        cli::cli_abort(c(
          "Tool {.val {name}} failed.",
          "x" = conditionMessage(e)
        ))
      }
    )
    output <- foundry_tool_output_string(value)

    input_items[[i]] <- list(
      type = "function_call_output",
      call_id = call_id,
      output = output
    )
    result_rows[[i]] <- tibble::tibble(
      call_id = call_id,
      name = name,
      arguments = list(args),
      output = output
    )
  }

  list(
    input = input_items,
    results = dplyr::bind_rows(result_rows)
  )
}


foundry_parse_tool_arguments <- function(arguments, name) {
  if (is.na(arguments) || arguments == "") {
    return(list())
  }

  tryCatch(
    jsonlite::fromJSON(arguments, simplifyVector = FALSE),
    error = function(e) {
      cli::cli_abort(c(
        "Failed to parse arguments for tool {.val {name}}.",
        "x" = conditionMessage(e)
      ))
    }
  )
}


foundry_tool_output_string <- function(value) {
  if (is.character(value) && length(value) == 1L && !is.na(value)) {
    return(value)
  }

  as.character(jsonlite::toJSON(value, auto_unbox = TRUE, null = "null"))
}


foundry_empty_tool_results <- function() {
  tibble::tibble(
    call_id = character(),
    name = character(),
    arguments = list(),
    output = character()
  )
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
