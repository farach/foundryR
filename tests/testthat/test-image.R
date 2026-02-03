# ============================================================================
# Unit Tests for Image Generation Functions
# Tests for: foundry_image(), foundry_save_image()
# ============================================================================

# ============================================================================
# Input Validation Tests - foundry_image()
# ============================================================================

test_that("foundry_image requires model", {
  withr::local_envvar(
    AZURE_FOUNDRY_KEY = "test-key",
    AZURE_FOUNDRY_ENDPOINT = "https://test.openai.azure.com",
    AZURE_FOUNDRY_IMAGE_MODEL = "",
    AZURE_FOUNDRY_IMAGE_ENDPOINT = ""
  )

  expect_error(
    foundry_image("A sunset over mountains"),
    "Image model/deployment name is required"
  )
})

test_that("foundry_image requires non-empty prompt", {
  withr::local_envvar(
    AZURE_FOUNDRY_KEY = "test-key",
    AZURE_FOUNDRY_ENDPOINT = "https://test.openai.azure.com",
    AZURE_FOUNDRY_IMAGE_MODEL = "dall-e-3"
  )

  expect_error(foundry_image(""), "cannot be empty")
  expect_error(foundry_image("", model = "dall-e-3"), "cannot be empty")
})

test_that("foundry_image requires single string prompt", {
  withr::local_envvar(
    AZURE_FOUNDRY_KEY = "test-key",
    AZURE_FOUNDRY_ENDPOINT = "https://test.openai.azure.com",
    AZURE_FOUNDRY_IMAGE_MODEL = "dall-e-3"
  )

  expect_error(
    foundry_image(c("prompt1", "prompt2"), model = "dall-e-3"),
    "single"
  )

  expect_error(
    foundry_image(NULL, model = "dall-e-3"),
    "single"
  )
})

test_that("foundry_image validates n parameter", {
  withr::local_envvar(
    AZURE_FOUNDRY_KEY = "test-key",
    AZURE_FOUNDRY_ENDPOINT = "https://test.openai.azure.com",
    AZURE_FOUNDRY_IMAGE_MODEL = "dall-e-3"
  )

  expect_error(foundry_image("test", model = "dall-e-3", n = 0), "between 1 and 10")
  expect_error(foundry_image("test", model = "dall-e-3", n = 11), "between 1 and 10")
  expect_error(foundry_image("test", model = "dall-e-3", n = -1), "between 1 and 10")
})

test_that("foundry_image validates size parameter", {
  withr::local_envvar(
    AZURE_FOUNDRY_KEY = "test-key",
    AZURE_FOUNDRY_ENDPOINT = "https://test.openai.azure.com",
    AZURE_FOUNDRY_IMAGE_MODEL = "dall-e-3"
  )

  expect_error(
    foundry_image("test", model = "dall-e-3", size = "invalid"),
    "'arg' should be one of"
  )
})

test_that("foundry_image validates quality parameter", {
  withr::local_envvar(
    AZURE_FOUNDRY_KEY = "test-key",
    AZURE_FOUNDRY_ENDPOINT = "https://test.openai.azure.com",
    AZURE_FOUNDRY_IMAGE_MODEL = "dall-e-3"
  )

  expect_error(
    foundry_image("test", model = "dall-e-3", quality = "ultra"),
    "'arg' should be one of"
  )
})

test_that("foundry_image validates style parameter", {
  withr::local_envvar(
    AZURE_FOUNDRY_KEY = "test-key",
    AZURE_FOUNDRY_ENDPOINT = "https://test.openai.azure.com",
    AZURE_FOUNDRY_IMAGE_MODEL = "dall-e-3"
  )

  expect_error(
    foundry_image("test", model = "dall-e-3", style = "artistic"),
    "'arg' should be one of"
  )
})

test_that("foundry_image validates response_format parameter", {
  withr::local_envvar(
    AZURE_FOUNDRY_KEY = "test-key",
    AZURE_FOUNDRY_ENDPOINT = "https://test.openai.azure.com",
    AZURE_FOUNDRY_IMAGE_MODEL = "dall-e-3"
  )

  expect_error(
    foundry_image("test", model = "dall-e-3", response_format = "png"),
    "'arg' should be one of"
  )
})

# ============================================================================
# Input Validation Tests - foundry_save_image()
# ============================================================================

