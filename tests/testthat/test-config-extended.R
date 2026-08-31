# ============================================================================
# Unit Tests for Extended Configuration Functions
# Tests for:
#   - foundry_set_content_safety_endpoint()
#   - foundry_set_content_safety_key()
#   - get_content_safety_endpoint() (internal)
#   - get_content_safety_key() (internal)
#   - foundry_set_image_endpoint()
#   - foundry_set_image_key()
#   - foundry_get_image_endpoint()
#   - foundry_get_image_key()
# ============================================================================

# ============================================================================
# Content Safety Endpoint Configuration
# ============================================================================

test_that("foundry_set_content_safety_endpoint sets environment variable", {
  withr::local_envvar(AZURE_CONTENT_SAFETY_ENDPOINT = "")

  suppressMessages(foundry_set_content_safety_endpoint("https://test-cs.cognitiveservices.azure.com"))
  expect_equal(Sys.getenv("AZURE_CONTENT_SAFETY_ENDPOINT"), "https://test-cs.cognitiveservices.azure.com")
})

test_that("foundry_set_content_safety_endpoint removes trailing slash", {
  withr::local_envvar(AZURE_CONTENT_SAFETY_ENDPOINT = "")

  suppressMessages(foundry_set_content_safety_endpoint("https://test-cs.cognitiveservices.azure.com/"))
  expect_equal(Sys.getenv("AZURE_CONTENT_SAFETY_ENDPOINT"), "https://test-cs.cognitiveservices.azure.com")
})

test_that("foundry_set_content_safety_endpoint rejects empty endpoint", {
  expect_error(foundry_set_content_safety_endpoint(""), "required")
  expect_error(foundry_set_content_safety_endpoint(NULL), "required")
})

test_that("foundry_set_content_safety_endpoint returns TRUE invisibly", {
  withr::local_envvar(AZURE_CONTENT_SAFETY_ENDPOINT = "")

  result <- suppressMessages(
    foundry_set_content_safety_endpoint("https://test.cognitiveservices.azure.com")
  )
  expect_true(result)
})

# ============================================================================
# Content Safety Key Configuration
# ============================================================================

test_that("foundry_set_content_safety_key sets environment variable", {
  withr::local_envvar(AZURE_CONTENT_SAFETY_KEY = "")

  suppressMessages(foundry_set_content_safety_key("test-content-safety-key-12345"))
  expect_equal(Sys.getenv("AZURE_CONTENT_SAFETY_KEY"), "test-content-safety-key-12345")
})

test_that("foundry_set_content_safety_key rejects empty key", {
  expect_error(foundry_set_content_safety_key(""), "cannot be empty")
  expect_error(foundry_set_content_safety_key(NA), "cannot be empty")
})

test_that("foundry_set_content_safety_key returns TRUE invisibly", {
  withr::local_envvar(AZURE_CONTENT_SAFETY_KEY = "")

  result <- suppressMessages(foundry_set_content_safety_key("test-key"))
  expect_true(result)
})

test_that("Content Safety settings persist in the package config file", {
  config_file <- tempfile()
  withr::local_options(foundryR.config_file = config_file)
  withr::local_envvar(
    AZURE_CONTENT_SAFETY_ENDPOINT = "",
    AZURE_CONTENT_SAFETY_KEY = ""
  )

  suppressMessages(foundry_set_content_safety_endpoint(
    "https://stored.cognitiveservices.azure.com",
    store = TRUE
  ))
  suppressMessages(foundry_set_content_safety_key("stored-key", store = TRUE))
  Sys.setenv(
    AZURE_CONTENT_SAFETY_ENDPOINT = "",
    AZURE_CONTENT_SAFETY_KEY = ""
  )

  expect_equal(
    get_content_safety_endpoint(),
    "https://stored.cognitiveservices.azure.com"
  )
  expect_equal(get_content_safety_key(), "stored-key")
})

# ============================================================================
# get_content_safety_endpoint() (internal)
# ============================================================================

test_that("get_content_safety_endpoint retrieves from environment", {
  withr::local_envvar(
    AZURE_CONTENT_SAFETY_ENDPOINT = "https://my-cs-resource.cognitiveservices.azure.com"
  )

  result <- get_content_safety_endpoint()
  expect_equal(result, "https://my-cs-resource.cognitiveservices.azure.com")
})

test_that("get_content_safety_endpoint returns NULL when not set", {
  withr::local_envvar(AZURE_CONTENT_SAFETY_ENDPOINT = "")
  withr::local_options(foundryR.config_file = tempfile())

  expect_null(get_content_safety_endpoint())
})

