#' Evaluate a data frame with Microsoft Foundry cloud evaluation
#'
#' @description
#' Run a Microsoft Foundry cloud evaluation from a data frame and get the
#' grader results back joined to your rows. `foundry_evaluate()` creates the
#' evaluation, starts a run, waits for it, and returns one row per input row and
#' grader, so pass rates, failure reasons, and generated responses can be
#' summarised with ordinary data-frame tools.
#'
#' There are two modes:
#'
#' * **Grade existing columns** (`target = NULL`). Graders read fields of
#'   `data` with `{{item.<column>}}`, for example a `response` column that your
#'   application already produced.
#' * **Generate, then grade** (`target` supplied). Foundry sends `input` for
#'   each row to a model deployment or agent, then graders read the generated
#'   output with `{{sample.output_text}}` or, for agents,
#'   `{{sample.output_items}}` (structured output including tool calls).
#'
#' @details
#' `foundry_evaluate()` creates a persistent evaluation and run in your project;
#' both stay visible in the Foundry portal and nothing is deleted afterwards.
#' Target generation and model-graded evaluators consume tokens on your
#' deployments.
#'
#' Every item sent to the service carries a reserved `foundryr_row_id` field,
#' and results are matched to rows of `data` only through that field as the
#' service echoes it back. Results are never matched by position. Column types
#' map to JSON Schema types (character and factor to `string`, logical to
#' `boolean`, integer to `integer`, finite double to `number`). Missing values
#' are rejected rather than silently dropped; recode them first. List columns
#' (for example message arrays for agent evaluators) require an explicit
#' `item_schema`.
#'
#' Before anything is created, every `{{item.<field>}}` reference in the graders
#' and `input` is checked against the columns of `data`.
#'
#' @param data Data frame with one row per test case. Every column is sent as a
#'   field of the evaluation item.
#' @param graders A grader from `foundry_grader_*()` or a list of graders.
#'   Required unless `eval_id` is supplied.
#' @param target Optional target that generates a response for each row: a
#'   model deployment name, an agent reference from [foundry_agent_reference()]
#'   (pin `version` for reproducible runs), a one-row agent tibble from
#'   [foundry_agent_create()], or a complete target list (see
#'   [foundry_eval_run_data()]).
#' @param input Required with `target`. The user message: either the name of a
#'   column in `data`, sent as `{{item.<column>}}`, or a template string such as
#'   `"Classify this comment: {{item.comment}}"`.
#' @param instructions Optional developer message sent before `input` when a
#'   target generates responses.
#' @param sampling_params Optional named list of sampling parameters for a
#'   model target, for example `list(max_completion_tokens = 2048)`.
#' @param item_schema Optional JSON Schema list describing every column of
#'   `data`. Required when `data` has list columns. The reserved
#'   `foundryr_row_id` field is added automatically.
#' @param eval_id Optional ID of an evaluation created by `foundry_evaluate()`.
#'   A new run is added to it, reusing its graders, so runs can be compared in
#'   the Foundry portal. `graders` and `item_schema` must then be `NULL`.
#' @param name Optional name for the evaluation and the run.
#' @param metadata Optional named list of metadata attached to the evaluation
#'   and the run.
#' @param wait Logical. If `TRUE` (the default), wait for the run and return the
#'   joined results. If `FALSE`, return the run immediately; collect it later
#'   with [foundry_eval_run_wait()] and [foundry_eval_run_results()].
#' @param interval Numeric. Seconds between status checks while waiting.
#' @param timeout Numeric. Maximum seconds to wait. Use `Inf` to wait
#'   indefinitely. On timeout the run keeps going; resume with
#'   [foundry_eval_run_wait()].
#' @inheritParams foundry_eval_create
#'
#' @return With `wait = TRUE`, the tibble returned by
#'   [foundry_eval_run_results()]. With `wait = FALSE`, the one-row run tibble
#'   returned by [foundry_eval_run_create()].
#' @seealso [foundry_eval_run_results()] for the result columns,
#'   `vignette("evaluations", package = "foundryR")` for a worked example.
#' @export
#'
#' @examples
#' \dontrun{
#' # Requires a Foundry project endpoint and credentials, plus deployments for
#' # the target and the judge model.
#' tickets <- data.frame(
#'   ticket = c("I was charged twice this month.", "The app crashes on login."),
#'   label = c("billing", "technical")
#' )
#'
#' foundry_evaluate(
#'   tickets,
#'   graders = foundry_grader_string_check(
#'     name = "label-match",
#'     input = "{{sample.output_text}}",
#'     reference = "{{item.label}}",
#'     operation = "ilike"
#'   ),
#'   target = "gpt-5-mini",
#'   input = "ticket",
#'   instructions = "Reply with one word: billing, technical, or account."
#' )
#' }
foundry_evaluate <- function(data,
                             graders = NULL,
                             target = NULL,
                             input = NULL,
                             instructions = NULL,
                             sampling_params = NULL,
                             item_schema = NULL,
                             eval_id = NULL,
                             name = NULL,
                             metadata = NULL,
                             wait = TRUE,
                             interval = 10,
                             timeout = Inf,
                             api_key = NULL,
                             token = NULL,
                             endpoint = NULL,
                             project_endpoint = NULL) {
  foundry_eval_check_data(data)
  foundry_check_logical_scalar(wait, "wait")
  foundry_eval_check_wait_args(interval, timeout)
  if (!is.null(name)) {
    foundry_check_character_scalar(name, "name")
  }
  if (!is.null(metadata) && !is.list(metadata)) {
    cli::cli_abort("{.arg metadata} must be a named list.")
  }
  route <- foundry_eval_route(endpoint = endpoint, project_endpoint = project_endpoint)

  input_messages <- NULL
  if (is.null(target)) {
    supplied <- c(
      input = !is.null(input),
      instructions = !is.null(instructions),
      sampling_params = !is.null(sampling_params)
    )
    if (any(supplied)) {
      cli::cli_abort("{.arg {names(supplied)[supplied]}} require{?s/} {.arg target}.")
    }
  } else {
    if (is.null(input)) {
      cli::cli_abort("{.arg input} is required when {.arg target} is supplied.")
    }
    target <- foundry_eval_sampled_target(target, sampling_params)
    input_messages <- foundry_eval_messages(
      foundry_eval_input_template(input, data),
      instructions
    )
  }

  if (is.null(eval_id)) {
    if (is.null(graders)) {
      cli::cli_abort("{.arg graders} is required unless {.arg eval_id} is supplied.")
    }
    graders <- foundry_eval_normalize_criteria(graders)
    schema <- foundry_eval_item_schema(data, item_schema)
  } else {
    foundry_check_character_scalar(eval_id, "eval_id")
    if (!is.null(graders) || !is.null(item_schema)) {
      cli::cli_abort(
        paste(
          "{.arg graders} and {.arg item_schema} belong to the existing evaluation;",
          "leave them {.code NULL} with {.arg eval_id}."
        )
      )
    }
    existing <- foundry_eval_get(
      eval_id,
      api_key = api_key,
      token = token,
      endpoint = route$endpoint,
      project_endpoint = route$project_endpoint
    )
    graders <- existing$testing_criteria[[1]]
    foundry_eval_check_missing(data)
    schema <- foundry_eval_existing_schema(existing, data, needs_sample = !is.null(target))
  }

  foundry_eval_check_route(route, graders, target)
  foundry_eval_check_references(
    graders = graders,
    input_messages = input_messages,
    fields = names(data),
    has_sample = !is.null(target)
  )
  items <- foundry_eval_items(data, schema)

  if (is.null(eval_id)) {
    evaluation <- foundry_eval_create(
      name = name,
      data_source_config = foundry_eval_data_config(
        type = "custom",
        item_schema = schema,
        include_sample_schema = !is.null(target)
      ),
      testing_criteria = graders,
      metadata = metadata,
      api_key = api_key,
      token = token,
      endpoint = route$endpoint,
      project_endpoint = route$project_endpoint
    )
    eval_id <- evaluation$eval_id[[1]]
  }

  run <- foundry_eval_run_create(
    eval_id,
    data_source = foundry_eval_run_data(
      content = items,
      target = target,
      input_messages = input_messages
    ),
    name = name,
    metadata = metadata,
    api_key = api_key,
    token = token,
    endpoint = route$endpoint,
    project_endpoint = route$project_endpoint
  )
  run_id <- run$run_id[[1]]
  cli::cli_inform(
    c("i" = "Started run {.val {run_id}} in evaluation {.val {eval_id}}."),
    class = "foundryR_eval_started"
  )
  if (!wait) {
    return(run)
  }

  final <- foundry_eval_run_wait(
    eval_id,
    run_id,
    interval = interval,
    timeout = timeout,
    api_key = api_key,
    token = token,
    endpoint = route$endpoint,
    project_endpoint = route$project_endpoint
  )
  foundry_eval_check_completed(final)
  foundry_eval_run_results(
    eval_id,
    run_id,
    data = data,
    api_key = api_key,
    token = token,
    endpoint = route$endpoint,
    project_endpoint = route$project_endpoint
  )
}


