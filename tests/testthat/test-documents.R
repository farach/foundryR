document_result <- function() {
  list(
    apiVersion = "2024-11-30", modelId = "prebuilt-layout",
    stringIndexType = "unicodeCodePoint", contentFormat = "text",
    content = "First page.\nSecond page.",
    pages = list(
      list(pageNumber = 1L, spans = list(list(offset = 0L, length = 11L)),
        words = list(list(content = "First", confidence = 0.95,
          polygon = c(0, 0, 1, 0, 1, 1, 0, 1)))),
      list(pageNumber = 2L, spans = list(list(offset = 12L, length = 12L)))
    ),
    tables = list(list(
      rowCount = 1L, columnCount = 2L,
      cells = list(list(
        rowIndex = 0L, columnIndex = 0L, columnSpan = 2L,
        kind = "columnHeader", content = "First page.", confidence = 0.9,
        spans = list(list(offset = 0L, length = 11L)),
        boundingRegions = list(list(pageNumber = 1L, polygon = c(0, 0, 1, 0, 1, 1, 0, 1)))
      ))
    ))
  )
}

test_that("document pages preserve source identity, service metadata and words", {
  raw <- document_result()
  pages <- foundry_document_pages(list(status = "succeeded", analyzeResult = raw), "doc-1")
  expect_equal(pages$text, c("First page.", "Second page."))
  expect_identical(pages$page_number, 1:2)
  expect_equal(pages$document_id, rep("doc-1", 2))
  expect_equal(pages$model_id, rep("prebuilt-layout", 2))
  expect_equal(pages$api_version, rep("2024-11-30", 2))
  expect_equal(pages$review_status, rep("unreviewed", 2))
  expect_identical(pages$words[[1]], raw$pages[[1]]$words)
  expect_identical(pages$spans[[2]], raw$pages[[2]]$spans)
  expect_identical(raw, document_result())
})

test_that("document cell rows preserve merged cells and cross-page regions", {
  raw <- document_result()
  raw$tables[[2]] <- raw$tables[[1]]
  raw$tables[[2]]$cells[[1]]$confidence <- NULL
  raw$tables[[2]]$cells[[1]]$boundingRegions[[2]] <- list(pageNumber = 2L)
  cells <- foundry_document_cells(raw, "doc-1")
  expect_identical(cells$table_index, 1:2)
  expect_identical(cells$row_index, c(0L, 0L))
  expect_identical(cells$column_index, c(0L, 0L))
  expect_identical(cells$row_span, c(1L, 1L))
  expect_identical(cells$column_span, c(2L, 2L))
  expect_equal(cells$service_confidence, c(0.9, NA_real_))
  expect_equal(cells$review_status, rep("unreviewed", 2))
  expect_identical(cells$bounding_regions[[2]], raw$tables[[2]]$cells[[1]]$boundingRegions)
  expect_identical(cells$spans[[1]], raw$tables[[1]]$cells[[1]]$spans)
})

test_that("span slicing respects Unicode code points, UTF-16 and grapheme clusters", {
  raw <- document_result()
  raw$content <- "A\U0001f600e\u0301Z"
  raw$pages <- list(list(pageNumber = 1L))
  for (type in c("unicodeCodePoint", "utf16CodeUnit", "textElements")) {
    raw$stringIndexType <- type
    size <- switch(type, unicodeCodePoint = 3L, utf16CodeUnit = 4L, textElements = 2L)
    raw$pages[[1]]$spans <- list(list(offset = 1L, length = size))
    pages <- foundry_document_pages(raw, "unicode")
    expect_identical(pages$text, "\U0001f600e\u0301")
    expect_identical(pages$string_index_type, type)
    expect_identical(pages$spans[[1]], raw$pages[[1]]$spans)
  }
  raw$stringIndexType <- "utf16CodeUnit"
  raw$pages[[1]]$spans <- list(list(offset = 2L, length = 1L))
  expect_error(foundry_document_pages(raw, "unicode"), "character boundaries")
})

