# ============================================================================
# Unit Tests for tidymodels Integration
# Tests for: step_foundry_embed() and related S3 methods
# ============================================================================

# Skip all tests if recipes package is not available
skip_if_not_installed("recipes")

library(recipes)

# ============================================================================
# step_foundry_embed() Constructor Tests
# ============================================================================

test_that("step_foundry_embed creates recipe step", {
  df <- data.frame(
    text = c("Hello", "World"),
    outcome = c(1, 0)
  )

  rec <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "text-embedding-ada-002")

  expect_s3_class(rec, "recipe")
  expect_length(rec$steps, 1)
  expect_s3_class(rec$steps[[1]], "step_foundry_embed")
})
test_that("step_foundry_embed stores model parameter", {
  df <- data.frame(
    text = c("Hello", "World"),
    outcome = c(1, 0)
  )

  rec <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "my-custom-model")

  expect_equal(rec$steps[[1]]$model, "my-custom-model")
})

test_that("step_foundry_embed stores dimensions parameter", {
  df <- data.frame(
    text = c("Hello", "World"),
    outcome = c(1, 0)
  )

  rec <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "test", dimensions = 256)

  expect_equal(rec$steps[[1]]$dimensions, 256)
})

test_that("step_foundry_embed stores prefix parameter", {
  df <- data.frame(
    text = c("Hello", "World"),
    outcome = c(1, 0)
  )

  rec <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "test", prefix = "vec_")

  expect_equal(rec$steps[[1]]$prefix, "vec_")
})

test_that("step_foundry_embed stores keep_original parameter", {
  df <- data.frame(
    text = c("Hello", "World"),
    outcome = c(1, 0)
  )

  rec <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "test", keep_original = TRUE)

  expect_true(rec$steps[[1]]$keep_original)
})

test_that("step_foundry_embed has default parameters", {
  df <- data.frame(
    text = c("Hello", "World"),
    outcome = c(1, 0)
  )

  rec <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "test")

  step <- rec$steps[[1]]
  expect_equal(step$role, "predictor")
  expect_false(step$trained)
  expect_equal(step$prefix, "emb_")
  expect_false(step$keep_original)
  expect_false(step$skip)
})

test_that("step_foundry_embed generates unique id", {
  df <- data.frame(
    text = c("Hello", "World"),
    outcome = c(1, 0)
  )

  rec1 <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "test")

  rec2 <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "test")

  # IDs should be different
  expect_false(rec1$steps[[1]]$id == rec2$steps[[1]]$id)
})

test_that("step_foundry_embed accepts custom id", {
  df <- data.frame(
    text = c("Hello", "World"),
    outcome = c(1, 0)
  )

  rec <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "test", id = "my_custom_id")

  expect_equal(rec$steps[[1]]$id, "my_custom_id")
})

# ============================================================================
# print.step_foundry_embed Tests
# ============================================================================

test_that("print.step_foundry_embed works for untrained step", {
  df <- data.frame(
    text = c("Hello", "World"),
    outcome = c(1, 0)
  )

  rec <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "test")

  # Should not error
  expect_output(print(rec), "Foundry embeddings")
})

test_that("print.step_foundry_embed shows column names when trained", {
  skip_on_cran()

  df <- data.frame(
    text = c("Hello", "World"),
    outcome = c(1, 0)
  )

  # Create a mock prepped recipe for testing print
  # We need to manually create a trained step
  rec <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "test")

  # Manually set trained = TRUE and columns for print test
  rec$steps[[1]]$trained <- TRUE
  rec$steps[[1]]$columns <- "text"

  expect_output(print(rec), "Foundry embeddings")
})

# ============================================================================
# tidy.step_foundry_embed Tests
# ============================================================================

test_that("tidy.step_foundry_embed returns tibble for untrained step", {
  df <- data.frame(
    text = c("Hello", "World"),
    outcome = c(1, 0)
  )

  rec <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "my-model", dimensions = 256)

  tidied <- tidy(rec$steps[[1]])

  expect_s3_class(tidied, "tbl_df")
  expect_named(tidied, c("terms", "model", "dimensions", "id"))
  expect_equal(tidied$model, "my-model")
  expect_equal(tidied$dimensions, 256)
})