#' Wait for an evaluation run to finish
#'
#' Poll an evaluation run until it reaches a terminal state (`"completed"`,
#' `"failed"`, or `"canceled"`).
#'
#' @param interval Numeric. Seconds between status checks.
#' @param timeout Numeric. Maximum seconds to wait. Use `Inf` to wait
#'   indefinitely. On timeout the run keeps going on the service.
#' @inheritParams foundry_eval_run_get
#'
#' @return The final one-row run tibble from [foundry_eval_run_get()]. Check
#'   its `status` column: failed and canceled runs are returned, not raised.
#' @export
#'
#' @examples
#' \dontrun{
#' # Requires a configured Foundry endpoint and credentials, plus an evaluation
#' # run. Polling may take several minutes.
#' foundry_eval_run_wait("eval_abc123", "evalrun_xyz", interval = 15)
#' }
foundry_eval_run_wait <- function(eval_id,
                                  run_id,
                                  interval = 10,
                                  timeout = Inf,
                                  api_key = NULL,
                                  token = NULL,
                                  endpoint = NULL,
                                  api_version = NULL,
                                  project_endpoint = NULL) {
  foundry_check_character_scalar(eval_id, "eval_id")
  foundry_check_character_scalar(run_id, "run_id")
  foundry_eval_check_wait_args(interval, timeout)
  route <- foundry_eval_route(endpoint = endpoint, project_endpoint = project_endpoint)

  started <- Sys.time()
  repeat {
    run <- foundry_eval_run_get(
      eval_id,
      run_id,
      api_key = api_key,
      token = token,
      endpoint = route$endpoint,
      api_version = api_version,
      project_endpoint = route$project_endpoint
    )
    status <- run$status[[1]]
    if (!is.na(status) && status %in% foundry_eval_terminal_statuses()) {
      return(run)
    }
    elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
    if (is.finite(timeout) && elapsed >= timeout) {
      cli::cli_abort(c(
        "Timed out waiting for evaluation run {.val {run_id}}; it is still {.val {status}}.",
        "i" = "Resume with {.code foundry_eval_run_wait(\"{eval_id}\", \"{run_id}\")}."
      ))
    }
    if (interval > 0) {
      Sys.sleep(interval)
    }
  }
}


