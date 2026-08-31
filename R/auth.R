#' Set Azure AI Foundry API Key
#'
#' Set or update your Azure AI Foundry API key for authentication.
#' The key can be obtained from the Azure Portal under your Azure OpenAI resource.
#'
#' @param key Character string containing your API key, or NULL to set interactively.
#'   If NULL in an interactive session, will prompt for input.
#' @param store Logical. If `TRUE`, stores the key in foundryR's
#'   package-specific user configuration file. Default: `FALSE`.
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

  if (store) {
    path <- foundry_store_setting("AZURE_FOUNDRY_KEY", key)
    cli::cli_alert_success("API key stored in {.file {path}}")
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
    if (key == "") {
      key <- foundry_get_stored_setting("AZURE_FOUNDRY_KEY")
    }
  }

  if (required && is.null(key)) {
    cli::cli_abort(c(
      "Azure AI Foundry API key is required.",
      "i" = "Set one with {.code foundry_set_key()} or set the {.envvar AZURE_FOUNDRY_KEY} environment variable."
    ))
  }

  key
}


#' Set Azure AI Foundry Bearer Token
#'
#' Set a Microsoft Entra ID bearer token for keyless authentication. API keys
#' remain supported, but Microsoft recommends keyless authentication for
#' production workloads.
#'
#' @param token Character string containing a bearer token. Do not include the
#'   `"Bearer "` prefix.
#' @param store Logical. If `TRUE`, stores the token in foundryR's
#'   package-specific user configuration file. Tokens expire, so persistent
#'   tokens are usually only useful for local testing.
#' @param scope Character. Endpoint family for the token: `"resource"` for
#'   resource-level `/openai/v1` and supported Content Safety operations, or
#'   `"project"` for `/api/projects/...` operations.
#'
#' @return Invisibly returns `TRUE` if the token was set successfully.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_set_token("eyJ0eXAiOiJKV1QiLCJhbGciOi...")
#' }
foundry_set_token <- function(token,
                              store = FALSE,
                              scope = c("resource", "project")) {
  scope <- match.arg(scope)
  if (missing(token) || is.null(token) || !is.character(token) ||
      length(token) != 1L || is.na(token) || token == "") {
    cli::cli_abort("Bearer token cannot be empty.")
  }

  token <- sub("^Bearer\\s+", "", token, ignore.case = TRUE)
  variable <- foundry_token_envvar(scope)
  do.call(Sys.setenv, stats::setNames(list(token), variable))
  cli::cli_alert_success("{scope} bearer token set for current session.")

  if (store) {
    path <- foundry_store_setting(variable, token)
    cli::cli_alert_success("{scope} bearer token stored in {.file {path}}")
  }

  invisible(TRUE)
}


#' Get Azure AI Foundry Bearer Token
#'
#' Retrieve a bearer token from the environment or a provided value.
#'
#' @param token Character. Optional token to use instead of environment
#'   variables.
#' @param required Logical. If `TRUE`, throws an error when no token is found.
#' @param scope Character. Endpoint family for the token.
#'
#' @return The bearer token string, or `NULL` if not found and not required.
#' @keywords internal
foundry_get_token <- function(token = NULL,
                              required = FALSE,
                              scope = c("resource", "project")) {
  scope <- match.arg(scope)
  if (is.null(token)) {
    variable <- foundry_token_envvar(scope)
    token <- Sys.getenv(variable)
    if (token == "" && identical(scope, "resource")) {
      token <- Sys.getenv("AZURE_OPENAI_TOKEN")
    }
    if (token == "") {
      token <- foundry_get_stored_setting(variable)
    }
  }

  if (!is.null(token)) {
    token <- sub("^Bearer\\s+", "", token, ignore.case = TRUE)
  }

  if (required && is.null(token)) {
    cli::cli_abort(c(
      "Azure AI Foundry bearer token is required.",
      "i" = "Set one with {.code foundry_set_token(scope = \"{scope}\")} or set the matching token environment variable."
    ))
  }

  token
}


foundry_auth_state <- new.env(parent = emptyenv())
foundry_auth_state$token_providers <- list(resource = NULL, project = NULL)


#' Set a Microsoft Entra ID token provider
#'
#' Register a function that returns a Microsoft Entra ID bearer token when
#' foundryR needs to authenticate without an API key. This is useful for long
#' polling jobs and keyless production environments where tokens should be
#' refreshed automatically.
#'
#' @param provider Function or `NULL`. A zero-argument function that returns a
#'   bearer token string. Use `NULL` to clear the provider.
#' @param scope Character. Endpoint family that the provider authenticates:
#'   `"resource"` or `"project"`.
#'
#' @return Invisibly returns the previous provider.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_set_token_provider(foundry_token_azure_cli())
#' }
foundry_set_token_provider <- function(provider,
                                       scope = c("resource", "project")) {
  scope <- match.arg(scope)
  if (!is.null(provider) && !is.function(provider)) {
    cli::cli_abort("{.arg provider} must be a function or NULL.")
  }

  old <- foundry_auth_state$token_providers[[scope]]
  foundry_auth_state$token_providers[[scope]] <- provider
  invisible(old)
}


