# Test helpers for foundryR
# These functions help with mocking and test setup

#' Skip tests that require API credentials
skip_if_no_auth <- function() {
  skip_if(
    Sys.getenv("AZURE_FOUNDRY_KEY") == "",
    "AZURE_FOUNDRY_KEY not set"
  )
  skip_if(
    Sys.getenv("AZURE_FOUNDRY_ENDPOINT") == "",
    "AZURE_FOUNDRY_ENDPOINT not set"
  )
}

#' Skip tests that require a specific model deployment
skip_if_no_model <- function(env_var = "AZURE_FOUNDRY_MODEL") {
  skip_if(
    Sys.getenv(env_var) == "",
    paste(env_var, "not set")
  )
}

#' Set up test environment with mock credentials
#'
#' Use within withr::local_ or test_that blocks
setup_mock_env <- function(env = parent.frame()) {
  withr::local_envvar(
    AZURE_FOUNDRY_KEY = "test-key-12345",
    AZURE_FOUNDRY_ENDPOINT = "https://test-resource.openai.azure.com",
    AZURE_FOUNDRY_MODEL = "gpt-4-test",
    AZURE_FOUNDRY_EMBED_MODEL = "text-embedding-ada-002",
    .local_envir = env
  )
}

#' Create a mock chat response
mock_chat_response <- function(content = "Hello! How can I help you?",
                                model = "gpt-4",
                                finish_reason = "stop",
                                prompt_tokens = 10,
                                completion_tokens = 20) {
  list(
    id = "chatcmpl-test123",
    object = "chat.completion",
    created = as.integer(Sys.time()),
    model = model,
    choices = list(
      list(
        index = 0,
        message = list(
          role = "assistant",
          content = content
        ),
        finish_reason = finish_reason
      )
    ),
    usage = list(
      prompt_tokens = prompt_tokens,
      completion_tokens = completion_tokens,
      total_tokens = prompt_tokens + completion_tokens
    )
  )
}

#' Create a mock Responses API response
mock_response_api_response <- function(output_text = "Hello from Responses API",
                                       model = "gpt-4.1",
                                       response_id = "resp_test123",
                                       include_web_search = FALSE,
                                       citations = FALSE) {
  content_item <- list(
    type = "output_text",
    text = output_text
  )

  if (citations) {
    content_item$annotations <- list(
      list(
        type = "url_citation",
        start_index = 0L,
        end_index = 12L,
        url = "https://learn.microsoft.com/azure/foundry/openai/how-to/responses",
        title = "Use the Azure OpenAI Responses API"
      )
    )
  }

  output <- list()
  if (include_web_search) {
    output[[1]] <- list(
      id = "ws_test123",
      type = "web_search_call",
      status = "completed",
      action = list(
        type = "search",
        query = "latest Azure AI Foundry Responses API updates"
      )
    )
  }

  output[[length(output) + 1L]] <- list(
    id = "msg_test123",
    type = "message",
    status = "completed",
    role = "assistant",
    content = list(content_item)
  )

  list(
    id = response_id,
    object = "response",
    created_at = 1741369938,
    status = "completed",
    model = model,
    output = output,
    usage = list(
      input_tokens = 10L,
      output_tokens = 20L,
      total_tokens = 30L,
      output_tokens_details = list(reasoning_tokens = 0L)
    )
  )
}

#' Create a mock embedding response
mock_embed_response <- function(embedding = NULL, n_dims = 1536, model = "text-embedding-ada-002") {
  if (is.null(embedding)) {
    embedding <- rnorm(n_dims)
  }

  list(
    object = "list",
    model = model,
    data = list(
      list(
        index = 0,
        object = "embedding",
        embedding = embedding
      )
    ),
    usage = list(
      prompt_tokens = 4,
      total_tokens = 4
    )
  )
}

# ============================================================================
# Fixture Helpers
# ============================================================================

#' Get path to fixture files
#'
#' @param ... Path components relative to fixtures directory
#' @return Full path to the fixture file
fixture_path <- function(...) {
  testthat::test_path("fixtures", ...)
}

#' Load a JSON fixture file
#'
#' @param ... Path components relative to fixtures directory
#' @return Parsed JSON as an R list
load_fixture <- function(...) {
  path <- fixture_path(...)
  jsonlite::fromJSON(path, simplifyVector = FALSE)
}

#' Set up mock environment for Content Safety API tests
#'
#' Use within withr::local_ or test_that blocks
setup_content_safety_env <- function(env = parent.frame()) {
  withr::local_envvar(
    AZURE_CONTENT_SAFETY_KEY = "test-content-safety-key-12345",
    AZURE_CONTENT_SAFETY_ENDPOINT = "https://test-content-safety.cognitiveservices.azure.com",
    .local_envir = env
  )
}

#' Create a mock httr2 response for testing
#'
#' @param body List. The response body (will be serialized to JSON).
#' @param status_code Integer. HTTP status code. Default: 200.
#' @param url Character. The request URL. Default: mock URL.
#' @return An httr2 response object
mock_httr2_response <- function(body, status_code = 200L,
                                 url = "https://mock-api.azure.com") {
  # Create JSON body
  body_json <- jsonlite::toJSON(body, auto_unbox = TRUE)

  # Create a mock response using httr2's testing utilities
  httr2::response(
    status_code = status_code,
    url = url,
    headers = list(`content-type` = "application/json"),
    body = charToRaw(as.character(body_json))
  )
}

