# Extract structured data with the Batch API

Prepare JSONL requests for structured extraction, upload them, and
create a batch. With `wait = TRUE`, waits for completion and returns
parsed results joined back to the input rows.

## Usage

``` r
foundry_extract_batch(
  data,
  text_col,
  schema,
  model,
  wait = FALSE,
  path = tempfile(fileext = ".jsonl"),
  schema_name = "ExtractedData",
  strict = TRUE,
  instructions = NULL,
  completion_window = "24h",
  api_key = NULL,
  token = NULL,
  endpoint_url = NULL,
  api_version = NULL
)
```

## Arguments

- data:

  Data frame containing input rows.

- text_col:

  Character. Name of the column containing input text.

- schema:

  List. JSON Schema object for structured extraction.

- model:

  Character. Model deployment name to include in each request.

- wait:

  Logical. Whether to block until the batch reaches a terminal state and
  parse results.

- path:

  Character. Optional JSONL path. Defaults to a temporary file.

- schema_name:

  Character. Name for `schema` when supplied.

- strict:

  Logical. Whether structured output should be strict.

- instructions:

  Character. Optional instructions for Responses API requests.

- completion_window:

  Character. Batch completion window, usually `"24h"`.

- api_key:

  Character. Optional API key override.

- token:

  Character. Optional bearer token override.

- endpoint_url:

  Character. Optional Foundry endpoint override.

- api_version:

  Character. Optional API version query value.

## Value

A batch tibble when `wait = FALSE`, or parsed result rows when
`wait = TRUE`.

## Examples

``` r
if (FALSE) { # \dontrun{
jobs <- data.frame(text = c("Great service.", "Slow support."))
schema <- foundry_schema(sentiment = schema_string())
foundry_extract_batch(jobs, text_col = "text", schema = schema, model = "gpt-5-nano")
} # }
```