foundry_get_token_provider <- function(scope = c("resource", "project")) {
  scope <- match.arg(scope)
  foundry_auth_state$token_providers[[scope]]
}


foundry_token_from_provider <- function(required = FALSE,
                                        scope = c("resource", "project")) {
  scope <- match.arg(scope)
  provider <- foundry_get_token_provider(scope)
  if (is.null(provider)) {
    if (required) {
      cli::cli_abort("No {scope} Azure AI Foundry token provider is configured.")
    }
    return(NULL)
  }

  token <- provider()
  if (is.null(token) || !is.character(token) || length(token) != 1L ||
      is.na(token) || token == "") {
    cli::cli_abort("The configured token provider did not return a token string.")
  }

  sub("^Bearer\\s+", "", token, ignore.case = TRUE)
}


#' Create an Azure CLI token provider
#'
#' Create a provider function for `foundry_set_token_provider()` that shells out
#' to `az account get-access-token`. Tokens are cached until five minutes before
#' expiry.
#'
#' @param resource Character. Azure resource used for the access token. Defaults
#'   to `"https://cognitiveservices.azure.com"` for resource-level v1 and
#'   Content Safety APIs. Use `"https://ai.azure.com"` for project APIs and
#'   register that provider with `scope = "project"`.
#' @param az Character. Azure CLI executable name or path.
#'
#' @return A zero-argument token provider function.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_set_token_provider(
#'   foundry_token_azure_cli("https://ai.azure.com"),
#'   scope = "project"
#' )
#' }
foundry_token_azure_cli <- function(resource = "https://cognitiveservices.azure.com",
                                    az = "az") {
  foundry_check_character_scalar(resource, "resource")
  foundry_check_character_scalar(az, "az")

  cache <- new.env(parent = emptyenv())
  cache$token <- NULL
  cache$expires_at <- as.POSIXct(NA_real_, origin = "1970-01-01", tz = "UTC")

  function() {
    now <- Sys.time()
    if (!is.null(cache$token) && !is.na(cache$expires_at) &&
        now < cache$expires_at - 300) {
      return(cache$token)
    }

    output <- tryCatch(
      system2(
        az,
        c("account", "get-access-token", "--resource", resource, "--output", "json"),
        stdout = TRUE,
        stderr = TRUE
      ),
      error = function(e) {
        cli::cli_abort(c(
          "Failed to run Azure CLI.",
          "x" = conditionMessage(e),
          "i" = "Install the Azure CLI and run {.code az login}, or use another token provider."
        ))
      }
    )

    status <- attr(output, "status", exact = TRUE)
    if (!is.null(status) && !identical(status, 0L)) {
      cli::cli_abort(c(
        "Azure CLI failed to get an access token.",
        "x" = paste(output, collapse = "\n")
      ))
    }

    parsed <- tryCatch(
      jsonlite::fromJSON(paste(output, collapse = "\n"), simplifyVector = FALSE),
      error = function(e) {
        cli::cli_abort(c(
          "Azure CLI returned invalid JSON.",
          "x" = conditionMessage(e)
        ))
      }
    )

    token <- parsed$accessToken %||% parsed$access_token
    expires_on <- parsed$expires_on %||% parsed$expiresOn
    if (is.null(token) || token == "") {
      cli::cli_abort("Azure CLI response did not include an access token.")
    }

    cache$token <- token
    cache$expires_at <- foundry_parse_token_expiry(expires_on)
    cache$token
  }
}


foundry_token_envvar <- function(scope = c("resource", "project")) {
  scope <- match.arg(scope)
  if (identical(scope, "project")) {
    "AZURE_FOUNDRY_PROJECT_TOKEN"
  } else {
    "AZURE_FOUNDRY_TOKEN"
  }
}


foundry_parse_token_expiry <- function(expires_on) {
  if (is.null(expires_on) || length(expires_on) != 1L || is.na(expires_on)) {
    return(Sys.time() + 55 * 60)
  }

  if (is.numeric(expires_on)) {
    return(as.POSIXct(expires_on, origin = "1970-01-01", tz = "UTC"))
  }

  numeric_expiry <- suppressWarnings(as.numeric(expires_on))
  if (!is.na(numeric_expiry)) {
    return(as.POSIXct(numeric_expiry, origin = "1970-01-01", tz = "UTC"))
  }

  parsed <- suppressWarnings(as.POSIXct(expires_on, tz = "UTC"))
  if (is.na(parsed)) {
    Sys.time() + 55 * 60
  } else {
    parsed
  }
}