test_that("page text supports disjoint and zero-length spans", {
  raw <- document_result()
  raw$pages <- list(list(pageNumber = 7L, spans = list(
    list(offset = 0L, length = 5L), list(offset = 5L, length = 0L),
    list(offset = 12L, length = 6L)
  )))
  pages <- foundry_document_pages(raw, "doc")
  expect_identical(pages$text, "FirstSecond")
  expect_identical(pages$page_number, 7L)
  raw$pages[[1]]$spans <- list(list(offset = 0L, length = 0L))
  expect_identical(foundry_document_pages(raw, "doc")$text, "")
})

test_that("empty results have stable column types and optional fields stay missing", {
  raw <- document_result()
  pages <- foundry_document_pages(raw, "doc")
  cells <- foundry_document_cells(raw, "doc")
  raw$pages <- list()
  raw$tables <- list()
  expect_identical(foundry_document_pages(raw, "doc"), pages[0, ])
  expect_identical(foundry_document_cells(raw, "doc"), cells[0, ])
  raw$modelId <- raw$apiVersion <- raw$contentFormat <- NULL
  raw$pages <- list(list(pageNumber = 1L, spans = list()))
  out <- foundry_document_pages(raw, "doc")
  expect_true(is.na(out$model_id))
  expect_true(is.na(out$api_version))
  expect_true(is.na(out$content_format))
  for (type in c("unicodeCodePoint", "utf16CodeUnit", "textElements")) {
    raw$stringIndexType <- type
    raw$content <- ""
    expect_identical(foundry_document_pages(raw, "doc")$text, "")
  }
})

test_that("failed or incomplete responses and simplified JSON are rejected", {
  for (status in c("failed", "running", "notStarted", "canceled")) {
    expect_error(
      foundry_document_pages(list(status = status, analyzeResult = document_result()), "doc"),
      "has not succeeded"
    )
  }
  expect_error(foundry_document_pages(list(status = "succeeded"), "doc"), "no.*analyzeResult")
  expect_error(foundry_document_pages("not a list", "doc"), "REST result list")
  expect_error(foundry_document_pages(document_result(), ""), "non-empty")
  raw <- document_result()
  raw$pages <- data.frame(pageNumber = 1L)
  expect_error(foundry_document_pages(raw, "doc"), "simplifyVector = FALSE", fixed = TRUE)
  raw$pages <- NULL
  expect_error(foundry_document_pages(raw, "doc"), "pages.*array")
})

test_that("malformed fields and invalid offsets fail explicitly", {
  for (bad in list(NA, Inf, -1, 0.5, c(1, 2), "0")) {
    raw <- document_result()
    raw$pages[[1]]$spans[[1]]$offset <- bad
    expect_error(foundry_document_pages(raw, "doc"), "span offset")
  }
  raw <- document_result()
  raw$pages[[1]]$spans[[1]]$length <- 100L
  expect_error(foundry_document_pages(raw, "doc"), "beyond")
  raw <- document_result()
  raw$pages[[2]]$pageNumber <- 1L
  expect_error(foundry_document_pages(raw, "doc"), "unique")
  raw <- document_result()
  raw$stringIndexType <- "bytes"
  expect_error(foundry_document_pages(raw, "doc"), "Unsupported")
  raw <- document_result()
  raw$tables[[1]]$cells[[1]]$confidence <- 2
  expect_error(foundry_document_cells(raw, "doc"), "confidence")
  raw$tables[[1]]$cells[[1]]$confidence <- NULL
  raw$tables[[1]]$cells[[1]]$columnSpan <- 0L
  expect_error(foundry_document_cells(raw, "doc"), "columnSpan")
})

test_that("REST JSON import carries provenance through structured extraction", {
  setup_mock_env()
  json <- jsonlite::toJSON(document_result(), auto_unbox = TRUE)
  raw <- jsonlite::fromJSON(json, simplifyVector = FALSE)
  pages <- foundry_document_pages(raw, "doc")
  testthat::local_mocked_bindings(
    req_perform_parallel = function(reqs, ...) {
      lapply(reqs, function(req) {
        mock_httr2_response(mock_response_api_response(output_text = '{"label":"yes"}'))
      })
    },
    .package = "httr2"
  )
  coded <- foundry_extract(
    pages, text_col = "text", model = "test",
    schema = foundry_schema(label = schema_enum(c("yes", "no")))
  )
  expect_identical(coded[names(pages)], pages)
  expect_identical(coded$label, c("yes", "yes"))
  expect_false(any(coded$.error))
})
