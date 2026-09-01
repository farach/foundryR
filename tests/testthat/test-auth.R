test_that("foundry_set_key sets environment variable", {
  withr::local_envvar(AZURE_FOUNDRY_KEY = "")

  suppressMessages(foundry_set_key("test-key-123"))
  expect_equal(Sys.getenv("AZURE_FOUNDRY_KEY"), "test-key-123")
})

test_that("foundry_set_key rejects empty key", {
  expect_error(foundry_set_key(""), "cannot be empty")
  expect_error(foundry_set_key(NA), "cannot be empty")
})

test_that("foundry_get_key retrieves from environment", {
  withr::local_envvar(AZURE_FOUNDRY_KEY = "env-key-456")

  expect_equal(foundry_get_key(), "env-key-456")
})

test_that("foundry_get_key returns NULL when not set", {
  withr::local_envvar(AZURE_FOUNDRY_KEY = "")
  withr::local_options(foundryR.config_file = tempfile())

  expect_null(foundry_get_key())
})

test_that("foundry_get_key errors when required and not set", {
  withr::local_envvar(AZURE_FOUNDRY_KEY = "")
  withr::local_options(foundryR.config_file = tempfile())

  expect_error(foundry_get_key(required = TRUE), "API key is required")
})

test_that("foundry_get_key uses provided key over environment", {
  withr::local_envvar(AZURE_FOUNDRY_KEY = "env-key")

  expect_equal(foundry_get_key(key = "provided-key"), "provided-key")
})

test_that("foundry_set_token sets environment variable", {
  withr::local_envvar(AZURE_FOUNDRY_TOKEN = "")

  suppressMessages(foundry_set_token("Bearer test-token-123"))
  expect_equal(Sys.getenv("AZURE_FOUNDRY_TOKEN"), "test-token-123")
})

test_that("foundry_get_token retrieves from environment", {
  withr::local_envvar(AZURE_FOUNDRY_TOKEN = "env-token-456")

  expect_equal(foundry_get_token(), "env-token-456")
})

test_that("foundry_get_token returns NULL when not set", {
  withr::local_envvar(
    AZURE_FOUNDRY_TOKEN = "",
    AZURE_OPENAI_TOKEN = ""
  )
  withr::local_options(foundryR.config_file = tempfile())

  expect_null(foundry_get_token())
})

test_that("persistent settings use the package config file", {
  config_file <- tempfile()
  home <- withr::local_tempdir()
  withr::local_options(foundryR.config_file = config_file)
  withr::local_envvar(
    HOME = home,
    AZURE_FOUNDRY_KEY = ""
  )

  suppressMessages(foundry_set_key("stored-key", store = TRUE))
  Sys.setenv(AZURE_FOUNDRY_KEY = "")

  expect_equal(foundry_get_key(), "stored-key")
  expect_equal(file.exists(config_file), TRUE)
  expect_equal(file.exists(file.path(home, ".Renviron")), FALSE)
})

test_that("invalid package config files have a recovery message", {
  config_file <- withr::local_tempfile(lines = "{")
  withr::local_options(foundryR.config_file = config_file)
  withr::local_envvar(AZURE_FOUNDRY_KEY = "")

  expect_error(
    foundry_get_key(),
    "Could not read foundryR configuration file"
  )
})

test_that("static tokens are separated by endpoint family", {
  withr::local_envvar(
    AZURE_FOUNDRY_TOKEN = "",
    AZURE_FOUNDRY_PROJECT_TOKEN = ""
  )

  suppressMessages(foundry_set_token("resource-token"))
  suppressMessages(foundry_set_token("project-token", scope = "project"))

  expect_equal(foundry_get_token(scope = "resource"), "resource-token")
  expect_equal(foundry_get_token(scope = "project"), "project-token")
})

test_that("explicit API key takes precedence over environment token", {
  withr::local_envvar(
    AZURE_FOUNDRY_TOKEN = "env-token",
    AZURE_FOUNDRY_KEY = "env-key"
  )

  req <- httr2::request("https://example.com") |>
    foundry_authenticate_request(api_key = "explicit-key")

  expect_contains(names(req$headers), "api-key")
  expect_setequal(setdiff(names(req$headers), "api-key"), character())
})

test_that("token provider is used before environment token and key", {
  withr::defer(foundry_set_token_provider(NULL, scope = "resource"))
  withr::local_envvar(
    AZURE_FOUNDRY_TOKEN = "env-token",
    AZURE_OPENAI_TOKEN = "",
    AZURE_FOUNDRY_KEY = "env-key"
  )
  foundry_set_token_provider(function() "provider-token")

  req <- httr2::request("https://example.com") |>
    foundry_authenticate_request()

  expect_contains(names(req$headers), "Authorization")
  expect_false("api-key" %in% names(req$headers))
})

test_that("request builders select providers by endpoint family", {
  withr::defer({
    foundry_set_token_provider(NULL, scope = "resource")
    foundry_set_token_provider(NULL, scope = "project")
  })
  withr::local_envvar(
    AZURE_FOUNDRY_KEY = "",
    AZURE_FOUNDRY_TOKEN = "",
    AZURE_FOUNDRY_PROJECT_TOKEN = "",
    AZURE_FOUNDRY_ENDPOINT = "https://resource.openai.azure.com",
    AZURE_FOUNDRY_PROJECT_ENDPOINT =
      "https://resource.services.ai.azure.com/api/projects/project"
  )
  calls <- character()
  foundry_set_token_provider(function() {
    calls <<- c(calls, "resource")
    "resource-token"
  }, scope = "resource")
  foundry_set_token_provider(function() {
    calls <<- c(calls, "project")
    "project-token"
  }, scope = "project")

  foundry_build_v1_request("models", method = "GET")
  foundry_build_project_request("agents", method = "GET")

  expect_equal(calls, c("resource", "project"))
})

test_that("azure cli token provider caches tokens", {
  calls <- 0L
  arguments <- NULL
  testthat::local_mocked_bindings(
    system2 = function(command, args, ...) {
      calls <<- calls + 1L
      arguments <<- args
      jsonlite::toJSON(
        list(accessToken = paste0("token-", calls), expires_on = as.numeric(Sys.time() + 3600)),
        auto_unbox = TRUE
      )
    },
    .package = "base"
  )

  provider <- foundry_token_azure_cli()

  expect_equal(provider(), "token-1")
  expect_equal(provider(), "token-1")
  expect_equal(calls, 1L)
  expect_equal(
    arguments[match("--resource", arguments) + 1L],
    "https://cognitiveservices.azure.com"
  )
})
