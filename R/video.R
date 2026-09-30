#' Defunct video generation functions
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' These functions are defunct and raise an error. Azure OpenAI retires its
#' last Sora video generation model (`sora-2`, version 2025-12-08) on
#' 2026-10-15 and has announced no replacement, so foundryR no longer wraps the
#' video job API.
#'
#' @param ... Ignored.
#'
#' @return None. Each function raises an error.
#' @name foundry_video_defunct
#' @keywords internal
NULL


#' @rdname foundry_video_defunct
#' @export
foundry_video_job_create <- function(...) {
  foundry_video_defunct("foundry_video_job_create()")
}


#' @rdname foundry_video_defunct
#' @export
foundry_video_jobs <- function(...) {
  foundry_video_defunct("foundry_video_jobs()")
}


#' @rdname foundry_video_defunct
#' @export
foundry_video_job_get <- function(...) {
  foundry_video_defunct("foundry_video_job_get()")
}


#' @rdname foundry_video_defunct
#' @export
foundry_video_job_delete <- function(...) {
  foundry_video_defunct("foundry_video_job_delete()")
}


#' @rdname foundry_video_defunct
#' @export
foundry_video_get <- function(...) {
  foundry_video_defunct("foundry_video_get()")
}


#' @rdname foundry_video_defunct
#' @export
foundry_video_download <- function(...) {
  foundry_video_defunct("foundry_video_download()")
}


foundry_video_defunct <- function(what) {
  lifecycle::deprecate_stop(
    when = "1.0.0",
    what = what,
    details = paste(
      "Azure OpenAI retires its last Sora video model (sora-2, version",
      "2025-12-08) on 2026-10-15 with no replacement."
    )
  )
}