test_that("vector store helpers build requests and parse search", {
  setup_mock_env()
  captured <- NULL
  response <- list(data = list(
    list(file_id = "file_1", score = 0.9, content = "matching text")
  ))

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      mock_httr2_response(response)
    },
    .package = "httr2"
  )

  result <- foundry_vector_search("vs_123", "query", top_k = 3)

  expect_match(captured$url, "/vector_stores/vs_123/search$")
  expect_equal(captured$body$data$max_num_results, 3L)
  expect_equal(result$file_id, "file_1")
})

test_that("foundry_tool_file_search emits Responses tool shape", {
  tool <- foundry_tool_file_search(c("vs_1", "vs_2"), max_num_results = 5)

  expect_equal(tool$type, "file_search")
  expect_equal(tool$vector_store_ids, list("vs_1", "vs_2"))
  expect_equal(tool$max_num_results, 5L)
})
