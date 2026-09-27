#' Build an evaluation item for model-based graders
#'
#' Model-based graders (`foundry_grader_label_model()` and
#' `foundry_grader_score_model()`) accept an `input` list of message-shaped
#' items. Each item has a `role` and `content`, and the content may embed
#' template references such as `{{item.question}}` or `{{sample.output_text}}`
#' that Azure resolves per row at evaluation time.
#'
#' @param content Character. The message content. May contain `{{...}}`
#'   template references.
#' @param role Character. One of `"user"`, `"assistant"`, `"system"`, or
#'   `"developer"`. Defaults to `"user"`.
#'
#' @return A named list with `role` and `content`, ready to place in a grader
#'   `input` list.
#' @export
#'
#' @examples
#' foundry_eval_item("Grade this answer: {{sample.output_text}}", role = "user")
foundry_eval_item <- function(content, role = c("user", "assistant", "system", "developer")) {
  foundry_check_character_scalar(content, "content")
  role <- match.arg(role)
  list(role = role, content = content)
}


#' String-check grader
#'
#' Compare a templated input string against a reference string with an exact or
#' pattern operation. Useful for deterministic pass/fail checks such as verifying
#' an extracted field matches a known value.
#'
#' @param name Character. Grader name shown in results.
#' @param input Character. Input text, typically a template such as
#'   `"{{sample.output_text}}"`.
#' @param reference Character. Reference text, typically a template such as
#'   `"{{item.expected}}"`.
#' @param operation Character. One of `"eq"`, `"ne"`, `"like"`, or `"ilike"`.
#'
#' @return A named list describing a `string_check` grader, for use in the
#'   `testing_criteria` of [foundry_eval_create()].
#' @export
#'
#' @examples
#' foundry_grader_string_check(
#'   name = "exact-match",
#'   input = "{{sample.output_text}}",
#'   reference = "{{item.answer}}",
#'   operation = "eq"
#' )
foundry_grader_string_check <- function(name,
                                        input,
                                        reference,
                                        operation = c("eq", "ne", "like", "ilike")) {
  foundry_check_character_scalar(name, "name")
  foundry_check_character_scalar(input, "input")
  foundry_check_character_scalar(reference, "reference")
  operation <- match.arg(operation)
  list(
    type = "string_check",
    name = name,
    input = input,
    reference = reference,
    operation = operation
  )
}


#' Text-similarity grader
#'
#' Grade output text against a reference using a similarity metric such as
#' fuzzy matching, BLEU, ROUGE, or METEOR. A row passes when its score is at
#' least `pass_threshold`.
#'
#' @param input Character. Text being graded, typically `"{{sample.output_text}}"`.
#' @param reference Character. Reference text, typically `"{{item.answer}}"`.
#' @param pass_threshold Numeric. Score at or above which a row passes.
#' @param evaluation_metric Character. One of `"fuzzy_match"`, `"bleu"`,
#'   `"gleu"`, `"meteor"`, `"rouge_1"`, `"rouge_2"`, `"rouge_3"`, `"rouge_4"`,
#'   `"rouge_5"`, or `"rouge_l"`.
#' @param name Character. Optional grader name.
#'
#' @return A named list describing a `text_similarity` grader.
#' @export
#'
#' @examples
#' foundry_grader_text_similarity(
#'   input = "{{sample.output_text}}",
#'   reference = "{{item.answer}}",
#'   pass_threshold = 0.8,
#'   evaluation_metric = "fuzzy_match"
#' )
foundry_grader_text_similarity <- function(input,
                                           reference,
                                           pass_threshold,
                                           evaluation_metric = c(
                                             "fuzzy_match", "bleu", "gleu", "meteor",
                                             "rouge_1", "rouge_2", "rouge_3", "rouge_4",
                                             "rouge_5", "rouge_l"
                                           ),
                                           name = NULL) {
  foundry_check_character_scalar(input, "input")
  foundry_check_character_scalar(reference, "reference")
  if (!is.numeric(pass_threshold) || length(pass_threshold) != 1L || is.na(pass_threshold)) {
    cli::cli_abort("{.arg pass_threshold} must be a single number.")
  }
  evaluation_metric <- match.arg(evaluation_metric)

  grader <- list(
    type = "text_similarity",
    input = input,
    reference = reference,
    pass_threshold = pass_threshold,
    evaluation_metric = evaluation_metric
  )
  if (!is.null(name)) {
    foundry_check_character_scalar(name, "name")
    grader$name <- name
  }
  grader
}


#' Label-model grader
#'
#' Use a model to assign one of a fixed set of labels to each row, then treat a
#' subset of those labels as passing. The model must support structured outputs.
#'
#' @param name Character. Grader name.
#' @param model Character. Deployment name of a model that supports structured
#'   outputs.
#' @param input List. A list of items from [foundry_eval_item()] (or a single
#'   item), forming the grading prompt.
#' @param labels Character vector. The complete set of labels the model may
#'   assign.
#' @param passing_labels Character vector. The labels that count as a pass. Must
#'   be a subset of `labels`.
#'
#' @return A named list describing a `label_model` grader.
#' @export
#'
#' @examples
#' foundry_grader_label_model(
#'   name = "relevance-label",
#'   model = "gpt-5-nano",
#'   input = list(
#'     foundry_eval_item("Is the answer relevant? {{sample.output_text}}")
#'   ),
#'   labels = c("relevant", "irrelevant"),
#'   passing_labels = "relevant"
#' )
foundry_grader_label_model <- function(name,
                                       model,
                                       input,
                                       labels,
                                       passing_labels) {
  foundry_check_character_scalar(name, "name")
  foundry_check_character_scalar(model, "model")
  if (!is.character(labels) || length(labels) == 0L || anyNA(labels)) {
    cli::cli_abort("{.arg labels} must be a non-empty character vector.")
  }
  if (!is.character(passing_labels) || length(passing_labels) == 0L || anyNA(passing_labels)) {
    cli::cli_abort("{.arg passing_labels} must be a non-empty character vector.")
  }
  missing_labels <- setdiff(passing_labels, labels)
  if (length(missing_labels) > 0L) {
    cli::cli_abort(c(
      "{.arg passing_labels} must be a subset of {.arg labels}.",
      "x" = "Not found in {.arg labels}: {.val {missing_labels}}."
    ))
  }

  list(
    type = "label_model",
    name = name,
    model = model,
    input = foundry_eval_normalize_items(input),
    labels = as.list(labels),
    passing_labels = as.list(passing_labels)
  )
}


