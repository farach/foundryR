#' Choose the endpoint for APIs that run on a resource or a project
#'
#' @description
#' Microsoft Foundry serves some OpenAI-compatible APIs from two places: the
#' resource endpoint (for example `https://<resource>.openai.azure.com`) and a
#' project endpoint
#' (`https://<resource>.services.ai.azure.com/api/projects/<project>`).
#' Responses, files, vector stores, and evaluations work on both. foundryR sends
#' them to the resource endpoint unless you ask for the project, so code written
#' for foundryR 0.1.0 keeps working.
#'
#' `foundry_set_route("project")` sends those calls to the project endpoint set
#' with [foundry_set_project_endpoint()] for the rest of the R session. A call's
#' own `endpoint` or `project_endpoint` argument always wins over the session
#' route.
#'
#' @details
#' Some calls use the project endpoint whatever the session route is, because
#' the feature exists only there: conversations and server-side agents always
#' do, and [foundry_evaluate()] does when a run uses built-in evaluators, an
#' agent target, or stored responses. It prints a message when it switches.
#'
#' Objects created on one endpoint are not always visible from the other. Look
#' a file, vector store, or evaluation up on the endpoint where you created it.
#'
#' Project endpoints accept Microsoft Entra ID tokens, not API keys. See
#' [foundry_token_azure_cli()], [foundry_token_azure_identity()], and
#' [foundry_set_token()] with `scope = "project"`.
#'
#' @param route Character. `"resource"` (the default) or `"project"`.
#'
#' @return The previous route, invisibly, so you can restore it.
#' @export
#'
#' @examples
#' old <- foundry_set_route("project")
#' foundry_set_route(old)
foundry_set_route <- function(route = c("resource", "project")) {
  route <- match.arg(route)
  old <- foundry_state$route %||% "resource"
  foundry_state$route <- route
  if (identical(route, "project") &&
      is.null(foundry_get_project_endpoint(required = FALSE))) {
    cli::cli_warn(c(
      "The session route is now {.val project}, but no project endpoint is set.",
      "i" = "Set one with {.fn foundry_set_project_endpoint}."
    ))
  }
  cli::cli_inform(
    "Responses, files, vector stores, and evaluations now use the {route} endpoint."
  )
  invisible(old)
}


# Which endpoints each API family can use. Families with one entry always use
# that endpoint.
foundry_route_families <- list(
  responses = c("resource", "project"),
  files = c("resource", "project"),
  vector_stores = c("resource", "project"),
  evals = c("resource", "project"),
  conversations = "project",
  agents = "project"
)

foundry_route_labels <- c(
  responses = "Responses",
  files = "Files",
  vector_stores = "Vector stores",
  evals = "Evaluations",
  conversations = "Conversations",
  agents = "Agents"
)


foundry_is_project_url <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x) &&
    grepl("/api/projects/", x, fixed = TRUE)
}


# Resolve the endpoint for one call. Explicit arguments win, then a feature that
# exists only on the project endpoint (`needs_project` names it), then the
# family's only route, then the session route from foundry_set_route().
foundry_resolve_route <- function(family,
                                  endpoint = NULL,
                                  project_endpoint = NULL,
                                  needs_project = NULL) {
  allowed <- foundry_route_families[[family]]
  label <- foundry_route_labels[[family]]
  if (is.null(allowed)) {
    cli::cli_abort("Unknown route family {.val {family}}.", .internal = TRUE)
  }
  if (!is.null(endpoint) && !is.null(project_endpoint)) {
    cli::cli_abort("Supply only one of {.arg endpoint} or {.arg project_endpoint}.")
  }
  if (foundry_is_project_url(endpoint)) {
    project_endpoint <- endpoint
    endpoint <- NULL
  }

  if (!is.null(project_endpoint)) {
    foundry_check_character_scalar(project_endpoint, "project_endpoint")
    return(list(
      route = "project",
      endpoint = NULL,
      project_endpoint = sub("/+$", "", project_endpoint)
    ))
  }

  if (!is.null(endpoint)) {
    if (!"resource" %in% allowed) {
      cli::cli_abort(c(
        "{label} are only available on a Foundry project endpoint.",
        "i" = "Pass {.arg project_endpoint}, or set one with {.fn foundry_set_project_endpoint}."
      ))
    }
    if (!is.null(needs_project)) {
      cli::cli_abort(c(
        "This call uses {needs_project}, available only on a Foundry project endpoint.",
        "i" = "Pass {.arg project_endpoint} instead of {.arg endpoint}."
      ))
    }
    return(list(route = "resource", endpoint = endpoint, project_endpoint = NULL))
  }

  project_only <- !"resource" %in% allowed
  session_project <- identical(foundry_state$route, "project")
  if (is.null(needs_project) && !project_only && !session_project) {
    return(list(route = "resource", endpoint = NULL, project_endpoint = NULL))
  }

  configured <- foundry_get_project_endpoint(required = FALSE)
  if (is.null(configured)) {
    reason <- if (!is.null(needs_project)) {
      "This call uses {needs_project}, available only on a Foundry project endpoint."
    } else if (project_only) {
      "{label} are only available on a Foundry project endpoint."
    } else {
      "The session route is {.val project} (see {.fn foundry_set_route})."
    }
    cli::cli_abort(c(
      reason,
      "i" = "Set one with {.fn foundry_set_project_endpoint} or pass {.arg project_endpoint}."
    ))
  }
  list(route = "project", endpoint = NULL, project_endpoint = configured)
}


# Build a request for an OpenAI v1 path on whichever endpoint the route selects.
foundry_build_routed_request <- function(family,
                                         path,
                                         body = NULL,
                                         method = "POST",
                                         api_key = NULL,
                                         token = NULL,
                                         endpoint = NULL,
                                         project_endpoint = NULL,
                                         api_version = NULL,
                                         needs_project = NULL,
                                         route = NULL) {
  route <- route %||% foundry_resolve_route(
    family,
    endpoint = endpoint,
    project_endpoint = project_endpoint,
    needs_project = needs_project
  )
  path <- sub("^/+", "", path)

  if (identical(route$route, "project")) {
    return(foundry_build_project_request(
      path = paste0("openai/v1/", path),
      body = body,
      method = method,
      api_key = api_key,
      token = token,
      endpoint = route$project_endpoint,
      api_version = api_version
    ))
  }

  foundry_build_v1_request(
    path = path,
    body = body,
    method = method,
    api_key = api_key,
    token = token,
    endpoint = route$endpoint,
    api_version = api_version
  )
}


# A JSON object with no members. `list()` serializes to `[]`, which the service
# rejects where it expects an object.
foundry_json_object <- function() {
  stats::setNames(list(), character())
}
