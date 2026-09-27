project_url <- "https://acct.services.ai.azure.com/api/projects/demo"

local_project <- function(env = parent.frame()) {
  setup_mock_env(env = env)
  withr::local_envvar(
    AZURE_FOUNDRY_PROJECT_ENDPOINT = project_url,
    AZURE_FOUNDRY_PROJECT_TOKEN = "test-project-token",
    .local_envir = env
  )
}

local_route <- function(route, env = parent.frame()) {
  old <- suppressMessages(suppressWarnings(foundry_set_route(route)))
  withr::defer(suppressMessages(foundry_set_route(old)), envir = env)
}

test_that("dual-route families default to the resource endpoint", {
  local_project()
  route <- foundry_resolve_route("files")
  expect_equal(route$route, "resource")
  expect_null(route$project_endpoint)
})

test_that("explicit arguments win over the session route", {
  local_project()
  local_route("project")

  expect_equal(foundry_resolve_route("files")$route, "project")
  resource <- foundry_resolve_route("files", endpoint = "https://test-resource.openai.azure.com")
  expect_equal(resource$route, "resource")
  expect_equal(resource$endpoint, "https://test-resource.openai.azure.com")

  explicit <- foundry_resolve_route("files", project_endpoint = paste0(project_url, "/"))
  expect_equal(explicit$project_endpoint, project_url)

  expect_error(
    foundry_resolve_route("files", endpoint = "https://a", project_endpoint = project_url),
    "only one"
  )
})

test_that("project-only families and features use the configured project", {
  local_project()
  expect_equal(foundry_resolve_route("conversations")$project_endpoint, project_url)
  expect_equal(
    foundry_resolve_route("evals", needs_project = "built-in evaluators")$route,
    "project"
  )
  expect_error(
    foundry_resolve_route(
      "evals",
      endpoint = "https://test-resource.openai.azure.com",
      needs_project = "built-in evaluators"
    ),
    "built-in evaluators, available only"
  )
})

test_that("a project URL passed as endpoint is treated as the project endpoint", {
  local_project()
  route <- foundry_resolve_route("responses", endpoint = project_url)
  expect_equal(route$route, "project")
  expect_equal(route$project_endpoint, project_url)
})

test_that("missing project endpoints give a reason", {
  setup_mock_env()
  expect_error(foundry_resolve_route("agents"), "Agents are only available")
  expect_error(
    foundry_resolve_route("evals", needs_project = "stored responses"),
    "stored responses"
  )
  local_route("project")
  expect_error(foundry_resolve_route("files"), "session route")
})

test_that("foundry_set_route returns the previous route and warns without a project", {
  setup_mock_env()
  expect_warning(
    expect_message(old <- foundry_set_route("project"), "project endpoint"),
    "no project endpoint"
  )
  expect_equal(old, "resource")
  expect_message(previous <- foundry_set_route("resource"), "resource endpoint")
  expect_equal(previous, "project")
  expect_error(foundry_set_route("somewhere"))
})

test_that("project requests accept API keys except for evaluations", {
  setup_mock_env()
  withr::local_envvar(AZURE_FOUNDRY_PROJECT_ENDPOINT = project_url)

  files_req <- foundry_build_routed_request("files", path = "files", method = "GET", project_endpoint = project_url)
  expect_equal(files_req$url, paste0(project_url, "/openai/v1/files"))
  expect_contains(names(files_req$headers), "api-key")

  expect_error(
    foundry_build_routed_request("evals", path = "evals", method = "GET", project_endpoint = project_url),
    "Microsoft Entra ID token"
  )
  expect_error(
    foundry_build_routed_request(
      "evals",
      path = "evals",
      method = "GET",
      api_key = "key",
      project_endpoint = project_url
    ),
    "not an API key"
  )

  withr::local_envvar(AZURE_FOUNDRY_PROJECT_TOKEN = "test-project-token")
  req <- foundry_build_routed_request("evals", path = "evals", method = "GET", project_endpoint = project_url)
  expect_equal(req$url, paste0(project_url, "/openai/v1/evals"))
  expect_equal(request_header(req, "Authorization"), "Bearer test-project-token")
  expect_null(req$headers$`api-key`)
})

test_that("foundry_json_object serializes to an empty JSON object", {
  expect_equal(as.character(jsonlite::toJSON(foundry_json_object(), auto_unbox = TRUE)), "{}")
})
