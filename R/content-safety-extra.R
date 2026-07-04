foundry_content_safety_request <- function(path,
                                           body = NULL,
                                           method = "POST",
                                           endpoint = NULL,
                                           api_key = NULL,
                                           api_version = "2024-09-01") {
  endpoint <- get_content_safety_endpoint(endpoint, required = TRUE)
  api_key <- get_content_safety_key(api_key, required = TRUE)
  path <- sub("^/+", "", path)

  req <- httr2::request(paste0(endpoint, "/contentsafety/", path)) |>
    httr2::req_method(method) |>
    httr2::req_url_query(`api-version` = api_version) |>
    httr2::req_headers(`Ocp-Apim-Subscription-Key` = api_key) |>
    httr2::req_retry(max_tries = 3, backoff = ~ 2) |>
    httr2::req_error(body = content_safety_error_body)

  if (!is.null(body)) {
    req <- req |>
      httr2::req_body_json(body)
  }

  req
}


#' Moderate image content
#'
#' Analyze an image for harmful content with Azure AI Content Safety. `image`
#' can be a local file path or an HTTPS Azure Blob Storage URL.
#'
#' @param image Character. Local image path or HTTPS Azure Blob Storage URL.
#' @param categories Character vector of harm categories.
#' @param output_type Character. Severity level granularity.
#' @param endpoint Character. Optional Content Safety endpoint.
#' @param api_key Character. Optional Content Safety key.
#' @param api_version Character. API version. Defaults to `"2024-09-01"`.
#'
#' @return A tibble with one row per category and raw response payloads.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_moderate_image("image.png")
#' }
foundry_moderate_image <- function(image,
                                   categories = c("Hate", "Sexual", "SelfHarm", "Violence"),
                                   output_type = c("FourSeverityLevels", "EightSeverityLevels"),
                                   endpoint = NULL,
                                   api_key = NULL,
                                   api_version = "2024-09-01") {
  foundry_check_character_scalar(image, "image")
  output_type <- match.arg(output_type)
  image_body <- foundry_image_body(image)
  body <- list(
    image = image_body,
    categories = as.list(categories),
    outputType = output_type
  )
  req <- foundry_content_safety_request(
    "image:analyze",
    body = body,
    endpoint = endpoint,
    api_key = api_key,
    api_version = api_version
  )
  result <- foundry_perform(req)
  foundry_parse_safety_categories(result, image, output_type)
}


#' Detect protected material in text
#'
#' Call the Azure AI Content Safety protected-material detector.
#'
#' @param text Character vector.
#' @inheritParams foundry_moderate_image
#'
#' @return A tibble with one row per input text.
#' @export
#'
#' @examples
#' if (interactive() &&
#'     nzchar(Sys.getenv("AZURE_CONTENT_SAFETY_ENDPOINT")) &&
#'     nzchar(Sys.getenv("AZURE_CONTENT_SAFETY_KEY"))) {
#'   foundry_protected_material("A short text sample.")
#' }
foundry_protected_material <- function(text,
                                       endpoint = NULL,
                                       api_key = NULL,
                                       api_version = "2024-09-01") {
  if (!is.character(text)) {
    cli::cli_abort("{.arg text} must be a character vector.")
  }
  purrr::map_dfr(seq_along(text), function(i) {
    if (is.na(text[[i]])) {
      return(tibble::tibble(
        text = NA_character_,
        detected = NA,
        raw_response = list(NULL)
      ))
    }
    req <- foundry_content_safety_request(
      "text:detectProtectedMaterial",
      body = list(text = text[[i]]),
      endpoint = endpoint,
      api_key = api_key,
      api_version = api_version
    )
    result <- foundry_perform(req)
    detected <- result$protectedMaterialAnalysis$detected %||%
      result$detected %||%
      FALSE
    tibble::tibble(
      text = text[[i]],
      detected = detected,
      raw_response = list(result)
    )
  })
}


