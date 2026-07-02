# Tests for the evaluations (evals) API: grader constructors, config helpers,
# and the eval/run lifecycle. All HTTP is mocked; no live calls are made.

# ---------------------------------------------------------------------------
# Grader and helper constructors
# ---------------------------------------------------------------------------

test_that("foundry_eval_item builds a message item and validates role", {
  item <- foundry_eval_item("Grade: {{sample.output_text}}", role = "system")
  expect_equal(item, list(role = "system", content = "Grade: {{sample.output_text}}"))

  expect_equal(foundry_eval_item("x")$role, "user")
  expect_error(foundry_eval_item("x", role = "robot"), "should be one of")
  expect_error(foundry_eval_item(""), "non-empty")
})

test_that("foundry_grader_string_check builds a valid grader", {
  g <- foundry_grader_string_check(
    name = "exact",
    input = "{{sample.output_text}}",
    reference = "{{item.answer}}",
    operation = "eq"
  )
  expect_equal(g$type, "string_check")
  expect_equal(g$operation, "eq")
  expect_error(
    foundry_grader_string_check("m", "a", "b", operation = "startswith"),
    "should be one of"
  )
})

test_that("foundry_grader_text_similarity validates threshold and metric", {
  g <- foundry_grader_text_similarity(
    input = "{{sample.output_text}}",
    reference = "{{item.answer}}",
    pass_threshold = 0.8,
    evaluation_metric = "rouge_l",
    name = "sim"
  )
  expect_equal(g$type, "text_similarity")
  expect_equal(g$evaluation_metric, "rouge_l")
  expect_equal(g$name, "sim")

  # name is optional and omitted when NULL
  g2 <- foundry_grader_text_similarity("a", "b", 0.5, "bleu")
  expect_null(g2$name)

  expect_error(
    foundry_grader_text_similarity("a", "b", "high", "bleu"),
    "single number"
  )
  expect_error(
    foundry_grader_text_similarity("a", "b", 0.5, "cosine"),
    "should be one of"
  )
})

test_that("foundry_grader_label_model forces array encoding and checks subset", {
  g <- foundry_grader_label_model(
    name = "rel",
    model = "gpt-4.1-mini",
    input = list(foundry_eval_item("Relevant? {{sample.output_text}}")),
    labels = c("relevant", "irrelevant"),
    passing_labels = "relevant"
  )
  expect_equal(g$type, "label_model")
  # length-1 passing_labels must serialize as a JSON array, not a scalar
  expect_type(g$passing_labels, "list")
  expect_equal(g$passing_labels, list("relevant"))
  json <- as.character(jsonlite::toJSON(g, auto_unbox = TRUE))
  expect_match(json, '"passing_labels":\\["relevant"\\]')
  expect_match(json, '"labels":\\["relevant","irrelevant"\\]')
  # input normalized to a list of items
  expect_equal(g$input, list(list(role = "user", content = "Relevant? {{sample.output_text}}")))

  expect_error(
    foundry_grader_label_model("m", "gpt", list(foundry_eval_item("x")),
      labels = "a", passing_labels = "b"
    ),
    "subset"
  )
})

test_that("foundry_grader_label_model accepts a single unwrapped input item", {
  g <- foundry_grader_label_model(
    name = "rel",
    model = "gpt-4.1-mini",
    input = foundry_eval_item("Relevant?"),
    labels = c("yes", "no"),
    passing_labels = "yes"
  )
  expect_equal(g$input, list(list(role = "user", content = "Relevant?")))
})

test_that("foundry_grader_score_model handles optional threshold and range", {
  g <- foundry_grader_score_model(
    name = "help",
    model = "gpt-4.1",
    input = list(foundry_eval_item("Rate 0-1")),
    pass_threshold = 0.7,
    range = c(0, 1)
  )
  expect_equal(g$type, "score_model")
  expect_equal(g$pass_threshold, 0.7)
  expect_equal(g$range, list(0, 1))

  g2 <- foundry_grader_score_model("s", "gpt", foundry_eval_item("x"))
  expect_null(g2$pass_threshold)
  expect_null(g2$range)

  expect_error(
    foundry_grader_score_model("s", "gpt", foundry_eval_item("x"), range = c(0, 1, 2)),
    "length 2"
  )
})

test_that("foundry_grader_azure_ai builds a builtin evaluator grader", {
  g <- foundry_grader_azure_ai(
    name = "coherence",
    evaluator_name = "builtin.coherence",
    initialization_parameters = list(model = "gpt-4.1-mini"),
    data_mapping = list(query = "{{item.query}}", response = "{{sample.output_text}}")
  )
  expect_equal(g$type, "azure_ai_evaluator")
  expect_equal(g$evaluator_name, "builtin.coherence")
  expect_equal(g$initialization_parameters$model, "gpt-4.1-mini")
  expect_equal(g$data_mapping$query, "{{item.query}}")
  expect_null(g$evaluator_version)

  expect_error(
    foundry_grader_azure_ai("c", "builtin.coherence", data_mapping = list("unnamed")),
    "named list"
  )
})

