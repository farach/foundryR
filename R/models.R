#' List Available Models/Deployments
#'
#' Retrieve information about models deployed in your Azure AI Foundry resource.
#'
#' Note: Azure AI Foundry doesn't have a direct "list deployments" API endpoint
#' in the same way that Hugging Face does. This function provides a placeholder
#' that can be extended when such an API becomes available, or can be used to
#' validate a specific deployment exists.
#'
#' @param model Character. Optional. A specific deployment name to check.
#' @param api_key Character. Optional API key override.
#' @param api_version Character. Optional API version override.
#'
#' @return A tibble with deployment information, or a message about available
#'   functionality.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Check if a deployment exists by making a minimal request
#' foundry_models("gpt-4")
#' }
foundry_models <- function(model = NULL,
                            api_key = NULL,
                            api_version = NULL) {

  if (is.null(model)) {
    cli::cli_inform(c(
      "i" = "Azure AI Foundry doesn't provide a list-deployments API.",
      "i" = "Deployments are managed in the Azure Portal.",
      "i" = "Use {.code foundry_models(\"deployment-name\")} to verify a specific deployment."
    ))

    return(tibble::tibble(
      deployment = character(),
      status = character(),
      message = character()
    ))
  }

  # Try to validate the deployment with a minimal chat request
  tryCatch({
    body <- list(
      messages = list(list(role = "user", content = "Hi")),
      max_tokens = 1
    )

    req <- foundry_build_request(
      deployment = model,
      endpoint_path = "chat/completions",
      body = body,
      api_key = api_key,
      api_version = api_version
    )

    result <- foundry_perform(req)

    tibble::tibble(
      deployment = model,
      status = "available",
      message = "Deployment is accessible and responding.",
      model_id = result$model %||% NA_character_
    )

  }, error = function(e) {
    msg <- conditionMessage(e)

    # Check if it's a "not found" vs other error
    if (grepl("not found|404", msg, ignore.case = TRUE)) {
      tibble::tibble(
        deployment = model,
        status = "not_found",
        message = "Deployment not found. Check the name in Azure Portal.",
        model_id = NA_character_
      )
    } else {
      tibble::tibble(
        deployment = model,
        status = "error",
        message = msg,
        model_id = NA_character_
      )
    }
  })
}