test_that("tidy.step_foundry_embed handles NULL model and dimensions", {
  df <- data.frame(
    text = c("Hello", "World"),
    outcome = c(1, 0)
  )

  rec <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text)  # No model or dimensions specified

  tidied <- tidy(rec$steps[[1]])

  expect_true(is.na(tidied$model))
  expect_true(is.na(tidied$dimensions))
})

test_that("tidy.step_foundry_embed returns column names when trained", {
  df <- data.frame(
    text = c("Hello", "World"),
    outcome = c(1, 0)
  )

  rec <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "test")

  # Manually set trained state
  rec$steps[[1]]$trained <- TRUE
  rec$steps[[1]]$columns <- c("text")

  tidied <- tidy(rec$steps[[1]])

  expect_equal(tidied$terms, "text")
})

# ============================================================================
# required_pkgs.step_foundry_embed Tests
# ============================================================================

test_that("required_pkgs.step_foundry_embed returns foundryR", {
  df <- data.frame(
    text = c("Hello", "World"),
    outcome = c(1, 0)
  )

  rec <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "test")

  pkgs <- required_pkgs(rec$steps[[1]])

  expect_true("foundryR" %in% pkgs)
})

# ============================================================================
# prep.step_foundry_embed Tests (with mocking)
# ============================================================================

test_that("prep.step_foundry_embed identifies text columns", {
  setup_mock_env()

  df <- data.frame(
    description = c("Hello", "World"),
    outcome = c(1, 0),
    stringsAsFactors = FALSE
  )

  rec <- recipe(outcome ~ description, data = df) %>%
    step_foundry_embed(description, model = "test")

  # Mock foundry_embed to avoid API call
  mock_embeddings <- tibble::tibble(
    text = df$description,
    embedding = list(rnorm(10), rnorm(10)),
    n_dims = c(10L, 10L)
  )

  testthat::local_mocked_bindings(
    foundry_embed = function(...) mock_embeddings,
    .package = "foundryR"
  )

  prepped <- prep(rec, training = df)

  expect_true(prepped$steps[[1]]$trained)
  expect_equal(prepped$steps[[1]]$columns, "description")
})

test_that("prep.step_foundry_embed handles factor columns", {
  setup_mock_env()

  df <- data.frame(
    text = factor(c("Hello", "World")),
    outcome = c(1, 0)
  )

  rec <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "test")

  mock_embeddings <- tibble::tibble(
    text = as.character(df$text),
    embedding = list(rnorm(10), rnorm(10)),
    n_dims = c(10L, 10L)
  )

  testthat::local_mocked_bindings(
    foundry_embed = function(...) mock_embeddings,
    .package = "foundryR"
  )

  # Should not error - factors are allowed
  prepped <- prep(rec, training = df)
  expect_true(prepped$steps[[1]]$trained)
})

# ============================================================================
# bake.step_foundry_embed Tests (with mocking)
# ============================================================================

test_that("bake.step_foundry_embed creates embedding columns", {
  setup_mock_env()

  df <- data.frame(
    text = c("Hello", "World"),
    outcome = c(1, 0),
    stringsAsFactors = FALSE
  )

  rec <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "test", prefix = "emb_")

  n_dims <- 5

  mock_embeddings <- tibble::tibble(
    text = df$text,
    embedding = list(rnorm(n_dims), rnorm(n_dims)),
    n_dims = c(n_dims, n_dims)
  )

  testthat::local_mocked_bindings(
    foundry_embed = function(...) mock_embeddings,
    .package = "foundryR"
  )

  prepped <- prep(rec, training = df)
  baked <- bake(prepped, new_data = NULL)

  # Check that embedding columns were created
  expected_cols <- paste0("emb_text_", 1:n_dims)
  expect_true(all(expected_cols %in% names(baked)))
})

