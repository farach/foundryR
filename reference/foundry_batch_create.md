# Create a Microsoft Foundry batch

Create a Microsoft Foundry batch

## Usage

``` r
foundry_batch_create(
  input_file_id,
  endpoint = "/v1/responses",
  completion_window = "24h",
  metadata = NULL,
  api_key = NULL,
  token = NULL,
  endpoint_url = NULL,
  api_version = NULL
)
```

## Arguments

- input_file_id:

  Character. File ID for an uploaded JSONL batch file.

- endpoint:

  Character. Endpoint path for the batch requests.

- completion_window:

  Character. Batch completion window, usually `"24h"`.

- metadata:

  List. Optional metadata attached to the batch.

- api_key:

  Character. Optional API key override.

- token:

  Character. Optional bearer token override.

- endpoint_url:

  Character. Optional Foundry endpoint override.

- api_version:

  Character. Optional API version query value.

## Value

A one-row tibble with batch metadata.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_batch_create("file_abc123", endpoint = "/v1/responses")
} # }
```