#' Score-model grader
#'
#' Use a model to assign a numeric score to each row. Rows at or above
#' `pass_threshold` pass. Scores fall within `range`, which defaults to
#' `c(0, 1)`.
#'
#' @param name Character. Grader name.
#' @param model Character. Deployment name of the scoring model.
#' @param input List. A list of items from [foundry_eval_item()] (or a single
#'   item) forming the grading prompt.
#' @param pass_threshold Numeric. Optional score at or above which a row passes.
#' @param range Numeric vector of length 2. Optional score range. Defaults to
#'   `c(0, 1)` on the service when omitted.
#'
#' @return A named list describing a `score_model` grader.
#' @export
#'
#' @examples
#' foundry_grader_score_model(
#'   name = "helpfulness",
#'   model = "gpt-5-nano",
#'   input = list(
#'     foundry_eval_item("Rate helpfulness 0-1: {{sample.output_text}}")
#'   ),
#'   pass_threshold = 0.7
#' )
foundry_grader_score_model <- function(name,
                                       model,
                                       input,
                                       pass_threshold = NULL,
                                       range = NULL) {
  foundry_check_character_scalar(name, "name")
  foundry_check_character_scalar(model, "model")

  grader <- list(
    type = "score_model",
    name = name,
    model = model,
    input = foundry_eval_normalize_items(input)
  )
  if (!is.null(pass_threshold)) {
    if (!is.numeric(pass_threshold) || length(pass_threshold) != 1L || is.na(pass_threshold)) {
      cli::cli_abort("{.arg pass_threshold} must be a single number.")
    }
    grader$pass_threshold <- pass_threshold
  }
  if (!is.null(range)) {
    if (!is.numeric(range) || length(range) != 2L || anyNA(range)) {
      cli::cli_abort("{.arg range} must be a numeric vector of length 2.")
    }
    grader$range <- as.list(range)
  }
  grader
}


#' Microsoft Foundry built-in evaluator grader
#'
#' Reference a Microsoft Foundry built-in evaluator (a `builtin.*` ID such as
#' `builtin.coherence` or `builtin.groundedness`) as a grader. Built-in
#' evaluators run only on a Foundry project endpoint; [foundry_eval_create()]
#' and [foundry_evaluate()] switch to it when a grader of this type is present.
#'
#' @param name Character. Grader name shown in results.
#' @param evaluator_name Character. The evaluator ID, e.g. `"builtin.coherence"`.
#' @param initialization_parameters List. Optional parameters passed to the
#'   evaluator. Model-graded evaluators take the judge deployment as
#'   `list(deployment_name = "gpt-5-mini")`.
#' @param data_mapping Named list. Optional mapping from evaluator inputs to
#'   dataset templates, e.g. `list(query = "{{item.query}}", response =
#'   "{{sample.output_text}}")`.
#' @param evaluator_version Character. Optional evaluator version. Defaults to
#'   the latest version on the service when omitted.
#'
#' @return A named list describing an `azure_ai_evaluator` grader.
#' @export
#'
#' @examples
#' foundry_grader_azure_ai(
#'   name = "coherence",
#'   evaluator_name = "builtin.coherence",
#'   initialization_parameters = list(deployment_name = "gpt-5-mini"),
#'   data_mapping = list(
#'     query = "{{item.query}}",
#'     response = "{{sample.output_text}}"
#'   )
#' )
foundry_grader_azure_ai <- function(name,
                                    evaluator_name,
                                    initialization_parameters = NULL,
                                    data_mapping = NULL,
                                    evaluator_version = NULL) {
  foundry_check_character_scalar(name, "name")
  foundry_check_character_scalar(evaluator_name, "evaluator_name")

  grader <- list(
    type = "azure_ai_evaluator",
    name = name,
    evaluator_name = evaluator_name
  )
  if (!is.null(evaluator_version)) {
    foundry_check_character_scalar(evaluator_version, "evaluator_version")
    grader$evaluator_version <- evaluator_version
  }
  if (!is.null(initialization_parameters)) {
    if (!is.list(initialization_parameters)) {
      cli::cli_abort("{.arg initialization_parameters} must be a list.")
    }
    grader$initialization_parameters <- initialization_parameters
  }
  if (!is.null(data_mapping)) {
    if (!is.list(data_mapping) || is.null(names(data_mapping)) || any(names(data_mapping) == "")) {
      cli::cli_abort("{.arg data_mapping} must be a named list.")
    }
    grader$data_mapping <- data_mapping
  }
  grader
}


