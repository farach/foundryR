test_that("foundry_video_job_create builds preview request", {
  setup_mock_env()
  captured <- NULL
  mock_resp <- mock_httr2_response(list(
    id = "job_123",
    status = "queued",
    model = "sora",
    prompt = "Ocean",
    width = 1280,
    height = 720,
    n_seconds = 5,
    n_variants = 1,
    created_at = 1741369938
  ))

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      mock_resp
    },
    .package = "httr2"
  )

  result <- foundry_video_job_create(
    "Ocean",
    model = "sora",
    width = 1280,
    height = 720
  )

  expect_match(captured$url, "/openai/v1/video/generations/jobs")
  expect_match(captured$url, "api-version=preview")
  expect_equal(result$job_id, "job_123")
  expect_equal(result$status, "queued")
})

test_that("foundry_video_job_create builds multipart request with files", {
  setup_mock_env()
  image <- tempfile(fileext = ".png")
  writeBin(charToRaw("fake image"), image)
  captured <- NULL
  mock_resp <- mock_httr2_response(list(
    id = "job_123",
    status = "queued",
    model = "sora",
    prompt = "Ocean",
    width = 1280,
    height = 720,
    n_seconds = 5,
    n_variants = 1,
    created_at = 1741369938
  ))

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      mock_resp
    },
    .package = "httr2"
  )

  result <- foundry_video_job_create(
    "Ocean",
    model = "sora",
    width = 1280,
    height = 720,
    files = image
  )

  expect_equal(result$job_id, "job_123")
  expect_valid_multipart_request(captured)
  expect_equal(sum(names(captured$body$data) == "files"), 1L)
  expect_equal(captured$body$data$n_seconds, "5")
})

test_that("foundry_video job helpers use expected paths", {
  setup_mock_env()
  captured <- character()

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- c(captured, paste(req$method, req$url))
      if (identical(req$method, "DELETE")) {
        return(mock_httr2_raw_response(raw()))
      }
      mock_httr2_response(list(id = "job_123", status = "succeeded"))
    },
    .package = "httr2"
  )

  got <- foundry_video_job_get("job_123")
  deleted <- foundry_video_job_delete("job_123")

  expect_equal(got$job_id, "job_123")
  expect_equal(deleted$deleted, TRUE)
  expect_match(captured[[1]], "GET .*/video/generations/jobs/job_123")
  expect_match(captured[[2]], "DELETE .*/video/generations/jobs/job_123")
})

test_that("foundry_video_download writes binary content", {
  setup_mock_env()
  path <- tempfile(fileext = ".mp4")
  mock_resp <- mock_httr2_raw_response(charToRaw("video bytes"))

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) mock_resp,
    .package = "httr2"
  )

  result <- foundry_video_download("vid_123", path)

  expect_equal(result$generation_id, "vid_123")
  expect_equal(result$content, "video")
  expect_true(file.exists(path))
})