test_that("get_content_safety_endpoint errors when required and not set", {
  withr::local_envvar(AZURE_CONTENT_SAFETY_ENDPOINT = "")
  withr::local_options(foundryR.config_file = tempfile())

  expect_error(get_content_safety_endpoint(required = TRUE), "endpoint is required")
})

test_that("get_content_safety_endpoint uses provided endpoint over environment", {
  withr::local_envvar(
    AZURE_CONTENT_SAFETY_ENDPOINT = "https://env-cs.cognitiveservices.azure.com"
  )

  result <- get_content_safety_endpoint(
    endpoint = "https://provided-cs.cognitiveservices.azure.com"
  )
  expect_equal(result, "https://provided-cs.cognitiveservices.azure.com")
})

test_that("get_content_safety_endpoint removes trailing slash", {
  withr::local_envvar(
    AZURE_CONTENT_SAFETY_ENDPOINT = "https://test-cs.cognitiveservices.azure.com/"
  )

  result <- get_content_safety_endpoint()
  expect_equal(result, "https://test-cs.cognitiveservices.azure.com")
})

# ============================================================================
# get_content_safety_key() (internal)
# ============================================================================

test_that("get_content_safety_key retrieves from environment", {
  withr::local_envvar(AZURE_CONTENT_SAFETY_KEY = "env-cs-key-12345")

  result <- get_content_safety_key()
  expect_equal(result, "env-cs-key-12345")
})

test_that("get_content_safety_key returns NULL when not set", {
  withr::local_envvar(AZURE_CONTENT_SAFETY_KEY = "")
  withr::local_options(foundryR.config_file = tempfile())

  expect_null(get_content_safety_key())
})

test_that("get_content_safety_key errors when required and not set", {
  withr::local_envvar(AZURE_CONTENT_SAFETY_KEY = "")
  withr::local_options(foundryR.config_file = tempfile())

  expect_error(get_content_safety_key(required = TRUE), "API key is required")
})

test_that("get_content_safety_key uses provided key over environment", {
  withr::local_envvar(AZURE_CONTENT_SAFETY_KEY = "env-key")

  result <- get_content_safety_key(key = "provided-key")
  expect_equal(result, "provided-key")
})

# ============================================================================
# Image Endpoint Configuration
# ============================================================================

test_that("foundry_set_image_endpoint sets environment variable", {
  withr::local_envvar(AZURE_FOUNDRY_IMAGE_ENDPOINT = "")

  suppressMessages(foundry_set_image_endpoint("https://test-dalle.cognitiveservices.azure.com"))
  expect_equal(Sys.getenv("AZURE_FOUNDRY_IMAGE_ENDPOINT"), "https://test-dalle.cognitiveservices.azure.com")
})

test_that("foundry_set_image_endpoint removes trailing slash", {
  withr::local_envvar(AZURE_FOUNDRY_IMAGE_ENDPOINT = "")

  suppressMessages(foundry_set_image_endpoint("https://test-dalle.cognitiveservices.azure.com/"))
  expect_equal(Sys.getenv("AZURE_FOUNDRY_IMAGE_ENDPOINT"), "https://test-dalle.cognitiveservices.azure.com")
})

test_that("foundry_set_image_endpoint rejects empty endpoint", {
  expect_error(foundry_set_image_endpoint(""), "required and cannot be empty")
  expect_error(foundry_set_image_endpoint(NULL), "required and cannot be empty")
})

test_that("foundry_set_image_endpoint returns endpoint invisibly", {
  withr::local_envvar(AZURE_FOUNDRY_IMAGE_ENDPOINT = "")

  result <- suppressMessages(
    foundry_set_image_endpoint("https://test.cognitiveservices.azure.com")
  )
  expect_equal(result, "https://test.cognitiveservices.azure.com")
})

# ============================================================================
# Image Key Configuration
# ============================================================================

test_that("foundry_set_image_key sets environment variable", {
  withr::local_envvar(AZURE_FOUNDRY_IMAGE_KEY = "")

  suppressMessages(foundry_set_image_key("test-image-key-12345"))
  expect_equal(Sys.getenv("AZURE_FOUNDRY_IMAGE_KEY"), "test-image-key-12345")
})

test_that("foundry_set_image_key rejects empty key", {
  expect_error(foundry_set_image_key(""), "cannot be empty")
  expect_error(foundry_set_image_key(NULL), "cannot be empty")
  expect_error(foundry_set_image_key(NA), "cannot be empty")
})