#' Define an evaluation data-source configuration
#'
#' Describe the shape of the data an evaluation expects. `type = "custom"`
#' declares an item schema you populate per run; `type = "logs"` sources rows
#' from stored completions matching a metadata filter; `type =
#' "azure_ai_source"` lets Microsoft Foundry supply the rows for a service
#' scenario, such as stored responses.
#'
#' @param type Character. One of `"custom"`, `"logs"`, or `"azure_ai_source"`.
#' @param item_schema List. For `type = "custom"`, a JSON Schema (as an R list)
#'   describing each row.
#' @param include_sample_schema Logical. For `type = "custom"`, whether the eval
#'   should expect a populated `sample` namespace (generated responses).
#'   Defaults to `FALSE`.
#' @param metadata List. For `type = "logs"`, the stored-completions metadata
#'   filter.
#' @param scenario Character. For `type = "azure_ai_source"`, the Foundry
#'   scenario, for example `"responses"` to evaluate stored responses by ID
#'   (see [foundry_eval_run_data()]). Requires the project Evals route.
#'
#' @return A named list describing a `data_source_config`, for use in
#'   [foundry_eval_create()].
#' @export
#'
#' @examples
#' foundry_eval_data_config(
#'   type = "custom",
#'   item_schema = list(
#'     type = "object",
#'     properties = list(
#'       question = list(type = "string"),
#'       answer = list(type = "string")
#'     ),
#'     required = list("question", "answer")
#'   ),
#'   include_sample_schema = TRUE
#' )
#'
#' foundry_eval_data_config(type = "azure_ai_source", scenario = "responses")
foundry_eval_data_config <- function(type = c("custom", "logs", "azure_ai_source"),
                                     item_schema = NULL,
                                     include_sample_schema = FALSE,
                                     metadata = NULL,
                                     scenario = NULL) {
  type <- match.arg(type)

  if (identical(type, "custom")) {
    if (!is.list(item_schema) || length(item_schema) == 0L) {
      cli::cli_abort("{.arg item_schema} must be a non-empty JSON Schema list when {.code type = \"custom\"}.")
    }
    foundry_check_logical_scalar(include_sample_schema, "include_sample_schema")
    return(list(
      type = "custom",
      item_schema = item_schema,
      include_sample_schema = include_sample_schema
    ))
  }

  if (identical(type, "azure_ai_source")) {
    if (is.null(scenario)) {
      cli::cli_abort("{.arg scenario} is required when {.code type = \"azure_ai_source\"}.")
    }
    foundry_check_character_scalar(scenario, "scenario")
    return(list(type = "azure_ai_source", scenario = scenario))
  }

  config <- list(type = "logs")
  if (!is.null(metadata)) {
    if (!is.list(metadata)) {
      cli::cli_abort("{.arg metadata} must be a list.")
    }
    config$metadata <- metadata
  }
  config
}


#' Define an evaluation run data source
#'
#' Point an evaluation run at its rows. Three shapes are supported:
#'
#' * **Dataset rows** (`type = "jsonl"`): supply exactly one of `file_id` or
#'   `content`. Graders read existing fields with `{{item.<field>}}`.
#' * **Target generation** (`type = "azure_ai_target_completions"`): also
#'   supply `target` and `input_messages`. Microsoft Foundry sends each row to
#'   a model deployment or agent and graders read the generated output with
#'   `{{sample.output_text}}` or, for agents, `{{sample.output_items}}`
#'   (structured output including tool calls).
#' * **Stored responses** (`type = "azure_ai_responses"`): supply only
#'   `response_ids`. Foundry retrieves each stored response and graders score
#'   it. Pair it with `foundry_eval_data_config(type = "azure_ai_source",
#'   scenario = "responses")`.
#'
#' Target and stored-response runs exist only on a Foundry project endpoint.
#' [foundry_eval_run_create()] and [foundry_evaluate()] use the configured
#' project endpoint for them and say so.
#'
#' @param file_id Character. ID of a JSONL file uploaded with
#'   [foundry_file_upload()].
#' @param content List. Inline rows, each a list with an `item` element (and an
#'   optional `sample` element).
#' @param target Optional target that generates a response for each row: a
#'   model deployment name (character), an agent reference from
#'   [foundry_agent_reference()] or [foundry_agent_create()], or a complete
#'   target list such as `list(type = "azure_ai_model", model = "gpt-5-mini",
#'   sampling_params = list(max_completion_tokens = 2048))`.
#' @param input_messages Required with `target`. Either a single template
#'   string sent as the user message, for example `"{{item.query}}"`, or a
#'   complete Foundry `input_messages` list.
#' @param response_ids Character vector of stored response IDs (for example
#'   the `response_id` column returned by [foundry_response()]). Cannot be
#'   combined with the other arguments.
#'
#' @return A named list describing a run data source, for use in
#'   [foundry_eval_run_create()].
#' @export
#'
#' @examples
#' foundry_eval_run_data(file_id = "file-abc123")
#'
#' foundry_eval_run_data(content = list(
#'   list(item = list(question = "2+2?", answer = "4"))
#' ))
#'
#' foundry_eval_run_data(
#'   content = list(list(item = list(query = "What is R?"))),
#'   target = "gpt-5-mini",
#'   input_messages = "{{item.query}}"
#' )
#'
#' foundry_eval_run_data(response_ids = c("resp_abc123", "resp_def456"))
foundry_eval_run_data <- function(file_id = NULL,
                                  content = NULL,
                                  target = NULL,
                                  input_messages = NULL,
                                  response_ids = NULL) {
  if (!is.null(response_ids)) {
    if (!is.null(file_id) || !is.null(content) || !is.null(target) || !is.null(input_messages)) {
      cli::cli_abort(
        "{.arg response_ids} cannot be combined with {.arg file_id}, {.arg content}, {.arg target}, or {.arg input_messages}."
      )
    }
    return(foundry_eval_responses_source(response_ids))
  }

  has_file <- !is.null(file_id)
  has_content <- !is.null(content)
  if (has_file == has_content) {
    cli::cli_abort("Supply exactly one of {.arg file_id} or {.arg content}.")
  }

  if (has_file) {
    foundry_check_character_scalar(file_id, "file_id")
    source <- list(type = "file_id", id = file_id)
  } else {
    if (!is.list(content) || length(content) == 0L) {
      cli::cli_abort("{.arg content} must be a non-empty list of rows.")
    }
    source <- list(type = "file_content", content = unname(content))
  }

  if (is.null(target)) {
    if (!is.null(input_messages)) {
      cli::cli_abort("{.arg input_messages} requires {.arg target}.")
    }
    return(list(type = "jsonl", source = source))
  }

  if (is.null(input_messages)) {
    cli::cli_abort("{.arg input_messages} is required when {.arg target} is supplied.")
  }

  list(
    type = "azure_ai_target_completions",
    source = source,
    input_messages = foundry_eval_input_messages(input_messages),
    target = foundry_eval_target(target)
  )
}


