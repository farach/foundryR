#' Manage Azure OpenAI vector stores
#'
#' Create, list, retrieve, update, delete, and search hosted vector stores.
#'
#' @param vector_store_id Character. Vector store ID.
#' @param name Character. Vector store name.
#' @param file_id Character. Uploaded file ID.
#' @param file_ids Character vector of uploaded file IDs.
#' @param expires_after_days Integer. Optional expiry in days from last active
#'   time.
#' @param metadata List. Optional metadata.
#' @param limit Integer. Optional page size.
#' @param after Character. Optional pagination cursor.
#' @param query Character. Search query.
#' @param top_k Integer. Maximum search results.
#' @param filters List. Optional search filters.
#' @param rewrite_query Logical. Whether the service may rewrite the query.
#' @param api_key Character. Optional API key override.
#' @param endpoint Character. Optional endpoint override.
#'
#' @return A tibble with vector store, file, or search-result metadata.
#' @name foundry_vector_stores
NULL


#' @rdname foundry_vector_stores
#' @export
foundry_vector_store_create <- function(name,
                                        file_ids = NULL,
                                        expires_after_days = NULL,
                                        metadata = NULL,
                                        api_key = NULL,
                                        endpoint = NULL) {
  foundry_check_character_scalar(name, "name")
  body <- list(name = name)
  if (!is.null(file_ids)) body$file_ids <- as.list(file_ids)
  if (!is.null(expires_after_days)) {
    body$expires_after <- list(
      anchor = "last_active_at",
      days = foundry_check_positive_integer(expires_after_days, "expires_after_days")
    )
  }
  if (!is.null(metadata)) body$metadata <- metadata
  req <- foundry_build_v1_request(
    path = "vector_stores",
    body = body,
    api_key = api_key,
    endpoint = endpoint
  )
  foundry_vector_store_tibble(foundry_perform(req))
}


#' @rdname foundry_vector_stores
#' @export
foundry_vector_stores <- function(limit = NULL,
                                  after = NULL,
                                  api_key = NULL,
                                  endpoint = NULL) {
  req <- foundry_build_v1_request(
    path = "vector_stores",
    method = "GET",
    api_key = api_key,
    endpoint = endpoint
  )
  req <- req |>
    httr2::req_url_query(limit = limit, after = after)
  result <- foundry_perform(req)
  stores <- result$data %||% list()
  if (length(stores) == 0L) return(foundry_vector_store_tibble(list()))
  purrr::map_dfr(stores, foundry_vector_store_tibble)
}


#' @rdname foundry_vector_stores
#' @export
foundry_vector_store_get <- function(vector_store_id,
                                     api_key = NULL,
                                     endpoint = NULL) {
  foundry_check_character_scalar(vector_store_id, "vector_store_id")
  req <- foundry_build_v1_request(
    path = paste0("vector_stores/", vector_store_id),
    method = "GET",
    api_key = api_key,
    endpoint = endpoint
  )
  foundry_vector_store_tibble(foundry_perform(req))
}


#' @rdname foundry_vector_stores
#' @export
foundry_vector_store_modify <- function(vector_store_id,
                                        name = NULL,
                                        metadata = NULL,
                                        expires_after_days = NULL,
                                        api_key = NULL,
                                        endpoint = NULL) {
  foundry_check_character_scalar(vector_store_id, "vector_store_id")
  body <- list()
  if (!is.null(name)) body$name <- name
  if (!is.null(metadata)) body$metadata <- metadata
  if (!is.null(expires_after_days)) {
    body$expires_after <- list(
      anchor = "last_active_at",
      days = foundry_check_positive_integer(expires_after_days, "expires_after_days")
    )
  }
  req <- foundry_build_v1_request(
    path = paste0("vector_stores/", vector_store_id),
    body = body,
    method = "POST",
    api_key = api_key,
    endpoint = endpoint
  )
  foundry_vector_store_tibble(foundry_perform(req))
}


#' @rdname foundry_vector_stores
#' @export
foundry_vector_store_delete <- function(vector_store_id,
                                        api_key = NULL,
                                        endpoint = NULL) {
  foundry_check_character_scalar(vector_store_id, "vector_store_id")
  req <- foundry_build_v1_request(
    path = paste0("vector_stores/", vector_store_id),
    method = "DELETE",
    api_key = api_key,
    endpoint = endpoint
  )
  result <- foundry_perform(req)
  tibble::tibble(
    vector_store_id = result$id %||% vector_store_id,
    deleted = result$deleted %||% NA,
    raw_vector_store = list(result)
  )
}


#' @rdname foundry_vector_stores
#' @export
foundry_vector_store_files <- function(vector_store_id,
                                       limit = NULL,
                                       after = NULL,
                                       api_key = NULL,
                                       endpoint = NULL) {
  foundry_check_character_scalar(vector_store_id, "vector_store_id")
  req <- foundry_build_v1_request(
    path = paste0("vector_stores/", vector_store_id, "/files"),
    method = "GET",
    api_key = api_key,
    endpoint = endpoint
  )
  req <- req |>
    httr2::req_url_query(limit = limit, after = after)
  foundry_vector_store_files_tibble(foundry_perform(req))
}


#' @rdname foundry_vector_stores
#' @export
foundry_vector_store_file_add <- function(vector_store_id,
                                          file_id,
                                          api_key = NULL,
                                          endpoint = NULL) {
  foundry_check_character_scalar(vector_store_id, "vector_store_id")
  foundry_check_character_scalar(file_id, "file_id")
  req <- foundry_build_v1_request(
    path = paste0("vector_stores/", vector_store_id, "/files"),
    body = list(file_id = file_id),
    api_key = api_key,
    endpoint = endpoint
  )
  foundry_vector_store_file_tibble(foundry_perform(req))
}


