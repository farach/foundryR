test_that("conversation helpers build v1 paths", {
  setup_mock_env()
  captured <- character()

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- c(captured, paste(req$method, req$url))
      mock_httr2_response(list(id = "conv_123", object = "conversation", created_at = 1741369938))
    },
    .package = "httr2"
  )

  created <- foundry_conversation_create(metadata = list(project = "demo"))
  got <- foundry_conversation_get("conv_123")

  expect_equal(created$conversation_id, "conv_123")
  expect_equal(got$conversation_id, "conv_123")
  expect_match(captured[[1]], "POST .*/conversations$")
  expect_match(captured[[2]], "GET .*/conversations/conv_123$")
})
