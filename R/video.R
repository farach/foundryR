#' Create a Microsoft Foundry video generation job
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Start a v1 preview video generation job. Video generation is a preview
#' feature and returns a job that should be polled with `foundry_video_job_get()`.
#'
#' @param prompt Character. Prompt for the generated video.
#' @param model Character. Video model deployment name.
#' @param width,height Integer. Output video dimensions.
#' @param n_seconds Integer. Duration in seconds, between 1 and 20.
#' @param n_variants Integer. Number of video variants, between 1 and 5.
#' @param files Character vector. Optional local files for image-to-video or
#'   inpainting workflows.
#' @param inpaint_items List. Optional inpainting items for multipart requests.
#' @param api_key Character. Optional API key override.
#' @param token Character. Optional bearer token override.
#' @param endpoint Character. Optional endpoint override.
#' @param api_version Character. Optional API version. Defaults to `"preview"`.
#'
#' @return A one-row tibble with job metadata and the raw job in a list-column.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_video_job_create(
#'   "A calm ocean at sunrise",
#'   model = "my-video-model",
#'   width = 1280,
#'   height = 720
#' )
#' }
foundry_video_job_create <- function(prompt,
                                     model = NULL,
                                     width,
                                     height,
                                     n_seconds = 5L,
                                     n_variants = 1L,
                                     files = NULL,
                                     inpaint_items = NULL,
                                     api_key = NULL,
                                     token = NULL,
                                     endpoint = NULL,
                                     api_version = "preview") {
  foundry_check_character_scalar(prompt, "prompt")
  model <- foundry_resolve_model(model)
  width <- foundry_check_positive_integer(width, "width")
  height <- foundry_check_positive_integer(height, "height")
  n_seconds <- foundry_check_integer_range(n_seconds, "n_seconds", 1L, 20L)
  n_variants <- foundry_check_integer_range(n_variants, "n_variants", 1L, 5L)

  body <- list(
    prompt = prompt,
    model = model,
    width = width,
    height = height,
    n_seconds = n_seconds,
    n_variants = n_variants
  )

  req <- foundry_build_v1_request(
    path = "video/generations/jobs",
    body = if (is.null(files)) body else NULL,
    method = "POST",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )

  if (!is.null(files)) {
    if (!is.character(files) || anyNA(files) || any(!file.exists(files))) {
      cli::cli_abort("{.arg files} must contain existing local file paths.")
    }
    multipart <- lapply(body, as.character)
    file_parts <- lapply(files, curl::form_file)
    names(file_parts) <- rep("files", length(file_parts))
    multipart <- c(multipart, file_parts)
    if (!is.null(inpaint_items)) {
      multipart$inpaint_items <- jsonlite::toJSON(inpaint_items, auto_unbox = TRUE)
    }
    req <- do.call(httr2::req_body_multipart, c(list(req), multipart))
  }

  foundry_parse_video_job(foundry_perform(req))
}


#' List Microsoft Foundry video generation jobs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param limit Integer. Maximum number of jobs to return.
#' @param before,after Character. Optional pagination cursors.
#' @param statuses Character vector. Optional status filters.
#' @inheritParams foundry_video_job_create
#'
#' @return A tibble with one row per video job.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_video_jobs(limit = 10)
#' }
foundry_video_jobs <- function(limit = 20L,
                               before = NULL,
                               after = NULL,
                               statuses = NULL,
                               api_key = NULL,
                               token = NULL,
                               endpoint = NULL,
                               api_version = "preview") {
  limit <- foundry_check_positive_integer(limit, "limit")
  req <- foundry_build_v1_request(
    path = "video/generations/jobs",
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )
  req <- req |>
    httr2::req_url_query(
      limit = limit,
      before = before,
      after = after,
      statuses = statuses
    )

  result <- foundry_perform(req)
  jobs <- result$data %||% result$jobs %||% list()
  if (length(jobs) == 0L) {
    return(foundry_video_job_tibble(list()))
  }
  purrr::map_dfr(jobs, foundry_video_job_tibble)
}


#' Retrieve a Microsoft Foundry video generation job
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param job_id Character. Video generation job ID.
#' @inheritParams foundry_video_job_create
#'
#' @return A one-row tibble with job metadata.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_video_job_get("videojob_abc123")
#' }
foundry_video_job_get <- function(job_id,
                                  api_key = NULL,
                                  token = NULL,
                                  endpoint = NULL,
                                  api_version = "preview") {
  foundry_check_character_scalar(job_id, "job_id")
  req <- foundry_build_v1_request(
    path = paste0("video/generations/jobs/", job_id),
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )
  foundry_parse_video_job(foundry_perform(req))
}


