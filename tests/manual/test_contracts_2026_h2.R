# Manual contract checks for the 2026 H2 roadmap.
# Run interactively with real Azure resources. These checks are intentionally
# outside testthat and must not run during R CMD check.

if (requireNamespace("devtools", quietly = TRUE)) {
  devtools::load_all(".", quiet = TRUE)
} else {
  library(foundryR)
}

required_env <- function(vars) {
  missing <- vars[Sys.getenv(vars) == ""]
  if (length(missing) > 0L) {
    stop("Missing environment variables: ", paste(missing, collapse = ", "), call. = FALSE)
  }
}

check_resource_entra_scope <- function() {
  resource <- "https://cognitiveservices.azure.com"
  provider <- foundry_token_azure_cli(resource)
  token <- provider()
  req <- foundry_build_v1_request(
    path = "evals",
    method = "GET",
    token = token,
    endpoint = Sys.getenv("AZURE_FOUNDRY_ENDPOINT")
  )
  resp <- httr2::req_perform(req)
  data.frame(
    endpoint_family = "resource",
    resource = resource,
    status = httr2::resp_status(resp)
  )
}


check_project_entra_scope <- function() {
  required_env(c("AZURE_FOUNDRY_PROJECT_ENDPOINT"))
  resource <- "https://ai.azure.com"
  provider <- foundry_token_azure_cli(resource)
  token <- provider()
  endpoint <- foundry_get_project_endpoint(required = TRUE)
  req <- foundry_build_project_request(
    path = "agents",
    method = "GET",
    token = token,
    endpoint = endpoint
  )
  resp <- httr2::req_perform(req)
  data.frame(
    endpoint_family = "project",
    resource = resource,
    status = httr2::resp_status(resp)
  )
}


check_agent_response_lifecycle <- function() {
  required_env(c(
    "AZURE_FOUNDRY_PROJECT_ENDPOINT",
    "AZURE_FOUNDRY_AGENT_NAME"
  ))
  endpoint <- foundry_get_project_endpoint(required = TRUE)
  foundry_set_token_provider(
    foundry_token_azure_cli("https://ai.azure.com"),
    scope = "project"
  )

  created <- foundry_response(
    "Reply with the word ok.",
    agent = Sys.getenv("AZURE_FOUNDRY_AGENT_NAME"),
    background = TRUE,
    store = TRUE,
    project_endpoint = endpoint
  )
  response_id <- created$response_id[[1]]
  retrieved <- foundry_response_retrieve(
    response_id,
    project_endpoint = endpoint
  )
  items <- foundry_response_input_items(
    response_id,
    project_endpoint = endpoint
  )
  cancelled <- foundry_response_cancel(
    response_id,
    project_endpoint = endpoint
  )
  deleted <- foundry_response_delete(
    response_id,
    project_endpoint = endpoint
  )

  data.frame(
    response_id = response_id,
    retrieved_status = retrieved$status[[1]],
    input_items = nrow(items),
    cancelled_status = cancelled$status[[1]],
    deleted = deleted$deleted[[1]]
  )
}

check_groundedness_correction_flag <- function(flag_name) {
  required_env(c("AZURE_CONTENT_SAFETY_ENDPOINT", "AZURE_CONTENT_SAFETY_KEY"))
  body <- list(
    domain = "Generic",
    task = "QnA",
    text = "The capital of France is Lyon.",
    groundingSources = list("Paris is the capital of France."),
    qna = list(query = "What is the capital of France?"),
    reasoning = TRUE
  )
  body[[flag_name]] <- TRUE
  req <- foundry_content_safety_request(
    "text:detectGroundedness",
    body = body,
    api_version = "2024-09-15-preview"
  )
  result <- foundry_perform(req)
  data.frame(
    flag = flag_name,
    has_correction_text = !is.null(result$correctionText) || !is.null(result$correctedText)
  )
}

run_contract_checks <- function() {
  required_env(c("AZURE_FOUNDRY_ENDPOINT"))
  rbind(
    check_resource_entra_scope(),
    check_project_entra_scope()
  ) |>
    print()

  rbind(
    check_groundedness_correction_flag("mitigating"),
    check_groundedness_correction_flag("correction")
  ) |>
    print()

  if (nzchar(Sys.getenv("AZURE_FOUNDRY_AGENT_NAME"))) {
    check_agent_response_lifecycle() |>
      print()
  }
}

if (interactive()) {
  run_contract_checks()
}
