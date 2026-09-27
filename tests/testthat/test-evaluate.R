# Tests for the evaluation workflow: target and stored-response data sources,
# run and output-item enrichment, run polling, foundry_evaluate(), and the
# row-key join in foundry_eval_run_results(). All HTTP is mocked.

project_url <- "https://acct.services.ai.azure.com/api/projects/demo"

setup_project_env <- function(env = parent.frame()) {
  setup_mock_env(env = env)
  withr::local_envvar(
    AZURE_FOUNDRY_PROJECT_ENDPOINT = project_url,
    AZURE_FOUNDRY_PROJECT_TOKEN = "test-project-token",
    .local_envir = env
  )
}

# A minimal fake Evals service. `routes` maps anchored "METHOD path" regular
# expressions to a response body or a function of the request. Every request is
# recorded, and any unexpected request fails the test.
local_fake_evals <- function(routes, env = parent.frame()) {
  log <- new.env(parent = emptyenv())
  log$requests <- list()
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      log$requests[[length(log$requests) + 1L]] <- req
      path <- sub("\\?.*$", "", sub("^https?://[^/]+", "", req$url))
      key <- paste(req$method, path)
      for (pattern in names(routes)) {
        if (grepl(pattern, key)) {
          handler <- routes[[pattern]]
          body <- if (is.function(handler)) handler(req) else handler
          return(mock_httr2_response(body))
        }
      }
      stop("Unexpected request: ", key, call. = FALSE)
    },
    .package = "httr2",
    .env = env
  )
  log
}

requests_matching <- function(log, pattern) {
  Filter(function(req) grepl(pattern, paste(req$method, req$url)), log$requests)
}

fake_eval <- function(id = "eval_1", properties = NULL, include_sample = TRUE,
                      criteria = NULL) {
  config <- list(type = "custom", include_sample_schema = include_sample)
  if (!is.null(properties)) {
    config$item_schema <- list(type = "object", properties = properties)
  }
  list(
    id = id,
    object = "eval",
    name = "tickets",
    created_at = 1741369938,
    data_source_config = config,
    testing_criteria = criteria %||% list(list(
      type = "string_check", name = "label-match",
      input = "{{sample.output_text}}", reference = "{{item.label}}",
      operation = "ilike"
    ))
  )
}

fake_run <- function(status = "completed", id = "run_1", error = NULL) {
  run <- list(
    id = id,
    object = "eval.run",
    eval_id = "eval_1",
    name = "tickets",
    status = status,
    created_at = 1741369938,
    report_url = "https://ai.azure.com/report",
    result_counts = list(total = 2, passed = 1, failed = 1, errored = 0),
    per_testing_criteria_results = list(
      list(testing_criteria = "label-match", passed = 1, failed = 1)
    ),
    latency = list(target = list(p50_ms = 812.5, p95_ms = 2400, sample_count = 2)),
    estimated_cost = list(target = list(
      estimated_cost = 0.0123, currency = "USD", completeness = "complete"
    ))
  )
  if (!is.null(error)) {
    run$error <- error
  }
  run
}

tickets <- function() {
  tibble::tibble(
    ticket = c("I was charged twice.", "The app crashes on login."),
    label = factor(c("billing", "technical")),
    priority = c(2L, 1L),
    urgent = c(TRUE, FALSE),
    score = c(0.5, 1.25)
  )
}

# Output items echo each item, including the reserved row key. The live service
# reports processing status ("completed") on each item, not pass/fail.
fake_items <- function(data, order = seq_len(nrow(data)), passed = TRUE,
                       echo = TRUE, text = "billing", legacy_keys = FALSE) {
  lapply(order, function(i) {
    item <- lapply(data, function(column) {
      value <- column[[i]]
      if (is.factor(value)) as.character(value) else value
    })
    item$foundryr_row_id <- if (legacy_keys) as.character(i) else paste0("row-", i)
    list(
      id = paste0("oi_", i),
      run_id = "run_1",
      eval_id = "eval_1",
      datasource_item_id = i - 1L,
      status = "completed",
      datasource_item = if (echo) item else NULL,
      sample = list(output = list(list(role = "assistant", content = text))),
      results = list(list(
        name = "label-match", type = "string_check", passed = passed, score = as.numeric(passed)
      ))
    )
  })
}

