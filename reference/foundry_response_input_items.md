# List input items for a Responses API response

List input items for a Responses API response

## Usage

``` r
foundry_response_input_items(
  response_id,
  api_key = NULL,
  endpoint = NULL,
  project_endpoint = NULL
)
```

## Arguments

- response_id:

  Character. The response ID to retrieve.

- api_key:

  Character. Optional API key override.

- endpoint:

  Character. Optional resource endpoint override.

- project_endpoint:

  Character. Optional project endpoint override. Supply this for a
  response created through the project-scoped API.

## Value

A tibble with one row per input item and the raw item in a list-column.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_response_input_items("resp_abc123")
} # }
```