#' Mock an HTTP request and return a fixture response
#'
#' This function uses local_mocked_bindings to replace httr2::req_perform
#' with a mock that returns the specified fixture.
#'
#' @param fixture_response List. The response data to return.
#' @param env Environment where the mock should be active.
#' @return NULL (invisibly). Called for side effect.
mock_request <- function(fixture_response, env = parent.frame()) {
  # Create a mock response
  mock_resp <- mock_httr2_response(fixture_response)

  # Mock req_perform to return our fixture response
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) mock_resp,
    .package = "httr2",
    .env = env
  )
}

#' Create a mock moderation response
#'
#' @param hate Integer. Severity for Hate category (0-6).
#' @param sexual Integer. Severity for Sexual category (0-6).
#' @param self_harm Integer. Severity for SelfHarm category (0-6).
#' @param violence Integer. Severity for Violence category (0-6).
#' @return List representing the API response
mock_moderate_response <- function(hate = 0L, sexual = 0L,
                                    self_harm = 0L, violence = 0L) {
  list(
    categoriesAnalysis = list(
      list(category = "Hate", severity = hate),
      list(category = "Sexual", severity = sexual),
      list(category = "SelfHarm", severity = self_harm),
      list(category = "Violence", severity = violence)
    )
  )
}

#' Create a mock groundedness response
#'
#' @param grounded Logical. Whether the response is grounded.
#' @param ungrounded_pct Numeric. Percentage of ungrounded content (0-1).
#' @param ungrounded_segments Character vector. Ungrounded text segments.
#' @return List representing the API response
mock_groundedness_response <- function(grounded = TRUE,
                                        ungrounded_pct = 0,
                                        ungrounded_segments = character(0)) {
  details <- lapply(ungrounded_segments, function(seg) {
    list(text = seg)
  })

  list(
    ungroundedDetected = !grounded,
    ungroundedPercentage = ungrounded_pct,
    ungroundedDetails = details
  )
}

#' Create a mock shield response
#'
#' @param user_attack Logical. Whether user prompt attack was detected.
#' @param doc_attacks Logical vector. Attack detection for each document.
#' @return List representing the API response
mock_shield_response <- function(user_attack = FALSE, doc_attacks = NULL) {
  result <- list(
    userPromptAnalysis = list(attackDetected = user_attack)
  )

  if (!is.null(doc_attacks)) {
    result$documentsAnalysis <- lapply(doc_attacks, function(attack) {
      list(attackDetected = attack)
    })
  } else {
    result$documentsAnalysis <- list()
  }

  result
}

# ============================================================================
# Image Generation Mocking Helpers
# ============================================================================

#' Set up mock environment for Image Generation API tests
#'
#' Use within withr::local_ or test_that blocks
setup_image_env <- function(env = parent.frame()) {
  withr::local_envvar(
    AZURE_FOUNDRY_IMAGE_KEY = "test-image-key-12345",
    AZURE_FOUNDRY_IMAGE_ENDPOINT = "https://test-image.cognitiveservices.azure.com",
    AZURE_FOUNDRY_IMAGE_MODEL = "dall-e-3",
    .local_envir = env
  )
}

#' Create a mock image generation response (URL format)
#'
#' @param prompt Character. The original prompt.
#' @param revised_prompt Character. DALL-E's revised prompt.
#' @param url Character. The image URL.
#' @param n Integer. Number of images to generate.
#' @return List representing the API response
mock_image_response_url <- function(prompt = "A test image",
                                     revised_prompt = "Enhanced test image description",
                                     url = "https://oaidalleapiprodscus.blob.core.windows.net/private/test.png",
                                     n = 1L) {
  data <- lapply(seq_len(n), function(i) {
    list(
      revised_prompt = paste(revised_prompt, "- Variation", i),
      url = paste0(url, "?v=", i)
    )
  })

  list(
    created = as.integer(Sys.time()),
    data = data
  )
}

#' Create a mock image generation response (base64 format)
#'
#' @param prompt Character. The original prompt.
#' @param revised_prompt Character. DALL-E's revised prompt.
#' @param b64_json Character. Base64-encoded image data (minimal valid PNG).
#' @return List representing the API response
mock_image_response_b64 <- function(prompt = "A test image",
                                     revised_prompt = "Enhanced test image description",
                                     b64_json = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==") {
  list(
    created = as.integer(Sys.time()),
    data = list(
      list(
        revised_prompt = revised_prompt,
        b64_json = b64_json
      )
    )
  )
}

# ============================================================================
# Batch Embedding Mocking Helpers
# ============================================================================

#' Create a mock batch embedding response
#'
#' @param texts Character vector. The input texts.
#' @param n_dims Integer. Embedding dimensionality.
#' @param model Character. Model name.
#' @return List representing the API response
mock_batch_embed_response <- function(texts, n_dims = 10L,
                                       model = "text-embedding-ada-002") {
  data <- lapply(seq_along(texts) - 1L, function(i) {
    list(
      index = i,
      object = "embedding",
      embedding = as.list(rnorm(n_dims))
    )
  })

  list(
    object = "list",
    model = model,
    data = data,
    usage = list(
      prompt_tokens = length(texts) * 4L,
      total_tokens = length(texts) * 4L
    )
  )
}
