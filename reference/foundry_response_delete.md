# Delete a stored Responses API response

Delete a stored Responses API response

## Usage

``` r
foundry_response_delete(
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

A tibble with deletion status.

## Examples

``` r
if (FALSE) { # \dontrun{
response <- foundry_response("Hello")
foundry_response_delete(response$response_id)
} # }
```
