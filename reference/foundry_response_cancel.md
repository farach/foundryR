# Cancel a background Responses API response

Cancel a background Responses API response

## Usage

``` r
foundry_response_cancel(
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

A one-row tibble parsed like
[`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md).

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_response_cancel("resp_abc123")
} # }
```