#' Manage Content Safety text blocklists
#'
#' Create, list, retrieve, delete, and edit Azure AI Content Safety blocklists.
#'
#' @param name Character. Blocklist name.
#' @param description Character. Optional blocklist description.
#' @param items Character vector of blocklist item text values.
#' @param item_ids Character vector of blocklist item IDs to remove.
#' @param is_regex Logical. Whether added items are regular expressions.
#' @inheritParams foundry_moderate_image
#'
#' @return A tibble with blocklist or blocklist-item metadata.
#' @name foundry_blocklists
#'
#' @examples
#' if (interactive() &&
#'     nzchar(Sys.getenv("AZURE_CONTENT_SAFETY_ENDPOINT")) &&
#'     nzchar(Sys.getenv("AZURE_CONTENT_SAFETY_KEY"))) {
#'   foundry_blocklists()
#'   foundry_blocklist_create("example-blocklist", description = "Example")
#'   foundry_blocklist_get("example-blocklist")
#'   items <- foundry_blocklist_add_items("example-blocklist", "blocked phrase")
#'   foundry_blocklist_items("example-blocklist")
#'   if (nrow(items) > 0 && !is.na(items$item_id[[1]])) {
#'     foundry_blocklist_remove_items("example-blocklist", items$item_id)
#'   }
#'   foundry_blocklist_delete("example-blocklist")
#' }
NULL


#' @rdname foundry_blocklists
#' @export
foundry_blocklists <- function(endpoint = NULL,
                               api_key = NULL,
                               api_version = "2024-09-01") {
  req <- foundry_content_safety_request(
    "text/blocklists",
    method = "GET",
    endpoint = endpoint,
    api_key = api_key,
    api_version = api_version
  )
  result <- foundry_perform(req)
  blocklists <- result$value %||% result$blocklists %||% result$data %||% list()
  if (length(blocklists) == 0L) return(foundry_blocklist_tibble(list()))
  purrr::map_dfr(blocklists, foundry_blocklist_tibble)
}


#' @rdname foundry_blocklists
#' @export
foundry_blocklist_create <- function(name,
                                     description = NULL,
                                     endpoint = NULL,
                                     api_key = NULL,
                                     api_version = "2024-09-01") {
  foundry_check_character_scalar(name, "name")
  body <- list()
  if (!is.null(description)) body$description <- description
  req <- foundry_content_safety_request(
    paste0("text/blocklists/", name),
    body = body,
    method = "PATCH",
    endpoint = endpoint,
    api_key = api_key,
    api_version = api_version
  )
  foundry_blocklist_tibble(foundry_perform(req))
}


#' @rdname foundry_blocklists
#' @export
foundry_blocklist_get <- function(name,
                                  endpoint = NULL,
                                  api_key = NULL,
                                  api_version = "2024-09-01") {
  foundry_check_character_scalar(name, "name")
  req <- foundry_content_safety_request(
    paste0("text/blocklists/", name),
    method = "GET",
    endpoint = endpoint,
    api_key = api_key,
    api_version = api_version
  )
  foundry_blocklist_tibble(foundry_perform(req))
}


#' @rdname foundry_blocklists
#' @export
foundry_blocklist_delete <- function(name,
                                     endpoint = NULL,
                                     api_key = NULL,
                                     api_version = "2024-09-01") {
  foundry_check_character_scalar(name, "name")
  req <- foundry_content_safety_request(
    paste0("text/blocklists/", name),
    method = "DELETE",
    endpoint = endpoint,
    api_key = api_key,
    api_version = api_version
  )
  foundry_perform_no_content(req)
  tibble::tibble(
    name = name,
    deleted = TRUE,
    raw_blocklist = list(NULL)
  )
}


#' @rdname foundry_blocklists
#' @export
foundry_blocklist_items <- function(name,
                                    endpoint = NULL,
                                    api_key = NULL,
                                    api_version = "2024-09-01") {
  foundry_check_character_scalar(name, "name")
  req <- foundry_content_safety_request(
    paste0("text/blocklists/", name, "/blocklistItems"),
    method = "GET",
    endpoint = endpoint,
    api_key = api_key,
    api_version = api_version
  )
  result <- foundry_perform(req)
  items <- result$value %||% result$blocklistItems %||% result$data %||% list()
  if (length(items) == 0L) return(foundry_blocklist_item_tibble(list()))
  purrr::map_dfr(items, foundry_blocklist_item_tibble)
}


#' @rdname foundry_blocklists
#' @export
foundry_blocklist_add_items <- function(name,
                                        items,
                                        is_regex = FALSE,
                                        endpoint = NULL,
                                        api_key = NULL,
                                        api_version = "2024-09-01") {
  foundry_check_character_scalar(name, "name")
  if (!is.character(items) || length(items) == 0L || any(is.na(items))) {
    cli::cli_abort("{.arg items} must be a non-empty character vector.")
  }
  foundry_check_logical_scalar(is_regex, "is_regex")
  body <- list(
    blocklistItems = lapply(items, function(item) {
      list(text = item, isRegex = is_regex)
    })
  )
  req <- foundry_content_safety_request(
    paste0("text/blocklists/", name, ":addOrUpdateBlocklistItems"),
    body = body,
    endpoint = endpoint,
    api_key = api_key,
    api_version = api_version
  )
  result <- foundry_perform(req)
  added <- result$value %||% result$blocklistItems %||% result$data %||% list()
  purrr::map_dfr(added, foundry_blocklist_item_tibble)
}