#' Create an evaluation
#'
#' Create an evaluation group that pairs a data-source configuration with one or
#' more graders (`testing_criteria`). Evaluations are run against data with
#' [foundry_eval_run_create()].
#'
#' @param name Character. Optional evaluation name.
#' @param data_source_config List. A configuration from
#'   [foundry_eval_data_config()].
#' @param testing_criteria List. A grader from `foundry_grader_*()`, or a list of
#'   graders.
#' @param metadata List. Optional metadata attached to the evaluation.
#' @param api_key Character. Optional API key. Falls back to configured auth.
#' @param token Character. Optional bearer token. Falls back to configured auth.
#' @param endpoint Character. Optional resource endpoint. Supplying it selects
#'   the resource-scoped Evals route (`<resource>/openai/v1/evals`). Supply at
#'   most one of `endpoint` and `project_endpoint`.
#' @param api_version Character. Optional `api-version` query value. The Foundry
#'   v1 evals surface is path-versioned, so this is usually left `NULL`.
#' @param project_endpoint Character. Optional Microsoft Foundry project
#'   endpoint, such as
#'   `"https://<account>.services.ai.azure.com/api/projects/<project>"`.
#'   Supplying it selects the project-scoped Evals route
#'   (`<project>/openai/v1/evals`), which accepts Microsoft Entra ID tokens
#'   only. Without it, evaluation calls use the resource endpoint, as in
#'   foundryR 0.1.0, unless [foundry_set_route()] selected the project or the
#'   call needs a feature that exists only on a project endpoint: built-in
#'   `azure_ai_evaluator` graders, model or agent targets, or stored responses.
#'   Those calls use the endpoint set with [foundry_set_project_endpoint()] and
#'   print a message. Evaluations created on the project endpoint are not
#'   visible from the resource endpoint, so pass `project_endpoint` (or set the
#'   route) when you look them up later.
#'
#' @return A one-row tibble describing the created evaluation.
#' @export
#'
#' @examples
#' \dontrun{
#' # Requires a configured Azure endpoint and credentials with evals API access.
#' foundry_eval_create(
#'   name = "qa-accuracy",
#'   data_source_config = foundry_eval_data_config(
#'     type = "custom",
#'     item_schema = list(
#'       type = "object",
#'       properties = list(answer = list(type = "string")),
#'       required = list("answer")
#'     ),
#'     include_sample_schema = TRUE
#'   ),
#'   testing_criteria = foundry_grader_string_check(
#'     name = "exact",
#'     input = "{{sample.output_text}}",
#'     reference = "{{item.answer}}",
#'     operation = "eq"
#'   )
#' )
#' }
foundry_eval_create <- function(name = NULL,
                                data_source_config,
                                testing_criteria,
                                metadata = NULL,
                                api_key = NULL,
                                token = NULL,
                                endpoint = NULL,
                                api_version = NULL,
                                project_endpoint = NULL) {
  if (!is.list(data_source_config) || is.null(data_source_config$type)) {
    cli::cli_abort("{.arg data_source_config} must be built with {.fn foundry_eval_data_config}.")
  }

  body <- list(
    data_source_config = data_source_config,
    testing_criteria = foundry_eval_normalize_criteria(testing_criteria)
  )
  if (!is.null(name)) {
    foundry_check_character_scalar(name, "name")
    body$name <- name
  }
  if (!is.null(metadata)) {
    if (!is.list(metadata)) {
      cli::cli_abort("{.arg metadata} must be a list.")
    }
    body$metadata <- metadata
  }

  route <- foundry_eval_resolve_route(
    endpoint = endpoint,
    project_endpoint = project_endpoint,
    needs_project = foundry_eval_needs_project(
      graders = body$testing_criteria,
      data_source_config = data_source_config
    )
  )
  req <- foundry_eval_request(
    path = "evals",
    body = body,
    method = "POST",
    api_key = api_key,
    token = token,
    api_version = api_version,
    route = route
  )

  foundry_eval_tibble(foundry_perform(req))
}


#' List evaluations
#'
#' @param limit Integer. Optional maximum number of evaluations to return.
#' @param after Character. Optional pagination cursor.
#' @param order Character. Optional sort order, `"asc"` or `"desc"`.
#' @inheritParams foundry_eval_create
#'
#' @return A tibble with one row per evaluation.
#' @export
#'
#' @examples
#' \dontrun{
#' # Requires a configured Azure endpoint and credentials with evals API access.
#' foundry_evals(limit = 10)
#' }
foundry_evals <- function(limit = NULL,
                          after = NULL,
                          order = NULL,
                          api_key = NULL,
                          token = NULL,
                          endpoint = NULL,
                          api_version = NULL,
                          project_endpoint = NULL) {
  req <- foundry_eval_request(
    path = "evals",
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version,
    project_endpoint = project_endpoint
  )
  req <- httr2::req_url_query(req, limit = limit, after = after, order = order)

  result <- foundry_perform(req)
  evals <- result$data %||% list()
  if (length(evals) == 0L) {
    return(foundry_eval_tibble(list()))
  }
  purrr::map_dfr(evals, foundry_eval_tibble)
}


#' Retrieve an evaluation
#'
#' @param eval_id Character. Evaluation ID.
#' @inheritParams foundry_eval_create
#'
#' @return A one-row tibble describing the evaluation.
#' @export
#'
#' @examples
#' \dontrun{
#' # Requires a configured Azure endpoint, credentials, and an evaluation ID.
#' foundry_eval_get("eval_abc123")
#' }
foundry_eval_get <- function(eval_id,
                             api_key = NULL,
                             token = NULL,
                             endpoint = NULL,
                             api_version = NULL,
                             project_endpoint = NULL) {
  foundry_check_character_scalar(eval_id, "eval_id")

  req <- foundry_eval_request(
    path = paste0("evals/", eval_id),
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version,
    project_endpoint = project_endpoint
  )

  foundry_eval_tibble(foundry_perform(req))
}


