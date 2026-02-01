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