test_that("foundry_save_image requires data frame input", {
  expect_error(
    foundry_save_image("not a df", "test.png"),
    "must be a tibble"
  )

  expect_error(
    foundry_save_image(list(a = 1), "test.png"),
    "must be a tibble"
  )
})

test_that("foundry_save_image requires url and b64_json columns", {
  df <- tibble::tibble(prompt = "test")

  expect_error(
    foundry_save_image(df, "test.png"),
    "must contain"
  )
})

test_that("foundry_save_image validates index parameter", {
  df <- tibble::tibble(
    url = "https://example.com/image.png",
    b64_json = NA_character_
  )

  expect_error(foundry_save_image(df, "test.png", index = 0), "must be between")
  expect_error(foundry_save_image(df, "test.png", index = 2), "must be between")
  expect_error(foundry_save_image(df, "test.png", index = -1), "must be between")
})

test_that("foundry_save_image validates path parameter", {
  df <- tibble::tibble(
    url = "https://example.com/image.png",
    b64_json = NA_character_
  )

  expect_error(foundry_save_image(df, path = NULL), "must be a single file path")
  expect_error(foundry_save_image(df, path = c("a.png", "b.png")), "must be a single file path")
})

test_that("foundry_save_image errors when no image data available", {
  df <- tibble::tibble(
    url = NA_character_,
    b64_json = NA_character_
  )

  expect_error(foundry_save_image(df, "test.png"), "No image data found")
})

# ============================================================================
# Mocked API Tests - foundry_image()
# ============================================================================

test_that("foundry_image returns tibble with correct structure (mocked)", {
  setup_mock_env()
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_ENDPOINT = "https://test-image.openai.azure.com",
    AZURE_FOUNDRY_IMAGE_MODEL = "dall-e-3"
  )

  mock_response <- list(
    created = as.integer(Sys.time()),
    data = list(
      list(
        url = "https://oaidalleapiprodscus.blob.core.windows.net/test-image.png",
        revised_prompt = "A beautiful sunset over mountain peaks with orange and purple sky"
      )
    )
  )

  mock_request(mock_response)

  result <- foundry_image("A sunset over mountains", model = "dall-e-3")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_named(result, c("prompt", "revised_prompt", "url", "b64_json", "created"))
})

test_that("foundry_image returns correct column types (mocked)", {
  setup_mock_env()
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_ENDPOINT = "https://test-image.openai.azure.com",
    AZURE_FOUNDRY_IMAGE_MODEL = "dall-e-3"
  )

  mock_response <- list(
    created = as.integer(Sys.time()),
    data = list(
      list(
        url = "https://oaidalleapiprodscus.blob.core.windows.net/test-image.png",
        revised_prompt = "Enhanced prompt description"
      )
    )
  )

  mock_request(mock_response)

  result <- foundry_image("A cat", model = "dall-e-3")

  expect_type(result$prompt, "character")
  expect_type(result$revised_prompt, "character")
  expect_type(result$url, "character")
  expect_s3_class(result$created, "POSIXct")
})

test_that("foundry_image preserves original prompt", {
  setup_mock_env()
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_ENDPOINT = "https://test-image.openai.azure.com",
    AZURE_FOUNDRY_IMAGE_MODEL = "dall-e-3"
  )

  original_prompt <- "A simple blue circle on white background"

  mock_response <- list(
    created = as.integer(Sys.time()),
    data = list(
      list(
        url = "https://example.com/image.png",
        revised_prompt = "A minimalist design featuring a simple blue circle"
      )
    )
  )

  mock_request(mock_response)

  result <- foundry_image(original_prompt, model = "dall-e-3")

  expect_equal(result$prompt, original_prompt)
})

test_that("foundry_image handles multiple images (mocked)", {
  setup_mock_env()
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_ENDPOINT = "https://test-image.openai.azure.com",
    AZURE_FOUNDRY_IMAGE_MODEL = "dall-e-3"
  )

  mock_response <- list(
    created = as.integer(Sys.time()),
    data = list(
      list(
        url = "https://example.com/image1.png",
        revised_prompt = "Variation 1"
      ),
      list(
        url = "https://example.com/image2.png",
        revised_prompt = "Variation 2"
      ),
      list(
        url = "https://example.com/image3.png",
        revised_prompt = "Variation 3"
      )
    )
  )

  mock_request(mock_response)

  result <- foundry_image("Abstract art", model = "dall-e-3", n = 3)

  expect_equal(nrow(result), 3)
  expect_equal(result$prompt, rep("Abstract art", 3))
})

