# Collect completed structured extraction batch results

Download a completed extraction batch, parse structured Responses API
output with the same schema-driven flattening rules as
[`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md),
and join results back to the original input rows using the `row-N`
custom IDs written by
[`foundry_batch_requests()`](https://farach.github.io/foundryR/reference/foundry_batch_requests.md).

## Usage

``` r
foundry_extract_batch_results(
  batch_id,
  data,
  schema,
  text_col = NULL,
  keep_raw = FALSE,
  api_key = NULL,
  token = NULL,
  endpoint_url = NULL,
  api_version = NULL
)
```

## Arguments

- batch_id:

  Character. Batch ID to retrieve.

- data:

  Data frame originally submitted to
  [`foundry_extract_batch()`](https://farach.github.io/foundryR/reference/foundry_extract_batch.md).

- schema:

  List. JSON Schema object used for structured extraction.

- text_col:

  Character. Optional original input text column. When supplied,
  `.input_text` is filled from this column after joining rows.

- keep_raw:

  Logical. Whether to keep the raw JSONL result object in a
  `raw_batch_result` list-column.

- api_key:

  Character. Optional API key override.

- token:

  Character. Optional bearer token override.

- endpoint_url:

  Character. Optional Foundry endpoint override.

- api_version:

  Character. Optional API version query value.

## Value

A tibble containing the caller's input columns, extracted schema fields,
and dot-prefixed extraction metadata.

## Examples

``` r
if (FALSE) { # \dontrun{
schema <- foundry_schema(sentiment = schema_string())
jobs <- data.frame(text = c("Great service.", "Slow support."))
foundry_extract_batch_results("batch_abc123", jobs, schema)
} # }
```
