test_that("vignette hooks restore configuration and do not add global bindings", {
  skip_if_not_installed("httptest2")
  original_redactor <- function(response) response
  withr::local_options(
    foundryR.sequential_requests = FALSE,
    foundryR.doc_restore = NULL,
    httptest2.redactor = original_redactor,
    httptest2.redactor.packages = "existing"
  )
  withr::local_envvar(
    AZURE_FOUNDRY_ENDPOINT = NA_character_,
    AZURE_FOUNDRY_KEY = "existing-example-key",
    AZURE_FOUNDRY_MODEL = ""
  )
  before_env <- Sys.getenv()
  before_options <- options(
    "foundryR.sequential_requests",
    "foundryR.doc_restore",
    "httptest2.redactor",
    "httptest2.redactor.packages"
  )
  before_global <- ls(globalenv(), all.names = TRUE)
  hook <- function(file) {
    source(
      system.file("httptest2", file, package = "foundryR"),
      local = new.env(parent = globalenv())
    )
  }
  withr::defer(hook("end-vignette.R"))
  hook("start-vignette.R")
  expect_identical(Sys.getenv("AZURE_FOUNDRY_KEY"), "existing-example-key")
  expect_identical(
    Sys.getenv("AZURE_FOUNDRY_ENDPOINT"),
    "https://example.openai.azure.com"
  )
  expect_identical(getOption("foundryR.sequential_requests"), TRUE)

  hook("end-vignette.R")
  after_env <- Sys.getenv()
  expect_setequal(names(after_env), names(before_env))
  expect_length(
    names(before_env)[after_env[names(before_env)] != before_env],
    0L
  )
  expect_identical(
    do.call(options, as.list(names(before_options))),
    before_options
  )
  expect_identical(ls(globalenv(), all.names = TRUE), before_global)
})
