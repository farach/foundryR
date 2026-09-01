# Tests for the project-scoped Agent Service: agent references, CRUD lifecycle,
# and running a stored agent through foundry_response(). All HTTP is mocked; no
# live calls are made.

# ---------------------------------------------------------------------------
# Test fixtures and environment
# ---------------------------------------------------------------------------

# Agents live on the project endpoint, so tests need that env var in addition
# to the shared mock credentials.
setup_agent_env <- function(env = parent.frame()) {
  setup_mock_env(env = env)
  withr::local_envvar(
    AZURE_FOUNDRY_PROJECT_ENDPOINT =
      "https://test-resource.services.ai.azure.com/api/projects/test-project",
    .local_envir = env
  )
}

mock_agent_object <- function(name = "france-facts") {
  list(
    id = "asst_1",
    object = "agent",
    name = name,
    description = "Answers questions about France",
    created_at = 1741369938,
    versions = list(
      latest = list(version = "1", created_at = 1741369938)
    )
  )
}

# ---------------------------------------------------------------------------
# foundry_agent_reference / foundry_agent_reference_object
# ---------------------------------------------------------------------------

test_that("foundry_agent_reference builds a reference and validates inputs", {
  ref <- foundry_agent_reference("france-facts")
  expect_equal(ref, list(type = "agent_reference", name = "france-facts"))

  versioned <- foundry_agent_reference("france-facts", version = "2")
  expect_equal(versioned$version, "2")

  expect_error(foundry_agent_reference(""), "non-empty")
  expect_error(foundry_agent_reference("x", version = ""), "non-empty")
})

test_that("foundry_agent_reference_object accepts names, references, and tibbles", {
  from_name <- foundry_agent_reference_object("france-facts")
  expect_equal(from_name$name, "france-facts")

  from_ref <- foundry_agent_reference_object(
    foundry_agent_reference("france-facts"),
    version = "3"
  )
  expect_equal(from_ref$version, "3")

  tbl <- tibble::tibble(agent_name = "france-facts", id = "asst_1")
  from_tbl <- foundry_agent_reference_object(tbl)
  expect_equal(from_tbl$name, "france-facts")

  expect_error(foundry_agent_reference_object(42), "must be an agent name")
})

# ---------------------------------------------------------------------------
# foundry_agent_create
# ---------------------------------------------------------------------------

test_that("foundry_agent_create posts a prompt definition to the project endpoint", {
  setup_agent_env()
  captured <- NULL
  resp <- mock_httr2_response(mock_agent_object())
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  out <- foundry_agent_create(
    name = "france-facts",
    model = "gpt-4.1-mini",
    instructions = "You answer questions about France concisely.",
    description = "France agent",
    metadata = list(team = "ds")
  )

  expect_match(captured$url, "/api/projects/test-project/agents")
  expect_match(captured$url, "api-version=v1")
  expect_equal(captured$method, "POST")

  body <- captured$body$data
  expect_equal(body$name, "france-facts")
  expect_equal(body$description, "France agent")
  expect_equal(body$metadata$team, "ds")
  expect_equal(body$definition$kind, "prompt")
  expect_equal(body$definition$model, "gpt-4.1-mini")
  expect_equal(
    body$definition$instructions,
    "You answer questions about France concisely."
  )

  expect_s3_class(out, "tbl_df")
  expect_equal(out$agent_name, "france-facts")
  expect_equal(out$id, "asst_1")
  expect_type(out$raw_agent, "list")
})

test_that("foundry_agent_create attaches tools and passes through a full definition", {
  setup_agent_env()
  captured <- NULL
  resp <- mock_httr2_response(mock_agent_object())
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  foundry_agent_create(
    name = "weather-bot",
    model = "gpt-4.1-mini",
    tools = list(list(type = "function", name = "get_weather", parameters = list())),
    tool_choice = "auto"
  )
  body <- captured$body$data
  expect_length(body$definition$tools, 1L)
  expect_equal(body$definition$tools[[1]]$type, "function")
  expect_equal(body$definition$tool_choice, "auto")

  # A full definition is sent as-is; model/instructions args are ignored.
  captured <- NULL
  foundry_agent_create(
    name = "custom",
    model = "ignored",
    definition = list(kind = "prompt", model = "gpt-4.1", temperature = 0.2)
  )
  body <- captured$body$data
  expect_equal(body$definition$model, "gpt-4.1")
  expect_equal(body$definition$temperature, 0.2)
})

test_that("foundry_agent_create validates the agent name", {
  setup_agent_env()
  expect_error(foundry_agent_create(name = ""), "non-empty")
  expect_error(
    foundry_agent_create(name = strrep("a", 64L), model = "gpt-4.1"),
    "at most 63 characters"
  )
  expect_error(
    foundry_agent_create(name = "bad name!", model = "gpt-4.1"),
    "letters, digits, and hyphens"
  )
  expect_error(
    foundry_agent_create(name = "ok", definition = list(model = "gpt-4.1")),
    "kind"
  )
})

# ---------------------------------------------------------------------------
# foundry_agents / foundry_agent_get / foundry_agent_delete
# ---------------------------------------------------------------------------

test_that("foundry_agents lists agents and forwards pagination", {
  setup_agent_env()
  captured <- NULL
  resp <- mock_httr2_response(list(
    object = "list",
    data = list(mock_agent_object("a"), mock_agent_object("b"))
  ))
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  out <- foundry_agents(limit = 20, after = "cursor-1")

  expect_match(captured$url, "/agents")
  expect_match(captured$url, "limit=20")
  expect_match(captured$url, "after=cursor-1")
  expect_equal(captured$method, "GET")

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 2L)
  expect_equal(out$agent_name, c("a", "b"))
})

