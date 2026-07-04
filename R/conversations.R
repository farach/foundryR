#' Manage Responses API conversations
#'
#' Create, list, retrieve, update, and delete server-side conversations used by
#' the Responses API.
#'
#' @param conversation_id Character. Conversation ID.
#' @param metadata List. Optional metadata.
#' @param limit Integer. Optional page size.
#' @param after Character. Optional pagination cursor.
#' @param items List. Conversation input items to add.
#' @param api_key Character. Optional API key override.
#' @param endpoint Character. Optional endpoint override.
#'
#' @return A tibble with conversation metadata or conversation items.
#' @name foundry_conversations
#'
#' @examples
#' if (interactive() &&
#'     nzchar(Sys.getenv("AZURE_FOUNDRY_ENDPOINT")) &&
#'     nzchar(Sys.getenv("AZURE_FOUNDRY_KEY"))) {
#'   conversation <- foundry_conversation_create(
#'     metadata = list(example = "cran")
#'   )
#'   id <- conversation$conversation_id[[1]]
#'   foundry_conversations(limit = 10)
#'   foundry_conversation_get(id)
#'   foundry_conversation_update(id, metadata = list(example = "updated"))
#'   foundry_conversation_items(id)
#'   foundry_conversation_delete(id)
#' }
NULL


#' @rdname foundry_conversations
#' @export
foundry_conversation_create <- function(metadata = NULL,
                                        api_key = NULL,
                                        endpoint = NULL) {
  body <- list()
  if (!is.null(metadata)) body$metadata <- metadata
  req <- foundry_build_v1_request(
    path = "conversations",
    body = body,
    api_key = api_key,
    endpoint = endpoint
  )
  foundry_conversation_tibble(foundry_perform(req))
}


#' @rdname foundry_conversations
#' @export
foundry_conversations <- function(limit = NULL,
                                  after = NULL,
                                  api_key = NULL,
                                  endpoint = NULL) {
  req <- foundry_build_v1_request(
    path = "conversations",
    method = "GET",
    api_key = api_key,
    endpoint = endpoint
  )
  req <- req |>
    httr2::req_url_query(limit = limit, after = after)
  result <- foundry_perform(req)
  conversations <- result$data %||% list()
  if (length(conversations) == 0L) {
    return(foundry_conversation_tibble(list()))
  }
  purrr::map_dfr(conversations, foundry_conversation_tibble)
}


#' @rdname foundry_conversations
#' @export
foundry_conversation_get <- function(conversation_id,
                                     api_key = NULL,
                                     endpoint = NULL) {
  foundry_check_character_scalar(conversation_id, "conversation_id")
  req <- foundry_build_v1_request(
    path = paste0("conversations/", conversation_id),
    method = "GET",
    api_key = api_key,
    endpoint = endpoint
  )
  foundry_conversation_tibble(foundry_perform(req))
}


#' @rdname foundry_conversations
#' @export
foundry_conversation_update <- function(conversation_id,
                                        metadata = NULL,
                                        api_key = NULL,
                                        endpoint = NULL) {
  foundry_check_character_scalar(conversation_id, "conversation_id")
  body <- list()
  if (!is.null(metadata)) body$metadata <- metadata
  req <- foundry_build_v1_request(
    path = paste0("conversations/", conversation_id),
    body = body,
    method = "POST",
    api_key = api_key,
    endpoint = endpoint
  )
  foundry_conversation_tibble(foundry_perform(req))
}


#' @rdname foundry_conversations
#' @export
foundry_conversation_delete <- function(conversation_id,
                                        api_key = NULL,
                                        endpoint = NULL) {
  foundry_check_character_scalar(conversation_id, "conversation_id")
  req <- foundry_build_v1_request(
    path = paste0("conversations/", conversation_id),
    method = "DELETE",
    api_key = api_key,
    endpoint = endpoint
  )
  result <- foundry_perform(req)
  tibble::tibble(
    conversation_id = result$id %||% conversation_id,
    deleted = result$deleted %||% NA,
    raw_conversation = list(result)
  )
}


#' @rdname foundry_conversations
#' @export
foundry_conversation_items <- function(conversation_id,
                                       limit = NULL,
                                       after = NULL,
                                       api_key = NULL,
                                       endpoint = NULL) {
  foundry_check_character_scalar(conversation_id, "conversation_id")
  req <- foundry_build_v1_request(
    path = paste0("conversations/", conversation_id, "/items"),
    method = "GET",
    api_key = api_key,
    endpoint = endpoint
  )
  req <- req |>
    httr2::req_url_query(limit = limit, after = after)
  foundry_conversation_items_tibble(foundry_perform(req))
}


#' @rdname foundry_conversations
#' @export
foundry_conversation_items_add <- function(conversation_id,
                                           items,
                                           api_key = NULL,
                                           endpoint = NULL) {
  foundry_check_character_scalar(conversation_id, "conversation_id")
  if (!is.list(items) || length(items) == 0L) {
    cli::cli_abort("{.arg items} must be a non-empty list.")
  }
  req <- foundry_build_v1_request(
    path = paste0("conversations/", conversation_id, "/items"),
    body = list(items = items),
    method = "POST",
    api_key = api_key,
    endpoint = endpoint
  )
  foundry_conversation_items_tibble(foundry_perform(req))
}


foundry_conversation_tibble <- function(conversation) {
  if (length(conversation) == 0L) {
    return(tibble::tibble(
      conversation_id = character(),
      object = character(),
      created_at = as.POSIXct(character()),
      metadata = list(),
      raw_conversation = list()
    ))
  }
  tibble::tibble(
    conversation_id = conversation$id %||% NA_character_,
    object = conversation$object %||% NA_character_,
    created_at = foundry_response_created_at(conversation$created_at %||% NA_real_),
    metadata = list(conversation$metadata %||% list()),
    raw_conversation = list(conversation)
  )
}


foundry_conversation_items_tibble <- function(result) {
  items <- result$data %||% list()
  if (length(items) == 0L) {
    return(tibble::tibble(
      item_id = character(),
      type = character(),
      role = character(),
      content = list(),
      raw_item = list()
    ))
  }
  purrr::map_dfr(items, function(item) {
    tibble::tibble(
      item_id = item$id %||% NA_character_,
      type = item$type %||% NA_character_,
      role = item$role %||% NA_character_,
      content = list(item$content %||% NULL),
      raw_item = list(item)
    )
  })
}
