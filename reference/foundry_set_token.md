# Set Azure AI Foundry Bearer Token

Set a Microsoft Entra ID bearer token for keyless authentication. API
keys remain supported, but Microsoft recommends keyless authentication
for production workloads.

## Usage

``` r
foundry_set_token(token, store = FALSE, scope = c("resource", "project"))
```

## Arguments

- token:

  Character string containing a bearer token. Do not include the
  `"Bearer "` prefix.

- store:

  Logical. If `TRUE`, stores the token in foundryR's package-specific
  user configuration file. Tokens expire, so persistent tokens are
  usually only useful for local testing.

- scope:

  Character. Endpoint family for the token: `"resource"` for
  resource-level `/openai/v1` and supported Content Safety operations,
  or `"project"` for `/api/projects/...` operations.

## Value

Invisibly returns `TRUE` if the token was set successfully.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_set_token("eyJ0eXAiOiJKV1QiLCJhbGciOi...")
} # }
```
