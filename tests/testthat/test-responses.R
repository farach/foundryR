# ============================================================================
# Responses API Tests
# ============================================================================

test_that("foundry_response requires input and model", {
  setup_mock_env()

  expect_error(foundry_response(), "input")
  expect_error(foundry_response(character()), "input")
  expect_error(foundry_response(c("a", "b")), "input")
})

test_that("foundry_response requires model", {
  withr::local_envvar(
    AZURE_FOUNDRY_KEY = "test-key",
    AZURE_FOUNDRY_ENDPOINT = "https://test-resource.openai.azure.com",
    AZURE_FOUNDRY_MODEL = ""
  )

  expect_error(foundry_response("Hello"), "Model/deployment name is required")
})

test_that("foundry_parse_response extracts output text, citations, and tool calls", {
  mock_response <- mock_response_api_response(
    output_text = "Grounded answer.",
    include_web_search = TRUE,
    citations = TRUE
  )

  result <- foundry_parse_response(mock_response)

  expect_s3_class(result, "tbl_df")
  expect_equal(result$response_id, "resp_test123")
  expect_equal(result$output_text, "Grounded answer.")
  expect_equal(result$input_tokens, 10L)
  expect_equal(result$output_tokens, 20L)
  expect_equal(result$total_tokens, 30L)

  citations <- result$citations[[1]]
  expect_equal(nrow(citations), 1L)
  expect_equal(citations$title, "Use the Azure OpenAI Responses API")

  tool_calls <- result$tool_calls[[1]]
  expect_equal(nrow(tool_calls), 1L)
  expect_equal(tool_calls$type, "web_search_call")
  expect_equal(tool_calls$query, "latest Azure AI Foundry Responses API updates")
})

test_that("foundry_response builds v1 request body", {
  setup_mock_env()
  mock_response <- mock_response_api_response(output_text = "{\"answer\":\"yes\"}")
  mock_resp <- mock_httr2_response(mock_response)
  captured <- NULL

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      mock_resp
    },
    .package = "httr2"
  )

  schema <- list(
    type = "object",
    properties = list(answer = list(type = "string")),
    required = "answer",
    additionalProperties = FALSE
  )

  result <- foundry_response(
    "Return yes as JSON.",
    instructions = "Return JSON.",
    text_format = foundry_json_schema_format(schema, "Answer"),
    reasoning_effort = "medium",
    max_output_tokens = 50,
    store = FALSE
  )

  expect_equal(captured$url, "https://test-resource.openai.azure.com/openai/v1/responses")
  expect_equal(captured$method, "POST")
  expect_equal(captured$body$data$model, "gpt-4-test")
  expect_equal(captured$body$data$input, "Return yes as JSON.")
  expect_equal(captured$body$data$instructions, "Return JSON.")
  expect_equal(captured$body$data$reasoning$effort, "medium")
  expect_equal(captured$body$data$max_output_tokens, 50L)
  expect_false(captured$body$data$store)
  expect_equal(captured$body$data$text$format$type, "json_schema")
  expect_true(inherits(captured$body$data$text$format$schema$required, "AsIs"))

  expect_equal(result$structured[[1]]$answer, "yes")
  expect_true(is.na(result$structured_error))
})

test_that("foundry_extract flattens structured output", {
  setup_mock_env()
  mock_response <- mock_response_api_response(
    output_text = "{\"sentiment\":\"positive\",\"entities\":[\"R\",\"Azure\"]}"
  )
  mock_resp <- mock_httr2_response(mock_response)

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) mock_resp,
    .package = "httr2"
  )

  schema <- list(
    type = "object",
    properties = list(
      sentiment = list(type = "string", enum = c("positive", "negative", "neutral")),
      entities = list(type = "array", items = list(type = "string"))
    ),
    required = c("sentiment", "entities"),
    additionalProperties = FALSE
  )

  result <- foundry_extract(
    "I love using R with Azure AI Foundry.",
    schema = schema,
    model = "gpt-4.1"
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1L)
  expect_false(result$.error)
  expect_equal(result$sentiment, "positive")
  expect_equal(result$entities[[1]], c("R", "Azure"))
})

test_that("foundry_extract handles NA inputs without an API call", {
  setup_mock_env()

  schema <- list(
    type = "object",
    properties = list(label = list(type = "string")),
    required = "label",
    additionalProperties = FALSE
  )

  result <- foundry_extract(NA_character_, schema = schema, model = "gpt-4.1")

  expect_true(result$.error)
  expect_equal(result$.status, "skipped")
  expect_match(result$.error_msg, "NA")
})

test_that("foundry_web_search builds web_search tool and parses citations", {
  setup_mock_env()
  withr::local_options(foundryR.web_search_warning = TRUE)

  mock_response <- mock_response_api_response(
    output_text = "Grounded web answer.",
    include_web_search = TRUE,
    citations = TRUE
  )
  mock_resp <- mock_httr2_response(mock_response)
  captured <- NULL

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      mock_resp
    },
    .package = "httr2"
  )

  result <- foundry_web_search(
    "What changed in Azure AI Foundry?",
    model = "gpt-4.1",
    country = "US",
    city = "Seattle",
    search_context_size = "high"
  )

  tool <- captured$body$data$tools[[1]]
  expect_equal(tool$type, "web_search")
  expect_equal(tool$search_context_size, "high")
  expect_equal(tool$user_location$type, "approximate")
  expect_equal(tool$user_location$city, "Seattle")

  expect_equal(result$output_text, "Grounded web answer.")
  expect_equal(nrow(result$citations[[1]]), 1L)
  expect_equal(nrow(result$tool_calls[[1]]), 1L)
})

test_that("foundry_response_retrieve and delete use v1 response paths", {
  setup_mock_env()
  captured_urls <- character()

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured_urls <<- c(captured_urls, req$url)
      if (identical(req$method, "DELETE")) {
        mock_httr2_response(list(id = "resp_123", deleted = TRUE))
      } else {
        mock_httr2_response(mock_response_api_response(response_id = "resp_123"))
      }
    },
    .package = "httr2"
  )

  retrieved <- foundry_response_retrieve("resp_123")
  deleted <- foundry_response_delete("resp_123")

  expect_equal(retrieved$response_id, "resp_123")
  expect_true(deleted$deleted)
  expect_equal(
    captured_urls,
    c(
      "https://test-resource.openai.azure.com/openai/v1/responses/resp_123",
      "https://test-resource.openai.azure.com/openai/v1/responses/resp_123"
    )
  )
})
