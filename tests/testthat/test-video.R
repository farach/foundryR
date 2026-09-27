test_that("video functions are defunct and explain why", {
  defunct <- list(
    foundry_video_job_create = function() foundry_video_job_create("A lighthouse at dusk"),
    foundry_video_jobs = function() foundry_video_jobs(),
    foundry_video_job_get = function() foundry_video_job_get("job_1"),
    foundry_video_job_delete = function() foundry_video_job_delete("job_1"),
    foundry_video_get = function() foundry_video_get("gen_1"),
    foundry_video_download = function() foundry_video_download("gen_1", path = tempfile())
  )
  for (name in names(defunct)) {
    lifecycle::expect_defunct(defunct[[name]]())
    expect_error(defunct[[name]](), "2026-10-15", info = name)
  }
})