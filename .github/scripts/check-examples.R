check_examples <- function(package_dir, report) {
  package_dir <- normalizePath(package_dir, mustWork = TRUE)
  report <- normalizePath(report, mustWork = FALSE)
  suppressPackageStartupMessages(pkgload::load_all(
    package_dir,
    export_all = FALSE,
    helpers = FALSE,
    quiet = TRUE
  ))

  sandbox <- withr::local_tempdir()
  work_dir <- file.path(sandbox, "working")
  user_dir <- file.path(sandbox, "user")
  dir.create(work_dir)
  dir.create(user_dir)
  withr::local_dir(work_dir)
  variables <- grep(
    "^(AZURE_|FOUNDRY_|FOUNDRYR_|ONET_API_KEY$)",
    names(Sys.getenv()),
    value = TRUE
  )
  withr::local_envvar(c(
    stats::setNames(rep(NA_character_, length(variables)), variables),
    R_USER_CONFIG_DIR = user_dir,
    R_USER_CACHE_DIR = user_dir,
    R_USER_DATA_DIR = user_dir
  ))
  withr::local_options(
    foundryR.config_file = file.path(user_dir, "config.json")
  )

  live_request <- function(...) {
    stop("An example attempted a live HTTP request.")
  }
  testthat::local_mocked_bindings(
    req_perform = live_request,
    req_perform_parallel = live_request,
    .package = "httr2"
  )
  run_example <- function(rd, path, include_donttest) {
    example_file <- tempfile(fileext = ".R")
    tools::Rd2ex(
      rd,
      out = example_file,
      commentDontrun = TRUE,
      commentDonttest = !include_donttest
    )
    code <- parse(example_file)
    unlink(example_file)
    before_env <- Sys.getenv()
    before_options <- options(
      "foundryR.config_file",
      "foundryR.sequential_requests",
      "httptest2.redactor"
    )
    started <- proc.time()[["elapsed"]]
    invisible(capture.output(
      eval(code, envir = new.env(parent = globalenv()))
    ))
    elapsed <- proc.time()[["elapsed"]] - started
    after_env <- Sys.getenv()
    changed_env <- union(
      setdiff(names(after_env), names(before_env)),
      names(before_env)[
        is.na(after_env[names(before_env)]) |
          after_env[names(before_env)] != before_env
      ]
    )
    changed_env <- grep(
      "^(AZURE_|FOUNDRY|ONET_API_KEY$|R_USER|HOME$|TMPDIR$)",
      changed_env,
      value = TRUE
    )
    if (length(changed_env)) {
      stop(
        basename(path),
        " changed environment variables: ",
        paste(changed_env, collapse = ", ")
      )
    }
    if (
      !identical(
        do.call(options, as.list(names(before_options))),
        before_options
      )
    ) {
      stop(basename(path), " changed package options.")
    }
    if (
      !identical(
        normalizePath(getwd(), winslash = "/"),
        normalizePath(work_dir, winslash = "/")
      )
    ) {
      stop(basename(path), " changed the working directory.")
    }
    if (
      length(list.files(
        sandbox,
        all.files = TRUE,
        recursive = TRUE,
        no.. = TRUE
      ))
    ) {
      stop(basename(path), " wrote outside the session temporary output area.")
    }
    elapsed
  }

  has_tag <- function(node, tag) {
    identical(attr(node, "Rd_tag"), tag) ||
      (is.list(node) && any(vapply(node, has_tag, logical(1), tag = tag)))
  }
  results <- list()
  for (path in list.files(
    file.path(package_dir, "man"),
    "\\.Rd$",
    full.names = TRUE
  )) {
    rd <- tools::parse_Rd(path)
    if (!has_tag(rd, "\\examples")) {
      next
    }
    standard <- run_example(rd, path, include_donttest = FALSE)
    extended <- if (has_tag(rd, "\\donttest")) {
      run_example(rd, path, include_donttest = TRUE)
    } else {
      standard
    }
    results[[length(results) + 1L]] <- data.frame(
      topic = basename(path),
      standard_seconds = standard,
      with_donttest_seconds = extended
    )
  }
  timings <- do.call(rbind, results)
  utils::write.csv(timings, report, row.names = FALSE)
  too_slow <- timings$topic[timings$standard_seconds >= 5]
  if (length(too_slow)) {
    stop(
      "Examples took at least five seconds: ",
      paste(too_slow, collapse = ", ")
    )
  }
  message(
    nrow(timings),
    " example topics passed, including donttest; every standard example took less than five seconds."
  )
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop("Usage: Rscript check-examples.R <package-directory> <timings.csv>")
}
check_examples(args[[1]], args[[2]])