#' Delete an evaluation
#'
#' @details
#' The returned `deleted` column is the service's answer. On the resource
#' endpoint the service confirms deletion. On a project endpoint it has been
#' observed to answer `deleted = FALSE` and keep the evaluation, in which case
#' a warning says so; delete it in the Foundry portal if you need it gone.
#'
#' @param eval_id Character. Evaluation ID to delete.
#' @inheritParams foundry_eval_create
#'
#' @return A one-row tibble with `eval_id`, `deleted`, and `object`.
#' @export
#'
#' @examples
#' \dontrun{
#' # Requires a configured Azure endpoint and credentials,
#' # plus an existing evaluation you can delete.
#' foundry_eval_delete("eval_abc123")
#' }
foundry_eval_delete <- function(eval_id,
                                api_key = NULL,
                                token = NULL,
                                endpoint = NULL,
                                api_version = NULL,
                                project_endpoint = NULL) {
  foundry_check_character_scalar(eval_id, "eval_id")

  req <- foundry_eval_request(
    path = paste0("evals/", eval_id),
    method = "DELETE",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version,
    project_endpoint = project_endpoint
  )

  result <- foundry_perform(req)
  deleted <- isTRUE(result$deleted)
  if (!deleted) {
    cli::cli_warn(c(
      "The service did not confirm that evaluation {.val {eval_id}} was deleted.",
      "i" = "It answered {.code deleted = false}; check with {.fn foundry_eval_get} or delete it in the Foundry portal."
    ))
  }
  tibble::tibble(
    eval_id = result$eval_id %||% eval_id,
    deleted = deleted,
    object = result$object %||% NA_character_
  )
}


#' Create an evaluation run
#'
#' Run an evaluation against a data source. The eval's `testing_criteria` are
#' applied to every row in the source.
#'
#' @param eval_id Character. Evaluation ID to run.
#' @param data_source List. A run data source from [foundry_eval_run_data()].
#' @param name Character. Optional run name. Target and stored-response runs
#'   need a name, so one is generated from the current UTC time when `NULL`.
#' @param metadata List. Optional metadata attached to the run.
#' @inheritParams foundry_eval_create
#'
#' @return A one-row tibble describing the created run.
#' @export
#'
#' @examples
#' \dontrun{
#' # Requires a configured Azure endpoint and credentials, an evaluation ID,
#' # and an uploaded JSONL file matching its data-source configuration.
#' foundry_eval_run_create(
#'   eval_id = "eval_abc123",
#'   data_source = foundry_eval_run_data(file_id = "file-xyz"),
#'   name = "nightly"
#' )
#' }
foundry_eval_run_create <- function(eval_id,
                                    data_source,
                                    name = NULL,
                                    metadata = NULL,
                                    api_key = NULL,
                                    token = NULL,
                                    endpoint = NULL,
                                    api_version = NULL,
                                    project_endpoint = NULL) {
  foundry_check_character_scalar(eval_id, "eval_id")
  if (!is.list(data_source) || is.null(data_source$type)) {
    cli::cli_abort("{.arg data_source} must be built with {.fn foundry_eval_run_data}.")
  }

  needs_project <- foundry_eval_needs_project(data_source = data_source)
  if (is.null(name) && !is.null(needs_project)) {
    name <- foundry_eval_default_name()
  }
  body <- list(data_source = data_source)
  if (!is.null(name)) {
    foundry_check_character_scalar(name, "name")
    body$name <- name
  }
  if (!is.null(metadata)) {
    if (!is.list(metadata)) {
      cli::cli_abort("{.arg metadata} must be a list.")
    }
    body$metadata <- metadata
  }

  route <- foundry_eval_resolve_route(
    endpoint = endpoint,
    project_endpoint = project_endpoint,
    needs_project = needs_project
  )
  req <- foundry_eval_request(
    path = paste0("evals/", eval_id, "/runs"),
    body = body,
    method = "POST",
    api_key = api_key,
    token = token,
    api_version = api_version,
    route = route
  )

  foundry_eval_run_tibble(foundry_perform(req))
}


#' List evaluation runs
#'
#' @param eval_id Character. Evaluation ID.
#' @param status Character. Optional status filter, one of `"queued"`,
#'   `"in_progress"`, `"failed"`, `"completed"`, or `"canceled"`.
#' @param order Character. Optional sort order, `"asc"` or `"desc"`.
#' @param limit Integer. Optional maximum number of runs to return.
#' @param after Character. Optional pagination cursor.
#' @inheritParams foundry_eval_create
#'
#' @return A tibble with one row per run.
#' @export
#'
#' @examples
#' \dontrun{
#' # Requires a configured Azure endpoint, credentials, and an evaluation ID.
#' foundry_eval_runs("eval_abc123", status = "completed")
#' }
foundry_eval_runs <- function(eval_id,
                              status = NULL,
                              order = NULL,
                              limit = NULL,
                              after = NULL,
                              api_key = NULL,
                              token = NULL,
                              endpoint = NULL,
                              api_version = NULL,
                              project_endpoint = NULL) {
  foundry_check_character_scalar(eval_id, "eval_id")

  req <- foundry_eval_request(
    path = paste0("evals/", eval_id, "/runs"),
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version,
    project_endpoint = project_endpoint
  )
  req <- httr2::req_url_query(
    req,
    status = status,
    order = order,
    limit = limit,
    after = after
  )

  result <- foundry_perform(req)
  runs <- result$data %||% list()
  if (length(runs) == 0L) {
    return(foundry_eval_run_tibble(list()))
  }
  purrr::map_dfr(runs, foundry_eval_run_tibble)
}


#' Retrieve an evaluation run
#'
#' @param eval_id Character. Evaluation ID.
#' @param run_id Character. Run ID.
#' @inheritParams foundry_eval_create
#'
#' @return A one-row tibble describing the run, including aggregate result
#'   counts.
#' @export
#'
#' @examples
#' \dontrun{
#' # Requires a configured Azure endpoint, credentials, and evaluation/run IDs.
#' foundry_eval_run_get("eval_abc123", "evalrun_xyz")
#' }
foundry_eval_run_get <- function(eval_id,
                                 run_id,
                                 api_key = NULL,
                                 token = NULL,
                                 endpoint = NULL,
                                 api_version = NULL,
                                 project_endpoint = NULL) {
  foundry_check_character_scalar(eval_id, "eval_id")
  foundry_check_character_scalar(run_id, "run_id")

  req <- foundry_eval_request(
    path = paste0("evals/", eval_id, "/runs/", run_id),
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version,
    project_endpoint = project_endpoint
  )

  foundry_eval_run_tibble(foundry_perform(req))
}


