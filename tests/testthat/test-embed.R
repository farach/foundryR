test_that("foundry_embed handles empty input", {
  result <- foundry_embed(character(), model = "test")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
  expect_named(result, c("text", "embedding", "n_dims"))
})

test_that("foundry_embed requires model", {
  withr::local_envvar(
    AZURE_FOUNDRY_KEY = "test-key",
    AZURE_FOUNDRY_ENDPOINT = "https://test.openai.azure.com",
    AZURE_FOUNDRY_EMBED_MODEL = ""
  )

  expect_error(foundry_embed("Hello"), "Embedding model/deployment name is required")
})

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

# Integration test
test_that("foundry_embed returns tibble with real API", {
  skip_on_cran()
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
