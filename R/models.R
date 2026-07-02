#' List or retrieve available model deployments
#'
#' List model deployments available through the Microsoft Foundry v1 data-plane
#' API, or retrieve metadata for one deployment by name. Use the deployment name
#' shown in the Foundry portal as the `model` value in `foundry_response()` and
#' other v1 helpers.
#'
#' @param model Character. Optional deployment name to retrieve.
#' @param api_key Character. Optional API key override.
#' @param token Character. Optional bearer token override.
#' @param endpoint Character. Optional endpoint override.
#' @param api_version Character. Optional API version query value.
#'
#' @return A tibble with model or deployment metadata and the raw model object
#'   in a list-column.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_models()
#' foundry_models("gpt-5.5")
#' }
foundry_models <- function(model = NULL,
                           api_key = NULL,
                           token = NULL,
                           endpoint = NULL,
                           api_version = NULL) {
  path <- "models"
  if (!is.null(model)) {
    foundry_check_character_scalar(model, "model")
    path <- paste0("models/", model)
  }

  req <- foundry_build_v1_request(
    path = path,
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )

  result <- foundry_perform(req)
  foundry_parse_models(result)
}


foundry_parse_models <- function(result) {
  models <- result$data %||% list(result)
  if (length(models) == 0L) {
    return(tibble::tibble(
      id = character(),
      object = character(),
      created = as.POSIXct(character()),
      owned_by = character(),
      raw_model = list()
    ))
  }

  purrr::map_dfr(models, function(model) {
    tibble::tibble(
      id = model$id %||% NA_character_,
      object = model$object %||% NA_character_,
      created = foundry_response_created_at(model$created %||% NA_real_),
      owned_by = model$owned_by %||% NA_character_,
      raw_model = list(model)
    )
  })
}
