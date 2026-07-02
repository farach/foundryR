# List input items for a Responses API response

List input items for a Responses API response

## Usage

``` r
foundry_response_input_items(response_id, api_key = NULL, endpoint = NULL)
```

## Arguments

- response_id:

  Character. The response ID.

- api_key:

  Character. Optional API key override.

- endpoint:

  Character. Optional endpoint override.

## Value

A tibble with one row per input item and the raw item in a list-column.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_response_input_items("resp_abc123")
} # }
```
