#' Chat with an Azure AI Model
#'
#' Send a message to an Azure AI Foundry deployed model and receive a response.
#' Returns a tibble with the assistant's response and usage metadata.
#'
#' @param message Character. The user message to send.
#' @param system Character. Optional system prompt to set the assistant's behavior.
#' @param model Character. The deployment name. Defaults to the environment variable
#'   `AZURE_FOUNDRY_MODEL` or must be specified.
#' @param history List. Optional conversation history as a list of message objects,
#'   each with `role` and `content` fields.
#' @param temperature Numeric. Sampling temperature between 0 and 2. Higher values
#'   make output more random, lower values more deterministic. Default: 1.
#' @param max_tokens Integer. Maximum tokens in response (legacy parameter, use
#'   `max_completion_tokens` for newer models).
#' @param max_completion_tokens Integer. Maximum tokens in response. Preferred
#'   parameter for newer models (gpt-4o, etc.). Takes precedence over `max_tokens`.
#' @param top_p Numeric. Nucleus sampling parameter between 0 and 1. Default: 1.
#' @param frequency_penalty Numeric. Penalty for token frequency (-2.0 to 2.0). Default: 0.
#' @param presence_penalty Numeric. Penalty for token presence (-2.0 to 2.0). Default: 0.
#' @param stop Character vector. Up to 4 sequences where the API will stop generating.
#' @param reasoning_effort Character. Optional reasoning effort (`"low"`,
#'   `"medium"`, or `"high"`) for reasoning models that accept this control.
#' @param api_key Character. Optional API key override.
#' @param api_version Character. Optional API version override.
#' @param ... Additional parameters passed to the API.
#'
#' @return A tibble with columns:
#'   \describe{
#'     \item{role}{Character. Always "assistant".}
#'     \item{content}{Character. The generated response text.}
#'     \item{model}{Character. The deployment/model name used.}
#'     \item{finish_reason}{Character. Why generation stopped: "stop", "length", etc.}
#'     \item{prompt_tokens}{Integer. Tokens in the prompt.}
#'     \item{completion_tokens}{Integer. Tokens in the response.}
#'     \item{reasoning_tokens}{Integer. Hidden reasoning tokens, when reported.}
#'     \item{cached_input_tokens}{Integer. Cached prompt tokens, when reported.}
#'     \item{total_tokens}{Integer. Total tokens used.}
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Simple chat
#' foundry_chat("What is the capital of France?", model = "gpt-4")
#'
#' # With system prompt
#' foundry_chat(
#'   "Explain tibbles",
#'   system = "You are a helpful R programming tutor. Be concise.",
#'   model = "gpt-4"
#' )
#'
#' # With parameters (use max_completion_tokens for newer models)
#' foundry_chat(
#'   "Write a haiku about data science",
#'   model = "gpt-4",
#'   temperature = 0.9,
#'   max_completion_tokens = 100
#' )
#'
#' # With conversation history
#' history <- list(
#'   list(role = "user", content = "My name is Alex"),
#'   list(role = "assistant", content = "Hello Alex! How can I help you?")
#' )
#' foundry_chat("What's my name?", model = "gpt-4", history = history)
#' }
foundry_chat <- function(message,
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
                          reasoning_effort = NULL,
                          api_key = NULL,
                          api_version = NULL,
                          ...) {

  # Get model/deployment
  if (is.null(model)) {
    model <- Sys.getenv("AZURE_FOUNDRY_MODEL")
    if (model == "") {
      cli::cli_abort(c(
        "Model/deployment name is required.",
        "i" = "Specify {.arg model} or set the {.envvar AZURE_FOUNDRY_MODEL} environment variable."
      ))
    }
  }

  # Validate message
  if (missing(message) || is.null(message) || !is.character(message)) {
    cli::cli_abort("{.arg message} must be a non-empty character string.")
  }

  # Build messages array
  messages <- list()

  # Add system message if provided
  if (!is.null(system)) {
    messages <- c(messages, list(list(role = "system", content = system)))
  }

  # Add history if provided
  if (!is.null(history)) {
    if (!is.list(history)) {
      cli::cli_abort("{.arg history} must be a list of message objects.")
    }
    messages <- c(messages, history)
  }

  # Add current user message
  messages <- c(messages, list(list(role = "user", content = message)))

  # Build request body
  body <- list(messages = messages)

  # Add optional parameters
  if (!is.null(temperature)) body$temperature <- temperature

  # Handle max tokens - prefer max_completion_tokens for newer models
  if (!is.null(max_completion_tokens)) {
    body$max_completion_tokens <- max_completion_tokens
  } else if (!is.null(max_tokens)) {
    body$max_tokens <- max_tokens
  }

  if (!is.null(top_p)) body$top_p <- top_p
  if (!is.null(frequency_penalty)) body$frequency_penalty <- frequency_penalty
  if (!is.null(presence_penalty)) body$presence_penalty <- presence_penalty
  if (!is.null(stop)) body$stop <- stop
  if (!is.null(reasoning_effort)) {
    foundry_check_character_scalar(reasoning_effort, "reasoning_effort")
    body$reasoning_effort <- reasoning_effort
  }

  # Add any additional parameters
  dots <- list(...)
  if (length(dots) > 0) {
    body <- c(body, dots)
  }

  # Build and perform request
  req <- foundry_build_request(
    deployment = model,
    endpoint_path = "chat/completions",
    body = body,
    api_key = api_key,
    api_version = api_version
  )

  result <- foundry_perform(req)

  # Parse response into tibble
  foundry_parse_chat_response(result, model)
}


#' Parse Chat Completion Response
#'
#' Internal function to parse chat completion API response into a tibble.
#'
#' @param result List. The parsed JSON response.
#' @param model Character. The model/deployment name.
#'
#' @return A tibble with chat response data.
#' @keywords internal
foundry_parse_chat_response <- function(result, model) {
  choice <- result$choices[[1]]

  tibble::tibble(
    role = choice$message$role %||% "assistant",
    content = choice$message$content %||% "",
    model = result$model %||% model,
    finish_reason = choice$finish_reason %||% NA_character_,
    prompt_tokens = result$usage$prompt_tokens %||% NA_integer_,
    completion_tokens = result$usage$completion_tokens %||% NA_integer_,
    reasoning_tokens = result$usage$completion_tokens_details$reasoning_tokens %||% NA_integer_,
    cached_input_tokens = result$usage$prompt_tokens_details$cached_tokens %||% NA_integer_,
    total_tokens = result$usage$total_tokens %||% NA_integer_
  )
}