string_grader <- function() {
  foundry_grader_string_check(
    name = "label-match",
    input = "{{sample.output_text}}",
    reference = "{{item.label}}",
    operation = "ilike"
  )
}

# ---------------------------------------------------------------------------
# Data-source constructors
# ---------------------------------------------------------------------------

test_that("foundry_eval_data_config builds an azure_ai_source config", {
  expect_equal(
    foundry_eval_data_config("azure_ai_source", scenario = "responses"),
    list(type = "azure_ai_source", scenario = "responses")
  )
  expect_error(foundry_eval_data_config("azure_ai_source"), "scenario")
})

test_that("foundry_eval_run_data builds a stored-response source", {
  source <- foundry_eval_run_data(response_ids = c("resp_1", "resp_2"))
  expect_equal(source$type, "azure_ai_responses")
  params <- source$item_generation_params
  expect_equal(params$type, "response_retrieval")
  expect_equal(params$data_mapping, list(response_id = "{{item.resp_id}}"))
  expect_equal(params$source$type, "file_content")
  expect_equal(params$source$content[[2]], list(item = list(resp_id = "resp_2")))

  expect_error(
    foundry_eval_run_data(response_ids = "resp_1", file_id = "file-1"),
    "cannot be combined"
  )
  expect_error(foundry_eval_run_data(response_ids = c("resp_1", NA)), "missing")
  expect_error(foundry_eval_run_data(response_ids = character()), "non-empty")
})

test_that("foundry_eval_run_data builds a model target source", {
  source <- foundry_eval_run_data(
    content = list(list(item = list(query = "What is R?"))),
    target = "gpt-5-mini",
    input_messages = "{{item.query}}"
  )
  expect_equal(source$type, "azure_ai_target_completions")
  expect_equal(source$source$type, "file_content")
  expect_equal(source$target, list(type = "azure_ai_model", model = "gpt-5-mini"))
  expect_equal(source$input_messages$type, "template")
  message <- source$input_messages$template[[1]]
  expect_equal(message$role, "user")
  expect_equal(message$content, list(type = "input_text", text = "{{item.query}}"))
})

test_that("agent targets resolve names and versions", {
  pinned <- foundry_eval_run_data(
    file_id = "file-1",
    target = foundry_agent_reference("helpdesk", version = "3"),
    input_messages = "{{item.query}}"
  )
  expect_equal(pinned$target, list(type = "azure_ai_agent", name = "helpdesk", version = "3"))

  expect_message(
    latest <- foundry_eval_run_data(
      file_id = "file-1",
      target = foundry_agent_reference("helpdesk"),
      input_messages = "{{item.query}}"
    ),
    class = "foundryR_unpinned_agent"
  )
  expect_null(latest$target$version)

  agent <- tibble::tibble(
    agent_name = "helpdesk",
    raw_agent = list(list(versions = list(latest = list(version = "7"))))
  )
  from_tibble <- foundry_eval_run_data(
    file_id = "file-1",
    target = agent,
    input_messages = "{{item.query}}"
  )
  expect_equal(from_tibble$target$version, "7")
})

test_that("foundry_eval_run_data validates target arguments", {
  expect_error(
    foundry_eval_run_data(file_id = "file-1", target = "gpt-5-mini"),
    "input_messages"
  )
  expect_error(
    foundry_eval_run_data(file_id = "file-1", input_messages = "{{item.q}}"),
    "requires"
  )
  expect_error(
    foundry_eval_run_data(file_id = "file-1", target = 42, input_messages = "x"),
    "model deployment name"
  )
  raw <- list(type = "azure_ai_model", model = "m", sampling_params = list(top_p = 1))
  expect_equal(
    foundry_eval_run_data(file_id = "file-1", target = raw, input_messages = "x")$target,
    raw
  )
})

# ---------------------------------------------------------------------------
# Run and output-item enrichment
# ---------------------------------------------------------------------------