test_that("foundry_agents returns an empty tibble when there are no agents", {
  setup_agent_env()
  mock_request(list(object = "list", data = list()))

  out <- foundry_agents()
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 0L)
  expect_true(all(
    c("agent_name", "id", "object", "description", "created_at", "raw_agent")
      %in% names(out)
  ))
})

test_that("foundry_agent_get retrieves a single agent", {
  setup_agent_env()
  captured <- NULL
  resp <- mock_httr2_response(mock_agent_object())
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  out <- foundry_agent_get("france-facts")

  expect_match(captured$url, "/agents/france-facts")
  expect_equal(captured$method, "GET")
  expect_equal(out$agent_name, "france-facts")
})

test_that("foundry_agent_delete issues a DELETE and reports the flag", {
  setup_agent_env()
  captured <- NULL
  resp <- mock_httr2_response(list(
    id = "asst_1",
    name = "france-facts",
    object = "agent.deleted",
    deleted = TRUE
  ))
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  out <- foundry_agent_delete("france-facts")

  expect_match(captured$url, "/agents/france-facts")
  expect_equal(captured$method, "DELETE")
  expect_true(out$deleted)
  expect_equal(out$agent_name, "france-facts")
})

# ---------------------------------------------------------------------------
# foundry_agent_versions
# ---------------------------------------------------------------------------

test_that("foundry_agent_versions lists versions for an agent", {
  setup_agent_env()
  captured <- NULL
  resp <- mock_httr2_response(list(
    object = "list",
    data = list(
      list(name = "france-facts", version = "1", created_at = 1741369938),
      list(name = "france-facts", version = "2", created_at = 1741369999)
    )
  ))
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  out <- foundry_agent_versions("france-facts")

  expect_match(captured$url, "/agents/france-facts/versions")
  expect_equal(captured$method, "GET")
  expect_equal(nrow(out), 2L)
  expect_equal(out$version, c("1", "2"))
  expect_equal(unique(out$agent_name), "france-facts")
})

# ---------------------------------------------------------------------------
# foundry_response(agent = ...) routing
# ---------------------------------------------------------------------------

test_that("foundry_response routes to the project endpoint when agent is set", {
  setup_agent_env()
  captured <- NULL
  resp <- mock_httr2_response(mock_response_api_response())
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  out <- foundry_response("What is the capital of France?", agent = "france-facts")

  # Routed to the project-scoped responses path, with no api-version query.
  expect_match(captured$url, "/api/projects/test-project/openai/v1/responses")
  expect_no_match(captured$url, "api-version")
  expect_equal(captured$method, "POST")

  body <- captured$body$data
  expect_equal(body$agent_reference$type, "agent_reference")
  expect_equal(body$agent_reference$name, "france-facts")
  # The model must not leak into an agent-routed request.
  expect_null(body$model)

  expect_s3_class(out, "tbl_df")
})

test_that("agent-backed response lifecycle stays on the project endpoint", {
  setup_agent_env()
  captured_urls <- character()
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured_urls <<- c(captured_urls, req$url)
      if (identical(req$method, "DELETE")) {
        return(mock_httr2_response(list(id = "resp_123", deleted = TRUE)))
      }
      if (grepl("/input_items$", req$url)) {
        return(mock_httr2_response(list(data = list())))
      }
      mock_httr2_response(mock_response_api_response(response_id = "resp_123"))
    },
    .package = "httr2"
  )
  project_endpoint <- Sys.getenv("AZURE_FOUNDRY_PROJECT_ENDPOINT")

  foundry_response_retrieve("resp_123", project_endpoint = project_endpoint)
  foundry_response_cancel("resp_123", project_endpoint = project_endpoint)
  foundry_response_input_items("resp_123", project_endpoint = project_endpoint)
  foundry_response_delete("resp_123", project_endpoint = project_endpoint)

  expect_equal(
    captured_urls,
    paste0(
      project_endpoint,
      c(
        "/openai/v1/responses/resp_123",
        "/openai/v1/responses/resp_123/cancel",
        "/openai/v1/responses/resp_123/input_items",
        "/openai/v1/responses/resp_123"
      )
    )
  )
})

test_that("foundry_response pins an agent version and ignores model when agent is set", {
  setup_agent_env()
  captured <- NULL
  resp <- mock_httr2_response(mock_response_api_response())
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  foundry_response(
    "Bonjour",
    model = "gpt-4.1-should-be-ignored",
    agent = foundry_agent_reference("france-facts"),
    agent_version = "2"
  )

  body <- captured$body$data
  expect_equal(body$agent_reference$name, "france-facts")
  expect_equal(body$agent_reference$version, "2")
  expect_null(body$model)
})

test_that("foundry_response without an agent still targets the resource endpoint", {
  setup_agent_env()
  captured <- NULL
  resp <- mock_httr2_response(mock_response_api_response())
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  foundry_response("Hello", model = "gpt-4.1")

  # Non-agent path is unchanged: resource endpoint, model in the body.
  expect_match(captured$url, "test-resource.openai.azure.com/openai/v1/responses")
  expect_equal(captured$body$data$model, "gpt-4.1")
  expect_null(captured$body$data$agent_reference)
})

test_that("project_endpoint routes a model response without an agent reference", {
  setup_agent_env()
  captured <- NULL
  resp <- mock_httr2_response(mock_response_api_response())
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  foundry_response(
    "Hello",
    model = "gpt-4.1",
    project_endpoint = Sys.getenv("AZURE_FOUNDRY_PROJECT_ENDPOINT")
  )

  expect_match(captured$url, "/api/projects/test-project/openai/v1/responses")
  expect_equal(captured$body$data$model, "gpt-4.1")
  expect_null(captured$body$data$agent_reference)
})
