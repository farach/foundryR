# Shared setup for httptest2-mocked vignettes and the package README.
#
# httptest2::start_vignette() sources this file before it enters record or
# replay mode, so it runs in both situations:
#
#   * Recording. A maintainer runs data-raw/record-doc-outputs.R with real
#     Azure credentials in the environment. Real requests are made and their
#     responses are written into each vignette's fixture directory. The redactor
#     below rewrites the real resource host to a stable placeholder and strips
#     keys, so the committed fixtures contain no secrets.
#
#   * Replaying. R CMD check, pkgdown, CRAN, or any build without credentials
#     reuses the recorded fixtures and makes no network calls. We supply
#     placeholder credentials only when none are set, so foundryR can still
#     build the request objects that httptest2 matches against the fixtures.

# Supply placeholder configuration for credential-free (replay) builds only.
# When real credentials are present we leave them untouched so recording works.
local({
  placeholders <- list(
    AZURE_FOUNDRY_ENDPOINT         = "https://example.openai.azure.com",
    AZURE_FOUNDRY_KEY              = "not-a-real-key",
    AZURE_FOUNDRY_MODEL            = "gpt-5-nano",
    AZURE_FOUNDRY_EMBED_MODEL      = "text-embedding-3-small",
    AZURE_FOUNDRY_IMAGE_ENDPOINT   = "https://example.openai.azure.com",
    AZURE_FOUNDRY_IMAGE_KEY        = "not-a-real-key",
    AZURE_FOUNDRY_IMAGE_MODEL      = "gpt-image-1",
    AZURE_FOUNDRY_SPEECH_ENDPOINT  = "https://example.cognitiveservices.azure.com",
    AZURE_FOUNDRY_SPEECH_KEY       = "not-a-real-key",
    AZURE_CONTENT_SAFETY_ENDPOINT  = "https://example.cognitiveservices.azure.com",
    AZURE_CONTENT_SAFETY_KEY       = "not-a-real-key",
    AZURE_FOUNDRY_PROJECT_ENDPOINT = "https://example.services.ai.azure.com/api/projects/demo",
    ONET_API_KEY                   = "not-a-real-key"
  )
  for (nm in names(placeholders)) {
    if (!nzchar(Sys.getenv(nm))) {
      do.call(Sys.setenv, stats::setNames(list(placeholders[[nm]]), nm))
    }
  }
})

# Map each configured real host to a placeholder so fixture paths and bodies are
# portable. Evaluated at source time: during recording the environment holds the
# real hosts; during replay it holds the placeholders above, which makes the
# substitutions harmless no-ops.
.foundry_doc_host_map <- local({
  host_of <- function(url) sub("/.*$", "", sub("^https?://", "", url))
  pairs <- list(
    c("AZURE_FOUNDRY_ENDPOINT",         "example.openai.azure.com"),
    c("AZURE_FOUNDRY_IMAGE_ENDPOINT",   "example.openai.azure.com"),
    c("AZURE_FOUNDRY_SPEECH_ENDPOINT",  "example.cognitiveservices.azure.com"),
    c("AZURE_CONTENT_SAFETY_ENDPOINT",  "example.cognitiveservices.azure.com"),
    c("AZURE_FOUNDRY_PROJECT_ENDPOINT", "example.services.ai.azure.com")
  )
  map <- list()
  for (p in pairs) {
    real <- host_of(Sys.getenv(p[1]))
    if (nzchar(real) && !identical(real, p[2])) {
      map[[real]] <- p[2]
    }
  }
  map
})

# Secret values to scrub from recorded bodies, gathered from the environment at
# source time. Empty during replay, so nothing is scrubbed then.
.foundry_doc_secrets <- local({
  keys <- c(
    "AZURE_FOUNDRY_KEY", "AZURE_FOUNDRY_IMAGE_KEY", "AZURE_FOUNDRY_SPEECH_KEY",
    "AZURE_CONTENT_SAFETY_KEY", "AZURE_FOUNDRY_TOKEN", "ONET_API_KEY"
  )
  vals <- vapply(keys, Sys.getenv, character(1))
  unname(vals[nzchar(vals) & vals != "not-a-real-key"])
})

httptest2::set_redactor(function(response) {
  response <- httptest2::redact_headers(
    response,
    c("api-key", "Authorization", "Ocp-Apim-Subscription-Key", "X-API-Key")
  )
  for (real_host in names(.foundry_doc_host_map)) {
    response <- httptest2::gsub_response(
      response, real_host, .foundry_doc_host_map[[real_host]],
      fixed = TRUE
    )
  }
  for (secret in .foundry_doc_secrets) {
    response <- httptest2::gsub_response(response, secret, "REDACTED", fixed = TRUE)
  }
  response
})
