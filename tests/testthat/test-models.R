test_that("foundry_models lists v1 models", {
  setup_mock_env()
  captured <- NULL
  mock_resp <- mock_httr2_response(list(
    object = "list",
    data = list(
      list(
        id = "gpt-4.1",
        object = "model",
        created = 1741369938,
        owned_by = "azure"
      )
    )
  ))

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      mock_resp
    },
    .package = "httr2"
  )

  result <- foundry_models()

  expect_equal(
    captured$url,
    "https://test-resource.openai.azure.com/openai/v1/models"
  )
  expect_equal(captured$method, "GET")
  expect_equal(result$id, "gpt-4.1")
  expect_s3_class(result$created, "POSIXct")
})
