test_that("foundry_moderate_image builds image analyze request", {
  setup_content_safety_env()
  response <- list(
    categoriesAnalysis = list(
      list(category = "Hate", severity = 0L),
      list(category = "Violence", severity = 2L)
    )
  )
  mock_resp <- mock_httr2_response(response)
  captured <- NULL

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      mock_resp
    },
    .package = "httr2"
  )

  result <- foundry_moderate_image("https://account.blob.core.windows.net/images/image.png")

  expect_match(captured$url, "/contentsafety/image:analyze")
  expect_equal(captured$body$data$image$blobUrl, "https://account.blob.core.windows.net/images/image.png")
  expect_equal(result$category, c("Hate", "Violence"))
})

test_that("foundry_moderate_image rejects non-blob remote URLs", {
  expect_error(
    foundry_moderate_image("https://example.com/image.png"),
    "Azure Blob Storage"
  )
})

test_that("foundry_protected_material parses detection response", {
  setup_content_safety_env()
  mock_request(list(protectedMaterialAnalysis = list(detected = TRUE)))

  result <- foundry_protected_material("quoted text")

  expect_equal(result$detected, TRUE)
  expect_equal(result$text, "quoted text")
})

test_that("documented Content Safety operations support resource tokens", {
  setup_content_safety_env()
  withr::local_envvar(AZURE_CONTENT_SAFETY_KEY = "")
  withr::defer(foundry_set_token_provider(NULL, scope = "resource"))
  provider_calls <- 0L
  foundry_set_token_provider(function() {
    provider_calls <<- provider_calls + 1L
    "content-safety-token"
  }, scope = "resource")
  captured <- NULL
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      mock_httr2_response(list(
        categoriesAnalysis = list(list(category = "Hate", severity = 0L))
      ))
    },
    .package = "httr2"
  )

  foundry_moderate_image(
    "https://account.blob.core.windows.net/images/image.png",
    categories = "Hate"
  )

  expect_equal(provider_calls, 1L)
  expect_equal("Authorization" %in% names(captured$headers), TRUE)
  expect_equal(
    "Ocp-Apim-Subscription-Key" %in% names(captured$headers),
    FALSE
  )
})

test_that("Content Safety keys take precedence over resource tokens", {
  setup_content_safety_env()
  withr::defer(foundry_set_token_provider(NULL, scope = "resource"))
  provider_calls <- 0L
  foundry_set_token_provider(function() {
    provider_calls <<- provider_calls + 1L
    "resource-token"
  }, scope = "resource")
  captured <- NULL
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      mock_httr2_response(list(
        categoriesAnalysis = list(list(category = "Hate", severity = 0L))
      ))
    },
    .package = "httr2"
  )

  foundry_moderate_image(
    "https://account.blob.core.windows.net/images/image.png",
    categories = "Hate"
  )

  expect_equal(provider_calls, 0L)
  expect_equal(
    "Ocp-Apim-Subscription-Key" %in% names(captured$headers),
    TRUE
  )
  expect_equal("Authorization" %in% names(captured$headers), FALSE)
})

test_that("blocklist helpers parse list and item responses", {
  setup_content_safety_env()
  captured <- character()

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- c(captured, paste(req$method, req$url))
      if (grepl("blocklistItems", req$url)) {
        mock_httr2_response(list(value = list(
          list(blocklistItemId = "item-1", text = "secret", isRegex = FALSE)
        )))
      } else {
        mock_httr2_response(list(value = list(
          list(blocklistName = "research", description = "terms")
        )))
      }
    },
    .package = "httr2"
  )

  lists <- foundry_blocklists()
  items <- foundry_blocklist_items("research")

  expect_equal(lists$name, "research")
  expect_equal(items$item_id, "item-1")
  expect_match(captured[[1]], "GET .*/text/blocklists")
  expect_match(captured[[2]], "GET .*/text/blocklists/research/blocklistItems")
})