#' Cancel an evaluation run
#'
#' @param eval_id Character. Evaluation ID.
#' @param run_id Character. Run ID to cancel.
#' @inheritParams foundry_eval_create
#'
#' @return A one-row tibble describing the run after cancellation.
#' @export
#'
#' @examples
#' \dontrun{
#' # Requires a configured Azure endpoint and credentials, an evaluation ID,
#' # and a run ID that can be cancelled.
#' foundry_eval_run_cancel("eval_abc123", "evalrun_xyz")
#' }
foundry_eval_run_cancel <- function(eval_id,
                                    run_id,
                                    api_key = NULL,
                                    token = NULL,
                                    endpoint = NULL,
                                    api_version = NULL,
                                    project_endpoint = NULL) {
  foundry_check_character_scalar(eval_id, "eval_id")
  foundry_check_character_scalar(run_id, "run_id")

  req <- foundry_eval_request(
    path = paste0("evals/", eval_id, "/runs/", run_id),
    method = "POST",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version,
    project_endpoint = project_endpoint
  )

  foundry_eval_run_tibble(foundry_perform(req))
}


#' List evaluation run output items
#'
#' Return the per-row grader results for a completed run. The result is unnested
#' to one row per grader outcome, so a row that was scored by three graders
#' yields three rows. The service returns output items in pages; this function
#' follows the pagination cursor, so by default every output item is returned.
#'
#' @param eval_id Character. Evaluation ID.
#' @param run_id Character. Run ID.
#' @param status Character. Optional output-item processing status passed to
#'   the service, for example `"completed"` or `"failed"`. It reports whether
#'   the item was processed, not whether it passed; the service rejects
#'   `"fail"` and `"pass"`. To find failing grades, filter the returned `passed`
#'   column.
#' @param order Character. Optional sort order, `"asc"` or `"desc"`.
#' @param limit Integer. Optional maximum number of output items to return.
#'   `NULL` (the default) returns all output items.
#' @param after Character. Optional output item ID to start after.
#' @inheritParams foundry_eval_create
#'
#' @return A tibble with one row per grader result, including `score`, `label`,
#'   `passed`, and `reason` where the grader supplies them.
#' @export
#'
#' @examples
#' \dontrun{
#' # Requires a configured Azure endpoint and credentials, an evaluation ID,
#' # and a completed run ID.
#' foundry_eval_run_output_items("eval_abc123", "evalrun_xyz")
#' }
foundry_eval_run_output_items <- function(eval_id,
                                          run_id,
                                          status = NULL,
                                          order = NULL,
                                          limit = NULL,
                                          after = NULL,
                                          api_key = NULL,
                                          token = NULL,
                                          endpoint = NULL,
                                          api_version = NULL,
                                          project_endpoint = NULL) {
  foundry_check_character_scalar(eval_id, "eval_id")
  foundry_check_character_scalar(run_id, "run_id")
  if (!is.null(limit)) {
    limit <- foundry_check_positive_integer(limit, "limit")
  }

  items <- list()
  cursor <- after
  repeat {
    page_size <- if (is.null(limit)) NULL else min(100L, limit - length(items))
    req <- foundry_eval_request(
      path = paste0("evals/", eval_id, "/runs/", run_id, "/output_items"),
      method = "GET",
      api_key = api_key,
      token = token,
      endpoint = endpoint,
      api_version = api_version,
      project_endpoint = project_endpoint
    )
    req <- httr2::req_url_query(
      req,
      status = status,
      order = order,
      limit = page_size,
      after = cursor
    )

    result <- foundry_perform(req)
    page <- result$data %||% list()
    items <- c(items, page)
    if (!is.null(limit) && length(items) >= limit) {
      items <- items[seq_len(limit)]
      break
    }
    if (!isTRUE(result$has_more)) {
      break
    }
    next_cursor <- result$last_id %||%
      if (length(page) > 0L) page[[length(page)]]$id else NULL
    if (is.null(next_cursor) || !nzchar(next_cursor)) {
      cli::cli_abort(c(
        "The service reported more output items but returned no pagination cursor.",
        "i" = "Retrieved {length(items)} output item{?s} for run {.val {run_id}} before stopping."
      ))
    }
    if (identical(next_cursor, cursor)) {
      cli::cli_abort(c(
        "The service returned the same pagination cursor twice.",
        "i" = "Retrieved {length(items)} output item{?s} for run {.val {run_id}} before stopping."
      ))
    }
    cursor <- next_cursor
  }

  if (length(items) == 0L) {
    return(foundry_eval_output_item_tibble(list()))
  }
  purrr::map_dfr(items, foundry_eval_output_item_tibble)
}


# Internal helpers ------------------------------------------------------------

foundry_eval_request <- function(path,
                                 body = NULL,
                                 method = "POST",
                                 api_key = NULL,
                                 token = NULL,
                                 endpoint = NULL,
                                 api_version = NULL,
                                 project_endpoint = NULL,
                                 route = NULL) {
  foundry_build_routed_request(
    "evals",
    path = path,
    body = body,
    method = method,
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    project_endpoint = project_endpoint,
    api_version = api_version,
    route = route
  )
}


# Name the features of an evaluation that exist only on a project endpoint, or
# return NULL when it can run on the resource endpoint.
foundry_eval_needs_project <- function(graders = NULL,
                                       target = NULL,
                                       data_source = NULL,
                                       data_source_config = NULL) {
  needs <- character()
  if (is.list(graders) && !is.null(graders$type)) {
    graders <- list(graders)
  }
  uses_builtin <- length(graders) > 0L && any(vapply(graders, function(grader) {
    is.list(grader) && identical(grader$type, "azure_ai_evaluator")
  }, logical(1)))
  if (uses_builtin) {
    needs <- c(needs, "built-in evaluators")
  }
  source_type <- data_source$type %||% NA_character_
  if (!is.null(target) || identical(source_type, "azure_ai_target_completions")) {
    needs <- c(needs, "a model or agent target")
  }
  if (identical(source_type, "azure_ai_responses")) {
    needs <- c(needs, "stored responses")
  }
  if (identical(data_source_config$type, "azure_ai_source")) {
    needs <- c(needs, "a Foundry data source")
  }
  if (length(needs) == 0L) {
    return(NULL)
  }
  paste(unique(needs), collapse = " and ")
}