#' Collect evaluation results joined to the evaluated rows
#'
#' Retrieve every output item of a completed run and join the grader results to
#' the data frame that was evaluated with [foundry_evaluate()]. Rows are matched
#' only through the `foundryr_row_id` field that `foundry_evaluate()` adds to
#' each item, and the echoed item fields are checked against `data`, so passing
#' a reordered or different data frame is an error rather than a silent
#' mismatch.
#'
#' @param data The data frame passed to [foundry_evaluate()], in the same row
#'   order.
#' @inheritParams foundry_eval_run_get
#'
#' @return A tibble with one row per row of `data` and grader, in the row order
#'   of `data`. It contains every column of `data` followed by:
#'   \describe{
#'     \item{.eval_id, .run_id, .output_item_id}{Evaluation, run, and output
#'       item identifiers.}
#'     \item{.status}{Output item status reported by the service.}
#'     \item{.grader, .grader_type, .metric}{Grader name, type, and metric.}
#'     \item{.score, .label, .passed, .threshold, .reason}{Grader result. Not
#'       every grader reports every field.}
#'     \item{.output_text, .output_items}{The generated response for target
#'       runs: plain text and the structured output (a list-column).}
#'   }
#'   Rows of `data` without an output item are kept with missing result fields,
#'   with a warning. The final run tibble, including per-criterion pass rates,
#'   target latency, and estimated target cost, is attached as the `"run"`
#'   attribute.
#' @export
#'
#' @examples
#' \dontrun{
#' # Requires a configured Foundry endpoint and credentials, plus a completed
#' # run started by foundry_evaluate(tickets, ..., wait = FALSE).
#' foundry_eval_run_results("eval_abc123", "evalrun_xyz", data = tickets)
#' }
foundry_eval_run_results <- function(eval_id,
                                     run_id,
                                     data,
                                     api_key = NULL,
                                     token = NULL,
                                     endpoint = NULL,
                                     api_version = NULL,
                                     project_endpoint = NULL) {
  foundry_check_character_scalar(eval_id, "eval_id")
  foundry_check_character_scalar(run_id, "run_id")
  foundry_eval_check_data(data)
  route <- foundry_eval_route(endpoint = endpoint, project_endpoint = project_endpoint)

  run <- foundry_eval_run_get(
    eval_id,
    run_id,
    api_key = api_key,
    token = token,
    endpoint = route$endpoint,
    api_version = api_version,
    project_endpoint = route$project_endpoint
  )
  foundry_eval_check_completed(run)

  items <- foundry_eval_run_output_items(
    eval_id,
    run_id,
    api_key = api_key,
    token = token,
    endpoint = route$endpoint,
    api_version = api_version,
    project_endpoint = route$project_endpoint
  )
  results <- foundry_eval_join_results(items, data, eval_id = eval_id, run_id = run_id)
  attr(results, "run") <- run
  results
}