test_that("run tibbles expose criteria pass rates, latency, and cost", {
  setup_mock_env()
  mock_request(fake_run())
  run <- foundry_eval_run_get("eval_1", "run_1")

  criteria <- run$per_testing_criteria_results[[1]]
  expect_equal(criteria$testing_criteria, "label-match")
  expect_equal(criteria$pass_rate, 0.5)
  expect_equal(run$target_latency_p50_ms, 812.5)
  expect_equal(run$target_latency_p95_ms, 2400)
  expect_equal(run$target_latency_samples, 2L)
  expect_equal(run$target_cost, 0.0123)
  expect_equal(run$target_cost_currency, "USD")
  expect_equal(run$target_cost_completeness, "complete")
  expect_identical(names(run)[ncol(run)], "raw_run")
})

test_that("run tibbles use missing values when metrics are absent", {
  setup_mock_env()
  mock_request(list(id = "run_1", eval_id = "eval_1", status = "queued"))
  run <- foundry_eval_run_get("eval_1", "run_1")
  expect_true(is.na(run$target_latency_p50_ms))
  expect_true(is.na(run$target_cost))
  expect_equal(nrow(run$per_testing_criteria_results[[1]]), 0L)

  mock_request(list(object = "list", data = list()))
  empty <- foundry_eval_runs("eval_1")
  expect_equal(nrow(empty), 0L)
  expect_contains(names(empty), c("per_testing_criteria_results", "target_cost"))
})

test_that("output items expose the echoed item and generated text", {
  setup_mock_env()
  item <- list(
    id = "oi_1", run_id = "run_1", eval_id = "eval_1", datasource_item_id = 0L,
    status = "pass",
    datasource_item = list(query = "Hi", foundryr_row_id = "1"),
    sample = list(output = list(
      list(role = "assistant", content = list(
        list(type = "output_text", text = "Hello"),
        list(type = "output_text", text = "there")
      ))
    )),
    results = list(list(name = "coherence", passed = TRUE))
  )
  mock_request(list(object = "list", data = list(item)))
  out <- foundry_eval_run_output_items("eval_1", "run_1")

  expect_equal(out$datasource_item[[1]]$query, "Hi")
  expect_equal(out$sample_output_text, "Hello\nthere")
  expect_type(out$sample_output_items, "list")
  expect_identical(names(out)[ncol(out)], "raw_item")

  expect_equal(foundry_eval_sample_text(list(output_text = "flat")), "flat")
  expect_true(is.na(foundry_eval_sample_text(NULL)))
  expect_true(is.na(foundry_eval_sample_text(list(output = list(
    list(role = "user", content = "question")
  )))))
})

test_that("output-item pagination stops on missing or repeated cursors", {
  setup_mock_env()
  mock_request(list(object = "list", has_more = TRUE, data = list()))
  expect_error(
    foundry_eval_run_output_items("eval_1", "run_1"),
    "no pagination cursor"
  )

  mock_request(list(
    object = "list", has_more = TRUE, last_id = "oi_1",
    data = list(list(id = "oi_1", results = list()))
  ))
  expect_error(
    foundry_eval_run_output_items("eval_1", "run_1", after = "oi_1"),
    "same pagination cursor"
  )
})

# ---------------------------------------------------------------------------
# Routing
# ---------------------------------------------------------------------------

test_that("eval calls use the resource endpoint unless routed to the project", {
  setup_project_env()
  log <- local_fake_evals(list("^GET .*/evals/eval_1$" = fake_eval()))

  foundry_eval_get("eval_1")
  expect_equal(
    log$requests[[1]]$url,
    "https://test-resource.openai.azure.com/openai/v1/evals/eval_1"
  )

  foundry_eval_get("eval_1", project_endpoint = project_url)
  expect_equal(log$requests[[2]]$url, paste0(project_url, "/openai/v1/evals/eval_1"))
  expect_equal(request_header(log$requests[[2]], "Authorization"), "Bearer test-project-token")

  old <- suppressMessages(foundry_set_route("project"))
  withr::defer(suppressMessages(foundry_set_route(old)))
  foundry_eval_get("eval_1")
  expect_equal(log$requests[[3]]$url, paste0(project_url, "/openai/v1/evals/eval_1"))

  expect_error(
    foundry_eval_get("eval_1", endpoint = "https://a", project_endpoint = project_url),
    "only one"
  )
})