# Resolve the Evals route, and say so when a project-only feature moved the
# call to the configured project endpoint.
foundry_eval_resolve_route <- function(endpoint = NULL,
                                       project_endpoint = NULL,
                                       needs_project = NULL) {
  route <- foundry_resolve_route(
    "evals",
    endpoint = endpoint,
    project_endpoint = project_endpoint,
    needs_project = needs_project
  )
  switched <- !is.null(needs_project) &&
    is.null(endpoint) &&
    is.null(project_endpoint) &&
    !identical(foundry_state$route, "project")
  if (switched) {
    cli::cli_inform(
      c(
        "i" = "Using the project endpoint because this evaluation uses {needs_project}.",
        " " = "Pass {.arg project_endpoint}, or call {.code foundry_set_route(\"project\")}, when you look it up later."
      ),
      class = "foundryR_eval_project_route"
    )
  }
  route
}


foundry_eval_default_name <- function() {
  paste("foundryR evaluation", format(Sys.time(), "%Y-%m-%d %H:%M:%S UTC", tz = "UTC"))
}


foundry_eval_responses_source <- function(response_ids) {
  if (!is.character(response_ids) || length(response_ids) == 0L ||
      anyNA(response_ids) || !all(nzchar(response_ids))) {
    cli::cli_abort(
      "{.arg response_ids} must be a non-empty character vector without missing or empty values."
    )
  }
  list(
    type = "azure_ai_responses",
    item_generation_params = list(
      type = "response_retrieval",
      data_mapping = list(response_id = "{{item.resp_id}}"),
      source = list(
        type = "file_content",
        content = lapply(unname(response_ids), function(id) list(item = list(resp_id = id)))
      )
    )
  )
}


foundry_eval_input_messages <- function(input_messages) {
  if (is.character(input_messages)) {
    foundry_check_character_scalar(input_messages, "input_messages")
    return(list(
      type = "template",
      template = list(foundry_eval_template_message("user", input_messages))
    ))
  }
  if (is.list(input_messages) && !is.null(input_messages$type)) {
    return(input_messages)
  }
  cli::cli_abort(
    "{.arg input_messages} must be a template string or a Foundry {.field input_messages} list with a {.field type}."
  )
}


foundry_eval_template_message <- function(role, text) {
  list(
    type = "message",
    role = role,
    content = list(type = "input_text", text = text)
  )
}


foundry_eval_target <- function(target) {
  if (is.character(target)) {
    foundry_check_character_scalar(target, "target")
    return(list(type = "azure_ai_model", model = target))
  }
  if (is.data.frame(target)) {
    if (!"agent_name" %in% names(target) || nrow(target) != 1L) {
      cli::cli_abort(
        "A data-frame {.arg target} must be a one-row agent tibble from {.fn foundry_agent_create} or {.fn foundry_agent_get}."
      )
    }
    raw <- if ("raw_agent" %in% names(target)) target$raw_agent[[1]] else list()
    return(foundry_eval_agent_target(
      target$agent_name[[1]],
      version = raw$versions$latest$version
    ))
  }
  if (is.list(target) && identical(target$type, "agent_reference")) {
    return(foundry_eval_agent_target(target$name, version = target$version))
  }
  if (is.list(target) && is.character(target$type) && length(target$type) == 1L) {
    return(target)
  }
  cli::cli_abort(
    "{.arg target} must be a model deployment name, an agent reference, or a target list with a {.field type}."
  )
}


foundry_eval_agent_target <- function(name, version = NULL) {
  foundry_check_character_scalar(name, "target")
  target <- list(type = "azure_ai_agent", name = name)
  if (is.null(version)) {
    cli::cli_inform(
      c(
        "!" = "Evaluating the latest version of agent {.val {name}}.",
        "i" = "Pass {.code foundry_agent_reference(name, version = ...)} to pin the version for a reproducible run."
      ),
      class = "foundryR_unpinned_agent"
    )
  } else {
    target$version <- as.character(version)
  }
  target
}

foundry_eval_normalize_items <- function(input) {
  if (!is.list(input)) {
    cli::cli_abort("Grader {.arg input} must be a list built with {.fn foundry_eval_item}.")
  }
  # A single item is a named list carrying content; wrap it in a list.
  if (!is.null(input$content)) {
    return(list(input))
  }
  if (length(input) == 0L) {
    cli::cli_abort("Grader {.arg input} must contain at least one item.")
  }
  unname(input)
}


foundry_eval_normalize_criteria <- function(testing_criteria) {
  if (!is.list(testing_criteria)) {
    cli::cli_abort("{.arg testing_criteria} must be a grader or a list of graders.")
  }
  # A single grader is a named list carrying a type; wrap it in a list.
  if (!is.null(testing_criteria$type)) {
    return(list(testing_criteria))
  }
  if (length(testing_criteria) == 0L) {
    cli::cli_abort("{.arg testing_criteria} must contain at least one grader.")
  }
  unname(testing_criteria)
}


foundry_eval_tibble <- function(evaluation) {
  if (length(evaluation) == 0L) {
    return(tibble::tibble(
      eval_id = character(),
      name = character(),
      created_at = as.POSIXct(character()),
      testing_criteria = list(),
      data_source_config = list(),
      metadata = list(),
      raw_eval = list()
    ))
  }

  tibble::tibble(
    eval_id = evaluation$id %||% NA_character_,
    name = evaluation$name %||% NA_character_,
    created_at = foundry_response_created_at(evaluation$created_at %||% NA_real_),
    testing_criteria = list(evaluation$testing_criteria %||% list()),
    data_source_config = list(evaluation$data_source_config %||% list()),
    metadata = list(evaluation$metadata %||% list()),
    raw_eval = list(evaluation)
  )
}