# Internal helpers ------------------------------------------------------------

foundry_eval_row_key <- "foundryr_row_id"

foundry_eval_result_columns <- c(
  ".eval_id", ".run_id", ".output_item_id", ".status", ".grader",
  ".grader_type", ".metric", ".score", ".label", ".passed", ".threshold",
  ".reason", ".output_text", ".output_items"
)


foundry_eval_terminal_statuses <- function() {
  c("completed", "failed", "canceled", "cancelled")
}


foundry_eval_check_wait_args <- function(interval, timeout) {
  if (!is.numeric(interval) || length(interval) != 1L || is.na(interval) || interval < 0) {
    cli::cli_abort("{.arg interval} must be a non-negative number.")
  }
  if (!is.numeric(timeout) || length(timeout) != 1L || is.na(timeout) || timeout < 0) {
    cli::cli_abort("{.arg timeout} must be a non-negative number or {.code Inf}.")
  }
  invisible(NULL)
}


foundry_eval_check_data <- function(data) {
  if (!is.data.frame(data) || nrow(data) == 0L || ncol(data) == 0L) {
    cli::cli_abort("{.arg data} must be a data frame with at least one row and one column.")
  }
  columns <- names(data)
  if (anyNA(columns) || any(!nzchar(columns)) || anyDuplicated(columns) > 0L) {
    cli::cli_abort("{.arg data} must have unique, non-empty column names.")
  }
  reserved <- intersect(columns, c(foundry_eval_row_key, foundry_eval_result_columns))
  if (length(reserved) > 0L) {
    cli::cli_abort(c(
      "{.arg data} uses column names reserved for evaluation results.",
      "x" = "Rename {.field {reserved}}."
    ))
  }
  invisible(data)
}


foundry_eval_check_completed <- function(run) {
  status <- run$status[[1]]
  if (identical(status, "completed")) {
    return(invisible(run))
  }
  raw <- run$raw_run[[1]] %||% list()
  detail <- raw$error$message %||% raw$error$code %||% NULL
  bullets <- c(
    paste(
      "Evaluation run {.val {run$run_id[[1]]}} in evaluation {.val {run$eval_id[[1]]}}",
      "is {.val {status}}, not {.val completed}."
    )
  )
  if (!is.null(detail)) {
    bullets <- c(bullets, "x" = "{detail}")
  }
  if (!is.na(status) && !status %in% foundry_eval_terminal_statuses()) {
    bullets <- c(bullets, "i" = "Wait for it with {.fn foundry_eval_run_wait}.")
  }
  cli::cli_abort(bullets)
}