test_that("built-in graders move eval creation to the project endpoint with a message", {
  setup_project_env()
  log <- local_fake_evals(list("^POST .*/openai/v1/evals$" = fake_eval()))
  grader <- foundry_grader_azure_ai(
    "coherence", "builtin.coherence",
    data_mapping = list(response = "{{item.ticket}}")
  )

  expect_message(
    foundry_eval_create(
      data_source_config = foundry_eval_data_config(
        "custom",
        item_schema = list(type = "object", properties = list(ticket = list(type = "string")))
      ),
      testing_criteria = grader
    ),
    class = "foundryR_eval_project_route"
  )
  expect_equal(log$requests[[1]]$url, paste0(project_url, "/openai/v1/evals"))

  expect_error(
    foundry_eval_create(
      data_source_config = foundry_eval_data_config(
        "custom",
        item_schema = list(type = "object", properties = list(ticket = list(type = "string")))
      ),
      testing_criteria = grader,
      endpoint = "https://test-resource.openai.azure.com"
    ),
    "available only on a Foundry project endpoint"
  )
})

# ---------------------------------------------------------------------------
# foundry_eval_run_wait()
# ---------------------------------------------------------------------------

test_that("foundry_eval_run_wait polls until the run is terminal", {
  setup_project_env()
  statuses <- c("queued", "in_progress", "completed")
  calls <- 0L
  local_fake_evals(list("^GET .*/runs/run_1$" = function(req) {
    calls <<- calls + 1L
    fake_run(statuses[[calls]])
  }))

  run <- foundry_eval_run_wait("eval_1", "run_1", interval = 0)
  expect_equal(calls, 3L)
  expect_equal(run$status, "completed")
})

test_that("foundry_eval_run_wait returns failed runs and times out", {
  setup_project_env()
  local_fake_evals(list("^GET .*/runs/run_1$" = fake_run("failed")))
  expect_equal(foundry_eval_run_wait("eval_1", "run_1", interval = 0)$status, "failed")

  local_fake_evals(list("^GET .*/runs/run_1$" = fake_run("in_progress")))
  expect_error(
    foundry_eval_run_wait("eval_1", "run_1", interval = 0, timeout = 0),
    "Timed out"
  )
  expect_error(foundry_eval_run_wait("eval_1", "run_1", interval = -1), "interval")
})

# ---------------------------------------------------------------------------
# foundry_evaluate()
# ---------------------------------------------------------------------------

test_that("foundry_evaluate grades existing columns and joins results", {
  setup_project_env()
  data <- tickets()
  log <- local_fake_evals(list(
    "^POST .*/openai/v1/evals$" = fake_eval(include_sample = FALSE),
    "^POST .*/evals/eval_1/runs$" = fake_run("queued"),
    "^GET .*/runs/run_1/output_items$" = list(
      object = "list", has_more = FALSE, data = fake_items(data)
    ),
    "^GET .*/runs/run_1$" = fake_run("completed")
  ))

  expect_message(
    out <- foundry_evaluate(
      data,
      graders = foundry_grader_string_check(
        "label-match", "{{item.ticket}}", "{{item.label}}", "like"
      ),
      interval = 0
    ),
    class = "foundryR_eval_started"
  )

  created <- requests_matching(log, "^POST .*/openai/v1/evals$")[[1]]$body$data
  schema <- created$data_source_config$item_schema
  expect_false(created$data_source_config$include_sample_schema)
  expect_equal(schema$properties$ticket, list(type = "string"))
  expect_equal(schema$properties$label, list(type = "string"))
  expect_equal(schema$properties$priority, list(type = "integer"))
  expect_equal(schema$properties$urgent, list(type = "boolean"))
  expect_equal(schema$properties$score, list(type = "number"))
  expect_equal(schema$properties$foundryr_row_id, list(type = "string"))
  expect_contains(unlist(schema$required), "foundryr_row_id")

  run_body <- requests_matching(log, "^POST .*/runs$")[[1]]$body$data
  expect_equal(run_body$data_source$type, "jsonl")
  first_item <- run_body$data_source$source$content[[1]]$item
  expect_equal(first_item$label, "billing")
  expect_equal(first_item$foundryr_row_id, "row-1")

  expect_equal(nrow(out), 2L)
  expect_s3_class(out$label, "factor")
  expect_equal(out$ticket, data$ticket)
  expect_equal(out$.grader, c("label-match", "label-match"))
  expect_true(all(out$.passed))
  expect_equal(unique(out$.eval_id), "eval_1")
  expect_equal(attr(out, "run")$target_cost, 0.0123)
})

