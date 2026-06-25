# List Microsoft Foundry batches

List Microsoft Foundry batches

## Usage

``` r
foundry_batches(
  limit = NULL,
  after = NULL,
  api_key = NULL,
  token = NULL,
  endpoint_url = NULL,
  api_version = NULL
)
```

## Arguments

- limit:

  Integer. Optional maximum number of batches to return.

- after:

  Character. Optional pagination cursor.

- api_key:

  Character. Optional API key override.

- token:

  Character. Optional bearer token override.

- endpoint_url:

  Character. Optional Foundry endpoint override.

- api_version:

  Character. Optional API version query value.

## Value

A tibble with one row per batch.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_batches(limit = 10)
} # }
```