test_that("foundry_eval_data_config builds custom and logs configs", {
  custom <- foundry_eval_data_config(
    type = "custom",
    item_schema = list(type = "object", properties = list(a = list(type = "string"))),
    include_sample_schema = TRUE
  )
  expect_equal(custom$type, "custom")
  expect_true(custom$include_sample_schema)

  logs <- foundry_eval_data_config(type = "logs", metadata = list(env = "prod"))
  expect_equal(logs$type, "logs")
  expect_equal(logs$metadata$env, "prod")

  expect_error(
    foundry_eval_data_config(type = "custom"),
    "item_schema"
  )
})

test_that("foundry_eval_run_data enforces exactly one source", {
  f <- foundry_eval_run_data(file_id = "file-abc")
  expect_equal(f$type, "jsonl")
  expect_equal(f$source, list(type = "file_id", id = "file-abc"))

  co <- foundry_eval_run_data(content = list(list(item = list(q = "2+2", a = "4"))))
  expect_equal(co$source$type, "file_content")
  expect_length(co$source$content, 1L)

  expect_error(foundry_eval_run_data(), "exactly one")
  expect_error(
    foundry_eval_run_data(file_id = "f", content = list(list(item = list()))),
    "exactly one"
  )
})

# ---------------------------------------------------------------------------
# Eval lifecycle
# ---------------------------------------------------------------------------

mock_eval_object <- function(id = "eval_1", name = "qa") {
  list(
    id = id,
    object = "eval",
    name = name,
    created_at = 1741369938,
    data_source_config = list(type = "custom"),
    testing_criteria = list(list(type = "string_check", name = "m")),
    metadata = list(team = "ds")
  )
}

test_that("foundry_eval_create posts graders to the evals endpoint", {
  setup_mock_env()
  captured <- NULL
  resp <- mock_httr2_response(mock_eval_object())
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  out <- foundry_eval_create(
    name = "qa",
    data_source_config = foundry_eval_data_config(
      type = "custom",
      item_schema = list(type = "object", properties = list(answer = list(type = "string")))
    ),
    testing_criteria = foundry_grader_string_check(
      "m", "{{sample.output_text}}", "{{item.answer}}", "eq"
    ),
    metadata = list(team = "ds")
  )

  expect_match(captured$url, "/openai/v1/evals$")
  expect_equal(captured$method, "POST")

  body <- captured$body$data
  expect_equal(body$name, "qa")
  expect_equal(body$data_source_config$type, "custom")
  expect_equal(body$metadata$team, "ds")
  # A single grader is wrapped into an unnamed array of one.
  expect_length(body$testing_criteria, 1L)
  expect_null(names(body$testing_criteria))
  expect_equal(body$testing_criteria[[1]]$type, "string_check")

  expect_s3_class(out, "tbl_df")
  expect_equal(out$eval_id, "eval_1")
  expect_equal(out$name, "qa")
  expect_type(out$testing_criteria, "list")
})

test_that("foundry_eval_create accepts a list of graders", {
  setup_mock_env()
  captured <- NULL
  resp <- mock_httr2_response(mock_eval_object())
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  foundry_eval_create(
    data_source_config = foundry_eval_data_config("logs"),
    testing_criteria = list(
      foundry_grader_string_check("a", "x", "y", "eq"),
      foundry_grader_azure_ai("b", "builtin.coherence")
    )
  )

  body <- captured$body$data
  expect_length(body$testing_criteria, 2L)
  expect_equal(body$testing_criteria[[2]]$type, "azure_ai_evaluator")
})

test_that("foundry_eval_create rejects a bad data_source_config", {
  setup_mock_env()
  expect_error(
    foundry_eval_create(
      data_source_config = list(no_type = TRUE),
      testing_criteria = foundry_grader_string_check("a", "x", "y", "eq")
    ),
    "foundry_eval_data_config"
  )
})

test_that("foundry_evals lists evaluations with query params", {
  setup_mock_env()
  captured <- NULL
  resp <- mock_httr2_response(list(
    object = "list",
    data = list(mock_eval_object("eval_1"), mock_eval_object("eval_2", "safety"))
  ))
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  out <- foundry_evals(limit = 5, order = "desc")
  expect_match(captured$url, "limit=5")
  expect_match(captured$url, "order=desc")
  expect_equal(nrow(out), 2L)
  expect_equal(out$eval_id, c("eval_1", "eval_2"))
})

test_that("foundry_evals returns a typed empty tibble when no data", {
  setup_mock_env()
  mock_request(list(object = "list", data = list()))
  out <- foundry_evals()
  expect_equal(nrow(out), 0L)
  expect_true(all(c("eval_id", "created_at", "raw_eval") %in% names(out)))
})

test_that("foundry_eval_get retrieves a single evaluation", {
  setup_mock_env()
  captured <- NULL
  resp <- mock_httr2_response(mock_eval_object())
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  out <- foundry_eval_get("eval_1")
  expect_match(captured$url, "/openai/v1/evals/eval_1$")
  expect_equal(captured$method, "GET")
  expect_equal(out$eval_id, "eval_1")
})

