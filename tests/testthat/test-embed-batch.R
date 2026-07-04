# ============================================================================
# Unit Tests for Batch Embedding Functions
# Tests for: foundry_embed_batch(), batch_vector()
# ============================================================================

# ============================================================================
# Input Validation Tests - foundry_embed_batch()
# ============================================================================

test_that("foundry_embed_batch requires model", {
  withr::local_envvar(
    AZURE_FOUNDRY_KEY = "test-key",
    AZURE_FOUNDRY_ENDPOINT = "https://test.openai.azure.com",
    AZURE_FOUNDRY_EMBED_MODEL = ""
  )

  expect_error(
    foundry_embed_batch(c("Hello", "World")),
    "Embedding model/deployment name is required"
  )
})

test_that("foundry_embed_batch requires character vector", {
  setup_mock_env()

  expect_error(
    foundry_embed_batch(123, model = "text-embedding-ada-002"),
    "must be a character vector"
  )

  expect_error(
    foundry_embed_batch(list("a", "b"), model = "text-embedding-ada-002"),
    "must be a character vector"
  )
})

test_that("foundry_embed_batch validates batch_size", {
  setup_mock_env()

  expect_error(
    foundry_embed_batch(c("a", "b"), model = "test", batch_size = 0),
    "batch_size.*must be at least 1"
  )

  expect_error(
    foundry_embed_batch(c("a", "b"), model = "test", batch_size = -5),
    "batch_size.*must be at least 1"
  )
})

test_that("foundry_embed_batch validates max_active", {
  setup_mock_env()

  expect_error(
    foundry_embed_batch(c("a", "b"), model = "test", max_active = 0),
    "max_active.*must be at least 1"
  )

  expect_error(
    foundry_embed_batch(c("a", "b"), model = "test", max_active = -1),
    "max_active.*must be at least 1"
  )
})

test_that("foundry_embed_batch handles empty input", {
  result <- foundry_embed_batch(character(), model = "test")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
  expect_named(result, c(
    ".input_idx", "text", "embedding", "n_dims",
    ".error", ".error_msg", "raw_response"
  ))
})

# ============================================================================
# batch_vector() Tests
# ============================================================================

test_that("batch_vector splits correctly with exact division", {
  x <- letters[1:6]
  batches <- batch_vector(x, batch_size = 2)

  expect_length(batches, 3)
  expect_equal(batches[[1]]$values, c("a", "b"))
  expect_equal(batches[[1]]$indices, 1:2)
  expect_equal(batches[[2]]$values, c("c", "d"))
  expect_equal(batches[[2]]$indices, 3:4)
  expect_equal(batches[[3]]$values, c("e", "f"))
  expect_equal(batches[[3]]$indices, 5:6)
})

test_that("batch_vector handles remainder", {
  x <- letters[1:7]
  batches <- batch_vector(x, batch_size = 3)

  expect_length(batches, 3)
  expect_equal(batches[[1]]$values, c("a", "b", "c"))
  expect_equal(batches[[1]]$indices, 1:3)
  expect_equal(batches[[2]]$values, c("d", "e", "f"))
  expect_equal(batches[[2]]$indices, 4:6)
  expect_equal(batches[[3]]$values, "g")
  expect_equal(batches[[3]]$indices, 7)
})

test_that("batch_vector handles single element", {
  x <- "single"
  batches <- batch_vector(x, batch_size = 10)

  expect_length(batches, 1)
  expect_equal(batches[[1]]$values, "single")
  expect_equal(batches[[1]]$indices, 1)
})

test_that("batch_vector handles empty input", {
  batches <- batch_vector(character(), batch_size = 5)

  expect_length(batches, 0)
  expect_type(batches, "list")
})

test_that("batch_vector preserves original indices", {
  x <- c("first", "second", "third", "fourth", "fifth")
  batches <- batch_vector(x, batch_size = 2)

  # All indices should be sequential and cover 1:5
  all_indices <- unlist(lapply(batches, function(b) b$indices))
  expect_equal(sort(all_indices), 1:5)
})

