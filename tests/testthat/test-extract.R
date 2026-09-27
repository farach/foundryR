test_that("foundry_extract orders caller columns, extracted fields, then metadata", {
  setup_mock_env()
  mock_response <- mock_response_api_response(
    output_text = "{\"sentiment\":\"positive\",\"score\":0.9}"
  )
  testthat::local_mocked_bindings(
    req_perform_parallel = function(reqs, ...) list(mock_httr2_response(mock_response)),
    .package = "httr2"
  )

  schema <- list(
    type = "object",
    properties = list(
      sentiment = list(type = "string"),
      score = list(type = "number")
    ),
    required = c("sentiment", "score"),
    additionalProperties = FALSE
  )
  data <- tibble::tibble(id = 1L, text = "Great product.")

  result <- foundry_extract(data, text_col = "text", schema = schema, model = "gpt-4.1")

  expect_named(result, c(
    "id", "text", "sentiment", "score",
    ".input_idx", ".input_text", ".response_id", ".status", ".output_text",
    ".error", ".error_msg", "raw_response"
  ))
})

test_that("foundry_extract aborts before requests when extracted fields collide", {
  setup_mock_env()
  called <- FALSE
  testthat::local_mocked_bindings(
    req_perform_parallel = function(reqs, ...) {
      called <<- TRUE
      list()
    },
    .package = "httr2"
  )

  schema <- list(
    type = "object",
    properties = list(theme = list(type = "string")),
    required = "theme",
    additionalProperties = FALSE
  )
  data <- tibble::tibble(text = "Story text", theme = "existing")

  expect_error(
    foundry_extract(data, text_col = "text", schema = schema, model = "gpt-4.1"),
    "collide.*theme.*Rename"
  )
  expect_false(called)
})

test_that("foundry_extract uses schema-driven scalar and list-column types", {
  setup_mock_env()
  responses <- list(
    mock_httr2_response(mock_response_api_response(
      output_text = "{\"label\":null,\"score\":null,\"count\":null,\"flag\":null,\"tags\":[\"one\"],\"details\":{\"a\":1}}"
    )),
    mock_httr2_response(mock_response_api_response(
      output_text = "{\"label\":null,\"score\":1.5,\"count\":2,\"flag\":true,\"tags\":[\"two\",\"three\"],\"details\":{\"b\":2}}"
    ))
  )
  testthat::local_mocked_bindings(
    req_perform_parallel = function(reqs, ...) responses,
    .package = "httr2"
  )

  schema <- list(
    type = "object",
    properties = list(
      label = list(type = "string", enum = c("a", "b")),
      score = list(type = "number"),
      count = list(type = "integer"),
      flag = list(type = "boolean"),
      tags = list(type = "array", items = list(type = "string")),
      details = list(type = "object")
    ),
    required = c("label", "score", "count", "flag", "tags", "details"),
    additionalProperties = FALSE
  )

  result <- foundry_extract(c("one", "two"), schema = schema, model = "gpt-4.1")

  expect_type(result$label, "character")
  expect_true(all(is.na(result$label)))
  expect_type(result$score, "double")
  expect_true(is.na(result$score[[1]]))
  expect_equal(result$score[[2]], 1.5)
  expect_type(result$count, "integer")
  expect_true(is.na(result$count[[1]]))
  expect_equal(result$count[[2]], 2L)
  expect_type(result$flag, "logical")
  expect_true(is.na(result$flag[[1]]))
  expect_true(result$flag[[2]])
  expect_true(is.list(result$tags))
  expect_identical(result$tags[[1]], "one")
  expect_identical(result$tags[[2]], c("two", "three"))
  expect_true(is.list(result$details))
})

test_that("foundry_extract keeps one-element arrays of objects as arrays", {
  setup_mock_env()
  responses <- list(
    mock_httr2_response(mock_response_api_response(
      output_text = "{\"people\":[{\"name\":\"Ada\"}]}"
    )),
    mock_httr2_response(mock_response_api_response(
      output_text = "{\"people\":[{\"name\":\"Ada\"},{\"name\":\"Grace\"}]}"
    ))
  )
  testthat::local_mocked_bindings(
    req_perform_parallel = function(reqs, ...) responses,
    .package = "httr2"
  )

  schema <- list(
    type = "object",
    properties = list(
      people = list(
        type = "array",
        items = list(type = "object", properties = list(name = list(type = "string")))
      )
    ),
    required = "people",
    additionalProperties = FALSE
  )

  result <- foundry_extract(c("one", "two"), schema = schema, model = "gpt-4.1")

  expect_length(result$people[[1]], 1L)
  expect_null(names(result$people[[1]]))
  expect_identical(result$people[[1]][[1]]$name, "Ada")
  expect_length(result$people[[2]], 2L)
})

