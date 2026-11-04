#' Turn Document Intelligence Results into Analysis Rows
#'
#' `r lifecycle::badge("experimental")`
#'
#' Import a completed Azure AI Document Intelligence REST result without making
#' network requests. Page text can be passed to [foundry_extract()] while keeping
#' document identifiers and source locations. Table cells remain in long form
#' so merged cells and cross-page tables are not silently flattened.
#'
#' @param result A parsed REST `analyzeResult` list, or the successful polling
#'   response containing it. Read saved JSON with
#'   `jsonlite::fromJSON(path, simplifyVector = FALSE)`. SDK-specific objects and
#'   simplified data frames are not supported.
#' @param document_id A single non-empty string identifying the source document.
#'   Supply a stable identifier from your own document inventory, not a secret
#'   download URL.
#'
#' @return `foundry_document_pages()` returns one row per page, with `document_id`,
#'   `page_number`, `text`, `spans`, and `words`. The `words` list-column retains
#'   word-level confidence and polygons exactly as supplied by the service.
#'   `foundry_document_cells()` returns one row per layout table cell, with
#'   `table_index` (one-based), `row_index` and `column_index` (zero-based, as in
#'   the service), `row_span`, `column_span`, `kind`, `text`,
#'   `service_confidence` (`NA` when absent), `spans`, and `bounding_regions`.
#'   Both include `model_id`, `api_version`, `string_index_type`,
#'   `content_format`, `extraction_method`, and `review_status = "unreviewed"`.
#'   Empty arrays return zero-row tibbles with the same column types.
#'
#' @details
#' These functions do not upload documents, perform OCR locally, or submit or
#' poll Document Intelligence jobs. They import the REST response from an
#' existing workflow. They do not import custom-model fields under `documents`.
#' Keep the original document and full JSON result alongside your analysis.
#'
#' Page text is sliced from the result's top-level `content` using page spans.
#' Disjoint spans are joined without an added separator. All three service
#' index conventions are supported: `unicodeCodePoint`, `utf16CodeUnit`, and
#' `textElements` (Unicode grapheme clusters, using R's PCRE library). Invalid
#' page offsets, including UTF-16 offsets splitting a surrogate pair, are errors.
#' Spans are kept unchanged and always refer to the original top-level content,
#' not the returned page or cell text. `content_format` records whether that
#' content is text or Markdown.
#'
#' Service confidence is not human validation or evidence that a downstream
#' annotation is correct. No confidence threshold marks a row as reviewed.
#' Compare a human-reviewed sample using [foundry_agreement()] before treating
#' model-produced fields as analytical variables.
#'
#' @seealso [foundry_extract()], [foundry_provenance()],
#'   <https://learn.microsoft.com/azure/ai-services/document-intelligence/concept/analyze-document-response>
#' @examples
#' result <- list(
#'   modelId = "prebuilt-read", apiVersion = "2024-11-30",
#'   stringIndexType = "unicodeCodePoint", contentFormat = "text",
#'   content = "A short document.",
#'   pages = list(list(
#'     pageNumber = 1L,
#'     spans = list(list(offset = 0L, length = 17L))
#'   ))
#' )
#' foundry_document_pages(result, document_id = "document-001")
#' foundry_document_cells(result, document_id = "document-001")
#' @export
foundry_document_pages <- function(result, document_id) {
  result <- foundry_document_result(result, document_id)
  pages <- foundry_document_array(result$pages, "pages", required = TRUE)
  spans <- lapply(pages, function(page) {
    foundry_document_array(page$spans, "page spans", required = TRUE)
  })
  bounds <- foundry_document_boundaries(result$content, result$stringIndexType)
  text <- vapply(spans, foundry_document_span_text, character(1),
    content = result$content, bounds = bounds, USE.NAMES = FALSE
  )
  page_number <- vapply(pages, function(page) {
    foundry_document_integer(page$pageNumber, "pageNumber", min = 1L)
  }, integer(1), USE.NAMES = FALSE)
  if (anyDuplicated(page_number)) {
    cli::cli_abort("Document Intelligence {.field pageNumber} values must be unique.")
  }

  tibble::tibble(
    document_id = rep(document_id, length(pages)),
    page_number = page_number,
    text = text,
    spans = spans,
    words = lapply(pages, function(page) foundry_document_array(page$words, "words")),
    !!!foundry_document_metadata(result, length(pages))
  )
}

#' @rdname foundry_document_pages
#' @export
foundry_document_cells <- function(result, document_id) {
  result <- foundry_document_result(result, document_id)
  tables <- foundry_document_array(result$tables, "tables")
  groups <- lapply(tables, function(table) {
    foundry_document_array(table$cells, "table cells", required = TRUE)
  })
  cells <- unlist(groups, recursive = FALSE, use.names = FALSE)
  n <- length(cells)
  integer_field <- function(name, default = NULL, min = 0L) {
    vapply(cells, function(cell) {
      foundry_document_integer(cell[[name]] %||% default, name, min)
    }, integer(1), USE.NAMES = FALSE)
  }
  text <- vapply(cells, function(cell) {
    foundry_document_string(cell$content, "cell content", empty = TRUE)
  }, character(1), USE.NAMES = FALSE)
  confidence <- vapply(cells, function(cell) {
    x <- cell$confidence
    if (is.null(x)) return(NA_real_)
    if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < 0 || x > 1) {
      cli::cli_abort("Document Intelligence {.field confidence} must be a number from 0 to 1.")
    }
    as.double(x)
  }, double(1), USE.NAMES = FALSE)

  tibble::tibble(
    document_id = rep(document_id, n),
    table_index = rep(seq_along(tables), lengths(groups)),
    row_index = integer_field("rowIndex"),
    column_index = integer_field("columnIndex"),
    row_span = integer_field("rowSpan", 1L, min = 1L),
    column_span = integer_field("columnSpan", 1L, min = 1L),
    kind = vapply(cells, function(cell) {
      foundry_document_string(cell$kind %||% "content", "cell kind")
    }, character(1), USE.NAMES = FALSE),
    text = text,
    service_confidence = confidence,
    spans = lapply(cells, function(cell) foundry_document_array(cell$spans, "cell spans")),
    bounding_regions = lapply(cells, function(cell) {
      foundry_document_array(cell$boundingRegions, "boundingRegions")
    }),
    !!!foundry_document_metadata(result, n)
  )
}

