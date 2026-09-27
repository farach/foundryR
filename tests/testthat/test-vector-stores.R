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

test_that("vector search joins the text of each content part", {
  setup_mock_env()
  mock_request(list(data = list(list(
    file_id = "file_1",
    score = 0.8,
    content = list(
      list(type = "text", text = "Office hours are on Fridays."),
      list(type = "text", text = "Room 204.")
    )
  ))))

  result <- foundry_vector_search("vs_123", "office hours")
  expect_equal(result$content, "Office hours are on Fridays.\nRoom 204.")
})

test_that("vector store modify sends a JSON object and can target a project", {
  setup_mock_env()
  project <- "https://acct.services.ai.azure.com/api/projects/demo"
  withr::local_envvar(AZURE_FOUNDRY_PROJECT_TOKEN = "test-project-token")
  captured <- list()
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured[[length(captured) + 1L]] <<- req
      mock_httr2_response(list(id = "vs_123", object = "vector_store", name = "policies"))
    },
    .package = "httr2"
  )

  foundry_vector_store_modify("vs_123")
  expect_equal(
    as.character(jsonlite::toJSON(captured[[1]]$body$data, auto_unbox = TRUE)),
    "{}"
  )

  foundry_vector_store_create("policies", project_endpoint = project)
  expect_equal(captured[[2]]$url, paste0(project, "/openai/v1/vector_stores"))
  expect_equal(request_header(captured[[2]], "Authorization"), "Bearer test-project-token")
})
