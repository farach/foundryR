#' Create a Microsoft Entra ID token provider using AzureAuth
#'
#' Create a provider function for [foundry_set_token_provider()] that acquires
#' Microsoft Entra ID access tokens through the \pkg{AzureAuth} package. This
#' supports service principals (client secret or certificate), managed identity,
#' and interactive or device-code flows, and refreshes tokens automatically as
#' they approach expiry.
#'
#' The token is acquired lazily on first use, so building the provider never
#' triggers a network call. Tokens are re-acquired within five minutes of
#' expiry; \pkg{AzureAuth} reuses its on-disk cache and refresh tokens under the
#' hood, so re-acquisition is inexpensive and does not re-prompt for interactive
#' flows.
#'
#' @param resource Character. The token audience. Defaults to
#'   `"https://ai.azure.com"`, the canonical Azure AI Foundry data-plane
#'   audience. Pass `"https://cognitiveservices.azure.com"` for legacy Cognitive
#'   Services resources.
#' @param tenant Character. Microsoft Entra ID tenant. Defaults to the
#'   `AZURE_TENANT_ID` environment variable. Ignored when
#'   `managed_identity = TRUE`.
#' @param app Character. Application (client) ID. Defaults to the
#'   `AZURE_CLIENT_ID` environment variable. Ignored when
#'   `managed_identity = TRUE`.
#' @param password Character or `NULL`. Client secret for a service principal, or
#'   the resource-owner password. `NULL` selects an interactive or device-code
#'   flow.
#' @param username Character or `NULL`. Username for the resource-owner flow.
#' @param certificate Character or `NULL`. Path to, or contents of, a certificate
#'   for certificate-based service-principal authentication.
#' @param auth_type Character or `NULL`. Explicit \pkg{AzureAuth} authentication
#'   type. `NULL` lets \pkg{AzureAuth} choose based on the other arguments.
#' @param managed_identity Logical. If `TRUE`, acquire a token from an Azure
#'   managed identity via [AzureAuth::get_managed_token()] and ignore `tenant`
#'   and `app`. Default `FALSE`.
#' @param version Integer. Microsoft Entra ID endpoint version, `1` or `2`.
#'   Default `1`, matching the resource-style `resource` above.
#' @param ... Additional arguments passed to [AzureAuth::get_azure_token()] or
#'   [AzureAuth::get_managed_token()].
#'
#' @return A zero-argument token provider function suitable for
#'   [foundry_set_token_provider()].
#' @export
#'
#' @seealso [foundry_token_azure_cli()] for a provider that shells out to the
#'   Azure CLI instead.
#'
#' @examples
#' \dontrun{
#' # Service principal with a client secret
#' foundry_set_token_provider(
#'   foundry_token_azure_identity(
#'     tenant = "your-tenant-id",
#'     app = "your-client-id",
#'     password = Sys.getenv("AZURE_CLIENT_SECRET")
#'   )
#' )
#'
#' # Managed identity inside Azure
#' foundry_set_token_provider(
#'   foundry_token_azure_identity(managed_identity = TRUE)
#' )
#' }
foundry_token_azure_identity <- function(resource = "https://ai.azure.com",
                                         tenant = Sys.getenv("AZURE_TENANT_ID"),
                                         app = Sys.getenv("AZURE_CLIENT_ID"),
                                         password = NULL,
                                         username = NULL,
                                         certificate = NULL,
                                         auth_type = NULL,
                                         managed_identity = FALSE,
                                         version = 1,
                                         ...) {
  foundry_check_character_scalar(resource, "resource")
  if (!is.logical(managed_identity) || length(managed_identity) != 1L ||
      is.na(managed_identity)) {
    cli::cli_abort("{.arg managed_identity} must be a single {.code TRUE} or {.code FALSE}.")
  }

  dots <- list(...)

  acquire <- function() {
    if (managed_identity) {
      return(do.call(
        foundry_azure_get_managed_token,
        c(list(resource = resource), dots)
      ))
    }

    if (!nzchar(tenant)) {
      cli::cli_abort(c(
        "{.arg tenant} is required for Entra ID authentication.",
        "i" = "Pass {.arg tenant} or set the {.envvar AZURE_TENANT_ID} environment variable."
      ))
    }
    if (!nzchar(app)) {
      cli::cli_abort(c(
        "{.arg app} is required for Entra ID authentication.",
        "i" = "Pass {.arg app} or set the {.envvar AZURE_CLIENT_ID} environment variable."
      ))
    }

    args <- list(
      resource = resource,
      tenant = tenant,
      app = app,
      password = password,
      username = username,
      certificate = certificate,
      auth_type = auth_type,
      version = version
    )
    args <- args[!vapply(args, is.null, logical(1))]
    do.call(foundry_azure_get_token, c(args, dots))
  }

  cache <- new.env(parent = emptyenv())
  cache$token <- NULL

  function() {
    token <- cache$token

    if (!is.null(token)) {
      expiry <- foundry_parse_token_expiry(token$credentials$expires_on)
      if (!is.na(expiry) && Sys.time() >= expiry - 300) {
        token <- NULL
      }
    }

    if (is.null(token)) {
      token <- acquire()
      cache$token <- token
    }

    access <- token$credentials$access_token
    if (is.null(access) || !is.character(access) || length(access) != 1L ||
        !nzchar(access)) {
      cli::cli_abort("Entra ID token acquisition did not return an access token.")
    }

    access
  }
}


# Internal indirection over AzureAuth so the token provider can be unit tested
# with mocked bindings. Both wrappers require the Suggests-only AzureAuth package.
foundry_azure_get_token <- function(...) {
  foundry_require_azureauth()
  AzureAuth::get_azure_token(...)
}


foundry_azure_get_managed_token <- function(...) {
  foundry_require_azureauth()
  AzureAuth::get_managed_token(...)
}


foundry_require_azureauth <- function() {
  if (!requireNamespace("AzureAuth", quietly = TRUE)) {
    cli::cli_abort(c(
      "The {.pkg AzureAuth} package is required for Entra ID token acquisition.",
      "i" = 'Install it with {.code install.packages("AzureAuth")}.'
    ))
  }
  invisible(TRUE)
}
