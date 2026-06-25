test_that("foundry_models lists v1 models", {
  setup_mock_env()
  captured <- NULL
  mock_resp <- mock_httr2_response(list(
    object = "list",
    data = list(
      list(id = "gpt-4.1", object = "model", created = 1741369938, owned_by = "azure")
    )
  ))

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      mock_resp
    },
    .package = "httr2"
  )

  result <- foundry_models()

  expect_equal(captured$url, "https://test-resource.openai.azure.com/openai/v1/models")
  expect_equal(captured$method, "GET")
  expect_equal(result$id, "gpt-4.1")
  expect_s3_class(result$created, "POSIXct")
})

test_that("foundry_file_upload builds multipart request", {
  setup_mock_env()
  path <- tempfile(fileext = ".jsonl")
  writeLines('{"custom_id":"row-1"}', path)
  captured <- NULL
  mock_resp <- mock_httr2_response(list(
    id = "file_123",
    filename = basename(path),
    purpose = "batch",
    status = "processed",
    bytes = 21,
    created_at = 1741369938
  ))

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      mock_resp
    },
    .package = "httr2"
  )

  result <- foundry_file_upload(path, purpose = "batch")

  expect_equal(captured$url, "https://test-resource.openai.azure.com/openai/v1/files")
  expect_equal(captured$method, "POST")
  expect_equal(result$file_id, "file_123")
  expect_equal(result$purpose, "batch")
})

test_that("foundry_files parses list response", {
  setup_mock_env()
  mock_request(list(
    object = "list",
    data = list(
      list(
        id = "file_123",
        filename = "batch.jsonl",
        purpose = "batch",
        status = "processed",
        bytes = 100,
        created_at = 1741369938
      )
    )
  ))

  result <- foundry_files(purpose = "batch", limit = 1)

  expect_equal(nrow(result), 1L)
  expect_equal(result$filename, "batch.jsonl")
})

test_that("foundry_file_get and delete use file paths", {
  setup_mock_env()
  captured <- character()

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- c(captured, paste(req$method, req$url))
      if (identical(req$method, "DELETE")) {
        mock_httr2_response(list(id = "file_123", deleted = TRUE))
      } else {
        mock_httr2_response(list(
          id = "file_123",
          filename = "data.jsonl",
          purpose = "batch",
          status = "processed",
          bytes = 10,
          created_at = 1741369938
        ))
      }
    },
    .package = "httr2"
  )

  file <- foundry_file_get("file_123")
  deleted <- foundry_file_delete("file_123")

  expect_equal(file$file_id, "file_123")
  expect_equal(deleted$deleted, TRUE)
  expect_match(captured[[1]], "GET .*/files/file_123$")
  expect_match(captured[[2]], "DELETE .*/files/file_123$")
})

test_that("foundry_batch_requests writes executable JSONL", {
  setup_mock_env()
  data <- data.frame(id = c("a", "b"), text = c("one", "two"))
  path <- tempfile(fileext = ".jsonl")

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
