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

test_that("foundry_agreement computes basic metrics", {
  data <- tibble::tibble(
    estimate = c("yes", "no", "yes", "no"),
    truth = c("yes", "no", "no", "no")
  )

  result <- foundry_agreement(data, "estimate", "truth")

  expect_equal(result$value[result$metric == "accuracy"], 0.75)
  expect_equal(result$value[result$metric == "f1_macro"], 11 / 15)
  expect_equal(result$n[[1]], 4L)
})

test_that("foundry_agreement reports Krippendorff's alpha", {
  data <- tibble::tibble(
    estimate = c("yes", "no", "yes", "no"),
    truth = c("yes", "no", "no", "no")
  )

  result <- foundry_agreement(data, "estimate", "truth")
  alpha <- result$value[result$metric == "krippendorff_alpha"]

  expect_true("krippendorff_alpha" %in% result$metric)
  expect_equal(alpha, 8 / 15)
})

test_that("foundry_provenance records schema hash", {
  schema <- foundry_schema(label = schema_string())

  result <- foundry_provenance("gpt-4.1", schema)

  expect_equal(result$model, "gpt-4.1")
  expect_type(result$schema_hash, "character")
  expect_type(result$metadata, "list")
})
