# ============================================================================
# Input Validation Tests
# ============================================================================

test_that("foundry_chat requires message", {
  setup_mock_env()

  expect_error(foundry_chat(), "message")
  expect_error(foundry_chat(NULL), "message")
})

test_that("foundry_chat requires model", {
  withr::local_envvar(
    AZURE_FOUNDRY_KEY = "test-key",
    AZURE_FOUNDRY_ENDPOINT = "https://test.openai.azure.com",
    AZURE_FOUNDRY_MODEL = ""
  )

  expect_error(foundry_chat("Hello"), "Model/deployment name is required")
})

# ============================================================================
# Response Parsing Tests
# ============================================================================

test_that("foundry_parse_chat_response returns correct tibble structure", {
  mock_response <- mock_chat_response(
    content = "Test response",
    model = "gpt-4",
    finish_reason = "stop",
    prompt_tokens = 5,
    completion_tokens = 10
  )

  result <- foundry_parse_chat_response(mock_response, "gpt-4")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_named(result, c("role", "content", "model", "finish_reason",
                          "prompt_tokens", "completion_tokens", "total_tokens"))
  expect_equal(result$role, "assistant")
  expect_equal(result$content, "Test response")
  expect_equal(result$model, "gpt-4")
  expect_equal(result$finish_reason, "stop")
  expect_equal(result$prompt_tokens, 5)
  expect_equal(result$completion_tokens, 10)
  expect_equal(result$total_tokens, 15)
})

test_that("foundry_parse_chat_response handles missing fields", {
  minimal_response <- list(
    choices = list(
      list(
        message = list(content = "Hello")
      )
    )
  )

  result <- foundry_parse_chat_response(minimal_response, "test-model")

  expect_s3_class(result, "tbl_df")
  expect_equal(result$content, "Hello")
  expect_equal(result$model, "test-model")
  expect_true(is.na(result$finish_reason))
})

test_that("foundry_parse_chat_response parses fixture correctly", {
  fixture <- load_fixture("chat", "response.json")

  result <- foundry_parse_chat_response(fixture, "gpt-4")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_equal(result$role, "assistant")
  expect_equal(result$content, "The capital of France is Paris.")
  expect_equal(result$model, "gpt-4")
  expect_equal(result$finish_reason, "stop")
  expect_equal(result$prompt_tokens, 12L)
  expect_equal(result$completion_tokens, 8L)
  expect_equal(result$total_tokens, 20L)
})

# ============================================================================
# Mocked API Tests
# ============================================================================

test_that("foundry_chat returns tibble with mocked response", {
  setup_mock_env()
  fixture <- load_fixture("chat", "response.json")
  mock_request(fixture)

  result <- foundry_chat(
    "What is the capital of France?",
    model = "gpt-4"
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_equal(result$role, "assistant")
  expect_equal(result$content, "The capital of France is Paris.")
  expect_equal(result$finish_reason, "stop")
})

test_that("foundry_chat returns correct column types", {
  setup_mock_env()
  fixture <- load_fixture("chat", "response.json")
  mock_request(fixture)

  result <- foundry_chat("Test", model = "gpt-4")

  expect_type(result$role, "character")
  expect_type(result$content, "character")
  expect_type(result$model, "character")
  expect_type(result$finish_reason, "character")
  expect_type(result$prompt_tokens, "integer")
  expect_type(result$completion_tokens, "integer")
  expect_type(result$total_tokens, "integer")
})

# ============================================================================
# Integration Test (requires real credentials)
# ============================================================================

test_that("foundry_chat returns tibble with real API", {
  skip_on_cran()
  skip_if_no_auth()
  skip_if_no_model()

  result <- foundry_chat(
    "Say 'test' and nothing else",
    model = Sys.getenv("AZURE_FOUNDRY_MODEL"),
    max_tokens = 10
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(result$role, "assistant")
  expect_true(nchar(result$content) > 0)
})
