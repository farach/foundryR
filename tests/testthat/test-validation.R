capture_validation_warnings <- function(expr) {
  warnings <- character()
  value <- withCallingHandlers(
    expr,
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(value = value, warnings = warnings)
}

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
  expect_match(result$schema_hash, "^[0-9a-f]{64}$")
  expect_equal(attr(result$captured_at, "tzone"), "UTC")
  expect_type(result$metadata, "list")
})

test_that("foundry_agreement matches reviewed nominal alpha examples", {
  # Worked examples from Krippendorff (2011) as reported by the methods review.
  binary <- tibble::tibble(
    c1 = c(0, 1, 0, 0, 0, 0, 0, 0, 1, 0),
    c2 = c(1, 1, 1, 0, 0, 1, 0, 0, 0, 0)
  )
  binary_result <- foundry_agreement(binary, "c1", "c2")
  expect_equal(
    binary_result$value[binary_result$metric == "krippendorff_alpha"],
    2 / 21
  )

  nominal <- tibble::tibble(
    c1 = c("a", "a", "b", "b", "d", "c", "c", "c", "e", "d", "d", "a"),
    c2 = c("b", "a", "b", "b", "b", "c", "c", "c", "e", "d", "d", "d")
  )
  nominal_result <- foundry_agreement(nominal, "c1", "c2")
  expect_equal(
    nominal_result$value[nominal_result$metric == "krippendorff_alpha"],
    155 / 224
  )
})

test_that("foundry_agreement matches Cohen kappa worked example", {
  # Worked example from Cohen (1960) as reported by the methods review.
  counts <- c(88, 14, 18, 10, 40, 10, 2, 6, 12)
  data <- tibble::tibble(
    a = rep(rep(1:3, each = 3), times = counts),
    b = rep(rep(1:3, times = 3), times = counts)
  )

  result <- foundry_agreement(data, "a", "b")

  expect_equal(result$value[result$metric == "cohen_kappa"], 29 / 59)
})

test_that("foundry_agreement handles perfect, inverse, and one-category data", {
  perfect <- tibble::tibble(
    estimate = c("pass", "fail", "pass", "fail"),
    truth = c("pass", "fail", "pass", "fail")
  )
  perfect_result <- foundry_agreement(perfect, "estimate", "truth")
  expect_equal(perfect_result$value[perfect_result$metric == "cohen_kappa"], 1)
  expect_equal(
    perfect_result$value[perfect_result$metric == "krippendorff_alpha"],
    1
  )

  swapped <- tibble::tibble(
    estimate = rep(c("pass", "fail"), each = 5),
    truth = rep(c("fail", "pass"), each = 5)
  )
  swapped_result <- foundry_agreement(swapped, "estimate", "truth")
  expect_equal(swapped_result$value[swapped_result$metric == "cohen_kappa"], -1)
  expect_equal(
    swapped_result$value[swapped_result$metric == "krippendorff_alpha"],
    -0.9
  )

  one_category <- tibble::tibble(
    estimate = rep("pass", 3),
    truth = rep("pass", 3)
  )
  one_captured <- capture_validation_warnings(
    foundry_agreement(one_category, "estimate", "truth")
  )
  one_result <- one_captured$value
  expect_true(any(grepl("only one category", one_captured$warnings)))
  expect_true(is.na(one_result$value[one_result$metric == "cohen_kappa"]))
  expect_true(is.na(one_result$value[one_result$metric == "krippendorff_alpha"]))
})

test_that("foundry_agreement uses yardstick-style macro conventions", {
  data <- tibble::tibble(
    estimate = rep("pass", 10),
    truth = c(rep("pass", 7), rep("fail", 3))
  )

  captured <- capture_validation_warnings(
    foundry_agreement(data, "estimate", "truth")
  )
  result <- captured$value
  expect_true(any(grepl("label sets differ", captured$warnings)))
  expect_true(any(grepl("dropped class", captured$warnings)))

  expect_equal(result$value[result$metric == "accuracy"], 0.7)
  expect_equal(result$value[result$metric == "cohen_kappa"], 0)
  expect_equal(result$value[result$metric == "krippendorff_alpha"], -2 / 17)
  expect_equal(result$value[result$metric == "precision_macro"], 0.7)
  expect_equal(result$value[result$metric == "recall_macro"], 0.5)
  expect_equal(result$value[result$metric == "f1_macro"], 14 / 17)
})

test_that("foundry_agreement warns for label-set differences and dropped NA pairs", {
  case_data <- tibble::tibble(estimate = "Pass", truth = "pass")
  case_captured <- capture_validation_warnings(
    foundry_agreement(case_data, "estimate", "truth")
  )
  expect_true(any(grepl("label sets differ", case_captured$warnings)))

  missing_data <- tibble::tibble(
    estimate = c("yes", NA, "no"),
    truth = c("yes", "no", NA)
  )
  missing_captured <- capture_validation_warnings(
    foundry_agreement(missing_data, "estimate", "truth")
  )
  result <- missing_captured$value
  expect_true(any(grepl("2 incomplete", missing_captured$warnings)))
  expect_equal(result$n[[1]], 1L)
})

test_that("foundry_consistency canonicalizes records and reports failures", {
  schema <- foundry_schema(label = schema_string())
  outputs <- list(
    tibble::tibble(
      .input_idx = 1L,
      .input_text = "same",
      .error = FALSE,
      .error_msg = NA_character_,
      .data = list(list(a = 1, b = 2))
    ),
    tibble::tibble(
      .input_idx = 1L,
      .input_text = "same",
      .error = FALSE,
      .error_msg = NA_character_,
      .data = list(list(b = 2, a = 1))
    ),
    tibble::tibble(
      .input_idx = 1L,
      .input_text = "same",
      .error = FALSE,
      .error_msg = NA_character_,
      .data = list(list(a = 0.123441))
    ),
    tibble::tibble(
      .input_idx = 1L,
      .input_text = "same",
      .error = FALSE,
      .error_msg = NA_character_,
      .data = list(list(a = 0.123449))
    )
  )
  i <- 0L
  local_mocked_bindings(
    foundry_extract = function(...) {
      i <<- i + 1L
      outputs[[i]]
    }
  )

  result <- foundry_consistency("same", schema, n = 4)

  expect_equal(result$successful_runs, 4L)
  expect_equal(result$modal_share, 0.5)
  expect_length(unique(result$values[[1]]), 3L)
})

test_that("foundry_consistency reports all failed runs", {
  schema <- foundry_schema(label = schema_string())
  local_mocked_bindings(
    foundry_extract = function(...) {
      tibble::tibble(
        .input_idx = 1L,
        .input_text = "failed",
        .error = TRUE,
        .error_msg = "mock failure",
        .data = list(NULL)
      )
    }
  )

  result <- foundry_consistency("failed", schema, n = 3)

  expect_equal(result$successful_runs, 0L)
  expect_equal(result$failed_runs, 3L)
  expect_true(is.na(result$modal_share))
  expect_true(is.na(result$entropy))
})
