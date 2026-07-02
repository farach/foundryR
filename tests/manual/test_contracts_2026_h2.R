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

check_entra_scope <- function(resource) {
  provider <- foundry_token_azure_cli(resource = resource)
  token <- provider()
  req <- foundry_build_v1_request(
    path = "evals",
    method = "GET",
    token = token,
    endpoint = Sys.getenv("AZURE_FOUNDRY_ENDPOINT")
  )
  resp <- httr2::req_perform(req)
  data.frame(resource = resource, status = httr2::resp_status(resp))
}

check_project_endpoint <- function() {
  required_env(c("AZURE_FOUNDRY_PROJECT_ENDPOINT"))
  endpoint <- foundry_get_project_endpoint(required = TRUE)
  data.frame(project_endpoint = endpoint)
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
    check_entra_scope("https://ai.azure.com"),
    check_entra_scope("https://cognitiveservices.azure.com")
  ) |>
    print()

  check_project_endpoint() |>
    print()

  rbind(
    check_groundedness_correction_flag("mitigating"),
    check_groundedness_correction_flag("correction")
  ) |>
    print()
}

if (interactive()) {
  run_contract_checks()
}
