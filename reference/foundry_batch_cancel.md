# Cancel a Microsoft Foundry batch

Cancel a Microsoft Foundry batch

## Usage

``` r
foundry_batch_cancel(
  batch_id,
  api_key = NULL,
  token = NULL,
  endpoint_url = NULL,
  api_version = NULL
)
```

## Arguments

- batch_id:

  Character. Batch ID to cancel.

- api_key:

  Character. Optional API key override.

- token:

  Character. Optional bearer token override.

- endpoint_url:

  Character. Optional Foundry endpoint override.

- api_version:

  Character. Optional API version query value.

## Value

A one-row tibble with batch metadata after cancellation.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a configured Azure endpoint and credentials,
# plus the ID of a batch that can be cancelled.
foundry_batch_cancel("batch_abc123")
} # }
```