#' @rdname foundry_blocklists
#' @export
foundry_blocklist_remove_items <- function(name,
                                           item_ids,
                                           endpoint = NULL,
                                           api_key = NULL,
                                           api_version = "2024-09-01") {
  foundry_check_character_scalar(name, "name")
  if (!is.character(item_ids) || length(item_ids) == 0L || any(is.na(item_ids))) {
    cli::cli_abort("{.arg item_ids} must be a non-empty character vector.")
  }
  req <- foundry_content_safety_request(
    paste0("text/blocklists/", name, ":removeBlocklistItems"),
    body = list(blocklistItemIds = as.list(item_ids)),
    endpoint = endpoint,
    api_key = api_key,
    api_version = api_version
  )
  foundry_perform_no_content(req)
  tibble::tibble(
    name = name,
    removed = length(item_ids),
    raw_response = list(NULL)
  )
}


foundry_image_body <- function(image) {
  if (grepl("^https?://", image)) {
    foundry_validate_blob_url(image)
    return(list(blobUrl = image))
  }
  if (!file.exists(image)) {
    cli::cli_abort("Image file does not exist: {.file {image}}.")
  }
  size <- file.info(image)$size
  if (!is.na(size) && size > 4 * 1024 * 1024) {
    cli::cli_abort("Image files for Content Safety must be 4 MB or smaller.")
  }
  if (!requireNamespace("base64enc", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg base64enc} is required for local image moderation.")
  }
  list(content = base64enc::base64encode(image))
}


foundry_validate_blob_url <- function(url) {
  if (!grepl("^https://", url)) {
    cli::cli_abort("Content Safety image URLs must use HTTPS.")
  }
  host <- sub("^https://([^/@:?#]+)(?::[0-9]+)?(?:[/?#].*)?$", "\\1", url, perl = TRUE)
  if (identical(host, url) || grepl("@", url, fixed = TRUE)) {
    cli::cli_abort("Content Safety image URLs must be valid HTTPS Azure Blob Storage URLs.")
  }
  host <- tolower(host)
  blob_host <- paste0(
    "^[a-z0-9][a-z0-9-]*\\.blob\\.core\\.",
    "(windows\\.net|usgovcloudapi\\.net|chinacloudapi\\.cn|cloudapi\\.de)$"
  )
  if (!grepl(blob_host, host, perl = TRUE)) {
    cli::cli_abort("Content Safety image URLs must point to Azure Blob Storage.")
  }
  invisible(url)
}


foundry_perform_no_content <- function(req) {
  resp <- httr2::req_perform(req)
  body <- httr2::resp_body_raw(resp)
  if (length(body) == 0L) {
    return(invisible(NULL))
  }
  invisible(jsonlite::fromJSON(rawToChar(body), simplifyVector = FALSE))
}


foundry_parse_safety_categories <- function(result, source, output_type) {
  categories_analysis <- result$categoriesAnalysis %||% list()
  if (length(categories_analysis) == 0L) {
    return(tibble::tibble(
      source = source,
      category = character(),
      severity = integer(),
      label = character(),
      raw_response = list()
    ))
  }
  purrr::map_dfr(categories_analysis, function(cat_result) {
    severity <- cat_result$severity %||% NA_integer_
    tibble::tibble(
      source = source,
      category = cat_result$category %||% NA_character_,
      severity = as.integer(severity),
      label = severity_to_label(severity, output_type),
      raw_response = list(result)
    )
  })
}


foundry_blocklist_tibble <- function(blocklist) {
  if (length(blocklist) == 0L) {
    return(tibble::tibble(
      name = character(),
      description = character(),
      raw_blocklist = list()
    ))
  }
  tibble::tibble(
    name = blocklist$blocklistName %||% blocklist$name %||% NA_character_,
    description = blocklist$description %||% NA_character_,
    raw_blocklist = list(blocklist)
  )
}


foundry_blocklist_item_tibble <- function(item) {
  if (length(item) == 0L) {
    return(tibble::tibble(
      item_id = character(),
      text = character(),
      is_regex = logical(),
      raw_item = list()
    ))
  }
  tibble::tibble(
    item_id = item$blocklistItemId %||% item$blockItemId %||% item$id %||% NA_character_,
    text = item$text %||% NA_character_,
    is_regex = item$isRegex %||% NA,
    raw_item = list(item)
  )
}