foundry_eval_column_type <- function(column, name) {
  if (inherits(column, c("Date", "POSIXt", "difftime", "integer64"))) {
    cli::cli_abort(c(
      "Column {.field {name}} has class {.cls {class(column)}}, which has no unambiguous JSON form.",
      "i" = "Convert it to character or double before evaluating."
    ))
  }
  if (is.factor(column) || is.character(column)) {
    return("string")
  }
  if (is.logical(column)) {
    return("boolean")
  }
  if (is.integer(column)) {
    return("integer")
  }
  if (is.double(column)) {
    if (any(is.infinite(column) | is.nan(column))) {
      cli::cli_abort("Column {.field {name}} contains non-finite values.")
    }
    return("number")
  }
  if (is.list(column)) {
    cli::cli_abort(c(
      "Column {.field {name}} is a list column.",
      "i" = "Supply {.arg item_schema} describing its JSON structure."
    ))
  }
  cli::cli_abort("Column {.field {name}} has unsupported type {.cls {class(column)}}.")
}


# Reject missing values in scalar columns rather than dropping or nulling them.
foundry_eval_check_missing <- function(data) {
  scalar <- !vapply(data, is.list, logical(1))
  missing <- names(data)[scalar][vapply(data[scalar], anyNA, logical(1))]
  if (length(missing) > 0L) {
    cli::cli_abort(c(
      "Missing values cannot be sent as evaluation items.",
      "x" = "Columns with {.code NA}: {.field {missing}}.",
      "i" = "Remove or recode those rows before evaluating."
    ))
  }
  invisible(data)
}


# Build the item schema, or validate a supplied one, and add the reserved row
# key.
foundry_eval_item_schema <- function(data, item_schema = NULL) {
  foundry_eval_check_missing(data)

  key <- foundry_eval_row_key
  if (is.null(item_schema)) {
    types <- vapply(names(data), function(col) foundry_eval_column_type(data[[col]], col), character(1))
    properties <- lapply(types, function(type) list(type = type))
    names(properties) <- names(data)
    properties[[key]] <- list(type = "string")
    return(list(
      type = "object",
      properties = properties,
      required = as.list(c(names(data), key))
    ))
  }

  if (!is.list(item_schema) || !is.list(item_schema$properties)) {
    cli::cli_abort("{.arg item_schema} must be a JSON Schema list with a {.field properties} element.")
  }
  described <- setdiff(names(item_schema$properties), key)
  undescribed <- setdiff(names(data), described)
  unknown <- setdiff(described, names(data))
  if (length(undescribed) > 0L || length(unknown) > 0L) {
    cli::cli_abort(c(
      "{.arg item_schema} must describe exactly the columns of {.arg data}.",
      "x" = if (length(undescribed) > 0L) "Not in the schema: {.field {undescribed}}.",
      "x" = if (length(unknown) > 0L) "Not in {.arg data}: {.field {unknown}}."
    ))
  }
  item_schema$type <- item_schema$type %||% "object"
  item_schema$properties[[key]] <- list(type = "string")
  item_schema$required <- as.list(unique(c(unlist(item_schema$required), key)))
  foundry_preserve_schema_arrays(item_schema)
}


# Validate that an existing evaluation can carry the rows of `data`. When the
# service does not echo a recognisable schema the check is skipped; the join
# still refuses to match rows without the echoed key.
foundry_eval_existing_schema <- function(evaluation, data, needs_sample) {
  config <- evaluation$data_source_config[[1]] %||% list()
  item <- config$item_schema %||% config$schema$properties$item
  properties <- item$properties
  if (is.null(properties)) {
    cli::cli_warn(c(
      "Could not read the item schema of evaluation {.val {evaluation$eval_id[[1]]}}.",
      "i" = "The run is created anyway; results are joined only if the service echoes {.field {foundry_eval_row_key}}."
    ))
    return(list(type = "object", properties = list()))
  }

  missing <- setdiff(c(names(data), foundry_eval_row_key), names(properties))
  if (length(missing) > 0L) {
    cli::cli_abort(c(
      "Evaluation {.val {evaluation$eval_id[[1]]}} cannot carry the rows of {.arg data}.",
      "x" = "Its item schema has no {.field {missing}}.",
      "i" = "Add runs only to evaluations created by {.fn foundry_evaluate} with the same columns."
    ))
  }
  has_sample <- config$include_sample_schema %||%
    (if (is.null(config$schema)) NA else !is.null(config$schema$properties$sample))
  if (needs_sample && isFALSE(has_sample)) {
    cli::cli_abort(c(
      "Evaluation {.val {evaluation$eval_id[[1]]}} was created without a sample schema.",
      "i" = "Target runs need an evaluation created with a {.arg target}."
    ))
  }
  invisible(item)
}


