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
  # A non-UTF-8 session writes characters such as a right single quote into the
  # fixtures as "<U+2019>" escapes, which then show up in the rendered pages.
  if (!isTRUE(l10n_info()[["UTF-8"]])) {
    stop(
      "Record documentation in a UTF-8 R session. On Windows, unset LC_CTYPE ",
      "(in PowerShell: Remove-Item Env:LC_CTYPE) and start R again.",
      call. = FALSE
    )
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
    project        = "AZURE_FOUNDRY_PROJECT_ENDPOINT"
  )
  have <- function(service) nzchar(Sys.getenv(optional[[service]]))

  # Documentation targets and the optional services each one exercises. A target
  # is recorded only when all of its services are configured.
  docs <- list(
    # httptest2 prepends "vignettes/" to README.Rmd's fixture path because a
    # vignettes/ directory exists at the package root.
    list(name = "README",              path = "README.Rmd",                        dir = "vignettes/tools/readme-fixtures", services = character()),
    list(name = "getting-started",     path = "vignettes/getting-started.Rmd",     dir = "vignettes/getting-started",     services = character()),
    list(name = "embeddings",          path = "vignettes/embeddings.Rmd",          dir = "vignettes/embeddings",          services = character()),
    list(name = "content-safety",      path = "vignettes/content-safety.Rmd",      dir = "vignettes/content-safety",      services = c("content_safety")),
    list(name = "annotation-workflow", path = "vignettes/annotation-workflow.Rmd", dir = "vignettes/annotation-workflow", services = c("content_safety")),
    list(name = "responses-api",       path = "vignettes/responses-api.Rmd",       dir = "vignettes/responses-api",       services = character()),
    list(name = "audio",               path = "vignettes/audio.Rmd",               dir = "vignettes/audio",               services = character()),
    list(name = "media-generation",    path = "vignettes/media-generation.Rmd",    dir = "vignettes/media-generation",    services = c("image")),
    list(name = "files-batches",       path = "vignettes/files-batches.Rmd",       dir = "vignettes/files-batches",       services = character()),
    list(name = "tidymodels",          path = "vignettes/tidymodels.Rmd",          dir = "vignettes/tidymodels",          services = character()),
    list(name = "evaluations",         path = "vignettes/evaluations.Rmd",         dir = "vignettes/evaluations",         services = c("project"))
  )
  # The onet2r article is withdrawn to data-raw/drafts/ until it can be
  # re-recorded with onet2r installed and an O*NET API key.

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

  leaks <- find_fixture_leaks(vapply(Filter(function(d) d$name %in% recorded, docs), `[[`, "", "dir"))
  if (length(leaks)) {
    stop(
      "Recorded fixtures still contain resource identifiers:\n  ",
      paste(leaks, collapse = "\n  "),
      "\nFix the redactor in inst/httptest2/start-vignette.R and record again.",
      call. = FALSE
    )
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

# Scan fixture files for real hosts, the real project path, and subscription
# paths that the redactor should have removed. Returns "file: pattern" strings.
find_fixture_leaks <- function(dirs) {
  host_of <- function(url) sub("/.*$", "", sub("^https?://", "", url))
  endpoints <- Sys.getenv(c(
    "AZURE_FOUNDRY_ENDPOINT",
    "AZURE_FOUNDRY_IMAGE_ENDPOINT",
    "AZURE_FOUNDRY_SPEECH_ENDPOINT",
    "AZURE_CONTENT_SAFETY_ENDPOINT",
    "AZURE_FOUNDRY_PROJECT_ENDPOINT"
  ))
  hosts <- unique(host_of(endpoints[nzchar(endpoints)]))
  hosts <- hosts[!grepl("^example\\.", hosts)]
  project <- sub("/+$", "", sub("^https?://", "", Sys.getenv("AZURE_FOUNDRY_PROJECT_ENDPOINT")))
  project_name <- if (grepl("/api/projects/", project)) sub("^.*/api/projects/", "", project) else ""
  literals <- unique(c(hosts, if (nzchar(project_name) && project_name != "demo") paste0("projects/", project_name)))

  files <- unlist(lapply(dirs[dir.exists(dirs)], list.files, recursive = TRUE, full.names = TRUE))
  leaks <- character()
  for (file in files) {
    text <- paste(readLines(file, warn = FALSE), collapse = "\n")
    found <- literals[vapply(literals, grepl, logical(1), x = text, fixed = TRUE)]
    if (grepl("/subscriptions/[0-9a-fA-F-]{8,}", text)) {
      found <- c(found, "/subscriptions/<id>")
    }
    if (grepl("<U\\+[0-9A-Fa-f]{4,}>", text)) {
      found <- c(found, "<U+XXXX> escape (recorded in a non-UTF-8 session)")
    }
    if (length(found)) {
      leaks <- c(leaks, paste0(file, ": ", paste(found, collapse = ", ")))
    }
  }
  leaks
}

if (identical(environment(), globalenv()) && !interactive()) {
  record_doc_outputs()
} else if (interactive()) {
  message("Loaded record_doc_outputs(). Call it to record, for example record_doc_outputs(only = \"embeddings\").")
}
