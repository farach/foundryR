# Chat with an Azure AI Model

Send a message to an Azure AI Foundry deployed model and receive a
response. Returns a tibble with the assistant's response and usage
metadata.

## Usage

``` r
foundry_chat(
  message,
  system = NULL,
  model = NULL,
  history = NULL,
  temperature = NULL,
  max_tokens = NULL,
  max_completion_tokens = NULL,
  top_p = NULL,
  frequency_penalty = NULL,
  presence_penalty = NULL,
  stop = NULL,
  api_key = NULL,
  api_version = NULL,
  ...
)
```

## Arguments

- message:

  Character. The user message to send.

- system:

  Character. Optional system prompt to set the assistant's behavior.

- model:

  Character. The deployment name. Defaults to the environment variable
  `AZURE_FOUNDRY_MODEL` or must be specified.

- history:

  List. Optional conversation history as a list of message objects, each
  with `role` and `content` fields.

- temperature:

  Numeric. Sampling temperature between 0 and 2. Higher values make
  output more random, lower values more deterministic. Default: 1.

- max_tokens:

  Integer. Maximum tokens in response (legacy parameter, use
  `max_completion_tokens` for newer models).

- max_completion_tokens:

  Integer. Maximum tokens in response. Preferred parameter for newer
  models (gpt-4o, etc.). Takes precedence over `max_tokens`.

- top_p:

  Numeric. Nucleus sampling parameter between 0 and 1. Default: 1.

- frequency_penalty:

  Numeric. Penalty for token frequency (-2.0 to 2.0). Default: 0.

- presence_penalty:

  Numeric. Penalty for token presence (-2.0 to 2.0). Default: 0.

- stop:

  Character vector. Up to 4 sequences where the API will stop
  generating.

- api_key:

  Character. Optional API key override.

- api_version:

  Character. Optional API version override.

- ...:

  Additional parameters passed to the API.

## Value

A tibble with columns:

- role:

  Character. Always "assistant".

- content:

  Character. The generated response text.

- model:

  Character. The deployment/model name used.

- finish_reason:

  Character. Why generation stopped: "stop", "length", etc.

- prompt_tokens:

  Integer. Tokens in the prompt.

- completion_tokens:

  Integer. Tokens in the response.

- total_tokens:

  Integer. Total tokens used.

## Examples

``` r
if (FALSE) { # \dontrun{
# Simple chat
foundry_chat("What is the capital of France?", model = "gpt-4")

# With system prompt
foundry_chat(
  "Explain tibbles",
  system = "You are a helpful R programming tutor. Be concise.",
  model = "gpt-4"
)

# With parameters (use max_completion_tokens for newer models)
foundry_chat(
  "Write a haiku about data science",
  model = "gpt-4",
  temperature = 0.9,
  max_completion_tokens = 100
)

# With conversation history
history <- list(
  list(role = "user", content = "My name is Alex"),
  list(role = "assistant", content = "Hello Alex! How can I help you?")
)
foundry_chat("What's my name?", model = "gpt-4", history = history)
} # }
```
