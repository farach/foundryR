test_that("foundry_batch_requests writes executable JSONL", {
  setup_mock_env()
  data <- data.frame(id = c("a", "b"), text = c("one", "two"))
  path <- withr::local_tempfile(fileext = ".jsonl")

  result <- foundry_batch_requests(
    data,
    input = "text",
    path = path,
    model = "gpt-4.1",
    custom_id = "id"
  )

  lines <- readLines(path)
  first <- jsonlite::fromJSON(lines[[1]], simplifyVector = FALSE)

  expect_equal(result$requests, 2L)
  expect_equal(first$custom_id, "a")
  expect_equal(first$body$model, "gpt-4.1")
  expect_equal(first$body$input, "one")
})

test_that("foundry_batch_requests preserves numeric precision and missing values", {
  data <- data.frame(
    text = "one",
    value = 0.123456,
    count = NA_integer_
  )
  path <- withr::local_tempfile(fileext = ".jsonl")

  foundry_batch_requests(
    data,
    input = "text",
    path = path,
    model = "gpt-4.1",
    body_columns = c("value", "count")
  )

  line <- readLines(path)[[1]]
  parsed <- jsonlite::fromJSON(line, simplifyVector = FALSE)

  expect_match(line, "0\\.123456")
  expect_equal(parsed$body$value, 0.123456)
  expect_null(parsed$body$count)
})

test_that("foundry_batch_requests writes structured output fields", {
  data <- data.frame(text = "one")
  path <- withr::local_tempfile(fileext = ".jsonl")
  schema <- foundry_schema(label = schema_string())

  foundry_batch_requests(
    data,
    input = "text",
    path = path,
    model = "gpt-4.1",
    schema = schema,
    instructions = "Extract labels."
  )

  line <- jsonlite::fromJSON(readLines(path)[[1]], simplifyVector = FALSE)

  expect_equal(line$body$instructions, "Extract labels.")
  expect_equal(line$body$text$format$type, "json_schema")
  expect_equal(line$body$text$format$schema$type, "object")
})

test_that("foundry_batch_create, get, and cancel parse batch metadata", {
  setup_mock_env()
  captured <- character()
  batch <- list(
    id = "batch_123",
    status = "validating",
    endpoint = "/v1/responses",
    input_file_id = "file_123",
    completion_window = "24h",
    created_at = 1741369938,
    request_counts = list(total = 2, completed = 0, failed = 0)
  )

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- c(captured, paste(req$method, req$url))
      mock_httr2_response(batch)
    },
    .package = "httr2"
  )

  created <- foundry_batch_create("file_123")
  retrieved <- foundry_batch_get("batch_123")
  cancelled <- foundry_batch_cancel("batch_123")

  expect_equal(created$batch_id, "batch_123")
  expect_equal(retrieved$request_counts_total, 2L)
  expect_equal(cancelled$status, "validating")
  expect_match(captured[[1]], "POST .*/batches$")
  expect_match(captured[[2]], "GET .*/batches/batch_123$")
  expect_match(captured[[3]], "POST .*/batches/batch_123/cancel$")
})

test_that("foundry_batch_results parses responses output JSONL", {
  setup_mock_env()
  batch <- list(
    id = "batch_123",
    status = "completed",
    endpoint = "/v1/responses",
    input_file_id = "file_in",
    output_file_id = "file_out",
    request_counts = list(total = 1, completed = 1, failed = 0)
  )
  response <- mock_response_api_response(output_text = "{\"label\":\"yes\"}")
  output <- paste0(
    jsonlite::toJSON(
      list(
        custom_id = "row-1",
        request = list(
          body = list(
            text = list(format = list(type = "json_schema"))
          )
        ),
        response = list(status_code = 200, body = response)
      ),
      auto_unbox = TRUE
    ),
    "\n"
  )

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

  result <- foundry_batch_results("batch_123")

  expect_equal(result$custom_id, "row-1")
  expect_equal(result$.error, FALSE)
  expect_equal(result$output_text, "{\"label\":\"yes\"}")
  expect_equal(result$structured[[1]]$label, "yes")
})

test_that("foundry_batch_results leaves plain text responses unparsed", {
  setup_mock_env()
  batch <- list(
    id = "batch_123",
    status = "completed",
    endpoint = "/v1/responses",
    input_file_id = "file_in",
    output_file_id = "file_out",
    request_counts = list(total = 1, completed = 1, failed = 0)
  )
  response <- mock_response_api_response(output_text = "plain text")
  output <- paste0(
    jsonlite::toJSON(
      list(
        custom_id = "row-1",
        request = list(body = list(text = list(format = list(type = "text")))),
        response = list(status_code = 200, body = response)
      ),
      auto_unbox = TRUE
    ),
    "\n"
  )

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

  result <- foundry_batch_results("batch_123")

  expect_equal(result$output_text, "plain text")
  expect_null(result$structured[[1]])
  expect_true(is.na(result$structured_error))
})

test_that("foundry_file_content_lines marks content as UTF-8", {
  setup_mock_env()
  batch <- list(
    id = "batch_123",
    status = "completed",
    endpoint = "/v1/responses",
    input_file_id = "file_in",
    output_file_id = "file_out",
    request_counts = list(total = 1, completed = 1, failed = 0)
  )
  response <- mock_response_api_response(output_text = "café")
  output <- paste0(
    jsonlite::toJSON(
      list(custom_id = "row-1", response = list(status_code = 200, body = response)),
      auto_unbox = TRUE
    ),
    "\n"
  )

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      if (grepl("/content$", req$url)) {
        httr2::response(
          status_code = 200L,
          url = req$url,
          headers = list(`content-type` = "application/octet-stream"),
          body = charToRaw(enc2utf8(output))
        )
      } else {
        mock_httr2_response(batch)
      }
    },
    .package = "httr2"
  )

  result <- foundry_batch_results("batch_123")

  expect_equal(result$output_text, "café")
  expect_equal(Encoding(result$output_text), "UTF-8")
})

test_that("foundry_usage sums token columns and rates without double-counting cache", {
  x <- tibble::tibble(
    input_tokens = c(10, 20),
    cached_input_tokens = c(2, 3),
    output_tokens = c(4, 5)
  )

  result <- foundry_usage(
    x,
    rates = c(input = 0.01, cached_input = 0.001, output = 0.02)
  )

  expect_equal(result$input_tokens, 30)
  expect_equal(result$cached_input_tokens, 5)
  expect_equal(result$output_tokens, 9)
  expect_equal(result$cost, 25 * 0.01 + 5 * 0.001 + 9 * 0.02)
})

test_that("foundry_usage accepts named lists and defaults cache to input rate", {
  x <- tibble::tibble(
    input_tokens = 30,
    cached_input_tokens = 5,
    output_tokens = 9
  )

  vec <- foundry_usage(x, rates = c(input = 0.01, output = 0.02))
  lst <- foundry_usage(x, rates = list(input = 0.01, output = 0.02))

  expect_equal(lst$cost, vec$cost)
  expect_equal(vec$cost, 30 * 0.01 + 9 * 0.02)
})
