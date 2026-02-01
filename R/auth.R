#' Set Azure AI Foundry API Key
#'
#' Set or update your Azure AI Foundry API key for authentication.
#' The key can be obtained from the Azure Portal under your Azure OpenAI resource.
#'
#' @param key Character string containing your API key, or NULL to set interactively.
#'   If NULL in an interactive session, will prompt for input.
#' @param store Logical. If TRUE, stores the key in `.Renviron` for future sessions.
#'   Default: FALSE (key only available for current session).
#'
#' @return Invisibly returns TRUE if key was set successfully.
#' @export
#'
#' @examples
#' \dontrun{
#' # Set key for current session only
#' foundry_set_key("your-api-key-here")
#'
#' # Set key interactively and store permanently
#' foundry_set_key(store = TRUE)
#' }
foundry_set_key <- function(key = NULL, store = FALSE) {

  # Interactive input if key is NULL
  if (is.null(key)) {
    if (!interactive()) {
      cli::cli_abort("API key must be provided in non-interactive sessions.")
    }
    key <- readline(prompt = "Enter your Azure AI Foundry API key: ")
    key <- trimws(key)
  }

  if (key == "" || is.na(key)) {
    cli::cli_abort("API key cannot be empty.")
  }

  # Set for current session
  Sys.setenv(AZURE_FOUNDRY_KEY = key)
  cli::cli_alert_success("API key set for current session.")

  # Optionally persist to .Renviron
  if (store) {
    renviron_path <- file.path(Sys.getenv("HOME"), ".Renviron")

    # Read existing .Renviron if it exists
    if (file.exists(renviron_path)) {
      renviron_lines <- readLines(renviron_path, warn = FALSE)
      # Remove any existing AZURE_FOUNDRY_KEY line
      renviron_lines <- renviron_lines[!grepl("^AZURE_FOUNDRY_KEY=", renviron_lines)]
    } else {
      renviron_lines <- character()
    }

    # Add new key
    renviron_lines <- c(renviron_lines, paste0("AZURE_FOUNDRY_KEY=", key))

    # Write back
    writeLines(renviron_lines, renviron_path)
    cli::cli_alert_success("API key stored in {.file {renviron_path}}")
  }

  invisible(TRUE)
}


#' Get Azure AI Foundry API Key
#'
#' Retrieve the API key from the environment or a provided value.
#' This is primarily an internal function used by other foundryR functions.
#'
#' @param key Character. Optional key to use instead of environment variable.
#' @param required Logical. If TRUE, throws an error when no key is found.
#'
#' @return The API key string, or NULL if not found and not required.
#' @keywords internal
#'
#' @importFrom rlang %||%
foundry_get_key <- function(key = NULL, required = FALSE) {
  if (is.null(key)) {
    key <- Sys.getenv("AZURE_FOUNDRY_KEY")
    if (key == "") key <- NULL
  }

  if (required && is.null(key)) {
    cli::cli_abort(c(
      "Azure AI Foundry API key is required.",
      "i" = "Set one with {.code foundry_set_key()} or set the {.envvar AZURE_FOUNDRY_KEY} environment variable."
    ))
  }

  key
}