test_that("bake.step_foundry_embed removes original column by default", {
  setup_mock_env()

  df <- data.frame(
    text = c("Hello", "World"),
    outcome = c(1, 0),
    stringsAsFactors = FALSE
  )

  rec <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "test", keep_original = FALSE)

  mock_embeddings <- tibble::tibble(
    text = df$text,
    embedding = list(rnorm(5), rnorm(5)),
    n_dims = c(5L, 5L)
  )

  testthat::local_mocked_bindings(
    foundry_embed = function(...) mock_embeddings,
    .package = "foundryR"
  )

  prepped <- prep(rec, training = df)
  baked <- bake(prepped, new_data = NULL)

  expect_false("text" %in% names(baked))
})

test_that("bake.step_foundry_embed keeps original column when requested", {
  setup_mock_env()

  df <- data.frame(
    text = c("Hello", "World"),
    outcome = c(1, 0),
    stringsAsFactors = FALSE
  )

  rec <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "test", keep_original = TRUE)

  mock_embeddings <- tibble::tibble(
    text = df$text,
    embedding = list(rnorm(5), rnorm(5)),
    n_dims = c(5L, 5L)
  )

  testthat::local_mocked_bindings(
    foundry_embed = function(...) mock_embeddings,
    .package = "foundryR"
  )

  prepped <- prep(rec, training = df)
  baked <- bake(prepped, new_data = NULL)

  expect_true("text" %in% names(baked))
})

test_that("bake.step_foundry_embed uses custom prefix", {
  setup_mock_env()

  df <- data.frame(
    text = c("Hello", "World"),
    outcome = c(1, 0),
    stringsAsFactors = FALSE
  )

  rec <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "test", prefix = "vec_")

  mock_embeddings <- tibble::tibble(
    text = df$text,
    embedding = list(c(1, 2, 3), c(4, 5, 6)),
    n_dims = c(3L, 3L)
  )

  testthat::local_mocked_bindings(
    foundry_embed = function(...) mock_embeddings,
    .package = "foundryR"
  )

  prepped <- prep(rec, training = df)
  baked <- bake(prepped, new_data = NULL)

  expect_true(all(c("vec_text_1", "vec_text_2", "vec_text_3") %in% names(baked)))
})

test_that("bake.step_foundry_embed preserves outcome column", {
  setup_mock_env()

  df <- data.frame(
    text = c("Hello", "World"),
    outcome = c(1, 0),
    stringsAsFactors = FALSE
  )

  rec <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "test")

  mock_embeddings <- tibble::tibble(
    text = df$text,
    embedding = list(rnorm(5), rnorm(5)),
    n_dims = c(5L, 5L)
  )

  testthat::local_mocked_bindings(
    foundry_embed = function(...) mock_embeddings,
    .package = "foundryR"
  )

  prepped <- prep(rec, training = df)
  baked <- bake(prepped, new_data = NULL)

  expect_true("outcome" %in% names(baked))
  expect_equal(baked$outcome, c(1, 0))
})

test_that("bake.step_foundry_embed handles multiple text columns", {
  setup_mock_env()

  df <- data.frame(
    title = c("Title 1", "Title 2"),
    body = c("Body 1", "Body 2"),
    outcome = c(1, 0),
    stringsAsFactors = FALSE
  )

  rec <- recipe(outcome ~ ., data = df) %>%
    step_foundry_embed(title, model = "test", prefix = "title_") %>%
    step_foundry_embed(body, model = "test", prefix = "body_")

  mock_embeddings_title <- tibble::tibble(
    text = df$title,
    embedding = list(c(1, 2), c(3, 4)),
    n_dims = c(2L, 2L)
  )

  mock_embeddings_body <- tibble::tibble(
    text = df$body,
    embedding = list(c(5, 6), c(7, 8)),
    n_dims = c(2L, 2L)
  )

  call_count <- 0
  testthat::local_mocked_bindings(
    foundry_embed = function(text, ...) {
      call_count <<- call_count + 1
      if (call_count <= 2) {
        # First two calls are for title
        if (identical(text, df$title)) return(mock_embeddings_title)
        if (identical(text, as.character(df$title))) return(mock_embeddings_title)
      }
      # Later calls are for body
      if (identical(text, df$body)) return(mock_embeddings_body)
      if (identical(text, as.character(df$body))) return(mock_embeddings_body)
      # Default
      mock_embeddings_title
    },
    .package = "foundryR"
  )

  prepped <- prep(rec, training = df)
  baked <- bake(prepped, new_data = NULL)

  # Check both sets of embedding columns exist
  expect_true(all(c("title_title_1", "title_title_2") %in% names(baked)))
  expect_true(all(c("body_body_1", "body_body_2") %in% names(baked)))
})

