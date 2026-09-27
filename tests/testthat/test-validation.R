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