test_that("foundry_evaluate sends model targets and returns generated text", {
  setup_project_env()
  data <- tickets()[, c("ticket", "label")]
  log <- local_fake_evals(list(
    "^POST .*/openai/v1/evals$" = fake_eval(),
    "^POST .*/evals/eval_1/runs$" = fake_run("queued"),
    "^GET .*/runs/run_1/output_items$" = list(
      object = "list", has_more = FALSE, data = fake_items(data, text = "billing")
    ),
    "^GET .*/runs/run_1$" = fake_run("completed")
  ))

  out <- suppressMessages(foundry_evaluate(
    data,
    graders = string_grader(),
    target = "gpt-5-mini",
    input = "ticket",
    instructions = "Reply with one label.",
    sampling_params = list(max_completion_tokens = 256),
    interval = 0
  ))

  created <- requests_matching(log, "^POST .*/openai/v1/evals$")[[1]]$body$data
  expect_true(created$data_source_config$include_sample_schema)

  source <- requests_matching(log, "^POST .*/runs$")[[1]]$body$data$data_source
  expect_equal(source$type, "azure_ai_target_completions")
  expect_equal(source$target, list(
    type = "azure_ai_model",
    model = "gpt-5-mini",
    sampling_params = list(max_completion_tokens = 256)
  ))
  roles <- vapply(source$input_messages$template, function(m) m$role, character(1))
  expect_equal(roles, c("developer", "user"))
  expect_equal(source$input_messages$template[[2]]$content$text, "{{item.ticket}}")
  run_name <- requests_matching(log, "^POST .*/runs$")[[1]]$body$data$name
  expect_true(is.character(run_name) && nzchar(run_name))

  expect_equal(out$.output_text, c("billing", "billing"))
})

test_that("foundry_evaluate sends pinned agent targets", {
  setup_project_env()
  data <- tickets()[, c("ticket", "label")]
  log <- local_fake_evals(list(
    "^POST .*/openai/v1/evals$" = fake_eval(),
    "^POST .*/evals/eval_1/runs$" = fake_run("queued")
  ))

  run <- suppressMessages(foundry_evaluate(
    data,
    graders = string_grader(),
    target = foundry_agent_reference("helpdesk", version = "2"),
    input = "Customer message: {{item.ticket}}",
    wait = FALSE
  ))

  source <- requests_matching(log, "^POST .*/runs$")[[1]]$body$data$data_source
  expect_equal(source$target, list(type = "azure_ai_agent", name = "helpdesk", version = "2"))
  expect_equal(
    source$input_messages$template[[1]]$content$text,
    "Customer message: {{item.ticket}}"
  )
  expect_equal(run$run_id, "run_1")
  expect_length(requests_matching(log, "^GET"), 0L)
  expect_error(
    foundry_evaluate(
      data,
      graders = string_grader(),
      target = foundry_agent_reference("helpdesk", version = "2"),
      input = "ticket",
      sampling_params = list(top_p = 1)
    ),
    "model deployment targets"
  )
})

test_that("foundry_evaluate validates inputs before any request", {
  setup_project_env()
  log <- local_fake_evals(list())
  data <- tickets()
  grader <- foundry_grader_string_check("m", "{{item.ticket}}", "{{item.label}}", "eq")

  expect_error(foundry_evaluate(data), "graders")
  expect_error(foundry_evaluate(data[0, ], graders = grader), "at least one row")
  expect_error(
    foundry_evaluate(transform(data, foundryr_row_id = "x"), graders = grader),
    "reserved"
  )
  expect_error(
    foundry_evaluate(transform(data, .score = 1), graders = grader),
    "reserved"
  )
  with_na <- data
  with_na$ticket[[2]] <- NA
  expect_error(foundry_evaluate(with_na, graders = grader), "Missing values")
  with_date <- data
  with_date$when <- as.Date("2026-01-01") + 0:1
  expect_error(foundry_evaluate(with_date, graders = grader), "JSON form")
  with_list <- data
  with_list$messages <- list(list(role = "user"), list("a", "b"))
  expect_error(foundry_evaluate(with_list, graders = grader), "item_schema")
  expect_error(
    foundry_evaluate(
      data,
      graders = foundry_grader_string_check("m", "{{item.answer}}", "{{item.label}}", "eq")
    ),
    "answer"
  )
  expect_error(foundry_evaluate(data, graders = string_grader()), "no .*target")
  expect_error(foundry_evaluate(data, graders = grader, input = "ticket"), "requires")
  expect_error(
    foundry_evaluate(data, graders = grader, target = "gpt-5-mini"),
    "input"
  )
  expect_error(
    foundry_evaluate(data, graders = grader, target = "gpt-5-mini", input = "missing"),
    "neither"
  )
  expect_error(
    foundry_evaluate(data, graders = grader, eval_id = "eval_1"),
    "existing evaluation"
  )
  expect_length(log$requests, 0L)
})