test_that("batch_vector handles batch_size larger than input", {
  x <- c("a", "b", "c")
  batches <- batch_vector(x, batch_size = 100)

  expect_length(batches, 1)
  expect_equal(batches[[1]]$values, c("a", "b", "c"))
  expect_equal(batches[[1]]$indices, 1:3)
})

test_that("batch_vector handles batch_size of 1", {
  x <- c("a", "b", "c")
  batches <- batch_vector(x, batch_size = 1)

  expect_length(batches, 3)
  expect_equal(batches[[1]]$values, "a")
  expect_equal(batches[[1]]$indices, 1)
  expect_equal(batches[[2]]$values, "b")
  expect_equal(batches[[2]]$indices, 2)
  expect_equal(batches[[3]]$values, "c")
  expect_equal(batches[[3]]$indices, 3)
})

# ============================================================================
# Return Type Tests
# ============================================================================

test_that("foundry_embed_batch returns correct column names", {
  result <- foundry_embed_batch(character(), model = "test")

  expected_cols <- c(
    ".input_idx", "text", "embedding", "n_dims",
    ".error", ".error_msg", "raw_response"
  )
  expect_named(result, expected_cols)
})

test_that("foundry_embed_batch returns correct column types (empty input)", {
  result <- foundry_embed_batch(character(), model = "test")

  expect_type(result$.input_idx, "integer")
  expect_type(result$text, "character")
  expect_type(result$embedding, "list")
  expect_type(result$n_dims, "integer")
  expect_type(result$.error, "logical")
  expect_type(result$.error_msg, "character")
})

# ============================================================================
# Mocked API Tests
# ============================================================================