test_that("foundry_eval_delete parses the deletion result", {
  setup_mock_env()
  captured <- NULL
  resp <- mock_httr2_response(list(
    object = "eval.deleted", deleted = TRUE, eval_id = "eval_1"
  ))
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  out <- foundry_eval_delete("eval_1")
  expect_equal(captured$method, "DELETE")
  expect_true(out$deleted)
  expect_equal(out$eval_id, "eval_1")
  expect_equal(out$object, "eval.deleted")
})

# ---------------------------------------------------------------------------
# Run lifecycle
# ---------------------------------------------------------------------------

mock_run_object <- function(id = "evalrun_1", status = "completed") {
  list(
    id = id,
    object = "eval.run",
    eval_id = "eval_1",
    name = "nightly",
    status = status,
    created_at = 1741369938,
    report_url = "https://ai.azure.com/report/evalrun_1",
    result_counts = list(total = 10, passed = 8, failed = 2, errored = 0)
  )
}

test_that("foundry_eval_run_create posts a data source to the runs endpoint", {
  setup_mock_env()
  captured <- NULL
  resp <- mock_httr2_response(mock_run_object())
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  out <- foundry_eval_run_create(
    eval_id = "eval_1",
    data_source = foundry_eval_run_data(file_id = "file-xyz"),
    name = "nightly"
  )

  expect_match(captured$url, "/openai/v1/evals/eval_1/runs$")
  expect_equal(captured$method, "POST")
  body <- captured$body$data
  expect_equal(body$name, "nightly")
  expect_equal(body$data_source$type, "jsonl")
  expect_equal(body$data_source$source$id, "file-xyz")

  expect_equal(out$run_id, "evalrun_1")
  expect_equal(out$result_total, 10L)
  expect_equal(out$result_passed, 8L)
})

test_that("foundry_eval_run_create rejects a bad data source", {
  setup_mock_env()
  expect_error(
    foundry_eval_run_create("eval_1", data_source = list(nope = TRUE)),
    "foundry_eval_run_data"
  )
})

test_that("foundry_eval_runs lists runs with a status filter", {
  setup_mock_env()
  captured <- NULL
  resp <- mock_httr2_response(list(
    object = "list",
    data = list(mock_run_object("evalrun_1"), mock_run_object("evalrun_2", "failed"))
  ))
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  out <- foundry_eval_runs("eval_1", status = "completed", limit = 20)
  expect_match(captured$url, "/openai/v1/evals/eval_1/runs")
  expect_match(captured$url, "status=completed")
  expect_equal(nrow(out), 2L)
  expect_equal(out$status, c("completed", "failed"))
})

test_that("foundry_eval_run_get and cancel hit the right paths and methods", {
  setup_mock_env()
  captured <- NULL
  resp <- mock_httr2_response(mock_run_object())
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  foundry_eval_run_get("eval_1", "evalrun_1")
  expect_match(captured$url, "/openai/v1/evals/eval_1/runs/evalrun_1$")
  expect_equal(captured$method, "GET")

  foundry_eval_run_cancel("eval_1", "evalrun_1")
  expect_match(captured$url, "/openai/v1/evals/eval_1/runs/evalrun_1$")
  expect_equal(captured$method, "POST")
})

test_that("foundry_eval_run_output_items unnests one row per grader result", {
  setup_mock_env()
  captured <- NULL
  item <- list(
    id = "oi_1",
    run_id = "evalrun_1",
    eval_id = "eval_1",
    datasource_item_id = 0L,
    status = "pass",
    results = list(
      list(
        name = "Coherence", type = "azure_ai_evaluator", metric = "coherence",
        score = 4.0, label = "pass", threshold = 3, passed = TRUE,
        reason = "clear and coherent"
      ),
      list(name = "exact", type = "string_check", passed = FALSE)
    )
  )
  resp <- mock_httr2_response(list(object = "list", data = list(item)))
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  out <- foundry_eval_run_output_items("eval_1", "evalrun_1", status = "pass")
  expect_match(captured$url, "/output_items")
  expect_match(captured$url, "status=pass")
  expect_equal(nrow(out), 2L)
  expect_equal(out$grader_name, c("Coherence", "exact"))
  expect_equal(out$score[1], 4)
  expect_true(out$passed[1])
  expect_false(out$passed[2])
  expect_true(is.na(out$score[2]))
  # both rows carry the shared output-item identity
  expect_equal(unique(out$output_item_id), "oi_1")
})

test_that("foundry_eval_run_output_items yields one NA row when results are empty", {
  setup_mock_env()
  item <- list(
    id = "oi_2", run_id = "evalrun_1", eval_id = "eval_1",
    datasource_item_id = 1L, status = "fail", results = list()
  )
  mock_request(list(object = "list", data = list(item)))
  out <- foundry_eval_run_output_items("eval_1", "evalrun_1")
  expect_equal(nrow(out), 1L)
  expect_equal(out$output_item_id, "oi_2")
  expect_true(is.na(out$grader_name))
})
