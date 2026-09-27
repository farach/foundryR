test_that("foundry_file_upload builds multipart request", {
  setup_mock_env()
  path <- withr::local_tempfile(fileext = ".jsonl")
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

  expect_equal(
    captured$url,
    "https://test-resource.openai.azure.com/openai/v1/files"
  )
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