test_that("foundry_evaluate needs a project endpoint for built-in graders", {
  setup_mock_env()
  log <- local_fake_evals(list())
  expect_error(
    foundry_evaluate(
      tickets(),
      graders = foundry_grader_azure_ai(
        "coherence", "builtin.coherence",
        data_mapping = list(response = "{{item.ticket}}")
      )
    ),
    "available only on a Foundry project endpoint"
  )
  expect_length(log$requests, 0L)
})

test_that("foundry_evaluate accepts list columns with an explicit schema", {
  setup_project_env()
  data <- tibble::tibble(
    query = c("Book a flight", "Cancel it"),
    tool_definitions = list(list(list(name = "book")), list(list(name = "cancel")))
  )
  log <- local_fake_evals(list(
    "^POST .*/openai/v1/evals$" = fake_eval(include_sample = FALSE),
    "^POST .*/evals/eval_1/runs$" = fake_run("queued")
  ))

  suppressMessages(foundry_evaluate(
    data,
    graders = foundry_grader_string_check("m", "{{item.query}}", "Book", "like"),
    item_schema = list(
      type = "object",
      properties = list(
        query = list(type = "string"),
        tool_definitions = list(type = "array")
      ),
      required = list("query")
    ),
    wait = FALSE
  ))

  schema <- requests_matching(log, "^POST .*/openai/v1/evals$")[[1]]$body$data$data_source_config$item_schema
  expect_equal(schema$properties$tool_definitions, list(type = "array"))
  expect_equal(unlist(schema$required), c("query", "foundryr_row_id"))
  items <- requests_matching(log, "^POST .*/runs$")[[1]]$body$data$data_source$source$content
  expect_equal(items[[2]]$item$tool_definitions, list(list(name = "cancel")))

  expect_error(
    foundry_evaluate(
      data,
      graders = foundry_grader_string_check("m", "{{item.query}}", "Book", "like"),
      item_schema = list(properties = list(query = list(type = "string")))
    ),
    "exactly the columns"
  )
})

test_that("single-element array cells stay JSON arrays", {
  setup_project_env()
  data <- tibble::tibble(
    query = c("Book a flight and a hotel", "Book a flight"),
    expected_actions = list(c("book_flight", "book_hotel"), "book_flight")
  )
  log <- local_fake_evals(list(
    "^POST .*/openai/v1/evals$" = fake_eval(include_sample = FALSE),
    "^POST .*/evals/eval_1/runs$" = fake_run("queued")
  ))

  suppressMessages(foundry_evaluate(
    data,
    graders = foundry_grader_string_check("m", "{{item.query}}", "Book", "like"),
    item_schema = list(
      type = "object",
      properties = list(
        query = list(type = "string", enum = "Book a flight"),
        expected_actions = list(type = "array", items = list(type = "string"))
      )
    ),
    wait = FALSE
  ))

  as_json <- function(x) {
    as.character(jsonlite::toJSON(x, auto_unbox = TRUE, digits = 22, null = "null"))
  }
  items <- requests_matching(log, "^POST .*/runs$")[[1]]$body$data$data_source$source$content
  expect_match(as_json(items[[2]]$item), "\"expected_actions\":[\"book_flight\"]", fixed = TRUE)
  expect_match(as_json(items[[2]]$item), "\"query\":\"Book a flight\"", fixed = TRUE)

  schema <- requests_matching(log, "^POST .*/openai/v1/evals$")[[1]]$body$data$data_source_config$item_schema
  expect_match(as_json(schema), "\"enum\":[\"Book a flight\"]", fixed = TRUE)
})

