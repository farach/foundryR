# Retrieve a stored Responses API response

Retrieve a stored Responses API response

## Usage

``` r
foundry_response_retrieve(
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
response <- foundry_response("Hello")
foundry_response_retrieve(response$response_id)

agent_response <- foundry_response("Hello", agent = "my-agent")
foundry_response_retrieve(
  agent_response$response_id,
  project_endpoint = foundry_get_project_endpoint()
)
} # }
```
