#' Set Azure AI Foundry Endpoint
#'
#' Set the base endpoint URL for your Azure AI Foundry resource.
#'
#' @param endpoint Character string containing the endpoint URL.
#'   Example: the endpoint URL from your Foundry resource.
#' @param store Logical. If TRUE, stores the endpoint in `.Renviron` for future sessions.
#'   Default: FALSE (endpoint only available for current session).
#'
#' @return Invisibly returns TRUE if endpoint was set successfully.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_set_endpoint("AZURE_FOUNDRY_ENDPOINT")
#'
#' # Store permanently
#' foundry_set_endpoint("AZURE_FOUNDRY_ENDPOINT", store = TRUE)
#' }
foundry_set_endpoint <- function(endpoint, store = FALSE) {

  if (missing(endpoint) || is.null(endpoint) || endpoint == "") {
    cli::cli_abort("Endpoint URL is required.")
  }

  # Remove trailing slash if present
  endpoint <- sub("/$", "", endpoint)

  # Set for current session
  Sys.setenv(AZURE_FOUNDRY_ENDPOINT = endpoint)
  cli::cli_alert_success("Endpoint set to {.url {endpoint}}")

  # Optionally persist to .Renviron
  if (store) {
    renviron_path <- file.path(Sys.getenv("HOME"), ".Renviron")

    if (file.exists(renviron_path)) {
      renviron_lines <- readLines(renviron_path, warn = FALSE)
      renviron_lines <- renviron_lines[!grepl("^AZURE_FOUNDRY_ENDPOINT=", renviron_lines)]
    } else {
      renviron_lines <- character()
    }

    renviron_lines <- c(renviron_lines, paste0("AZURE_FOUNDRY_ENDPOINT=", endpoint))
    writeLines(renviron_lines, renviron_path)
    cli::cli_alert_success("Endpoint stored in {.file {renviron_path}}")
  }

  invisible(TRUE)
}


#' Get Azure AI Foundry Endpoint
#'
#' Retrieve the endpoint URL from the environment or a provided value.
#'
#' @param endpoint Character. Optional endpoint to use instead of environment variable.
#' @param required Logical. If TRUE, throws an error when no endpoint is found.
#'
#' @return The endpoint URL string, or NULL if not found and not required.
#' @export
#'
#' @examples
#' \dontrun{
#' # Get current endpoint
#' foundry_get_endpoint()
#' }
foundry_get_endpoint <- function(endpoint = NULL, required = FALSE) {
  if (is.null(endpoint)) {
    endpoint <- Sys.getenv("AZURE_FOUNDRY_ENDPOINT")
    if (endpoint == "") endpoint <- NULL
  }

  # Remove trailing slash if present
  if (!is.null(endpoint)) {
    endpoint <- sub("/$", "", endpoint)
  }

  if (required && is.null(endpoint)) {
    cli::cli_abort(c(
      "Azure AI Foundry endpoint is required.",
      "i" = "Set one with {.code foundry_set_endpoint()} or set the {.envvar AZURE_FOUNDRY_ENDPOINT} environment variable."
    ))
  }

  endpoint
}


#' Get API Version
#'
#' Retrieve the API version to use for requests.
#'
#' @param api_version Character. Optional version to use instead of default.
#'
#' @return The API version string.
#' @keywords internal
foundry_get_api_version <- function(api_version = NULL) {
  if (is.null(api_version)) {
    api_version <- Sys.getenv("AZURE_FOUNDRY_API_VERSION", "2024-10-21")
    if (!nzchar(api_version)) api_version <- "2024-10-21"
  }
  api_version
}