test_that("foundry_evaluate adds a run to an existing evaluation", {
  setup_project_env()
  data <- tickets()[, c("ticket", "label")]
  properties <- list(
    ticket = list(type = "string"),
    label = list(type = "string"),
    foundryr_row_id = list(type = "string")
  )
  log <- local_fake_evals(list(
    "^GET .*/openai/v1/evals/eval_1$" = fake_eval(properties = properties),
    "^POST .*/evals/eval_1/runs$" = fake_run("queued")
  ))

  run <- suppressMessages(foundry_evaluate(
    data,
    target = "gpt-5-nano",
    input = "ticket",
    eval_id = "eval_1",
    name = "prompt-b",
    wait = FALSE
  ))

  expect_equal(run$run_id, "run_1")
  expect_length(requests_matching(log, "^POST .*/openai/v1/evals$"), 0L)
  run_body <- requests_matching(log, "^POST .*/runs$")[[1]]$body$data
  expect_equal(run_body$name, "prompt-b")
  expect_equal(run_body$data_source$target$model, "gpt-5-nano")
})

test_that("foundry_evaluate refuses evaluations that cannot carry the rows", {
  setup_project_env()
  log <- local_fake_evals(list(
    "^GET .*/openai/v1/evals/eval_1$" = fake_eval(properties = list(
      ticket = list(type = "string"),
      label = list(type = "string")
    ))
  ))
  expect_error(
    foundry_evaluate(
      tickets()[, c("ticket", "label")],
      target = "gpt-5-nano",
      input = "ticket",
      eval_id = "eval_1"
    ),
    "cannot carry"
  )
  expect_length(requests_matching(log, "^POST"), 0L)

  local_fake_evals(list(
    "^GET .*/openai/v1/evals/eval_1$" = fake_eval(
      include_sample = FALSE,
      properties = list(
        ticket = list(type = "string"),
        label = list(type = "string"),
        foundryr_row_id = list(type = "string")
      ),
      criteria = list(list(type = "string_check", name = "m", input = "{{item.ticket}}"))
    )
  ))
  expect_error(
    foundry_evaluate(
      tickets()[, c("ticket", "label")],
      target = "gpt-5-nano",
      input = "ticket",
      eval_id = "eval_1"
    ),
    "without a sample schema"
  )
})

test_that("foundry_evaluate reports failed runs with their identifiers", {
  setup_project_env()
  local_fake_evals(list(
    "^POST .*/openai/v1/evals$" = fake_eval(),
    "^POST .*/evals/eval_1/runs$" = fake_run("queued"),
    "^GET .*/runs/run_1$" = fake_run("failed", error = list(message = "Deployment not found"))
  ))

  expect_error(
    suppressMessages(foundry_evaluate(
      tickets()[, c("ticket", "label")],
      graders = string_grader(),
      target = "gpt-5-mini",
      input = "ticket",
      interval = 0
    )),
    "run_1.*eval_1.*failed|Deployment not found"
  )
})

# ---------------------------------------------------------------------------
# foundry_eval_run_results()
# ---------------------------------------------------------------------------

results_routes <- function(items, status = "completed") {
  list(
    "^GET .*/runs/run_1/output_items$" = list(object = "list", has_more = FALSE, data = items),
    "^GET .*/runs/run_1$" = fake_run(status)
  )
}

test_that("results are joined by the echoed row key, not by position", {
  setup_project_env()
  data <- tickets()
  local_fake_evals(results_routes(fake_items(data, order = c(2L, 1L))))

  out <- foundry_eval_run_results("eval_1", "run_1", data = data)
  expect_equal(out$ticket, data$ticket)
  expect_equal(out$.output_item_id, c("oi_1", "oi_2"))
})

test_that("results still join runs that echo legacy numeric row keys", {
  setup_project_env()
  data <- tickets()
  local_fake_evals(results_routes(fake_items(data, order = c(2L, 1L), legacy_keys = TRUE)))

  out <- foundry_eval_run_results("eval_1", "run_1", data = data)
  expect_equal(out$ticket, data$ticket)
})

