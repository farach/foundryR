# Parse completed Microsoft Foundry batch results

Retrieve a batch, download its output and error JSONL files, and parse
each request result into a tibble. Responses, chat-completions, and
embeddings payloads are parsed into endpoint-specific columns when
possible.

## Usage

``` r
foundry_batch_results(
  batch_id,
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

A tibble with one row per batch request.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_batch_results("batch_abc123")
} # }
```