test_that("foundry_image handles b64_json response format (mocked)", {
  setup_mock_env()
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_ENDPOINT = "https://test-image.openai.azure.com",
    AZURE_FOUNDRY_IMAGE_MODEL = "dall-e-3"
  )

  mock_response <- list(
    created = as.integer(Sys.time()),
    data = list(
      list(
        b64_json = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
        revised_prompt = "Base64 encoded image"
      )
    )
  )

  mock_request(mock_response)

  result <- foundry_image("A logo", model = "dall-e-3", response_format = "b64_json")

  expect_true(!is.na(result$b64_json))
  expect_true(is.na(result$url))
})

# ============================================================================
# foundry_save_image with base64 data
# ============================================================================

test_that("foundry_save_image saves base64 image to file", {
  skip_if_not_installed("base64enc")

  # Create a minimal valid PNG in base64 (1x1 transparent pixel)
  b64_data <- "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="

  df <- tibble::tibble(
    prompt = "test",
    revised_prompt = "test",
    url = NA_character_,
    b64_json = b64_data,
    created = Sys.time()
  )

  temp_file <- tempfile(fileext = ".png")
  on.exit(unlink(temp_file), add = TRUE)

  suppressMessages(foundry_save_image(df, temp_file))

  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
})

test_that("foundry_save_image selects correct image by index", {
  skip_if_not_installed("base64enc")

  b64_data <- "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="

  df <- tibble::tibble(
    prompt = rep("test", 3),
    revised_prompt = c("rev1", "rev2", "rev3"),
    url = NA_character_,
    b64_json = b64_data,
    created = Sys.time()
  )

  temp_file <- tempfile(fileext = ".png")
  on.exit(unlink(temp_file), add = TRUE)

  suppressMessages(foundry_save_image(df, temp_file, index = 2))

  expect_true(file.exists(temp_file))
})

# ============================================================================
# Endpoint and Key Configuration Tests
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

test_that("foundry_get_image_endpoint falls back to main endpoint", {
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_ENDPOINT = "",
    AZURE_FOUNDRY_ENDPOINT = "https://main-resource.openai.azure.com"
  )

  result <- foundry_get_image_endpoint()
  expect_equal(result, "https://main-resource.openai.azure.com")
})

test_that("foundry_get_image_endpoint prefers image-specific endpoint", {
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_ENDPOINT = "https://image-resource.cognitiveservices.azure.com",
    AZURE_FOUNDRY_ENDPOINT = "https://main-resource.openai.azure.com"
  )

  result <- foundry_get_image_endpoint()
  expect_equal(result, "https://image-resource.cognitiveservices.azure.com")
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

  expect_error(foundry_get_image_endpoint(required = TRUE), "Image endpoint is required")
})

test_that("foundry_get_image_key falls back to main key", {
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_KEY = "",
    AZURE_FOUNDRY_KEY = "main-api-key"
  )

  result <- foundry_get_image_key()
  expect_equal(result, "main-api-key")
})

test_that("foundry_get_image_key prefers image-specific key", {
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_KEY = "image-api-key",
    AZURE_FOUNDRY_KEY = "main-api-key"
  )

  result <- foundry_get_image_key()
  expect_equal(result, "image-api-key")
})

test_that("foundry_get_image_key uses provided key over environment", {
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_KEY = "env-key",
    AZURE_FOUNDRY_KEY = "main-key"
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

  expect_error(foundry_get_image_key(required = TRUE), "Image API key is required")
})

# ============================================================================
# Integration Test (requires real credentials)
# ============================================================================

test_that("foundry_image generates image with real API", {
 skip_on_cran()
  skip_if(
    Sys.getenv("AZURE_FOUNDRY_IMAGE_ENDPOINT") == "" &&
    Sys.getenv("AZURE_FOUNDRY_ENDPOINT") == "",
    "Image endpoint not configured"
  )
  skip_if(
    Sys.getenv("AZURE_FOUNDRY_IMAGE_MODEL") == "",
    "AZURE_FOUNDRY_IMAGE_MODEL not set"
  )

  result <- foundry_image(
    "A simple red square on a white background, minimalist",
    model = Sys.getenv("AZURE_FOUNDRY_IMAGE_MODEL"),
    quality = "standard"
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_true(!is.na(result$url) || !is.na(result$b64_json))
  expect_true(!is.na(result$created))
  expect_s3_class(result$created, "POSIXct")
})