test_that("target runs warn about numeric-looking text columns", {
  setup_project_env()
  data <- data.frame(zip = c("02139", "10001"), label = c("north", "east"))
  local_fake_evals(list(
    "^POST .*/openai/v1/evals$" = fake_eval(),
    "^POST .*/evals/eval_1/runs$" = fake_run("queued")
  ))

  expect_warning(
    suppressMessages(foundry_evaluate(
      data,
      graders = string_grader(),
      target = "gpt-5-mini",
      input = "Which region is ZIP {{item.zip}} in?",
      wait = FALSE
    )),
    "numeric-looking"
  )
})

test_that("agent output text decodes JSON-encoded content parts", {
  encoded <- '[{"annotations": [], "text": "Fridays at 5 pm."}]'
  expect_equal(
    foundry_eval_sample_text(list(output = list(list(role = "assistant", content = encoded)))),
    "Fridays at 5 pm."
  )
  expect_equal(
    foundry_eval_sample_text(list(output_text = '[{"type": "output_text", "text": "Hi"}]')),
    "Hi"
  )
  expect_equal(foundry_eval_sample_text(list(output_text = "[not json")), "[not json")
})

test_that("list columns infer object and array item schemas", {
  data <- tibble::tibble(
    q = c("a", "b"),
    meta = list(list(k = 1), list(k = 2)),
    tags = list("x", c("y", "z"))
  )
  schema <- foundry_eval_item_schema(data)
  expect_equal(schema$properties$meta$type, "object")
  expect_equal(schema$properties$tags$type, "array")

  items <- foundry_eval_items(data, schema)
  json <- as.character(jsonlite::toJSON(items[[1]], auto_unbox = TRUE))
  expect_match(json, "\"tags\":\\[\"x\"\\]")
})

test_that("rows without output items are kept and flagged", {
  setup_project_env()
  data <- tickets()
  local_fake_evals(results_routes(fake_items(data, order = 2L)))

  expect_warning(
    out <- foundry_eval_run_results("eval_1", "run_1", data = data),
    "had no output item"
  )
  expect_equal(nrow(out), 2L)
  expect_equal(out$ticket, data$ticket)
  expect_true(is.na(out$.passed[[1]]))
  expect_true(out$.passed[[2]])
})

test_that("results refuse reordered data and missing row keys", {
  setup_project_env()
  data <- tickets()
  local_fake_evals(results_routes(fake_items(data)))
  expect_error(
    foundry_eval_run_results("eval_1", "run_1", data = data[2:1, ]),
    "do not match"
  )

  local_fake_evals(results_routes(fake_items(data, echo = FALSE)))
  expect_error(
    foundry_eval_run_results("eval_1", "run_1", data = data),
    "foundry_eval_run_output_items"
  )

  local_fake_evals(results_routes(fake_items(data)))
  expect_error(
    foundry_eval_run_results("eval_1", "run_1", data = data[1, ]),
    "not in"
  )
})

test_that("results require a completed run", {
  setup_project_env()
  local_fake_evals(results_routes(list(), status = "in_progress"))
  expect_error(
    foundry_eval_run_results("eval_1", "run_1", data = tickets()),
    "foundry_eval_run_wait"
  )
})


test_that("foundry_eval_existing_schema reads project-endpoint item schemas", {
  item <- list(
    type = "object",
    properties = list(
      comment = list(type = "string"),
      foundryr_row_id = list(type = "string")
    )
  )
  sample <- list(type = "object", properties = list(output_text = list(type = "string")))
  project_eval <- tibble::tibble(
    eval_id = "eval_1",
    data_source_config = list(list(
      type = "custom",
      item_schema = list(),
      include_sample_schema = TRUE,
      schema = list(item = item, sample = sample)
    ))
  )
  data <- tibble::tibble(comment = c("a", "b"))

  expect_no_warning(
    schema <- foundry_eval_existing_schema(project_eval, data, needs_sample = TRUE)
  )
  expect_named(schema$properties, c("comment", "foundryr_row_id"))

  no_flag <- project_eval
  no_flag$data_source_config[[1]]$include_sample_schema <- NULL
  expect_no_error(foundry_eval_existing_schema(no_flag, data, needs_sample = TRUE))

  no_sample <- no_flag
  no_sample$data_source_config[[1]]$schema$sample <- NULL
  expect_error(
    foundry_eval_existing_schema(no_sample, data, needs_sample = TRUE),
    "without a sample schema"
  )
})