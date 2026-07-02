test_that("foundry_agent_tool builds the tool schema", {
  tool <- foundry_agent_tool("order_car", "Buy a car model")

  expect_equal(tool$type, "function")
  expect_equal(tool[["function"]]$name, "order_car")
  expect_equal(tool[["function"]]$description, "Buy a car model")
})

test_that("foundry_agent_tool_call builds the tool-call schema", {
  call <- foundry_agent_tool_call("get_limit", id = "call_001", arguments = "{}")

  expect_equal(call$type, "function")
  expect_equal(call[["function"]]$name, "get_limit")
  expect_equal(call[["function"]]$arguments, "{}")
  expect_equal(call$id, "call_001")
})

test_that("foundry_agent_message builds turns and drops empty fields", {
  user_turn <- foundry_agent_message("Prompt", "User", "hello")
  expect_equal(user_turn$source, "Prompt")
  expect_equal(user_turn$role, "User")
  expect_equal(user_turn$contents, "hello")
  expect_null(user_turn$toolCalls)
  expect_null(user_turn$toolCallId)

  tool_turn <- foundry_agent_message(
    "Completion", "Tool",
    contents = "100000",
    tool_call_id = "call_001"
  )
  expect_equal(tool_turn$toolCallId, "call_001")
})

test_that("foundry_agent_message rejects invalid source and role", {
  expect_error(foundry_agent_message("Bogus", "User"), "arg")
  expect_error(foundry_agent_message("Prompt", "Robot"), "arg")
})

# ---------------------------------------------------------------------------
# Protected material for code
# ---------------------------------------------------------------------------

test_that("foundry_protected_code parses detection and citations", {
  setup_content_safety_env()

  captured <- NULL
  resp <- mock_httr2_response(list(
    protectedMaterialAnalysis = list(
      detected = TRUE,
      codeCitations = list(
        list(
          license = "NOASSERTION",
          sourceUrls = list(
            "https://github.com/a/b/tree/x/game.py",
            "https://github.com/c/d/tree/y/jump.py"
          )
        )
      )
    )
  ))
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  result <- foundry_protected_code("import pygame")

  expect_equal(captured$body$data$code, "import pygame")
  expect_match(captured$url, "text:detectProtectedMaterialForCode")
  expect_match(captured$url, "api-version=2024-09-15-preview")
  expect_true(result$detected)

  citations <- result$citations[[1]]
  expect_s3_class(citations, "tbl_df")
  expect_equal(citations$license, "NOASSERTION")
  expect_equal(length(citations$source_urls[[1]]), 2L)
})

test_that("foundry_protected_code handles clean code with no citations", {
  setup_content_safety_env()

  resp <- mock_httr2_response(list(
    protectedMaterialAnalysis = list(detected = FALSE, codeCitations = list())
  ))
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) resp,
    .package = "httr2"
  )

  result <- foundry_protected_code("print('hi')")

  expect_false(result$detected)
  expect_equal(nrow(result$citations[[1]]), 0L)
})

test_that("foundry_protected_code rejects non-character input", {
  expect_error(foundry_protected_code(123), "character")
})

# ---------------------------------------------------------------------------
# Multimodal image-with-text moderation
# ---------------------------------------------------------------------------

test_that("foundry_moderate_multimodal sends image, text and OCR flag", {
  setup_content_safety_env()

  captured <- NULL
  resp <- mock_httr2_response(list(
    categoriesAnalysis = list(
      list(category = "Hate", severity = 2),
      list(category = "SelfHarm", severity = 0),
      list(category = "Sexual", severity = 0),
      list(category = "Violence", severity = 0)
    )
  ))
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  result <- foundry_moderate_multimodal(
    image = "https://acct.blob.core.windows.net/c/meme.png",
    text = "a caption",
    enable_ocr = TRUE
  )

  expect_equal(captured$body$data$image$blobUrl,
               "https://acct.blob.core.windows.net/c/meme.png")
  expect_true(captured$body$data$enableOcr)
  expect_equal(captured$body$data$text, "a caption")
  expect_match(captured$url, "imageWithText:analyze")
  expect_match(captured$url, "api-version=2024-09-15-preview")

  expect_equal(nrow(result), 4L)
  expect_equal(result$label[result$category == "Hate"], "low")
})

test_that("foundry_moderate_multimodal validates categories", {
  setup_content_safety_env()

  expect_error(
    foundry_moderate_multimodal(
      image = "https://acct.blob.core.windows.net/c/x.png",
      categories = c("Hate", "Bogus")
    ),
    "Invalid categories"
  )
})

# ---------------------------------------------------------------------------
# Task adherence
# ---------------------------------------------------------------------------

test_that("foundry_task_adherence sends tools and messages and parses risk", {
  setup_content_safety_env()

  captured <- NULL
  resp <- mock_httr2_response(list(
    taskRiskDetected = TRUE,
    details = "Agent ordered a car without confirmation."
  ))
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      resp
    },
    .package = "httr2"
  )

  result <- foundry_task_adherence(
    tools = list(
      foundry_agent_tool("order_car", "Buy a car model")
    ),
    messages = list(
      foundry_agent_message("Prompt", "User", "How many can I buy?"),
      foundry_agent_message(
        "Completion", "Assistant", "Ordering now",
        tool_calls = list(
          foundry_agent_tool_call("order_car", id = "call_001")
        )
      )
    )
  )

  expect_match(captured$url, "agent:analyzeTaskAdherence")
  expect_match(captured$url, "api-version=2025-09-15-preview")
  expect_equal(captured$body$data$tools[[1]][["function"]]$name, "order_car")
  expect_equal(captured$body$data$messages[[2]]$toolCalls[[1]]$id, "call_001")

  expect_true(result$task_risk_detected)
  expect_match(result$details, "without confirmation")
})

test_that("foundry_task_adherence reports aligned transcripts", {
  setup_content_safety_env()

  resp <- mock_httr2_response(list(taskRiskDetected = FALSE))
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) resp,
    .package = "httr2"
  )

  result <- foundry_task_adherence(
    messages = list(foundry_agent_message("Prompt", "User", "hi"))
  )

  expect_false(result$task_risk_detected)
  expect_true(is.na(result$details))
})

test_that("foundry_task_adherence requires a non-empty messages list", {
  expect_error(foundry_task_adherence(messages = list()), "non-empty")
  expect_error(foundry_task_adherence(messages = "nope"), "non-empty")
})
