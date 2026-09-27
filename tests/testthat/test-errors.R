error_response <- function(status, body = NULL, url = "https://test-resource.openai.azure.com/openai/v1/evals/eval_1") {
  httr2::response(
    status_code = status,
    url = url,
    headers = list(`content-type` = "application/json"),
    body = if (is.null(body)) raw() else charToRaw(body)
  )
}

test_that("the service message is kept for every status", {
  cases <- list(
    list(status = 400L, body = '{"error":{"message":"Bad key name in schema"}}'),
    list(status = 401L, body = '{"error":{"message":"Access denied due to invalid subscription key"}}'),
    list(status = 403L, body = '{"error":{"message":"Principal lacks permission"}}'),
    list(status = 404L, body = '{"error":{"message":"Eval eval_1 cannot be found."}}'),
    list(status = 429L, body = '{"error":{"message":"Requests are throttled"}}'),
    list(status = 503L, body = '{"error":{"message":"Service unavailable"}}')
  )
  for (case in cases) {
    lines <- foundry_error_body(error_response(case$status, case$body))
    service_message <- jsonlite::fromJSON(case$body)$error$message
    expect_true(any(grepl(service_message, lines, fixed = TRUE)), info = case$status)
  }
})

test_that("a schema error that mentions a key is not reported as a bad API key", {
  lines <- foundry_error_body(error_response(
    400L,
    '{"error":{"message":"Invalid value for key \'item\' in the data source schema"}}'
  ))
  expect_false(any(grepl("API key", lines)))
  expect_match(lines[[1]], "^API error: Invalid value for key")
})

test_that("empty and non-standard bodies do not break error handling", {
  empty <- foundry_error_body(error_response(404L))
  expect_match(empty[[1]], "no response body")

  string_error <- foundry_error_body(error_response(400L, '{"error":"model is required"}'))
  expect_match(string_error[[1]], "model is required")

  text <- foundry_error_body(error_response(500L, "upstream timeout"))
  expect_match(text[[1]], "upstream timeout")
})

test_that("404 hints depend on the endpoint that was called", {
  resource <- foundry_error_body(error_response(404L, '{"error":{"message":"not found"}}'))
  expect_true(any(grepl("project_endpoint", resource, fixed = TRUE)))

  project <- foundry_error_body(error_response(
    404L,
    '{"error":{"message":"not found"}}',
    url = "https://acct.services.ai.azure.com/api/projects/demo/openai/v1/evals/eval_1"
  ))
  expect_true(any(grepl("created on this project", project, fixed = TRUE)))

  deployment <- foundry_error_body(error_response(
    404L,
    '{"error":{"code":"DeploymentNotFound","message":"The API deployment for this resource does not exist."}}',
    url = "https://test-resource.openai.azure.com/openai/deployments/gpt-x/chat/completions"
  ))
  expect_true(any(grepl("deployment name", deployment, fixed = TRUE)))
})

test_that("401 hints cover keys and tokens", {
  lines <- foundry_error_body(error_response(401L, '{"error":{"message":"Unauthorized"}}'))
  expect_true(any(grepl("API key", lines, fixed = TRUE)))
  expect_true(any(grepl("https://ai.azure.com", lines, fixed = TRUE)))
})

test_that("vector search Entra rejection gets an API key hint", {
  lines <- foundry_error_body(error_response(
    400L,
    '{"error":{"message":"ApiId openai-language-model-instance-api OperationId search_vector_store not supported for CheckAccess."}}'
  ))
  expect_true(any(grepl("does not accept Microsoft Entra ID tokens", lines, fixed = TRUE)))
})

test_that("content filter errors list the filtered categories", {
  body <- jsonlite::toJSON(list(error = list(
    code = "content_filter",
    message = "The response was filtered.",
    innererror = list(content_filter_result = list(
      hate = list(filtered = TRUE, severity = "medium"),
      violence = list(filtered = FALSE, severity = "safe")
    ))
  )), auto_unbox = TRUE)
  lines <- foundry_error_body(error_response(400L, as.character(body)))
  expect_match(lines[[1]], "Content filtered: hate \\(medium\\)")
  expect_match(lines[[2]], "The response was filtered.")
})

test_that("Content Safety errors use Content Safety hints", {
  lines <- content_safety_error_body(error_response(
    401L,
    '{"error":{"code":"401","message":"Access denied"}}',
    url = "https://test-content-safety.cognitiveservices.azure.com/contentsafety/text:analyze"
  ))
  expect_match(lines[[1]], "^Content Safety API error: Access denied")
  expect_true(any(grepl("AZURE_CONTENT_SAFETY_KEY", lines, fixed = TRUE)))
})

test_that("foundry_error_message gives one line for row-level errors", {
  message <- foundry_error_message(error_response(429L, '{"error":{"message":"Slow down"}}'))
  expect_length(message, 1L)
  expect_match(message, "^HTTP 429\\. API error: Slow down")
})

test_that("httr2 errors carry the classified lines", {
  req <- httr2::request("https://test-resource.openai.azure.com/openai/v1/evals/eval_1") |>
    httr2::req_error(body = foundry_error_body)
  err <- tryCatch(
    httr2::req_perform(req, mock = function(req) {
      error_response(404L, '{"error":{"message":"Eval eval_1 cannot be found."}}', url = req$url)
    }),
    error = function(e) e
  )
  expect_s3_class(err, "httr2_http_404")
  expect_match(conditionMessage(err), "Eval eval_1 cannot be found.", fixed = TRUE)
  expect_match(conditionMessage(err), "project_endpoint", fixed = TRUE)
})
