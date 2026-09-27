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

test_that("the recording redactor removes project names and report links", {
  skip_if_not_installed("httptest2")
  withr::local_options(
    foundryR.sequential_requests = FALSE,
    foundryR.doc_restore = NULL,
    httptest2.redactor = NULL,
    httptest2.redactor.packages = NULL
  )
  withr::local_envvar(
    AZURE_FOUNDRY_PROJECT_ENDPOINT = "https://real-acct.services.ai.azure.com/api/projects/secret-proj/"
  )
  hook <- function(file) {
    source(
      system.file("httptest2", file, package = "foundryR"),
      local = new.env(parent = globalenv())
    )
  }
  withr::defer(hook("end-vignette.R"))
  hook("start-vignette.R")
  redact <- getOption("httptest2.redactor")

  real_base <- "https://real-acct.services.ai.azure.com/api/projects/secret-proj"
  body <- paste0(
    "{\"id\":\"evalrun_1\",\"report_url\":\"https://ai.azure.com/build?wsid=/subscriptions/0000/x\",",
    "\"source\":\"", real_base, "/openai/v1/evals/eval_1\"}"
  )
  response <- httr2::response(
    status_code = 200L,
    url = paste0(real_base, "/openai/v1/evals/eval_1/runs/evalrun_1"),
    headers = list(`content-type` = "application/json"),
    body = charToRaw(body)
  )

  redacted <- redact(response)
  expect_identical(
    redacted$url,
    "https://example.services.ai.azure.com/api/projects/demo/openai/v1/evals/eval_1/runs/evalrun_1"
  )
  text <- httr2::resp_body_string(redacted)
  expect_false(grepl("secret-proj|real-acct|subscriptions", text))
  expect_match(text, "\"report_url\":\"https://ai.azure.com/\"", fixed = TRUE)
  expect_match(text, "example.services.ai.azure.com/api/projects/demo/openai", fixed = TRUE)
})
