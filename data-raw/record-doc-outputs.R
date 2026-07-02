# Record real, credential-free documentation fixtures.
#
# WHAT THIS DOES
# Runs the package README and vignettes against your live Azure AI Foundry
# resources exactly once, and captures each API response as a sanitized httptest2
# fixture. After this, every documentation build (R CMD check, pkgdown, CRAN, CI)
# replays those fixtures and shows real output with no credentials and no network
# calls. Secrets and your resource host names are stripped on the way to disk by
# the redactor in inst/httptest2/start-vignette.R.
#
# YOU RUN THIS. It is the only step that needs real credentials. Copilot and CI
# never have them.
#
# HOW TO RUN
#   1. Put your real deployment names and credentials in the environment (for
#      example via .Renviron). The variables read here are listed in `required`
#      and `optional` below.
#   2. From the package root, in a fresh R session:
#        source("data-raw/record-doc-outputs.R")
#      Optionally record a subset:
#        source("data-raw/record-doc-outputs.R"); record_doc_outputs(only = "embeddings")
#   3. Inspect the regenerated README.md and vignettes, then commit the new
#      README.md and the vignettes/<name>/ fixture directories.
#
# RE-RECORDING
# Delete the fixture directory for a doc (or pass refresh = TRUE) and run again to
# capture fresh responses from the service.

record_doc_outputs <- function(only = NULL, refresh = FALSE) {
  if (!file.exists("DESCRIPTION")) {
    stop("Run this from the foundryR package root (DESCRIPTION not found).", call. = FALSE)
  }
  for (pkg in c("pkgload", "rmarkdown", "httptest2", "withr")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop("Package '", pkg, "' is required to record documentation.", call. = FALSE)
    }
  }

  # Core credentials that every text-based doc needs.
  required <- c(
    "AZURE_FOUNDRY_ENDPOINT",
    "AZURE_FOUNDRY_MODEL",
    "AZURE_FOUNDRY_EMBED_MODEL"
  )
  # Present unless you authenticate with a token instead of a key.
  needs_key <- !nzchar(Sys.getenv("AZURE_FOUNDRY_TOKEN"))
  if (needs_key) required <- c(required, "AZURE_FOUNDRY_KEY")

  missing <- required[!nzchar(vapply(required, Sys.getenv, character(1)))]
  if (length(missing)) {
    stop(
      "Missing required environment variables:\n  ",
      paste(missing, collapse = "\n  "),
      "\nSet them (e.g. in .Renviron) before recording.",
      call. = FALSE
    )
  }

  # Optional per-service credentials. A doc that needs an unset service is skipped
  # with a message rather than failing the whole run.
  optional <- list(
    content_safety = "AZURE_CONTENT_SAFETY_ENDPOINT",
    image          = "AZURE_FOUNDRY_IMAGE_ENDPOINT",
    speech         = "AZURE_FOUNDRY_SPEECH_ENDPOINT",
    project        = "AZURE_FOUNDRY_PROJECT_ENDPOINT",
    onet           = "ONET_API_KEY"
  )
  have <- function(service) nzchar(Sys.getenv(optional[[service]]))

  # Documentation targets and the optional services each one exercises. A target
  # is recorded only when all of its services are configured.
  docs <- list(
    list(name = "README",              path = "README.Rmd",                        dir = "tools/readme-fixtures", services = c("content_safety")),
    list(name = "getting-started",     path = "vignettes/getting-started.Rmd",     dir = "vignettes/getting-started",     services = character()),
    list(name = "embeddings",          path = "vignettes/embeddings.Rmd",          dir = "vignettes/embeddings",          services = character()),
    list(name = "content-safety",      path = "vignettes/content-safety.Rmd",      dir = "vignettes/content-safety",      services = c("content_safety")),
    list(name = "annotation-workflow", path = "vignettes/annotation-workflow.Rmd", dir = "vignettes/annotation-workflow", services = c("content_safety")),
    list(name = "responses-api",       path = "vignettes/responses-api.Rmd",       dir = "vignettes/responses-api",       services = character()),
    list(name = "audio",               path = "vignettes/audio.Rmd",               dir = "vignettes/audio",               services = c("speech")),
    list(name = "media-generation",    path = "vignettes/media-generation.Rmd",    dir = "vignettes/media-generation",    services = c("image")),
    list(name = "files-batches",       path = "vignettes/files-batches.Rmd",       dir = "vignettes/files-batches",       services = character()),
    list(name = "tidymodels",          path = "vignettes/tidymodels.Rmd",          dir = "vignettes/tidymodels",          services = character()),
    list(name = "foundryr-vs-ellmer",  path = "vignettes/foundryr-vs-ellmer.Rmd",  dir = "vignettes/foundryr-vs-ellmer",  services = character()),
    list(name = "onet2r-integration",  path = "vignettes/articles/onet2r-integration.Rmd", dir = "vignettes/articles/onet2r-integration", services = c("onet"))
  )

  if (!is.null(only)) {
    docs <- Filter(function(d) d$name %in% only, docs)
    if (!length(docs)) stop("No documentation target matched `only`.", call. = FALSE)
  }

  pkgload::load_all(".", quiet = TRUE)
  withr::local_envvar(FOUNDRY_RECORD_DOCS = "1")

  recorded <- character()
  skipped <- character()
  for (doc in docs) {
    unmet <- doc$services[!vapply(doc$services, have, logical(1))]
    if (length(unmet)) {
      message("Skipping ", doc$name, " (unset services: ", paste(unmet, collapse = ", "), ")")
      skipped <- c(skipped, doc$name)
      next
    }
    if (refresh && dir.exists(doc$dir)) {
      unlink(doc$dir, recursive = TRUE)
    }
    message("Recording ", doc$name, " ...")
    if (identical(doc$name, "README")) {
      rmarkdown::render("README.Rmd", output_file = "README.md", quiet = TRUE)
    } else {
      rmarkdown::render(doc$path, quiet = TRUE)
      # Vignette rendering leaves an .html next to the source; keep the tree clean.
      html <- sub("\\.Rmd$", ".html", doc$path)
      if (file.exists(html)) unlink(html)
    }
    recorded <- c(recorded, doc$name)
  }

  message("\nRecorded: ", if (length(recorded)) paste(recorded, collapse = ", ") else "(none)")
  if (length(skipped)) {
    message("Skipped:  ", paste(skipped, collapse = ", "))
  }
  message(
    "\nReview the regenerated README.md and vignettes, then commit README.md and ",
    "the fixture directories."
  )
  invisible(list(recorded = recorded, skipped = skipped))
}

if (identical(environment(), globalenv()) && !interactive()) {
  record_doc_outputs()
}