#' Delete a Microsoft Foundry video generation job
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param job_id Character. Video generation job ID.
#' @inheritParams foundry_video_job_create
#'
#' @return A tibble with deletion status.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_video_job_delete("videojob_abc123")
#' }
foundry_video_job_delete <- function(job_id,
                                     api_key = NULL,
                                     token = NULL,
                                     endpoint = NULL,
                                     api_version = "preview") {
  foundry_check_character_scalar(job_id, "job_id")
  req <- foundry_build_v1_request(
    path = paste0("video/generations/jobs/", job_id),
    method = "DELETE",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )
  httr2::req_perform(req)
  tibble::tibble(job_id = job_id, deleted = TRUE)
}


#' Retrieve a Microsoft Foundry video generation
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param generation_id Character. Video generation ID.
#' @inheritParams foundry_video_job_create
#'
#' @return A one-row tibble with generation metadata.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_video_get("vidgen_abc123")
#' }
foundry_video_get <- function(generation_id,
                              api_key = NULL,
                              token = NULL,
                              endpoint = NULL,
                              api_version = "preview") {
  foundry_check_character_scalar(generation_id, "generation_id")
  req <- foundry_build_v1_request(
    path = paste0("video/generations/", generation_id),
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )
  foundry_parse_video_generation(foundry_perform(req))
}


#' Download Microsoft Foundry generated video content
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param generation_id Character. Video generation ID.
#' @param path Character. Local file path for the downloaded content.
#' @param content Character. `"video"` for video bytes or `"thumbnail"` for the
#'   generated thumbnail.
#' @param overwrite Logical. Whether to overwrite an existing file.
#' @inheritParams foundry_video_job_create
#'
#' @return A tibble with the local path, bytes written, generation ID, and
#'   content type.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_video_download("vidgen_abc123", "clip.mp4")
#' }
foundry_video_download <- function(generation_id,
                                   path,
                                   content = c("video", "thumbnail"),
                                   overwrite = FALSE,
                                   api_key = NULL,
                                   token = NULL,
                                   endpoint = NULL,
                                   api_version = "preview") {
  foundry_check_character_scalar(generation_id, "generation_id")
  foundry_check_character_scalar(path, "path")
  content <- match.arg(content)

  req <- foundry_build_v1_request(
    path = paste0("video/generations/", generation_id, "/content/", content),
    method = "GET",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version
  )
  out <- foundry_write_raw_response(req, path, overwrite = overwrite)
  out$generation_id <- generation_id
  out$content <- content
  out
}


foundry_parse_video_job <- function(result) {
  foundry_video_job_tibble(result)
}


foundry_parse_video_generation <- function(result) {
  tibble::tibble(
    generation_id = result$id %||% result$generation_id %||% NA_character_,
    status = result$status %||% NA_character_,
    created_at = foundry_response_created_at(result$created_at %||% NA_real_),
    raw_generation = list(result)
  )
}


foundry_video_job_tibble <- function(job) {
  if (length(job) == 0L) {
    return(tibble::tibble(
      job_id = character(),
      status = character(),
      model = character(),
      prompt = character(),
      width = integer(),
      height = integer(),
      n_seconds = integer(),
      n_variants = integer(),
      created_at = as.POSIXct(character()),
      generations = list(),
      raw_job = list()
    ))
  }

  tibble::tibble(
    job_id = job$id %||% job$job_id %||% NA_character_,
    status = job$status %||% NA_character_,
    model = job$model %||% NA_character_,
    prompt = job$prompt %||% NA_character_,
    width = as.integer(job$width %||% NA_integer_),
    height = as.integer(job$height %||% NA_integer_),
    n_seconds = as.integer(job$n_seconds %||% NA_integer_),
    n_variants = as.integer(job$n_variants %||% NA_integer_),
    created_at = foundry_response_created_at(job$created_at %||% NA_real_),
    generations = list(job$generations %||% list()),
    raw_job = list(job)
  )
}


foundry_check_positive_integer <- function(x, arg) {
  x <- as.integer(x)
  if (is.na(x) || x < 1L) {
    cli::cli_abort("{.arg {arg}} must be a positive integer.")
  }
  x
}


foundry_check_integer_range <- function(x, arg, min, max) {
  x <- as.integer(x)
  if (is.na(x) || x < min || x > max) {
    cli::cli_abort("{.arg {arg}} must be between {min} and {max}.")
  }
  x
}