foundry_eval_sampled_target <- function(target, sampling_params) {
  target <- foundry_eval_target(target)
  if (is.null(sampling_params)) {
    return(target)
  }
  if (!identical(target$type, "azure_ai_model")) {
    cli::cli_abort("{.arg sampling_params} applies only to model deployment targets.")
  }
  if (!is.list(sampling_params) || is.null(names(sampling_params)) || any(!nzchar(names(sampling_params)))) {
    cli::cli_abort("{.arg sampling_params} must be a named list.")
  }
  target$sampling_params <- sampling_params
  target
}


foundry_eval_input_template <- function(input, data) {
  foundry_check_character_scalar(input, "input")
  if (input %in% names(data)) {
    return(paste0("{{item.", input, "}}"))
  }
  if (!grepl("\\{\\{\\s*item\\.", input)) {
    cli::cli_abort(c(
      "{.arg input} must name a column of {.arg data} or be a template with {.code {{{{item.<field>}}}}} references.",
      "x" = "{.val {input}} is neither."
    ))
  }
  input
}


foundry_eval_messages <- function(input_template, instructions = NULL) {
  template <- list(foundry_eval_template_message("user", input_template))
  if (!is.null(instructions)) {
    foundry_check_character_scalar(instructions, "instructions")
    template <- c(list(foundry_eval_template_message("developer", instructions)), template)
  }
  list(type = "template", template = template)
}


foundry_eval_check_route <- function(route, graders, target) {
  if (!is.null(route$project_endpoint)) {
    return(invisible(NULL))
  }
  needs <- character()
  if (!is.null(target)) {
    needs <- c(needs, "model and agent targets")
  }
  uses_builtin <- any(vapply(graders, function(grader) {
    identical(grader$type, "azure_ai_evaluator")
  }, logical(1)))
  if (uses_builtin) {
    needs <- c(needs, "built-in {.code azure_ai_evaluator} graders")
  }
  if (length(needs) > 0L) {
    cli::cli_abort(c(
      paste(paste(needs, collapse = " and "), "require the project Evals route."),
      "i" = "Pass {.arg project_endpoint} or set one with {.fn foundry_set_project_endpoint}."
    ))
  }
  invisible(NULL)
}


foundry_eval_template_fields <- function(x, namespace) {
  strings <- rapply(list(x), function(s) s, classes = "character", how = "unlist")
  if (length(strings) == 0L) {
    return(character())
  }
  pattern <- paste0("\\{\\{\\s*", namespace, "\\.([A-Za-z0-9_]+)")
  matches <- regmatches(strings, gregexpr(pattern, strings, perl = TRUE))
  fields <- sub(pattern, "\\1", unlist(matches, use.names = FALSE), perl = TRUE)
  unique(fields)
}


foundry_eval_check_references <- function(graders, input_messages, fields, has_sample) {
  referenced <- foundry_eval_template_fields(list(graders, input_messages), "item")
  unknown <- setdiff(referenced, fields)
  if (length(unknown) > 0L) {
    cli::cli_abort(c(
      "Graders or {.arg input} reference item fields that are not columns of {.arg data}.",
      "x" = "Unknown: {.field {unknown}}.",
      "i" = "Available: {.field {fields}}."
    ))
  }
  if (!has_sample && length(foundry_eval_template_fields(graders, "sample")) > 0L) {
    cli::cli_abort(c(
      "Graders reference {.code sample} fields, but no {.arg target} generates responses.",
      "i" = "Supply {.arg target}, or grade existing columns with {.code {{{{item.<column>}}}}}."
    ))
  }
  invisible(NULL)
}


foundry_eval_items <- function(data, schema = NULL) {
  columns <- names(data)
  properties <- schema$properties %||% list()
  # auto_unbox would turn a one-element array cell into a JSON scalar, so keep
  # atomic cells of array-typed list columns boxed.
  array_columns <- columns[vapply(columns, function(col) {
    is.list(data[[col]]) && "array" %in% unlist(properties[[col]]$type)
  }, logical(1))]

  lapply(seq_len(nrow(data)), function(i) {
    item <- lapply(columns, function(col) {
      value <- data[[col]]
      if (is.factor(value)) {
        return(as.character(value[[i]]))
      }
      cell <- value[[i]]
      if (col %in% array_columns && is.atomic(cell)) {
        return(I(cell))
      }
      cell
    })
    names(item) <- columns
    item[[foundry_eval_row_key]] <- as.character(i)
    list(item = item)
  })
}


