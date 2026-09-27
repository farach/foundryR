test_that("conversation helpers use the project endpoint with an Entra token", {
  setup_mock_env()
  project <- "https://acct.services.ai.azure.com/api/projects/demo"
  withr::local_envvar(
    AZURE_FOUNDRY_PROJECT_ENDPOINT = project,
    AZURE_FOUNDRY_PROJECT_TOKEN = "test-project-token"
  )
  captured <- list()

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured[[length(captured) + 1L]] <<- req
      mock_httr2_response(list(id = "conv_123", object = "conversation", created_at = 1741369938))
    },
    .package = "httr2"
  )

  created <- foundry_conversation_create()
  got <- foundry_conversation_get("conv_123")
  foundry_conversation_update("conv_123")

  expect_equal(created$conversation_id, "conv_123")
  expect_equal(got$conversation_id, "conv_123")
  expect_equal(captured[[1]]$method, "POST")
  expect_equal(captured[[1]]$url, paste0(project, "/openai/v1/conversations"))
  expect_equal(request_header(captured[[1]], "Authorization"), "Bearer test-project-token")
  expect_null(captured[[1]]$headers$`api-key`)
  expect_equal(
    as.character(jsonlite::toJSON(captured[[1]]$body$data, auto_unbox = TRUE)),
    "{}"
  )
  expect_equal(captured[[2]]$url, paste0(project, "/openai/v1/conversations/conv_123"))
  expect_equal(
    as.character(jsonlite::toJSON(captured[[3]]$body$data, auto_unbox = TRUE)),
    "{}"
  )
})

test_that("conversation helpers reject resource endpoints and accept API keys", {
  setup_mock_env()
  captured <- NULL
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      mock_httr2_response(list(id = "conv_123", object = "conversation"))
    },
    .package = "httr2"
  )

  expect_error(
    foundry_conversation_get("conv_123", endpoint = "https://test-resource.openai.azure.com"),
    "only available on a Foundry project endpoint"
  )
  expect_error(
    foundry_conversation_get("conv_123"),
    "only available on a Foundry project endpoint"
  )
  expect_null(captured)

  foundry_conversation_get(
    "conv_123",
    api_key = "key",
    project_endpoint = "https://acct.services.ai.azure.com/api/projects/demo"
  )
  expect_equal(
    captured$url,
    "https://acct.services.ai.azure.com/api/projects/demo/openai/v1/conversations/conv_123"
  )
  expect_contains(names(captured$headers), "api-key")
})

test_that("a project URL passed as endpoint routes to the project", {
  setup_mock_env()
  withr::local_envvar(AZURE_FOUNDRY_PROJECT_TOKEN = "test-project-token")
  project <- "https://acct.services.ai.azure.com/api/projects/demo"
  captured <- NULL
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      mock_httr2_response(list(id = "conv_123", object = "conversation"))
    },
    .package = "httr2"
  )

  foundry_conversation_get("conv_123", endpoint = project)
  expect_equal(captured$url, paste0(project, "/openai/v1/conversations/conv_123"))
})