foundry_eval_run_tibble <- function(run) {
  if (length(run) == 0L) {
    return(tibble::tibble(
      run_id = character(),
      eval_id = character(),
      name = character(),
      status = character(),
      created_at = as.POSIXct(character()),
      result_total = integer(),
      result_passed = integer(),
      result_failed = integer(),
      result_errored = integer(),
      report_url = character(),
      per_testing_criteria_results = list(),
      target_latency_p50_ms = numeric(),
      target_latency_p95_ms = numeric(),
      target_latency_samples = integer(),
      target_cost = numeric(),
      target_cost_currency = character(),
      target_cost_completeness = character(),
      raw_run = list()
    ))
  }

  counts <- run$result_counts %||% list()
  latency <- run$latency$target %||% list()
  cost <- run$estimated_cost$target %||% list()
  tibble::tibble(
    run_id = run$id %||% NA_character_,
    eval_id = run$eval_id %||% NA_character_,
    name = run$name %||% NA_character_,
    status = run$status %||% NA_character_,
    created_at = foundry_response_created_at(run$created_at %||% NA_real_),
    result_total = as.integer(counts$total %||% NA_integer_),
    result_passed = as.integer(counts$passed %||% NA_integer_),
    result_failed = as.integer(counts$failed %||% NA_integer_),
    result_errored = as.integer(counts$errored %||% NA_integer_),
    report_url = run$report_url %||% NA_character_,
    per_testing_criteria_results = list(
      foundry_eval_criteria_tibble(run$per_testing_criteria_results)
    ),
    target_latency_p50_ms = as.numeric(latency$p50_ms %||% NA_real_),
    target_latency_p95_ms = as.numeric(latency$p95_ms %||% NA_real_),
    target_latency_samples = as.integer(latency$sample_count %||% NA_integer_),
    target_cost = as.numeric(cost$estimated_cost %||% NA_real_),
    target_cost_currency = cost$currency %||% NA_character_,
    target_cost_completeness = cost$completeness %||% NA_character_,
    raw_run = list(run)
  )
}


foundry_eval_criteria_tibble <- function(results) {
  results <- results %||% list()
  if (length(results) == 0L) {
    return(tibble::tibble(
      testing_criteria = character(),
      passed = integer(),
      failed = integer(),
      pass_rate = numeric()
    ))
  }

  purrr::map_dfr(results, function(result) {
    passed <- as.integer(result$passed %||% NA_integer_)
    failed <- as.integer(result$failed %||% NA_integer_)
    pass_rate <- result$pass_rate %||% NA_real_
    if (is.na(pass_rate) && !is.na(passed) && !is.na(failed) && passed + failed > 0L) {
      pass_rate <- passed / (passed + failed)
    }
    tibble::tibble(
      testing_criteria = result$testing_criteria %||% result$name %||% NA_character_,
      passed = passed,
      failed = failed,
      pass_rate = as.numeric(pass_rate)
    )
  })
}


foundry_eval_output_item_tibble <- function(item) {
  empty <- tibble::tibble(
    output_item_id = character(),
    run_id = character(),
    eval_id = character(),
    datasource_item_id = integer(),
    status = character(),
    grader_name = character(),
    grader_type = character(),
    metric = character(),
    score = numeric(),
    label = character(),
    passed = logical(),
    threshold = numeric(),
    reason = character(),
    datasource_item = list(),
    sample_output_text = character(),
    sample_output_items = list(),
    raw_item = list()
  )
  if (length(item) == 0L) {
    return(empty)
  }

  results <- item$results %||% list()
  base <- tibble::tibble(
    output_item_id = item$id %||% NA_character_,
    run_id = item$run_id %||% NA_character_,
    eval_id = item$eval_id %||% NA_character_,
    datasource_item_id = as.integer(item$datasource_item_id %||% NA_integer_),
    status = item$status %||% NA_character_
  )
  item_details <- tibble::tibble(
    datasource_item = list(item$datasource_item),
    sample_output_text = foundry_eval_sample_text(item$sample),
    sample_output_items = list(item$sample$output_items %||% item$sample$output),
    raw_item = list(item)
  )

  grader_row <- function(res) {
    tibble::tibble(
      grader_name = res$name %||% NA_character_,
      grader_type = res$type %||% NA_character_,
      metric = res$metric %||% NA_character_,
      score = as.numeric(res$score %||% NA_real_),
      label = res$label %||% NA_character_,
      passed = if (is.null(res$passed)) NA else isTRUE(res$passed),
      threshold = as.numeric(res$threshold %||% NA_real_),
      reason = res$reason %||% NA_character_
    )
  }

  if (length(results) == 0L) {
    return(dplyr::bind_cols(base, grader_row(list()), item_details))
  }

  purrr::map_dfr(results, function(res) {
    dplyr::bind_cols(base, grader_row(res), item_details)
  })
}


# Collapse the assistant text in an output item's `sample`. Target runs return
# either a flat `output_text` or a list of output messages whose content is a
# string or a list of parts with `text`. Agent targets can return the parts as a
# JSON-encoded string, which is decoded to its text.
foundry_eval_sample_text <- function(sample) {
  if (is.null(sample)) {
    return(NA_character_)
  }
  if (is.character(sample$output_text) && length(sample$output_text) == 1L) {
    return(paste(foundry_eval_decode_parts(sample$output_text), collapse = "\n"))
  }

  message_text <- function(message) {
    if (!is.list(message)) {
      return(NULL)
    }
    if (!is.null(message$role) && !identical(message$role, "assistant")) {
      return(NULL)
    }
    content <- message$content
    if (is.character(content)) {
      return(unlist(lapply(content, foundry_eval_decode_parts), use.names = FALSE))
    }
    if (is.list(content)) {
      parts <- lapply(content, function(part) {
        if (is.list(part) && is.character(part$text)) part$text else NULL
      })
      return(unlist(parts, use.names = FALSE))
    }
    NULL
  }

  texts <- unlist(lapply(sample$output %||% list(), message_text), use.names = FALSE)
  if (length(texts) == 0L) {
    return(NA_character_)
  }
  paste(texts, collapse = "\n")
}


# Return the `text` of JSON-encoded content parts such as
# '[{"annotations": [], "text": "..."}]', or the string unchanged.
foundry_eval_decode_parts <- function(x) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !grepl("^\\s*[[{]", x)) {
    return(x)
  }
  parsed <- tryCatch(
    jsonlite::fromJSON(x, simplifyVector = FALSE),
    error = function(e) NULL
  )
  if (!is.list(parsed)) {
    return(x)
  }
  parts <- if (!is.null(names(parsed))) list(parsed) else parsed
  texts <- unlist(lapply(parts, function(part) {
    if (is.list(part) && is.character(part$text)) part$text else NULL
  }), use.names = FALSE)
  if (length(texts) > 0L) texts else x
}
