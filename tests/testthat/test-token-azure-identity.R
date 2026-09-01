fake_azure_token <- function(access_token, expires_on = NULL) {
  if (is.null(expires_on)) {
    expires_on <- as.character(as.integer(Sys.time()) + 3600L)
  }
  list(credentials = list(
    access_token = access_token,
    expires_on = expires_on
  ))
}

test_that("azure identity provider is lazy and does not acquire on construction", {
  called <- FALSE
  testthat::local_mocked_bindings(
    foundry_azure_get_token = function(...) {
      called <<- TRUE
      fake_azure_token("token-1")
    }
  )

  provider <- foundry_token_azure_identity(tenant = "t", app = "a")

  expect_type(provider, "closure")
  expect_false(called)
})

test_that("azure identity provider caches tokens until near expiry", {
  calls <- 0L
  testthat::local_mocked_bindings(
    foundry_azure_get_token = function(...) {
      calls <<- calls + 1L
      fake_azure_token(paste0("token-", calls))
    }
  )

  provider <- foundry_token_azure_identity(tenant = "t", app = "a")

  expect_equal(provider(), "token-1")
  expect_equal(provider(), "token-1")
  expect_equal(calls, 1L)
})

test_that("azure identity provider re-acquires when the cached token is near expiry", {
  calls <- 0L
  testthat::local_mocked_bindings(
    foundry_azure_get_token = function(...) {
      calls <<- calls + 1L
      # expires_on set to "now" so the 5-minute early-refresh window always trips
      fake_azure_token(
        paste0("token-", calls),
        expires_on = as.character(as.integer(Sys.time()))
      )
    }
  )

  provider <- foundry_token_azure_identity(tenant = "t", app = "a")

  expect_equal(provider(), "token-1")
  expect_equal(provider(), "token-2")
  expect_equal(calls, 2L)
})

test_that("azure identity provider passes resource, tenant and app to AzureAuth", {
  captured <- NULL
  testthat::local_mocked_bindings(
    foundry_azure_get_token = function(...) {
      captured <<- list(...)
      fake_azure_token("token-1")
    }
  )

  provider <- foundry_token_azure_identity(
    resource = "https://ai.azure.com",
    tenant = "my-tenant",
    app = "my-app",
    password = "secret"
  )
  provider()

  expect_equal(captured$resource, "https://ai.azure.com")
  expect_equal(captured$tenant, "my-tenant")
  expect_equal(captured$app, "my-app")
  expect_equal(captured$password, "secret")
})

test_that("azure identity provider supports managed identity without tenant or app", {
  captured <- NULL
  testthat::local_mocked_bindings(
    foundry_azure_get_managed_token = function(...) {
      captured <<- list(...)
      fake_azure_token("managed-token")
    }
  )

  provider <- foundry_token_azure_identity(managed_identity = TRUE)

  expect_equal(provider(), "managed-token")
  expect_equal(captured$resource, "https://cognitiveservices.azure.com")
  expect_false("tenant" %in% names(captured))
  expect_false("app" %in% names(captured))
})

test_that("azure identity provider errors when tenant or app is missing", {
  provider_no_tenant <- foundry_token_azure_identity(tenant = "", app = "a")
  expect_error(provider_no_tenant(), "tenant")

  provider_no_app <- foundry_token_azure_identity(tenant = "t", app = "")
  expect_error(provider_no_app(), "app")
})

test_that("azure identity provider validates managed_identity", {
  expect_error(
    foundry_token_azure_identity(managed_identity = "yes"),
    "TRUE"
  )
})

test_that("azure identity provider errors when no access token is returned", {
  testthat::local_mocked_bindings(
    foundry_azure_get_token = function(...) fake_azure_token("")
  )

  provider <- foundry_token_azure_identity(tenant = "t", app = "a")
  expect_error(provider(), "did not return an access token")
})

test_that("foundry_require_azureauth errors when AzureAuth is unavailable", {
  testthat::local_mocked_bindings(
    requireNamespace = function(...) FALSE,
    .package = "base"
  )

  expect_error(foundry_require_azureauth(), "AzureAuth")
})
