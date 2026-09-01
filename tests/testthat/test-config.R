test_that("foundry_set_endpoint sets environment variable", {
  withr::local_envvar(AZURE_FOUNDRY_ENDPOINT = "")

  suppressMessages(foundry_set_endpoint("https://test.openai.azure.com"))
  expect_equal(Sys.getenv("AZURE_FOUNDRY_ENDPOINT"), "https://test.openai.azure.com")
})

test_that("project endpoint setters normalize trailing slashes", {
  withr::local_envvar(AZURE_FOUNDRY_PROJECT_ENDPOINT = "")

  suppressMessages(foundry_set_project_endpoint("https://example.services.ai.azure.com/api/projects/p1/"))

  expect_equal(
    foundry_get_project_endpoint(),
    "https://example.services.ai.azure.com/api/projects/p1"
  )
})

test_that("foundry_set_endpoint removes trailing slash", {
  withr::local_envvar(AZURE_FOUNDRY_ENDPOINT = "")

  suppressMessages(foundry_set_endpoint("https://test.openai.azure.com/"))
  expect_equal(Sys.getenv("AZURE_FOUNDRY_ENDPOINT"), "https://test.openai.azure.com")
})

test_that("foundry_set_endpoint rejects empty endpoint", {
  expect_error(foundry_set_endpoint(""), "required")
  expect_error(foundry_set_endpoint(NULL), "required")
})

test_that("foundry_get_endpoint retrieves from environment", {
  withr::local_envvar(AZURE_FOUNDRY_ENDPOINT = "https://my-resource.openai.azure.com")

  expect_equal(foundry_get_endpoint(), "https://my-resource.openai.azure.com")
})

test_that("foundry_get_endpoint returns NULL when not set", {
  withr::local_envvar(AZURE_FOUNDRY_ENDPOINT = "")
  withr::local_options(foundryR.config_file = tempfile())

  expect_null(foundry_get_endpoint())
})

test_that("stored endpoints are read without modifying Renviron", {
  config_file <- tempfile()
  home <- withr::local_tempdir()
  withr::local_options(foundryR.config_file = config_file)
  withr::local_envvar(
    HOME = home,
    AZURE_FOUNDRY_ENDPOINT = ""
  )

  suppressMessages(
    foundry_set_endpoint("https://stored.openai.azure.com", store = TRUE)
  )
  Sys.setenv(AZURE_FOUNDRY_ENDPOINT = "")

  expect_equal(foundry_get_endpoint(), "https://stored.openai.azure.com")
  expect_equal(file.exists(file.path(home, ".Renviron")), FALSE)
})

test_that("foundry_get_endpoint errors when required and not set", {
  withr::local_envvar(AZURE_FOUNDRY_ENDPOINT = "")
  withr::local_options(foundryR.config_file = tempfile())

  expect_error(foundry_get_endpoint(required = TRUE), "endpoint is required")
})

test_that("foundry_get_api_version returns default", {
  withr::local_envvar(AZURE_FOUNDRY_API_VERSION = "")

  expect_equal(foundry_get_api_version(), "2024-10-21")
})

test_that("foundry_get_api_version uses environment variable", {
  withr::local_envvar(AZURE_FOUNDRY_API_VERSION = "2025-01-01-preview")

  expect_equal(foundry_get_api_version(), "2025-01-01-preview")
})
