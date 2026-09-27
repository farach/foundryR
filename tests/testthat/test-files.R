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
  expect_null(captured$body$data$expires_after)
})

test_that("foundry_file_upload sends an expiry only when asked", {
  setup_mock_env()
  path <- withr::local_tempfile(fileext = ".txt")
  writeLines("Office hours are on Fridays.", path)
  captured <- list()
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured[[length(captured) + 1L]] <<- req
      mock_httr2_response(list(id = "file_1", purpose = "assistants"))
    },
    .package = "httr2"
  )

  foundry_file_upload(path)
  expect_null(captured[[1]]$body$data$expires_after)

  foundry_file_upload(path, purpose = "batch", expires_after_seconds = 3600)
  expiry <- jsonlite::fromJSON(as.character(captured[[2]]$body$data$expires_after))
  expect_equal(expiry, list(anchor = "created_at", seconds = 3600L))
})

test_that("foundry_file_upload can target a project endpoint", {
  setup_mock_env()
  project <- "https://acct.services.ai.azure.com/api/projects/demo"
  withr::local_envvar(AZURE_FOUNDRY_PROJECT_TOKEN = "test-project-token")
  path <- withr::local_tempfile(fileext = ".txt")
  writeLines("Office hours are on Fridays.", path)
  captured <- NULL
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      mock_httr2_response(list(id = "file_1", purpose = "assistants"))
    },
    .package = "httr2"
  )

  foundry_file_upload(path, project_endpoint = project)
  expect_equal(captured$url, paste0(project, "/openai/v1/files"))
  expect_equal(request_header(captured, "Authorization"), "Bearer test-project-token")
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