foundry_document_result <- function(result, document_id) {
  foundry_check_character_scalar(document_id, "document_id")
  if (!is.list(result) || is.data.frame(result)) {
    cli::cli_abort("{.arg result} must be a Document Intelligence REST result list.")
  }
  if (!is.null(result$status)) {
    status <- foundry_document_string(result$status, "status")
    if (!identical(status, "succeeded")) {
      cli::cli_abort("Document Intelligence analysis has not succeeded (status: {status}).")
    }
    if (is.null(result$analyzeResult)) {
      cli::cli_abort("The completed response has no {.field analyzeResult}.")
    }
  }
  result <- result$analyzeResult %||% result
  if (!is.list(result) || is.data.frame(result)) {
    cli::cli_abort("{.field analyzeResult} must be a REST result list.")
  }
  foundry_document_string(result$content, "content", empty = TRUE)
  foundry_document_string(result$stringIndexType, "stringIndexType")
  if (!result$stringIndexType %in% c("unicodeCodePoint", "utf16CodeUnit", "textElements")) {
    cli::cli_abort("Unsupported Document Intelligence {.field stringIndexType}: {result$stringIndexType}.")
  }
  result
}

foundry_document_metadata <- function(result, n) {
  optional_string <- function(name) {
    value <- result[[name]]
    if (is.null(value)) return(rep(NA_character_, n))
    rep(foundry_document_string(value, name), n)
  }
  list(
    model_id = optional_string("modelId"),
    api_version = optional_string("apiVersion"),
    string_index_type = optional_string("stringIndexType"),
    content_format = optional_string("contentFormat"),
    extraction_method = rep("azure_document_intelligence", n),
    review_status = rep("unreviewed", n)
  )
}

foundry_document_array <- function(x, field, required = FALSE) {
  if (is.null(x) && !required) return(list())
  if (!is.list(x) || is.data.frame(x) ||
      any(!vapply(x, function(item) is.list(item) && !is.data.frame(item), logical(1)))) {
    cli::cli_abort(c(
      "Document Intelligence {.field {field}} must be an array of objects.",
      "i" = "Parse REST JSON with {.code jsonlite::fromJSON(..., simplifyVector = FALSE)}."
    ))
  }
  unname(x)
}

foundry_document_string <- function(x, field, empty = FALSE) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || (!empty && !nzchar(x))) {
    cli::cli_abort("Document Intelligence {.field {field}} must be a single{if (empty) '' else ' non-empty'} string.")
  }
  x
}

foundry_document_integer <- function(x, field, min = 0L) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) ||
      x < min || x > .Machine$integer.max || x != floor(x)) {
    cli::cli_abort("Document Intelligence {.field {field}} must be an integer >= {min}.")
  }
  as.integer(x)
}

foundry_document_boundaries <- function(content, type) {
  n <- nchar(content, type = "chars")
  if (type == "unicodeCodePoint") return(list(units = NULL, chars = NULL, n = n))
  if (type == "utf16CodeUnit") {
    return(list(
      units = c(0, cumsum(ifelse(utf8ToInt(content) > 65535L, 2L, 1L))),
      chars = seq.int(0L, n)
    ))
  }
  if (!nzchar(content)) return(list(units = 0L, chars = 0L))
  clusters <- gregexpr("\\X", enc2utf8(content), perl = TRUE)[[1]]
  list(units = seq.int(0L, length(clusters)), chars = c(clusters - 1L, n))
}

foundry_document_span_text <- function(spans, content, bounds) {
  if (!length(spans)) return("")
  starts <- vapply(spans, function(span) {
    foundry_document_integer(span$offset, "span offset")
  }, integer(1), USE.NAMES = FALSE)
  sizes <- vapply(spans, function(span) {
    foundry_document_integer(span$length, "span length")
  }, integer(1), USE.NAMES = FALSE)
  ends <- as.double(starts) + sizes
  if (is.null(bounds$units)) {
    if (any(ends > bounds$n)) {
      cli::cli_abort("Document Intelligence spans extend beyond {.field content}.")
    }
  } else {
    start_index <- match(starts, bounds$units)
    end_index <- match(ends, bounds$units)
    if (anyNA(start_index) || anyNA(end_index)) {
      cli::cli_abort("Document Intelligence spans must fall on character boundaries within {.field content}.")
    }
    starts <- bounds$chars[start_index]
    ends <- bounds$chars[end_index]
  }
  keep <- sizes > 0L
  if (!any(keep)) return("")
  paste0(substring(content, starts[keep] + 1L, ends[keep]), collapse = "")
}