test_that("foundry_set_image_key returns TRUE invisibly", {
  withr::local_envvar(AZURE_FOUNDRY_IMAGE_KEY = "")

  result <- suppressMessages(foundry_set_image_key("test-key"))
  expect_true(result)
})

# ============================================================================
# foundry_get_image_endpoint()
# ============================================================================

test_that("foundry_get_image_endpoint retrieves image-specific endpoint", {
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_ENDPOINT = "https://image-resource.cognitiveservices.azure.com",
    AZURE_FOUNDRY_ENDPOINT = "https://main-resource.openai.azure.com"
  )

  result <- foundry_get_image_endpoint()
  expect_equal(result, "https://image-resource.cognitiveservices.azure.com")
})

test_that("foundry_get_image_endpoint falls back to main endpoint", {
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_ENDPOINT = "",
    AZURE_FOUNDRY_ENDPOINT = "https://main-resource.openai.azure.com"
  )

  result <- foundry_get_image_endpoint()
  expect_equal(result, "https://main-resource.openai.azure.com")
})

test_that("foundry_get_image_endpoint returns NULL when not set", {
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_ENDPOINT = "",
    AZURE_FOUNDRY_ENDPOINT = ""
  )

  expect_null(foundry_get_image_endpoint())
})

test_that("foundry_get_image_endpoint errors when required and not set", {
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_ENDPOINT = "",
    AZURE_FOUNDRY_ENDPOINT = ""
  )

  expect_error(
    foundry_get_image_endpoint(required = TRUE),
    "Image endpoint is required"
  )
})

# ============================================================================
# foundry_get_image_key()
# ============================================================================

test_that("foundry_get_image_key retrieves image-specific key", {
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_KEY = "image-key-12345",
    AZURE_FOUNDRY_KEY = "main-key-67890"
  )

  result <- foundry_get_image_key()
  expect_equal(result, "image-key-12345")
})

test_that("foundry_get_image_key falls back to main key", {
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_KEY = "",
    AZURE_FOUNDRY_KEY = "main-key-67890"
  )

  result <- foundry_get_image_key()
  expect_equal(result, "main-key-67890")
})

test_that("foundry_get_image_key uses provided key first", {
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_KEY = "env-image-key",
    AZURE_FOUNDRY_KEY = "env-main-key"
  )

  result <- foundry_get_image_key(key = "provided-key")
  expect_equal(result, "provided-key")
})

test_that("foundry_get_image_key returns NULL when not set", {
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_KEY = "",
    AZURE_FOUNDRY_KEY = ""
  )

  expect_null(foundry_get_image_key())
})

test_that("foundry_get_image_key errors when required and not set", {
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_KEY = "",
    AZURE_FOUNDRY_KEY = ""
  )

  expect_error(
    foundry_get_image_key(required = TRUE),
    "Image API key is required"
  )
})

# ============================================================================
# Cross-Configuration Interaction Tests
# ============================================================================

test_that("image and content safety configs are independent", {
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_ENDPOINT = "",
    AZURE_FOUNDRY_IMAGE_KEY = "",
    AZURE_CONTENT_SAFETY_ENDPOINT = "",
    AZURE_CONTENT_SAFETY_KEY = ""
  )

  # Set image config
  suppressMessages({
    foundry_set_image_endpoint("https://image.azure.com")
    foundry_set_image_key("image-key")
  })

  # Set content safety config
  suppressMessages({
    foundry_set_content_safety_endpoint("https://cs.azure.com")
    foundry_set_content_safety_key("cs-key")
  })

  # Verify they are independent
  expect_equal(Sys.getenv("AZURE_FOUNDRY_IMAGE_ENDPOINT"), "https://image.azure.com")
  expect_equal(Sys.getenv("AZURE_FOUNDRY_IMAGE_KEY"), "image-key")
  expect_equal(Sys.getenv("AZURE_CONTENT_SAFETY_ENDPOINT"), "https://cs.azure.com")
  expect_equal(Sys.getenv("AZURE_CONTENT_SAFETY_KEY"), "cs-key")
})

test_that("main credentials don't affect content safety when not fallback", {
  withr::local_envvar(
    AZURE_FOUNDRY_ENDPOINT = "https://main.openai.azure.com",
    AZURE_FOUNDRY_KEY = "main-key",
    AZURE_CONTENT_SAFETY_ENDPOINT = "https://cs.azure.com",
    AZURE_CONTENT_SAFETY_KEY = "cs-key"
  )

  # Content safety should use its own endpoint
  expect_equal(get_content_safety_endpoint(), "https://cs.azure.com")
  expect_equal(get_content_safety_key(), "cs-key")
})
