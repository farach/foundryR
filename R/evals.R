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
#'   model = "gpt-4.1-mini",
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
#'   model = "gpt-4.1",
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


#' Azure AI built-in evaluator grader
#'
#' Reference an Azure AI Foundry built-in evaluator (a `builtin.*` ID such as
#' `builtin.coherence` or `builtin.groundedness`) as a grader. This grader type
#' is only available on the project-scoped Foundry endpoint.
#'
#' @param name Character. Grader name shown in results.
#' @param evaluator_name Character. The evaluator ID, e.g. `"builtin.coherence"`.
#' @param initialization_parameters List. Optional parameters passed to the
#'   evaluator, e.g. `list(model = "gpt-4.1-mini")` for model-graded evaluators.
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
#'   initialization_parameters = list(model = "gpt-4.1-mini"),
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
#' from stored completions matching a metadata filter.
#'
#' @param type Character. Either `"custom"` or `"logs"`.
#' @param item_schema List. For `type = "custom"`, a JSON Schema (as an R list)
#'   describing each row.
#' @param include_sample_schema Logical. For `type = "custom"`, whether the eval
#'   should expect a populated `sample` namespace (generated responses).
#'   Defaults to `FALSE`.
#' @param metadata List. For `type = "logs"`, the stored-completions metadata
#'   filter.
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
foundry_eval_data_config <- function(type = c("custom", "logs"),
                                     item_schema = NULL,
                                     include_sample_schema = FALSE,
                                     metadata = NULL) {
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
#' Point an evaluation run at its rows: either an uploaded JSONL file (via
#' `file_id`) or inline `content`. Exactly one of `file_id` or `content` must be
#' supplied.
#'
#' @param file_id Character. ID of a JSONL file uploaded with
#'   [foundry_file_upload()].
#' @param content List. Inline rows, each a list with an `item` element (and an
#'   optional `sample` element).
#'
#' @return A named list describing a `jsonl` run data source, for use in
#'   [foundry_eval_run_create()].
#' @export
#'
#' @examples
#' foundry_eval_run_data(file_id = "file-abc123")
#'
#' foundry_eval_run_data(content = list(
#'   list(item = list(question = "2+2?", answer = "4"))
#' ))
foundry_eval_run_data <- function(file_id = NULL, content = NULL) {
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

  list(type = "jsonl", source = source)
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
#' @param endpoint Character. Optional endpoint override.
#' @param api_version Character. Optional `api-version` query value. The Foundry
#'   v1 evals surface is path-versioned, so this is usually left `NULL`.
#'
#' @return A one-row tibble describing the created evaluation.
#' @export
#'
#' @examples
#' \dontrun{
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
                                api_version = NULL) {
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

  req <- foundry_build_v1_request(
    path = "evals",
    body = body,
    method = "POST",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
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
#' foundry_evals(limit = 10)
#' }
foundry_evals <- function(limit = NULL,
                          after = NULL,
                          order = NULL,
                          api_key = NULL,
                          token = NULL,
                          endpoint = NULL,
                          api_version = NULL) {
  req <- foundry_build_v1_request(
    path = "evals",
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
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
#' foundry_eval_get("eval_abc123")
#' }
foundry_eval_get <- function(eval_id,
                             api_key = NULL,
                             token = NULL,
                             endpoint = NULL,
                             api_version = NULL) {
  foundry_check_character_scalar(eval_id, "eval_id")

  req <- foundry_build_v1_request(
    path = paste0("evals/", eval_id),
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )

  foundry_eval_tibble(foundry_perform(req))
}


#' Delete an evaluation
#'
#' @param eval_id Character. Evaluation ID to delete.
#' @inheritParams foundry_eval_create
#'
#' @return A one-row tibble with `eval_id`, `deleted`, and `object`.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_eval_delete("eval_abc123")
#' }
foundry_eval_delete <- function(eval_id,
                                api_key = NULL,
                                token = NULL,
                                endpoint = NULL,
                                api_version = NULL) {
  foundry_check_character_scalar(eval_id, "eval_id")

  req <- foundry_build_v1_request(
    path = paste0("evals/", eval_id),
    method = "DELETE",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )

  result <- foundry_perform(req)
  tibble::tibble(
    eval_id = result$eval_id %||% eval_id,
    deleted = isTRUE(result$deleted),
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
#' @param name Character. Optional run name.
#' @param metadata List. Optional metadata attached to the run.
#' @inheritParams foundry_eval_create
#'
#' @return A one-row tibble describing the created run.
#' @export
#'
#' @examples
#' \dontrun{
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
                                    api_version = NULL) {
  foundry_check_character_scalar(eval_id, "eval_id")
  if (!is.list(data_source) || is.null(data_source$type)) {
    cli::cli_abort("{.arg data_source} must be built with {.fn foundry_eval_run_data}.")
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

  req <- foundry_build_v1_request(
    path = paste0("evals/", eval_id, "/runs"),
    body = body,
    method = "POST",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
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
                              api_version = NULL) {
  foundry_check_character_scalar(eval_id, "eval_id")

  req <- foundry_build_v1_request(
    path = paste0("evals/", eval_id, "/runs"),
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
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
#' foundry_eval_run_get("eval_abc123", "evalrun_xyz")
#' }
foundry_eval_run_get <- function(eval_id,
                                 run_id,
                                 api_key = NULL,
                                 token = NULL,
                                 endpoint = NULL,
                                 api_version = NULL) {
  foundry_check_character_scalar(eval_id, "eval_id")
  foundry_check_character_scalar(run_id, "run_id")

  req <- foundry_build_v1_request(
    path = paste0("evals/", eval_id, "/runs/", run_id),
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
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
#' foundry_eval_run_cancel("eval_abc123", "evalrun_xyz")
#' }
foundry_eval_run_cancel <- function(eval_id,
                                    run_id,
                                    api_key = NULL,
                                    token = NULL,
                                    endpoint = NULL,
                                    api_version = NULL) {
  foundry_check_character_scalar(eval_id, "eval_id")
  foundry_check_character_scalar(run_id, "run_id")

  req <- foundry_build_v1_request(
    path = paste0("evals/", eval_id, "/runs/", run_id),
    method = "POST",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )

  foundry_eval_run_tibble(foundry_perform(req))
}


#' List evaluation run output items
#'
#' Return the per-row grader results for a completed run. The result is unnested
#' to one row per grader outcome, so a row that was scored by three graders
#' yields three rows.
#'
#' @param eval_id Character. Evaluation ID.
#' @param run_id Character. Run ID.
#' @param status Character. Optional status filter, `"fail"` or `"pass"`.
#' @param order Character. Optional sort order, `"asc"` or `"desc"`.
#' @param limit Integer. Optional maximum number of output items to return.
#' @param after Character. Optional pagination cursor.
#' @inheritParams foundry_eval_create
#'
#' @return A tibble with one row per grader result, including `score`, `label`,
#'   `passed`, and `reason` where the grader supplies them.
#' @export
#'
#' @examples
#' \dontrun{
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
                                          api_version = NULL) {
  foundry_check_character_scalar(eval_id, "eval_id")
  foundry_check_character_scalar(run_id, "run_id")

  req <- foundry_build_v1_request(
    path = paste0("evals/", eval_id, "/runs/", run_id, "/output_items"),
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )
  req <- httr2::req_url_query(
    req,
    status = status,
    order = order,
    limit = limit,
    after = after
  )

  result <- foundry_perform(req)
  items <- result$data %||% list()
  if (length(items) == 0L) {
    return(foundry_eval_output_item_tibble(list()))
  }
  purrr::map_dfr(items, foundry_eval_output_item_tibble)
}


# Internal helpers ------------------------------------------------------------

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
      raw_run = list()
    ))
  }

  counts <- run$result_counts %||% list()
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
    raw_run = list(run)
  )
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
    return(dplyr::bind_cols(base, grader_row(list()), tibble::tibble(raw_item = list(item))))
  }

  purrr::map_dfr(results, function(res) {
    dplyr::bind_cols(base, grader_row(res), tibble::tibble(raw_item = list(item)))
  })
}
