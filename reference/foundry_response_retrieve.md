# Retrieve a stored Responses API response

Retrieve a stored Responses API response

## Usage

``` r
foundry_response_retrieve(response_id, api_key = NULL, endpoint = NULL)
```

## Arguments

- response_id:

  Character. The response ID to retrieve.

- api_key:

  Character. Optional API key override.

- endpoint:

  Character. Optional endpoint override.

## Value

A one-row tibble parsed like
[`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md).

## Examples

``` r
if (FALSE) { # \dontrun{
response <- foundry_response("Hello", model = "gpt-5.5")
foundry_response_retrieve(response$response_id)
} # }
```
