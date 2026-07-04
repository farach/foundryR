# ============================================================================
# Input Validation Tests
# ============================================================================

test_that("foundry_embed handles empty input", {
  result <- foundry_embed(character(), model = "test")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
  expect_named(result, c(
    ".input_idx", "text", "embedding", "n_dims",
    ".error", ".error_msg", "raw_response"
  ))
})

test_that("foundry_embed requires model", {
  withr::local_envvar(
    AZURE_FOUNDRY_KEY = "test-key",
    AZURE_FOUNDRY_ENDPOINT = "https://test.openai.azure.com",
    AZURE_FOUNDRY_EMBED_MODEL = ""
  )

  expect_error(foundry_embed("Hello"), "Embedding model/deployment name is required")
})

# ============================================================================
# Similarity Function Tests
# ============================================================================

test_that("foundry_similarity requires data frame", {
  expect_error(foundry_similarity("not a df"), "must be a data frame")
})

test_that("foundry_similarity requires embedding column", {
  df <- tibble::tibble(text = c("a", "b"))
  expect_error(foundry_similarity(df), "embedding")
})

test_that("foundry_similarity requires at least 2 rows", {
  df <- tibble::tibble(
    text = "single",
    embedding = list(c(1, 2, 3))
  )
  expect_error(foundry_similarity(df), "at least 2")
})

test_that("foundry_similarity computes correct cosine similarity", {
  # Create test data with known embeddings
  df <- tibble::tibble(
    text = c("a", "b", "c"),
    embedding = list(
      c(1, 0, 0),  # Unit vector along x
      c(0, 1, 0),  # Unit vector along y (orthogonal to a)
      c(1, 0, 0)   # Same as a (identical)
    )
  )

  result <- foundry_similarity(df)

  expect_s3_class(result, "tbl_df")
  expect_named(result, c("text_1", "text_2", "similarity"))

  # a and c should have similarity 1 (identical)
  ac_sim <- result$similarity[result$text_1 == "a" & result$text_2 == "c"]
  expect_equal(ac_sim, 1, tolerance = 1e-10)

  # a and b should have similarity 0 (orthogonal)
  ab_sim <- result$similarity[result$text_1 == "a" & result$text_2 == "b"]
  expect_equal(ab_sim, 0, tolerance = 1e-10)
})

test_that("foundry_similarity filters NULL embeddings", {
  df <- tibble::tibble(
    text = c("a", "b", "c"),
    embedding = list(
      c(1, 0),
      NULL,
      c(0, 1)
    )
  )

  result <- foundry_similarity(df)

  expect_equal(nrow(result), 1)
  expect_equal(result$text_1, "a")
  expect_equal(result$text_2, "c")
})

test_that("foundry_similarity errors on mismatched embedding dimensions", {
  df <- tibble::tibble(
    text = c("a", "b"),
    embedding = list(c(1, 0), c(1, 0, 0))
  )
  expect_error(foundry_similarity(df), "same dimensionality")
})

test_that("foundry_similarity returns all unique pairs sorted by similarity", {
  df <- tibble::tibble(
    text = c("a", "b", "c", "d"),
    embedding = list(c(1, 0), c(1, 0), c(0, 1), c(-1, 0))
  )

  result <- foundry_similarity(df)

  # n*(n-1)/2 = 6 unique pairs
  expect_equal(nrow(result), 6)
  # sorted descending
  expect_false(is.unsorted(rev(result$similarity)))
  # identical vectors a,b -> similarity 1
  ab <- result$similarity[result$text_1 == "a" & result$text_2 == "b"]
  expect_equal(ab, 1, tolerance = 1e-10)
  # opposite vectors a,d -> similarity -1
  ad <- result$similarity[result$text_1 == "a" & result$text_2 == "d"]
  expect_equal(ad, -1, tolerance = 1e-10)
})

# ============================================================================
# Mocked API Tests
# ============================================================================

test_that("foundry_embed returns tibble with mocked response", {
  setup_mock_env()
  fixture <- load_fixture("embed", "response.json")
  mock_parallel_request(list(fixture))

  result <- foundry_embed("Hello world", model = "text-embedding-ada-002")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_equal(result$text, "Hello world")
  expect_true(is.list(result$embedding))
  expect_true(length(result$embedding[[1]]) > 0)
  expect_equal(result$.input_idx, 1L)
  expect_equal(result$.error, FALSE)
})

test_that("foundry_embed returns correct column types", {
  setup_mock_env()
  fixture <- load_fixture("embed", "response.json")
  mock_parallel_request(list(fixture))

  result <- foundry_embed("Test", model = "text-embedding-ada-002")

  expect_type(result$text, "character")
  expect_type(result$embedding, "list")
  expect_type(result$n_dims, "integer")
  expect_type(result$.error, "logical")
  expect_type(result$.error_msg, "character")
  expect_type(result$embedding[[1]], "double")
})

test_that("foundry_embed n_dims matches embedding length", {
  setup_mock_env()
  fixture <- load_fixture("embed", "response.json")
  mock_parallel_request(list(fixture))

  result <- foundry_embed("Test", model = "text-embedding-ada-002")

  expect_equal(result$n_dims, length(result$embedding[[1]]))
})

test_that("foundry_embed sends v1 array requests", {
  setup_mock_env()
  fixture <- load_fixture("embed", "response.json")
  mock_resp <- mock_httr2_response(fixture)
  captured <- NULL

  testthat::local_mocked_bindings(
    req_perform_parallel = function(reqs, ...) {
      captured <<- reqs[[1]]
      list(mock_resp)
    },
    .package = "httr2"
  )

  foundry_embed(c("one", "two"), model = "embed-v-4-0")

  expect_equal(captured$url, "https://test-resource.openai.azure.com/openai/v1/embeddings")
  expect_equal(captured$body$data$model, "embed-v-4-0")
  expect_equal(captured$body$data$input, c("one", "two"))
})

test_that("foundry_similarity can limit rows or return a matrix", {
  df <- tibble::tibble(
    text = c("a", "b", "c"),
    embedding = list(c(1, 0), c(1, 0), c(0, 1))
  )

  limited <- foundry_similarity(df, top_k = 1)
  mat <- foundry_similarity(df, as_matrix = TRUE)

  expect_equal(nrow(limited), 1L)
  expect_equal(dim(mat), c(3L, 3L))
  expect_equal(mat["a", "b"], 1, tolerance = 1e-10)
})

# ============================================================================
# Integration Test (requires real credentials)
# ============================================================================

test_that("foundry_embed returns tibble with real API", {
  skip_on_cran()
  skip_if_no_live_api()
  skip_if_no_auth()
  skip_if_no_model("AZURE_FOUNDRY_EMBED_MODEL")

  result <- foundry_embed(
    "Hello world",
    model = Sys.getenv("AZURE_FOUNDRY_EMBED_MODEL")
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(result$text, "Hello world")
  expect_true(is.list(result$embedding))
  expect_true(length(result$embedding[[1]]) > 0)
  expect_equal(result$n_dims, length(result$embedding[[1]]))
})