test_that("foundry_extract keeps all-null schema fields typed", {
  setup_mock_env()
  responses <- list(
    mock_httr2_response(mock_response_api_response(
      output_text = "{\"label\":null,\"score\":null,\"count\":null,\"flag\":null}"
    )),
    mock_httr2_response(mock_response_api_response(
      output_text = "{\"label\":null,\"score\":null,\"count\":null,\"flag\":null}"
    ))
  )
  testthat::local_mocked_bindings(
    req_perform_parallel = function(reqs, ...) responses,
    .package = "httr2"
  )

  schema <- list(
    type = "object",
    properties = list(
      label = list(type = "string"),
      score = list(type = "number"),
      count = list(type = "integer"),
      flag = list(type = "boolean")
    ),
    required = c("label", "score", "count", "flag"),
    additionalProperties = FALSE
  )

  result <- foundry_extract(c("one", "two"), schema = schema, model = "gpt-4.1")

  expect_type(result$label, "character")
  expect_type(result$score, "double")
  expect_type(result$count, "integer")
  expect_type(result$flag, "logical")
  expect_true(all(is.na(result$label)))
  expect_true(all(is.na(result$score)))
  expect_true(all(is.na(result$count)))
  expect_true(all(is.na(result$flag)))
})

test_that("foundry_extract suppresses progress by default in tests", {
  setup_mock_env()
  mock_response <- mock_response_api_response(output_text = "{\"label\":\"yes\"}")
  testthat::local_mocked_bindings(
    req_perform_parallel = function(reqs, ...) list(mock_httr2_response(mock_response)),
    .package = "httr2"
  )

  schema <- list(
    type = "object",
    properties = list(label = list(type = "string")),
    required = "label",
    additionalProperties = FALSE
  )

  expect_silent(foundry_extract("one", schema = schema, model = "gpt-4.1"))
})

test_that("foundry_extract_batch_results joins row-N results and flattens schema fields", {
  setup_mock_env()
  batch <- list(
    id = "batch_123",
    status = "completed",
    endpoint = "/v1/responses",
    input_file_id = "file_in",
    output_file_id = "file_out",
    request_counts = list(total = 2, completed = 2, failed = 0)
  )
  response_1 <- mock_response_api_response(
    output_text = "{\"label\":\"yes\",\"tags\":[\"a\"]}",
    response_id = "resp_1"
  )
  response_2 <- mock_response_api_response(
    output_text = "{\"label\":\"no\",\"tags\":[\"b\",\"c\"]}",
    response_id = "resp_2"
  )
  line <- function(custom_id, response) {
    jsonlite::toJSON(
      list(
        custom_id = custom_id,
        request = list(
          body = list(text = list(format = list(type = "json_schema")))
        ),
        response = list(status_code = 200, body = response)
      ),
      auto_unbox = TRUE
    )
  }
  output <- paste(c(line("row-2", response_2), line("row-1", response_1)), collapse = "\n")

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      if (grepl("/content$", req$url)) {
        httr2::response(
          status_code = 200L,
          url = req$url,
          headers = list(`content-type` = "application/octet-stream"),
          body = charToRaw(output)
        )
      } else {
        mock_httr2_response(batch)
      }
    },
    .package = "httr2"
  )

  schema <- list(
    type = "object",
    properties = list(
      label = list(type = "string"),
      tags = list(type = "array", items = list(type = "string"))
    ),
    required = c("label", "tags"),
    additionalProperties = FALSE
  )
  data <- tibble::tibble(id = c(10L, 20L), text = c("first", "second"))

  result <- foundry_extract_batch_results("batch_123", data, schema)

  expect_equal(result$id, c(10L, 20L))
  expect_equal(result$label, c("yes", "no"))
  expect_identical(result$tags[[1]], "a")
  expect_identical(result$tags[[2]], c("b", "c"))
  expect_named(result, c(
    "id", "text", "label", "tags",
    ".input_idx", ".input_text", ".response_id", ".status", ".output_text",
    ".error", ".error_msg", "raw_response"
  ))
})

test_that("foundry_extract_batch_results warns about input rows without results", {
  setup_mock_env()
  batch <- list(
    id = "batch_123",
    status = "expired",
    endpoint = "/v1/responses",
    output_file_id = "file_out"
  )
  body <- mock_response_api_response(output_text = "{\"label\":\"yes\"}", response_id = "resp_1")
  output <- jsonlite::toJSON(
    list(custom_id = "row-1", response = list(status_code = 200, body = body)),
    auto_unbox = TRUE
  )
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      if (grepl("/content$", req$url)) {
        httr2::response(
          status_code = 200L,
          url = req$url,
          headers = list(`content-type` = "application/octet-stream"),
          body = charToRaw(as.character(output))
        )
      } else {
        mock_httr2_response(batch)
      }
    },
    .package = "httr2"
  )
  schema <- list(
    type = "object",
    properties = list(label = list(type = "string")),
    required = "label",
    additionalProperties = FALSE
  )
  data <- tibble::tibble(text = c("first", "second", "third"))

  expect_warning(
    result <- foundry_extract_batch_results("batch_123", data, schema),
    "2 input rows have no result"
  )
  expect_equal(nrow(result), 1L)
  expect_equal(result$.input_idx, 1L)
})
