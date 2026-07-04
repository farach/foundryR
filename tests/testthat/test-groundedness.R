# ============================================================================
# Input Validation Tests
# ============================================================================

test_that("foundry_groundedness requires text", {
  setup_content_safety_env()

  expect_error(foundry_groundedness(), "text")
  expect_error(foundry_groundedness(NULL), "text")
})

test_that("foundry_groundedness requires grounding_sources", {
  setup_content_safety_env()

  expect_error(
    foundry_groundedness(text = "Test"),
    "grounding_sources"
  )

  expect_error(
    foundry_groundedness(text = "Test", grounding_sources = NULL),
    "grounding_sources"
  )
})

test_that("foundry_groundedness requires query for QnA task", {
  setup_content_safety_env()

  expect_error(
    foundry_groundedness(
      text = "Paris is the capital.",
      grounding_sources = "Paris is the capital of France.",
      task = "QnA"
    ),
    "query.*is required"
  )
})

test_that("foundry_groundedness accepts Summarization without query", {
  setup_content_safety_env()
  fixture <- load_fixture("groundedness", "response_grounded.json")
  mock_request(fixture)

  # Should not error when task is Summarization and no query
 expect_no_error(
    foundry_groundedness(
      text = "Paris is the capital.",
      grounding_sources = "Paris is the capital of France.",
      task = "Summarization"
    )
  )
})

test_that("foundry_groundedness requires endpoint", {
  withr::local_envvar(
    AZURE_CONTENT_SAFETY_ENDPOINT = "",
    AZURE_CONTENT_SAFETY_KEY = "test-key"
  )

  expect_error(
    foundry_groundedness(
      text = "Test",
      grounding_sources = "Source",
      query = "Question?"
    ),
    "endpoint is required"
  )
})

test_that("foundry_groundedness requires API key", {
  withr::local_envvar(
    AZURE_CONTENT_SAFETY_ENDPOINT = "https://test.cognitiveservices.azure.com",
    AZURE_CONTENT_SAFETY_KEY = ""
  )

  expect_error(
    foundry_groundedness(
      text = "Test",
      grounding_sources = "Source",
      query = "Question?"
    ),
    "API key is required"
  )
})

# ============================================================================
# Mocked API Tests - Grounded Response
# ============================================================================