#' @rdname foundry_vector_stores
#' @export
foundry_vector_store_file_remove <- function(vector_store_id,
                                             file_id,
                                             api_key = NULL,
                                             endpoint = NULL) {
  foundry_check_character_scalar(vector_store_id, "vector_store_id")
  foundry_check_character_scalar(file_id, "file_id")
  req <- foundry_build_v1_request(
    path = paste0("vector_stores/", vector_store_id, "/files/", file_id),
    method = "DELETE",
    api_key = api_key,
    endpoint = endpoint
  )
  result <- foundry_perform(req)
  tibble::tibble(
    vector_store_id = vector_store_id,
    file_id = result$id %||% file_id,
    deleted = result$deleted %||% NA,
    raw_file = list(result)
  )
}


#' @rdname foundry_vector_stores
#' @export
foundry_vector_store_file_batch <- function(vector_store_id,
                                            file_ids,
                                            api_key = NULL,
                                            endpoint = NULL) {
  foundry_check_character_scalar(vector_store_id, "vector_store_id")
  if (!is.character(file_ids) || length(file_ids) == 0L || any(is.na(file_ids))) {
    cli::cli_abort("{.arg file_ids} must be a non-empty character vector.")
  }
  req <- foundry_build_v1_request(
    path = paste0("vector_stores/", vector_store_id, "/file_batches"),
    body = list(file_ids = as.list(file_ids)),
    api_key = api_key,
    endpoint = endpoint
  )
  result <- foundry_perform(req)
  tibble::tibble(
    batch_id = result$id %||% NA_character_,
    vector_store_id = vector_store_id,
    status = result$status %||% NA_character_,
    file_counts = list(result$file_counts %||% list()),
    raw_batch = list(result)
  )
}


#' @rdname foundry_vector_stores
#' @export
foundry_vector_search <- function(vector_store_id,
                                  query,
                                  top_k = 10L,
                                  filters = NULL,
                                  rewrite_query = FALSE,
                                  api_key = NULL,
                                  endpoint = NULL) {
  foundry_check_character_scalar(vector_store_id, "vector_store_id")
  foundry_check_character_scalar(query, "query")
  top_k <- foundry_check_positive_integer(top_k, "top_k")
  foundry_check_logical_scalar(rewrite_query, "rewrite_query")

  body <- list(query = query, max_num_results = top_k, rewrite_query = rewrite_query)
  if (!is.null(filters)) body$filters <- filters
  req <- foundry_build_v1_request(
    path = paste0("vector_stores/", vector_store_id, "/search"),
    body = body,
    api_key = api_key,
    endpoint = endpoint
  )
  foundry_vector_search_tibble(foundry_perform(req))
}


#' Create a file-search tool definition
#'
#' @param vector_store_ids Character vector of vector store IDs.
#' @param max_num_results Integer. Optional maximum file-search results.
#'
#' @return A Responses API tool definition list.
#' @export
foundry_tool_file_search <- function(vector_store_ids, max_num_results = NULL) {
  if (!is.character(vector_store_ids) || length(vector_store_ids) == 0L ||
      any(is.na(vector_store_ids))) {
    cli::cli_abort("{.arg vector_store_ids} must be a non-empty character vector.")
  }
  tool <- list(
    type = "file_search",
    vector_store_ids = as.list(vector_store_ids)
  )
  if (!is.null(max_num_results)) {
    tool$max_num_results <- foundry_check_positive_integer(max_num_results, "max_num_results")
  }
  tool
}


foundry_vector_store_tibble <- function(store) {
  if (length(store) == 0L) {
    return(tibble::tibble(
      vector_store_id = character(),
      name = character(),
      status = character(),
      file_counts = list(),
      created_at = as.POSIXct(character()),
      raw_vector_store = list()
    ))
  }
  tibble::tibble(
    vector_store_id = store$id %||% NA_character_,
    name = store$name %||% NA_character_,
    status = store$status %||% NA_character_,
    file_counts = list(store$file_counts %||% list()),
    created_at = foundry_response_created_at(store$created_at %||% NA_real_),
    raw_vector_store = list(store)
  )
}


foundry_vector_store_files_tibble <- function(result) {
  files <- result$data %||% list()
  if (length(files) == 0L) return(foundry_vector_store_file_tibble(list()))
  purrr::map_dfr(files, foundry_vector_store_file_tibble)
}


foundry_vector_store_file_tibble <- function(file) {
  if (length(file) == 0L) {
    return(tibble::tibble(
      file_id = character(),
      status = character(),
      created_at = as.POSIXct(character()),
      raw_file = list()
    ))
  }
  tibble::tibble(
    file_id = file$id %||% file$file_id %||% NA_character_,
    status = file$status %||% NA_character_,
    created_at = foundry_response_created_at(file$created_at %||% NA_real_),
    raw_file = list(file)
  )
}


foundry_vector_search_tibble <- function(result) {
  data <- result$data %||% result$results %||% list()
  if (length(data) == 0L) {
    return(tibble::tibble(
      file_id = character(),
      score = numeric(),
      content = character(),
      raw_result = list()
    ))
  }
  purrr::map_dfr(data, function(item) {
    content <- item$content %||% item$text %||% NA_character_
    if (is.list(content)) {
      content <- paste(unlist(content, use.names = FALSE), collapse = "\n")
    }
    tibble::tibble(
      file_id = item$file_id %||% item$id %||% NA_character_,
      score = as.numeric(item$score %||% NA_real_),
      content = content,
      raw_result = list(item)
    )
  })
}
