#' Reference a Foundry agent from the Responses API
#'
#' Build the `agent_reference` object used to run a stored Azure AI Foundry
#' agent through [foundry_response()]. Pass the resulting object (or simply the
#' agent name) to the `agent` argument of `foundry_response()`.
#'
#' @param name Character. The agent name.
#' @param version Character. Optional version identifier. Omit to use the latest
#'   version.
#'
#' @return A named list describing an `agent_reference`.
#' @export
#'
#' @examples
#' foundry_agent_reference("my-agent")
#' foundry_agent_reference("my-agent", version = "2")
foundry_agent_reference <- function(name, version = NULL) {
  foundry_check_character_scalar(name, "name")
  ref <- list(type = "agent_reference", name = name)
  if (!is.null(version)) {
    foundry_check_character_scalar(version, "version")
    ref$version <- version
  }
  ref
}


#' Create a Foundry agent
#'
#' Create a named, versioned prompt agent on the project-scoped Agent Service.
#' The agent bundles a model, system instructions, and optional tools so it can
#' later be run by name through [foundry_response()].
#'
#' @param name Character. Agent name. Up to 63 characters, alphanumeric and
#'   hyphens, unique within the project.
#' @param model Character. Model deployment name. Required unless `definition`
#'   is supplied.
#' @param instructions Character. Optional system prompt.
#' @param description Character. Optional human-readable description.
#' @param metadata Named list. Optional key-value metadata (up to 16 pairs).
#' @param temperature Numeric. Optional sampling temperature in `[0, 2]`.
#' @param top_p Numeric. Optional nucleus-sampling value in `[0, 1]`.
#' @param tools List. Optional tools: [foundry_tool()] objects or raw tool
#'   definition lists.
#' @param tool_choice Character or list. Optional tool-choice control.
#' @param definition List. Optional full agent definition. When supplied, the
#'   individual `model`/`instructions`/`tools` arguments are ignored and this
#'   list is sent as-is (must include `kind`).
#' @param api_key Character. Optional API key. Falls back to configured auth.
#' @param token Character. Optional bearer token. Falls back to configured auth.
#' @param endpoint Character. Optional project endpoint override.
#' @param api_version Character. API version query value. Defaults to `"v1"`.
#'
#' @return A one-row tibble describing the created agent.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_agent_create(
#'   name = "france-facts",
#'   model = "gpt-5-nano",
#'   instructions = "You answer questions about France concisely."
#' )
#' }
foundry_agent_create <- function(name,
                                 model = NULL,
                                 instructions = NULL,
                                 description = NULL,
                                 metadata = NULL,
                                 temperature = NULL,
                                 top_p = NULL,
                                 tools = NULL,
                                 tool_choice = NULL,
                                 definition = NULL,
                                 api_key = NULL,
                                 token = NULL,
                                 endpoint = NULL,
                                 api_version = "v1") {
  foundry_check_agent_name(name)

  if (is.null(definition)) {
    definition <- list(kind = "prompt", model = foundry_resolve_model(model))
    if (!is.null(instructions)) {
      foundry_check_character_scalar(instructions, "instructions")
      definition$instructions <- instructions
    }
    if (!is.null(temperature)) definition$temperature <- temperature
    if (!is.null(top_p)) definition$top_p <- top_p
    if (!is.null(tools)) {
      if (!is.list(tools)) {
        cli::cli_abort("{.arg tools} must be a list.")
      }
      definition$tools <- foundry_tool_schemas(tools)
    }
    if (!is.null(tool_choice)) definition$tool_choice <- tool_choice
  } else if (!is.list(definition) || is.null(definition$kind)) {
    cli::cli_abort("{.arg definition} must be a list containing a {.field kind} field.")
  }

  body <- list(name = name, definition = definition)
  if (!is.null(description)) {
    foundry_check_character_scalar(description, "description")
    body$description <- description
  }
  if (!is.null(metadata)) {
    if (!is.list(metadata)) {
      cli::cli_abort("{.arg metadata} must be a list.")
    }
    body$metadata <- metadata
  }

  req <- foundry_build_project_request(
    path = "agents",
    body = body,
    method = "POST",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )

  foundry_agent_tibble(foundry_perform(req))
}


#' List Foundry agents
#'
#' @param limit Integer. Optional maximum number of agents to return.
#' @param after Character. Optional pagination cursor.
#' @inheritParams foundry_agent_create
#'
#' @return A tibble with one row per agent.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_agents(limit = 20)
#' }
foundry_agents <- function(limit = NULL,
                           after = NULL,
                           api_key = NULL,
                           token = NULL,
                           endpoint = NULL,
                           api_version = "v1") {
  req <- foundry_build_project_request(
    path = "agents",
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )
  req <- httr2::req_url_query(req, limit = limit, after = after)

  result <- foundry_perform(req)
  agents <- result$data %||% list()
  if (length(agents) == 0L) {
    return(foundry_agent_tibble(list()))
  }
  purrr::map_dfr(agents, foundry_agent_tibble)
}


