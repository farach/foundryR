# Delete a stored Responses API response

Delete a stored Responses API response

## Usage

``` r
foundry_response_delete(response_id, api_key = NULL, endpoint = NULL)
```

## Arguments

- response_id:

  Character. The response ID to delete.

- api_key:

  Character. Optional API key override.

- endpoint:

  Character. Optional endpoint override.

## Value

A tibble with deletion status.

## Examples

``` r
if (FALSE) { # \dontrun{
response <- foundry_response("Hello", model = "gpt-5.5")
foundry_response_delete(response$response_id)
} # }
```
