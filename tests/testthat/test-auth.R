test_that("foundry_set_key sets environment variable", {
  withr::local_envvar(AZURE_FOUNDRY_KEY = "")

  expect_silent(foundry_set_key("test-key-123"))
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
