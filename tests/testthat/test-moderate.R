# ============================================================================
# Input Validation Tests
# ============================================================================

test_that("foundry_moderate requires endpoint", {
  withr::local_options(foundryR.config_file = tempfile())
  withr::local_envvar(
    AZURE_CONTENT_SAFETY_ENDPOINT = "",
    AZURE_CONTENT_SAFETY_KEY = "test-key"
  )

  expect_error(foundry_moderate("Hello"), "endpoint is required")
})

test_that("foundry_moderate requires an API key or resource token", {
  withr::defer(foundry_set_token_provider(NULL, scope = "resource"))
  foundry_set_token_provider(NULL, scope = "resource")
  withr::local_options(foundryR.config_file = tempfile())
  withr::local_envvar(
    AZURE_CONTENT_SAFETY_ENDPOINT = "https://test.cognitiveservices.azure.com",
    AZURE_CONTENT_SAFETY_KEY = "",
    AZURE_FOUNDRY_TOKEN = "",
    AZURE_OPENAI_TOKEN = ""
  )

  expect_error(foundry_moderate("Hello"), "authentication is required")
})

test_that("foundry_moderate validates categories", {
  setup_content_safety_env()

  expect_error(
    foundry_moderate("Hello", categories = c("InvalidCategory")),
    "Invalid categories"
  )
})

test_that("foundry_moderate handles empty input", {
  setup_content_safety_env()

  result <- foundry_moderate(character())

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
  expect_named(result, c(
    "text", "category", "severity", "label",
    "blocklist_matches", "raw_response"
  ))
})

# ============================================================================
# Response Parsing Tests
# ============================================================================

test_that("severity_to_label returns correct labels", {
  expect_equal(severity_to_label(0), "safe")
  expect_equal(severity_to_label(1), "low")
  expect_equal(severity_to_label(2), "low")
  expect_equal(severity_to_label(3), "medium")
  expect_equal(severity_to_label(4), "medium")
  expect_equal(severity_to_label(5), "high")
  expect_equal(severity_to_label(6), "high")
  expect_equal(severity_to_label(7), "high")
  expect_true(is.na(severity_to_label(NA)))
})

# ============================================================================
# Mocked API Tests
# ============================================================================

test_that("foundry_moderate returns tibble with mocked safe response", {
  setup_content_safety_env()
  fixture <- load_fixture("moderate", "response.json")
  mock_request(fixture)

  result <- foundry_moderate("This is a friendly message.")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 4)  # 4 categories
  expect_named(result, c(
    "text", "category", "severity", "label",
    "blocklist_matches", "raw_response"
  ))

  # All severities should be 0 (safe)
  expect_true(all(result$severity == 0))
  expect_true(all(result$label == "safe"))

  # Check categories are present
  expect_true("Hate" %in% result$category)
  expect_true("Sexual" %in% result$category)
  expect_true("SelfHarm" %in% result$category)
  expect_true("Violence" %in% result$category)
})

test_that("foundry_moderate returns tibble with mocked flagged response", {
  setup_content_safety_env()
  fixture <- load_fixture("moderate", "response_flagged.json")
  mock_request(fixture)

  result <- foundry_moderate("Some problematic text.")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 4)

  # Check Hate category was flagged
  hate_row <- result[result$category == "Hate", ]
  expect_equal(hate_row$severity, 4L)
  expect_equal(hate_row$label, "medium")

  # Check Violence category was flagged
  violence_row <- result[result$category == "Violence", ]
  expect_equal(violence_row$severity, 2L)
  expect_equal(violence_row$label, "low")

  # Safe categories
  sexual_row <- result[result$category == "Sexual", ]
  expect_equal(sexual_row$severity, 0L)
  expect_equal(sexual_row$label, "safe")
})

test_that("foundry_moderate returns correct column types", {
  setup_content_safety_env()
  fixture <- load_fixture("moderate", "response.json")
  mock_request(fixture)

  result <- foundry_moderate("Test message")

  expect_type(result$text, "character")
  expect_type(result$category, "character")
  expect_type(result$severity, "integer")
  expect_type(result$label, "character")
})

test_that("foundry_moderate truncates long text in output", {
  setup_content_safety_env()
  fixture <- load_fixture("moderate", "response.json")
  mock_request(fixture)

  long_text <- paste(rep("word", 100), collapse = " ")
  result <- foundry_moderate(long_text)

  # Text in result should be truncated with "..."
  expect_true(nchar(result$text[1]) <= 50)
  expect_true(grepl("\\.\\.\\.$", result$text[1]))
})

test_that("foundry_moderate works with custom categories", {
  setup_content_safety_env()

  # Create response with only requested categories
  fixture <- list(
    categoriesAnalysis = list(
      list(category = "Hate", severity = 0L),
      list(category = "Violence", severity = 0L)
    )
  )
  mock_request(fixture)

  result <- foundry_moderate("Hello", categories = c("Hate", "Violence"))

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true(all(result$category %in% c("Hate", "Violence")))
})

# ============================================================================
# Integration Test (requires real credentials)
# ============================================================================

test_that("foundry_moderate returns tibble with real API", {
  skip_on_cran()
  skip_if_no_live_api()
  skip_if(
    Sys.getenv("AZURE_CONTENT_SAFETY_KEY") == "",
    "AZURE_CONTENT_SAFETY_KEY not set"
  )
  skip_if(
    Sys.getenv("AZURE_CONTENT_SAFETY_ENDPOINT") == "",
    "AZURE_CONTENT_SAFETY_ENDPOINT not set"
  )

  result <- foundry_moderate("This is a friendly test message.")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 4)
  expect_named(result, c("text", "category", "severity", "label", "blocklist_matches", "raw_response"))
  expect_true(all(result$category %in% c("Hate", "Sexual", "SelfHarm", "Violence")))
})
