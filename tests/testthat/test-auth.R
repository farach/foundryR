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

  expect_null(foundry_get_key())
})

test_that("foundry_get_key errors when required and not set", {
  withr::local_envvar(AZURE_FOUNDRY_KEY = "")

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

  expect_null(foundry_get_token())
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
  withr::defer(foundry_set_token_provider(NULL))
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

test_that("azure cli token provider caches tokens", {
  calls <- 0L
  testthat::local_mocked_bindings(
    system2 = function(...) {
      calls <<- calls + 1L
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
})