test_that("foundry_embed_batch returns tibble with mocked response", {
  setup_mock_env()

  # Create mock response for batch embedding
  mock_response <- list(
    object = "list",
    model = "text-embedding-ada-002",
    data = list(
      list(
        index = 0,
        object = "embedding",
        embedding = as.list(rnorm(10))  # Simplified dimensions for testing
      ),
      list(
        index = 1,
        object = "embedding",
        embedding = as.list(rnorm(10))
      )
    ),
    usage = list(prompt_tokens = 8, total_tokens = 8)
  )

  # Mock req_perform_parallel to return our fixture
  mock_resp <- mock_httr2_response(mock_response)
  testthat::local_mocked_bindings(
    req_perform_parallel = function(reqs, ...) {
      # Return one response per request
      lapply(reqs, function(req) mock_resp)
    },
    .package = "httr2"
  )

  result <- foundry_embed_batch(
    c("Hello world", "Test message"),
    model = "text-embedding-ada-002",
    batch_size = 2,
    progress = FALSE
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_equal(result$text, c("Hello world", "Test message"))
})

test_that("foundry_embed_batch preserves original order", {
  setup_mock_env()

  texts <- c("First", "Second", "Third", "Fourth", "Fifth")

  # Create mock responses
  create_mock_response <- function(indices) {
    list(
      object = "list",
      model = "text-embedding-ada-002",
      data = lapply(seq_along(indices) - 1, function(i) {
        list(
          index = i,
          object = "embedding",
          embedding = as.list(rnorm(10))
        )
      }),
      usage = list(prompt_tokens = 4, total_tokens = 4)
    )
  }

  # Mock to handle multiple batches
  testthat::local_mocked_bindings(
    req_perform_parallel = function(reqs, ...) {
      lapply(seq_along(reqs), function(i) {
        batch_size <- if (i <= 2) 2 else 1  # First two batches have 2 items, last has 1
        mock_httr2_response(create_mock_response(1:batch_size))
      })
    },
    .package = "httr2"
  )

  result <- foundry_embed_batch(
    texts,
    model = "text-embedding-ada-002",
    batch_size = 2,
    progress = FALSE
  )

  expect_equal(result$.input_idx, 1:5)
  expect_equal(result$text, texts)
})

test_that("foundry_embed_batch tracks errors per batch", {
  setup_mock_env()

  texts <- c("Text 1", "Text 2", "Text 3", "Text 4")

  # Create one success and one error response
  success_response <- mock_httr2_response(list(
    object = "list",
    model = "text-embedding-ada-002",
    data = list(
      list(index = 0, object = "embedding", embedding = as.list(rnorm(10))),
      list(index = 1, object = "embedding", embedding = as.list(rnorm(10)))
    ),
    usage = list(prompt_tokens = 4, total_tokens = 4)
  ))

  error_response <- structure(
    list(message = "Rate limit exceeded"),
    class = c("error", "condition")
  )

  testthat::local_mocked_bindings(
    req_perform_parallel = function(reqs, ...) {
      list(success_response, error_response)
    },
    .package = "httr2"
  )

  result <- foundry_embed_batch(
    texts,
    model = "text-embedding-ada-002",
    batch_size = 2,
    progress = FALSE
  )

  expect_equal(nrow(result), 4)

  # First batch should succeed
  expect_false(result$.error[1])
  expect_false(result$.error[2])
  expect_true(is.na(result$.error_msg[1]))
  expect_true(is.na(result$.error_msg[2]))

  # Second batch should have errors
  expect_true(result$.error[3])
  expect_true(result$.error[4])
  expect_false(is.na(result$.error_msg[3]))
  expect_false(is.na(result$.error_msg[4]))
})

test_that("foundry_embed_batch returns n_dims for successful embeddings", {
  setup_mock_env()

  n_dims <- 256

  mock_response <- list(
    object = "list",
    model = "text-embedding-3-small",
    data = list(
      list(
        index = 0,
        object = "embedding",
        embedding = as.list(rnorm(n_dims))
      )
    ),
    usage = list(prompt_tokens = 4, total_tokens = 4)
  )

  mock_resp <- mock_httr2_response(mock_response)
  testthat::local_mocked_bindings(
    req_perform_parallel = function(reqs, ...) list(mock_resp),
    .package = "httr2"
  )

  result <- foundry_embed_batch(
    "Test",
    model = "text-embedding-3-small",
    dimensions = n_dims,
    batch_size = 1,
    progress = FALSE
  )

  expect_equal(result$n_dims[1], n_dims)
  expect_equal(length(result$embedding[[1]]), n_dims)
})

# ============================================================================
# Integration Test (requires real credentials)
# ============================================================================

test_that("foundry_embed_batch works with real API", {
  skip_on_cran()
  skip_if_no_live_api()
  skip_if_no_auth()
  skip_if_no_model("AZURE_FOUNDRY_EMBED_MODEL")

  texts <- c(
    "Machine learning transforms industries",
    "Deep learning uses neural networks",
    "NLP analyzes text data",
    "Computer vision interprets images"
  )

  result <- foundry_embed_batch(
    texts,
    model = Sys.getenv("AZURE_FOUNDRY_EMBED_MODEL"),
    batch_size = 2,
    progress = FALSE
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 4)
  expect_equal(result$text, texts)
  expect_equal(result$.input_idx, 1:4)

  # Check successful embeddings
  expect_true(all(!result$.error))
  expect_true(all(is.na(result$.error_msg)))
  expect_true(all(result$n_dims > 0))
  expect_true(all(sapply(result$embedding, function(e) length(e) > 0)))
})

test_that("foundry_embed_batch processes many texts efficiently", {
  skip_on_cran()
  skip_if_no_live_api()
  skip_if_no_auth()
  skip_if_no_model("AZURE_FOUNDRY_EMBED_MODEL")

  # Create a larger set of texts
  texts <- paste("Sample text number", 1:10)

  result <- foundry_embed_batch(
    texts,
    model = Sys.getenv("AZURE_FOUNDRY_EMBED_MODEL"),
    batch_size = 3,
    max_active = 2,
    progress = FALSE
  )

  expect_equal(nrow(result), 10)
  expect_equal(result$.input_idx, 1:10)

  # Verify all embeddings were generated
  successful <- sum(!result$.error)
  expect_equal(successful, 10)
})
