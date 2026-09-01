#' Check foundryR Setup
#'
#' Validates your Azure AI Foundry configuration and provides helpful
#' guidance if anything is missing or misconfigured.
#'
#' @param model Character. Optional deployment name to test. If provided,
#'   will make a test API call to verify the deployment works.
#' @param verbose Logical. If TRUE (default), prints detailed status messages.
#'
#' @return Invisibly returns a list with configuration status:
#'   \describe{
#'     \item{endpoint}{The configured endpoint URL, or NA if not set.}
#'     \item{key_set}{Logical. TRUE if an API key is configured.}
#'     \item{token_set}{Logical. TRUE if a bearer token is configured.}
#'     \item{model_tested}{The deployment name tested, or NA if none.}
#'     \item{api_ok}{Logical. TRUE if the API test succeeded, NA if not tested.}
#'     \item{all_ok}{Logical. TRUE if all checks passed.}
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Check basic configuration
#' foundry_check_setup()
#'
#' # Also test a specific deployment
#' foundry_check_setup(model = "my-gpt4")
#' }
foundry_check_setup <- function(model = NULL, verbose = TRUE) {

  results <- list(
    endpoint = NA_character_,
    project_endpoint = NA_character_,
    key_set = FALSE,
    token_set = FALSE,
    token_provider_set = FALSE,
    model_tested = NA_character_,
    api_ok = NA,
    all_ok = FALSE
  )

  if (verbose) {
    cli::cli_h1("foundryR Setup Check")
  }

  # Check endpoint
  endpoint <- foundry_get_endpoint()
  if (is.null(endpoint)) {
    if (verbose) {
      cli::cli_alert_danger("Endpoint not configured")
      cli::cli_bullets(c(
        "i" = "Set with: {.code foundry_set_endpoint(Sys.getenv(\"AZURE_FOUNDRY_ENDPOINT\"))}",
        "i" = "Or set {.envvar AZURE_FOUNDRY_ENDPOINT} to your endpoint URL"
      ))
    }
  } else {
    results$endpoint <- endpoint
    if (verbose) {
      cli::cli_alert_success("Endpoint: {.url {endpoint}}")
    }

    # Validate endpoint format
    if (!grepl("^https://", endpoint)) {
      if (verbose) {
        cli::cli_alert_warning("Endpoint should start with https://")
      }
    }
    if (grepl("/openai", endpoint)) {
      if (verbose) {
        cli::cli_alert_warning("Endpoint should not include '/openai' path - just the base URL")
      }
    }
  }

  project_endpoint <- foundry_get_project_endpoint()
  if (!is.null(project_endpoint)) {
    results$project_endpoint <- project_endpoint
    if (verbose) {
      cli::cli_alert_success("Project endpoint: {.url {results$project_endpoint}}")
    }
  } else if (verbose) {
    cli::cli_alert_info("No project endpoint set")
  }

  # Check authentication
  key <- foundry_get_key()
  token <- foundry_get_token()
  provider <- foundry_get_token_provider("resource")
  results$token_provider_set <- !is.null(provider)
  if (is.null(key) && is.null(token) && is.null(provider)) {
    if (verbose) {
      cli::cli_alert_danger("Authentication not configured")
      cli::cli_bullets(c(
        "i" = "Set with: {.code foundry_set_key(\"your-api-key\")}",
        "i" = "For keyless auth, set with: {.code foundry_set_token(\"your-token\")}",
        "i" = "For refreshable keyless auth, set with: {.code foundry_set_token_provider(foundry_token_azure_cli())}",
        "i" = "Or set environment variable: {.envvar AZURE_FOUNDRY_KEY}",
        "i" = "Find your key in Azure Portal > Your Resource > Keys and Endpoint"
      ))
    }
  } else {
    if (!is.null(key)) {
      results$key_set <- TRUE
      masked <- paste0(substr(key, 1, 4), "...", substr(key, nchar(key) - 3, nchar(key)))
      if (verbose) {
      cli::cli_alert_success("API key: {masked}")
      }
    }
    if (!is.null(token)) {
      results$token_set <- TRUE
      if (verbose) cli::cli_alert_success("Bearer token: configured")
    }
    if (!is.null(provider)) {
      if (verbose) cli::cli_alert_success("Token provider: configured")
    }
  }

  # Check default models (optional)
  if (verbose) {
    cli::cli_h2("Default Models (Optional)")
  }

  default_model <- Sys.getenv("AZURE_FOUNDRY_MODEL")
  if (default_model == "") {
    if (verbose) {
      cli::cli_alert_info("No default chat model set")
      cli::cli_bullets(c(
        "i" = "Set {.envvar AZURE_FOUNDRY_MODEL} to avoid specifying {.arg model} each time",
        "i" = "Use {.code foundry_models()} to list deployments available through the v1 API"
      ))
    }
  } else {
    if (verbose) {
      cli::cli_alert_success("Default chat model: {.val {default_model}}")
    }
  }

  default_embed <- Sys.getenv("AZURE_FOUNDRY_EMBED_MODEL")
  if (default_embed == "") {
    if (verbose) {
      cli::cli_alert_info("No default embedding model set")
      cli::cli_bullets(c(
        "i" = "Set {.envvar AZURE_FOUNDRY_EMBED_MODEL} for embedding defaults"
      ))
    }
  } else {
    if (verbose) {
      cli::cli_alert_success("Default embedding model: {.val {default_embed}}")
    }
  }

  # API version
  api_version <- Sys.getenv("AZURE_FOUNDRY_API_VERSION", "2024-10-21")
  if (verbose) {
    cli::cli_alert_info("API version: {.val {api_version}}")
  }

  # Test API call if model provided and config is complete
  auth_ok <- results$key_set || results$token_set || results$token_provider_set
  if (!is.null(model) && auth_ok && !is.na(results$endpoint)) {
    if (verbose) {
      cli::cli_h2("API Connection Test")
      cli::cli_alert_info("Testing deployment: {.val {model}}")
    }

    results$model_tested <- model

    test_result <- tryCatch({
      resp <- foundry_chat(
        message = "Say 'ok' and nothing else.",
        model = model,
        max_completion_tokens = 5
      )
      TRUE
    }, error = function(e) {
      if (verbose) {
        cli::cli_alert_danger("API test failed: {conditionMessage(e)}")
      }
      FALSE
    })

    results$api_ok <- test_result

    if (test_result && verbose) {
      cli::cli_alert_success("API connection successful!")
    }
  } else if (!is.null(model) && verbose) {
    cli::cli_alert_warning("Cannot test API - endpoint or key not configured")
  }

  # Summary
  results$all_ok <- auth_ok &&
    !is.na(results$endpoint) &&
    (is.na(results$api_ok) || isTRUE(results$api_ok))

  if (verbose) {
    cli::cli_h2("Summary")
    if (results$all_ok) {
      cli::cli_alert_success("Configuration looks good! You're ready to use foundryR.")
    } else {
      cli::cli_alert_warning("Some configuration is missing. See messages above.")
    }
  }

  invisible(results)
}
