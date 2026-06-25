#' Upload a file to Microsoft Foundry
#'
#' Upload a local file for use with Foundry APIs such as Batch, fine-tuning,
#' evals, or assistants/file-search workflows.
#'
#' @param path Character. Local file path to upload.
#' @param purpose Character. File purpose. One of `"assistants"`, `"batch"`,
#'   `"fine-tune"`, or `"evals"`.
#' @param expires_after_seconds Integer. Optional number of seconds after
#'   creation when the file should expire. Azure's v1 Files API accepts this as
#'   an `expires_after` object.
#' @param api_key Character. Optional API key override.
#' @param token Character. Optional bearer token override.
#' @param endpoint Character. Optional endpoint override.
#' @param api_version Character. Optional API version query value.
#'
#' @return A one-row tibble with file metadata.
#' @export
#'
#' @examples
#' \dontrun{
#' path <- tempfile(fileext = ".jsonl")
#' writeLines('{"custom_id":"row-1","method":"POST","url":"/v1/responses"}', path)
#' foundry_file_upload(path, purpose = "batch")
#' }
foundry_file_upload <- function(path,
                                purpose = c("assistants", "batch", "fine-tune", "evals"),
                                expires_after_seconds = 30 * 24 * 60 * 60,
                                api_key = NULL,
                                token = NULL,
                                endpoint = NULL,
                                api_version = NULL) {
  foundry_check_character_scalar(path, "path")
  if (!file.exists(path)) {
    cli::cli_abort("File does not exist: {.file {path}}.")
  }
  purpose <- match.arg(purpose)

  req <- foundry_build_v1_request(
    path = "files",
    method = "POST",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )

  multipart <- list(
    file = curl::form_file(path),
    purpose = purpose
  )

  if (!is.null(expires_after_seconds)) {
    expires_after_seconds <- as.integer(expires_after_seconds)
    if (is.na(expires_after_seconds) || expires_after_seconds < 1L) {
      cli::cli_abort("{.arg expires_after_seconds} must be a positive integer.")
    }
    multipart$expires_after <- jsonlite::toJSON(
      list(anchor = "created_at", seconds = expires_after_seconds),
      auto_unbox = TRUE
    )
  }

  req <- do.call(httr2::req_body_multipart, c(list(req), multipart))
  foundry_parse_file(foundry_perform(req))
}


#' List uploaded Microsoft Foundry files
#'
#' @param purpose Character. Optional purpose filter.
#' @param limit Integer. Optional maximum number of files to return.
#' @param order Character. Optional sort order, `"asc"` or `"desc"`.
#' @param after Character. Optional pagination cursor.
#' @inheritParams foundry_file_upload
#'
#' @return A tibble with one row per file.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_files(purpose = "batch", limit = 10)
#' }
foundry_files <- function(purpose = NULL,
                          limit = NULL,
                          order = NULL,
                          after = NULL,
                          api_key = NULL,
                          token = NULL,
                          endpoint = NULL,
                          api_version = NULL) {
  req <- foundry_build_v1_request(
    path = "files",
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )

  req <- req |>
    httr2::req_url_query(
      purpose = purpose,
      limit = limit,
      order = order,
      after = after
    )

  result <- foundry_perform(req)
  foundry_parse_files(result)
}


#' Retrieve a Microsoft Foundry file
#'
#' @param file_id Character. File ID to retrieve.
#' @inheritParams foundry_file_upload
#'
#' @return A one-row tibble with file metadata.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_file_get("file_abc123")
#' }
foundry_file_get <- function(file_id,
                             api_key = NULL,
                             token = NULL,
                             endpoint = NULL,
                             api_version = NULL) {
  foundry_check_character_scalar(file_id, "file_id")

  req <- foundry_build_v1_request(
    path = paste0("files/", file_id),
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )

  foundry_parse_file(foundry_perform(req))
}


#' Delete a Microsoft Foundry file
#'
#' @param file_id Character. File ID to delete.
#' @inheritParams foundry_file_upload
#'
#' @return A tibble with deletion status.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_file_delete("file_abc123")
#' }
foundry_file_delete <- function(file_id,
                                api_key = NULL,
                                token = NULL,
                                endpoint = NULL,
                                api_version = NULL) {
  foundry_check_character_scalar(file_id, "file_id")

  req <- foundry_build_v1_request(
    path = paste0("files/", file_id),
    method = "DELETE",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )

  result <- foundry_perform(req)
  tibble::tibble(
    file_id = result$id %||% file_id,
    deleted = result$deleted %||% NA
  )
}


#' Download Microsoft Foundry file content
#'
#' @param file_id Character. File ID to download.
#' @param path Character. Local path where the file content should be written.
#' @param overwrite Logical. Whether to overwrite an existing file.
#' @inheritParams foundry_file_upload
#'
#' @return A tibble with the local path, number of bytes written, and file ID.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_file_download("file_abc123", "batch-output.jsonl")
#' }
foundry_file_download <- function(file_id,
                                  path,
                                  overwrite = FALSE,
                                  api_key = NULL,
                                  token = NULL,
                                  endpoint = NULL,
                                  api_version = NULL) {
  foundry_check_character_scalar(file_id, "file_id")
  foundry_check_character_scalar(path, "path")

  req <- foundry_build_v1_request(
    path = paste0("files/", file_id, "/content"),
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )

  out <- foundry_write_raw_response(req, path, overwrite = overwrite)
  out$file_id <- file_id
  out
}


foundry_parse_files <- function(result) {
  files <- result$data %||% list()
  if (length(files) == 0L) {
    return(foundry_file_tibble(list()))
  }
  purrr::map_dfr(files, foundry_file_tibble)
}


foundry_parse_file <- function(result) {
  foundry_file_tibble(result)
}


foundry_file_tibble <- function(file) {
  if (length(file) == 0L) {
    return(tibble::tibble(
      file_id = character(),
      filename = character(),
      purpose = character(),
      status = character(),
      bytes = integer(),
      created_at = as.POSIXct(character()),
      expires_at = as.POSIXct(character()),
      raw_file = list()
    ))
  }

  tibble::tibble(
    file_id = file$id %||% NA_character_,
    filename = file$filename %||% NA_character_,
    purpose = file$purpose %||% NA_character_,
    status = file$status %||% NA_character_,
    bytes = as.integer(file$bytes %||% NA_integer_),
    created_at = foundry_response_created_at(file$created_at %||% NA_real_),
    expires_at = foundry_response_created_at(file$expires_at %||% NA_real_),
    raw_file = list(file)
  )
}