#' Retrieve a Foundry agent
#'
#' @param name Character. Agent name.
#' @inheritParams foundry_agent_create
#'
#' @return A one-row tibble describing the agent.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_agent_get("france-facts")
#' }
foundry_agent_get <- function(name,
                              api_key = NULL,
                              token = NULL,
                              endpoint = NULL,
                              api_version = "v1") {
  foundry_check_character_scalar(name, "name")

  req <- foundry_build_project_request(
    path = paste0("agents/", name),
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )

  foundry_agent_tibble(foundry_perform(req))
}


#' Delete a Foundry agent
#'
#' @param name Character. Agent name to delete.
#' @inheritParams foundry_agent_create
#'
#' @return A one-row tibble with `agent_name` and `deleted`.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_agent_delete("france-facts")
#' }
foundry_agent_delete <- function(name,
                                 api_key = NULL,
                                 token = NULL,
                                 endpoint = NULL,
                                 api_version = "v1") {
  foundry_check_character_scalar(name, "name")

  req <- foundry_build_project_request(
    path = paste0("agents/", name),
    method = "DELETE",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )

  result <- foundry_perform(req)
  tibble::tibble(
    agent_name = result$name %||% name,
    deleted = result$deleted %||% NA,
    raw_agent = list(result)
  )
}


#' List versions of a Foundry agent
#'
#' @param name Character. Agent name.
#' @param limit Integer. Optional maximum number of agent versions to return.
#' @param after Character. Optional pagination cursor.
#' @inheritParams foundry_agent_create
#'
#' @return A tibble with one row per agent version.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_agent_versions("france-facts")
#' }
foundry_agent_versions <- function(name,
                                   limit = NULL,
                                   after = NULL,
                                   api_key = NULL,
                                   token = NULL,
                                   endpoint = NULL,
                                   api_version = "v1") {
  foundry_check_character_scalar(name, "name")

  req <- foundry_build_project_request(
    path = paste0("agents/", name, "/versions"),
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )
  req <- httr2::req_url_query(req, limit = limit, after = after)

  result <- foundry_perform(req)
  versions <- result$data %||% list()
  if (length(versions) == 0L) {
    return(foundry_agent_version_tibble(list(), name))
  }
  purrr::map_dfr(versions, foundry_agent_version_tibble, agent_name = name)
}


# Internal helpers ------------------------------------------------------------

foundry_check_agent_name <- function(name) {
  foundry_check_character_scalar(name, "name")
  if (nchar(name) > 63L) {
    cli::cli_abort("{.arg name} must be at most 63 characters.")
  }
  if (!grepl("^[A-Za-z0-9-]+$", name)) {
    cli::cli_abort("{.arg name} must contain only letters, digits, and hyphens.")
  }
  invisible(name)
}


foundry_agent_reference_object <- function(agent, version = NULL) {
  if (is.character(agent)) {
    return(foundry_agent_reference(agent, version = version))
  }
  if (is.data.frame(agent) && "agent_name" %in% names(agent) && nrow(agent) >= 1L) {
    return(foundry_agent_reference(agent$agent_name[[1]], version = version))
  }
  if (is.list(agent) && identical(agent$type, "agent_reference") && !is.null(agent$name)) {
    if (!is.null(version)) agent$version <- version
    return(agent)
  }
  cli::cli_abort(c(
    "{.arg agent} must be an agent name, a {.fn foundry_agent_reference} object, or a tibble from {.fn foundry_agent_create}."
  ))
}


foundry_agent_tibble <- function(agent) {
  if (length(agent) == 0L) {
    return(tibble::tibble(
      agent_name = character(),
      id = character(),
      object = character(),
      description = character(),
      created_at = as.POSIXct(character()),
      raw_agent = list()
    ))
  }

  latest <- agent$versions$latest %||% list()
  tibble::tibble(
    agent_name = agent$name %||% NA_character_,
    id = agent$id %||% NA_character_,
    object = agent$object %||% NA_character_,
    description = agent$description %||% latest$description %||% NA_character_,
    created_at = foundry_response_created_at(agent$created_at %||% latest$created_at %||% NA_real_),
    raw_agent = list(agent)
  )
}


foundry_agent_version_tibble <- function(version_obj, agent_name) {
  if (length(version_obj) == 0L) {
    return(tibble::tibble(
      agent_name = character(),
      version = character(),
      created_at = as.POSIXct(character()),
      raw_version = list()
    ))
  }

  tibble::tibble(
    agent_name = version_obj$name %||% agent_name %||% NA_character_,
    version = as.character(version_obj$version %||% NA_character_),
    created_at = foundry_response_created_at(version_obj$created_at %||% NA_real_),
    raw_version = list(version_obj)
  )
}