test_that("foundry_groundedness returns tibble for grounded response", {
  setup_content_safety_env()
  fixture <- load_fixture("groundedness", "response_grounded.json")
  mock_request(fixture)

  result <- foundry_groundedness(
    text = "The capital of France is Paris.",
    grounding_sources = "Paris is the capital and largest city of France.",
    query = "What is the capital of France?"
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_named(result, c("grounded", "grounded_pct", "ungrounded_pct", "ungrounded_segments", "ungrounded_reasons", "correction_text"))
})

test_that("foundry_groundedness returns TRUE for grounded content", {
  setup_content_safety_env()
  fixture <- load_fixture("groundedness", "response_grounded.json")
  mock_request(fixture)

  result <- foundry_groundedness(
    text = "The capital of France is Paris.",
    grounding_sources = "Paris is the capital and largest city of France.",
    query = "What is the capital of France?"
  )

  expect_true(result$grounded)
  expect_equal(result$grounded_pct, 1.0)
  expect_equal(result$ungrounded_pct, 0.0)
  expect_equal(result$ungrounded_segments[[1]], character(0))
})

# ============================================================================
# Mocked API Tests - Ungrounded Response
# ============================================================================

test_that("foundry_groundedness returns FALSE for ungrounded content", {
  setup_content_safety_env()
  fixture <- load_fixture("groundedness", "response_ungrounded.json")
  mock_request(fixture)

  result <- foundry_groundedness(
    text = "Paris is the capital. It has a population of 12 million.",
    grounding_sources = "Paris is the capital of France.",
    query = "Tell me about Paris."
  )

  expect_false(result$grounded)
  expect_equal(result$ungrounded_pct, 0.35)
  expect_equal(result$grounded_pct, 0.65)
})

test_that("foundry_groundedness returns ungrounded segments", {
  setup_content_safety_env()
  fixture <- load_fixture("groundedness", "response_ungrounded.json")
  mock_request(fixture)

  result <- foundry_groundedness(
    text = "Paris is the capital. It has a population of 12 million.",
    grounding_sources = "Paris is the capital of France.",
    query = "Tell me about Paris."
  )

  segments <- result$ungrounded_segments[[1]]
  expect_type(segments, "character")
  expect_true(length(segments) > 0)
  expect_true("It has a population of 12 million." %in% segments)
})

# ============================================================================
# Column Type Tests
# ============================================================================

test_that("foundry_groundedness returns correct column types", {
  setup_content_safety_env()
  fixture <- load_fixture("groundedness", "response_grounded.json")
  mock_request(fixture)

  result <- foundry_groundedness(
    text = "Test text",
    grounding_sources = "Source document",
    query = "Test query?"
  )

  expect_type(result$grounded, "logical")
  expect_true(is.numeric(result$grounded_pct))
  expect_true(is.numeric(result$ungrounded_pct))
  expect_type(result$ungrounded_segments, "list")
})

# ============================================================================
# Multiple Grounding Sources Tests
# ============================================================================

test_that("foundry_groundedness accepts multiple grounding sources", {
  setup_content_safety_env()
  fixture <- load_fixture("groundedness", "response_grounded.json")
  mock_request(fixture)

  sources <- c(
    "Paris is the capital of France.",
    "France is a country in Europe.",
    "The Eiffel Tower is in Paris."
  )

  result <- foundry_groundedness(
    text = "Paris, the capital of France, has the Eiffel Tower.",
    grounding_sources = sources,
    query = "Tell me about Paris."
  )

  expect_s3_class(result, "tbl_df")
  expect_true(result$grounded)
})

# ============================================================================
# Domain and Task Options Tests
# ============================================================================

test_that("foundry_groundedness accepts Medical domain", {
  setup_content_safety_env()
  fixture <- load_fixture("groundedness", "response_grounded.json")
  mock_request(fixture)

  expect_no_error(
    foundry_groundedness(
      text = "The patient should take medication.",
      grounding_sources = "Prescribed medication regimen.",
      query = "What is the treatment?",
      domain = "Medical"
    )
  )
})

test_that("foundry_groundedness accepts Summarization task", {
  setup_content_safety_env()
  fixture <- load_fixture("groundedness", "response_grounded.json")
  mock_request(fixture)

  expect_no_error(
    foundry_groundedness(
      text = "This is a summary.",
      grounding_sources = "Original document content.",
      task = "Summarization"
    )
  )
})

# ============================================================================
# Correction (mitigating) and reasoning output Tests
# ============================================================================

test_that("foundry_llm_resource builds the LLMResource shape", {
  res <- foundry_llm_resource(
    endpoint = "https://my-openai.openai.azure.com",
    deployment_name = "gpt-4o"
  )

  expect_equal(res$resourceType, "AzureOpenAI")
  expect_equal(res$azureOpenAIEndpoint, "https://my-openai.openai.azure.com")
  expect_equal(res$azureOpenAIDeploymentName, "gpt-4o")
})

test_that("foundry_groundedness rejects correction without an llm_resource", {
  setup_content_safety_env()

  expect_error(
    foundry_groundedness(
      text = "The patient name is Kevin.",
      grounding_sources = "The patient name is Jane.",
      task = "Summarization",
      correction = TRUE
    ),
    "requires an Azure OpenAI resource"
  )
})

test_that("foundry_groundedness validates malformed llm_resource", {
  setup_content_safety_env()

  expect_error(
    foundry_groundedness(
      text = "Test",
      grounding_sources = "Source",
      task = "Summarization",
      llm_resource = list(azureOpenAIEndpoint = "https://x")
    ),
    "azureOpenAIDeploymentName"
  )
})

test_that("foundry_groundedness sends mitigating and llmResource and returns correction_text", {
  setup_content_safety_env()

  captured <- NULL
  resp <- mock_httr2_response(list(
    ungroundedDetected = TRUE,
    ungroundedPercentage = 1,
    ungroundedDetails = list(list(
      text = "The patient name is Kevin.",
      reason = "Grounding source states the name is Jane."
    )),
    correctionText = "The patient name is Jane."
  ))
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  result <- foundry_groundedness(
    text = "The patient name is Kevin.",
    grounding_sources = "The patient name is Jane.",
    task = "Summarization",
    domain = "Medical",
    correction = TRUE,
    llm_resource = foundry_llm_resource(
      endpoint = "https://my-openai.openai.azure.com",
      deployment_name = "gpt-4o"
    )
  )

  expect_true(captured$body$data$mitigating)
  expect_equal(captured$body$data$llmResource$azureOpenAIDeploymentName, "gpt-4o")
  expect_equal(result$correction_text, "The patient name is Jane.")
  expect_false(result$grounded)
})

test_that("foundry_groundedness surfaces reasons aligned with segments", {
  setup_content_safety_env()

  resp <- mock_httr2_response(list(
    ungroundedDetected = TRUE,
    ungroundedPercentage = 0.5,
    ungroundedDetails = list(
      list(text = "Population is 12 million.", reason = "Source gives no figure."),
      list(text = "Founded in 1850.", reason = "Source says 1900.")
    )
  ))
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) resp,
    .package = "httr2"
  )

  result <- foundry_groundedness(
    text = "Population is 12 million. Founded in 1850.",
    grounding_sources = "A large city founded in 1900.",
    task = "Summarization",
    reasoning = TRUE
  )

  expect_equal(result$ungrounded_segments[[1]],
               c("Population is 12 million.", "Founded in 1850."))
  expect_equal(result$ungrounded_reasons[[1]],
               c("Source gives no figure.", "Source says 1900."))
  expect_true(is.na(result$correction_text))
})

test_that("foundry_groundedness validates the correction flag", {
  setup_content_safety_env()

  expect_error(
    foundry_groundedness(
      text = "Test",
      grounding_sources = "Source",
      task = "Summarization",
      correction = "yes"
    ),
    "correction"
  )
})

# ============================================================================
# Integration Test (requires real credentials)
# ============================================================================

test_that("foundry_groundedness returns tibble with real API", {
  skip_on_cran()
  skip_if_no_live_api()
  skip_if(
    Sys.getenv("AZURE_CONTENT_SAFETY_KEY") == "",
    "AZURE_CONTENT_SAFETY_KEY not set"
  )
  skip_if(
    Sys.getenv("AZURE_CONTENT_SAFETY_ENDPOINT") == "",
    "AZURE_CONTENT_SAFETY_ENDPOINT not set"
  )

  result <- foundry_groundedness(
    text = "The capital of France is Paris.",
    grounding_sources = "Paris is the capital and largest city of France.",
    query = "What is the capital of France?",
    task = "QnA"
  )

  expect_s3_class(result, "tbl_df")
  expect_named(result, c("grounded", "grounded_pct", "ungrounded_pct", "ungrounded_segments", "ungrounded_reasons", "correction_text"))
  expect_type(result$grounded, "logical")
})
