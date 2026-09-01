foundry_config_file <- function() {
  configured <- getOption("foundryR.config_file")
  if (!is.null(configured)) {
    foundry_check_character_scalar(
      configured,
      "getOption(\"foundryR.config_file\")"
    )
    return(configured)
  }

  file.path(tools::R_user_dir("foundryR", "config"), "config.json")
}


foundry_read_config <- function() {
  path <- foundry_config_file()
  if (!file.exists(path)) {
    return(list())
  }

  config <- tryCatch(
    jsonlite::read_json(path, simplifyVector = FALSE),
    error = function(error) {
      cli::cli_abort(c(
        "Could not read foundryR configuration file: {.file {path}}.",
        "x" = conditionMessage(error),
        "i" = "Delete or repair the file, then run the relevant {.code foundry_set_*()} function again."
      ))
    }
  )
  if (!is.list(config) || is.null(names(config))) {
    cli::cli_abort("Invalid foundryR configuration file: {.file {path}}.")
  }

  config
}


foundry_store_setting <- function(name, value) {
  foundry_check_character_scalar(name, "name")
  foundry_check_character_scalar(value, "value")

  path <- foundry_config_file()
  directory <- dirname(path)
  if (.Platform$OS.type != "windows") {
    old_umask <- Sys.umask("077")
    on.exit(Sys.umask(old_umask), add = TRUE)
  }
  if (
    !dir.exists(directory) &&
      !dir.create(directory, recursive = TRUE, mode = "0700")
  ) {
    cli::cli_abort(
      "Could not create foundryR configuration directory: {.file {directory}}."
    )
  }

  config <- foundry_read_config()
  config[[name]] <- value
  temporary <- tempfile("config-", tmpdir = directory)
  on.exit(unlink(temporary), add = TRUE)
  if (!file.create(temporary, showWarnings = FALSE)) {
    cli::cli_abort(
      "Could not create a temporary foundryR configuration file in {.file {directory}}."
    )
  }
  if (.Platform$OS.type != "windows") {
    Sys.chmod(temporary, mode = "0600")
  }
  jsonlite::write_json(config, temporary, auto_unbox = TRUE, pretty = TRUE)

  if (
    .Platform$OS.type == "windows" && file.exists(path) && unlink(path) != 0L
  ) {
    cli::cli_abort(
      "Could not replace foundryR configuration file: {.file {path}}."
    )
  }
  if (!file.rename(temporary, path)) {
    cli::cli_abort(
      "Could not install foundryR configuration file: {.file {path}}."
    )
  }

  path
}


foundry_get_stored_setting <- function(name) {
  value <- foundry_read_config()[[name]]
  if (
    is.null(value) ||
      !is.character(value) ||
      length(value) != 1L ||
      is.na(value) ||
      !nzchar(value)
  ) {
    return(NULL)
  }

  value
}