foundry_eval_same_value <- function(expected, echoed) {
  if (is.null(echoed) || length(echoed) != 1L) {
    return(FALSE)
  }
  if (is.factor(expected) || is.character(expected)) {
    return(identical(as.character(expected), as.character(echoed)))
  }
  if (is.logical(expected)) {
    return(identical(expected, isTRUE(echoed)))
  }
  if (is.numeric(expected)) {
    echoed <- suppressWarnings(as.numeric(echoed))
    return(!is.na(echoed) && abs(expected - echoed) <= 1e-9 * max(1, abs(expected)))
  }
  TRUE
}


foundry_eval_join_results <- function(items, data, eval_id, run_id) {
  key <- foundry_eval_row_key
  echoed_key <- vapply(items$datasource_item, function(item) {
    value <- item[[key]]
    if (is.null(value) || length(value) != 1L) NA_character_ else as.character(value)
  }, character(1))
  if (anyNA(echoed_key)) {
    cli::cli_abort(c(
      paste(
        "The service did not echo {.field {key}} for every output item,",
        "so results cannot be matched to rows of {.arg data}."
      ),
      "i" = paste(
        "Nothing was matched by position. Inspect the raw results with",
        "{.code foundry_eval_run_output_items(\"{eval_id}\", \"{run_id}\")}."
      )
    ))
  }

  row <- match(echoed_key, as.character(seq_len(nrow(data))))
  if (anyNA(row)) {
    cli::cli_abort(c(
      "Output items refer to rows that are not in {.arg data}.",
      "i" = "Pass the same data frame, in the same row order, that was evaluated."
    ))
  }

  # Compare every echoed scalar field with the matching row of `data`.
  first <- !duplicated(items$output_item_id)
  scalar_columns <- names(data)[!vapply(data, is.list, logical(1))]
  mismatched <- vapply(which(first), function(i) {
    echoed <- items$datasource_item[[i]]
    !all(vapply(scalar_columns, function(col) {
      is.null(echoed[[col]]) || foundry_eval_same_value(data[[col]][[row[[i]]]], echoed[[col]])
    }, logical(1)))
  }, logical(1))
  if (any(mismatched)) {
    cli::cli_abort(c(
      "{sum(mismatched)} output item{?s} do{?es/} not match the corresponding rows of {.arg data}.",
      "i" = "Pass the same data frame, in the same row order, that was evaluated."
    ))
  }

  unmatched <- setdiff(seq_len(nrow(data)), row)
  if (length(unmatched) > 0L) {
    cli::cli_warn(
      "{length(unmatched)} row{?s} of {.arg data} had no output item; their result fields are missing."
    )
  }

  results <- tibble::tibble(
    .row = c(row, unmatched),
    .eval_id = eval_id,
    .run_id = run_id,
    .output_item_id = c(items$output_item_id, rep(NA_character_, length(unmatched))),
    .status = c(items$status, rep(NA_character_, length(unmatched))),
    .grader = c(items$grader_name, rep(NA_character_, length(unmatched))),
    .grader_type = c(items$grader_type, rep(NA_character_, length(unmatched))),
    .metric = c(items$metric, rep(NA_character_, length(unmatched))),
    .score = c(items$score, rep(NA_real_, length(unmatched))),
    .label = c(items$label, rep(NA_character_, length(unmatched))),
    .passed = c(items$passed, rep(NA, length(unmatched))),
    .threshold = c(items$threshold, rep(NA_real_, length(unmatched))),
    .reason = c(items$reason, rep(NA_character_, length(unmatched))),
    .output_text = c(items$sample_output_text, rep(NA_character_, length(unmatched))),
    .output_items = c(items$sample_output_items, vector("list", length(unmatched)))
  )
  results <- results[order(results$.row, seq_len(nrow(results))), , drop = FALSE]
  input_rows <- tibble::as_tibble(data)[results$.row, , drop = FALSE]
  dplyr::bind_cols(input_rows, results[, setdiff(names(results), ".row")])
}