test_that("bake.step_foundry_embed handles NA in embeddings", {
  setup_mock_env()

  df <- data.frame(
    text = c("Hello", "World"),
    outcome = c(1, 0),
    stringsAsFactors = FALSE
  )

  rec <- recipe(outcome ~ text, data = df) %>%
    step_foundry_embed(text, model = "test")

  # One embedding is NULL (simulating a failed API call)
  mock_embeddings <- tibble::tibble(
    text = df$text,
    embedding = list(c(1, 2, 3), NULL),
    n_dims = c(3L, NA_integer_)
  )

  testthat::local_mocked_bindings(
    foundry_embed = function(...) mock_embeddings,
    .package = "foundryR"
  )

  prepped <- prep(rec, training = df)
  baked <- bake(prepped, new_data = NULL)

  # First row should have values
  expect_false(is.na(baked$emb_text_1[1]))

  # Second row should have NAs for embedding columns
  expect_true(is.na(baked$emb_text_1[2]))
})

# ============================================================================
# Integration Test (requires real credentials)
# ============================================================================

test_that("step_foundry_embed works with real API", {
  skip_on_cran()
  skip_if_no_auth()
  skip_if_no_model("AZURE_FOUNDRY_EMBED_MODEL")

  df <- data.frame(
    text = c("Great product!", "Terrible", "Average"),
    sentiment = factor(c("pos", "neg", "neu")),
    stringsAsFactors = FALSE
  )

  rec <- recipe(sentiment ~ text, data = df) %>%
    step_foundry_embed(
      text,
      model = Sys.getenv("AZURE_FOUNDRY_EMBED_MODEL"),
      keep_original = FALSE
    )

  prepped <- prep(rec, training = df)
  baked <- bake(prepped, new_data = NULL)

  expect_s3_class(baked, "tbl_df")
  expect_equal(nrow(baked), 3)
  expect_true("sentiment" %in% names(baked))
  expect_false("text" %in% names(baked))

  # Should have many embedding columns
  expect_gt(ncol(baked), 10)

  # All embedding columns should be numeric
  emb_cols <- names(baked)[grepl("^emb_", names(baked))]
  for (col in emb_cols) {
    expect_type(baked[[col]], "double")
  }
})

test_that("step_foundry_embed works with new_data in bake", {
  skip_on_cran()
  skip_if_no_auth()
  skip_if_no_model("AZURE_FOUNDRY_EMBED_MODEL")

  train_df <- data.frame(
    text = c("Great!", "Bad"),
    outcome = c(1, 0),
    stringsAsFactors = FALSE
  )

  test_df <- data.frame(
    text = c("Amazing!", "Horrible"),
    outcome = c(1, 0),
    stringsAsFactors = FALSE
  )

  rec <- recipe(outcome ~ text, data = train_df) %>%
    step_foundry_embed(
      text,
      model = Sys.getenv("AZURE_FOUNDRY_EMBED_MODEL"),
      keep_original = FALSE
    )

  prepped <- prep(rec, training = train_df)

  # Bake with new data
  baked_test <- bake(prepped, new_data = test_df)

  expect_equal(nrow(baked_test), 2)
  expect_true("outcome" %in% names(baked_test))
  expect_false("text" %in% names(baked_test))
})
