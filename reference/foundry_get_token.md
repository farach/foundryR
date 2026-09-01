# Get Azure AI Foundry Bearer Token

Retrieve a bearer token from the environment or a provided value.

## Usage

``` r
foundry_get_token(
  token = NULL,
  required = FALSE,
  scope = c("resource", "project")
)
```

## Arguments

- token:

  Character. Optional token to use instead of environment variables.

- required:

  Logical. If `TRUE`, throws an error when no token is found.

- scope:

  Character. Endpoint family for the token.

## Value

The bearer token string, or `NULL` if not found and not required.
