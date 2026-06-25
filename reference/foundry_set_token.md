# Set Azure AI Foundry Bearer Token

Set a Microsoft Entra ID bearer token for keyless authentication. API
keys remain supported, but Microsoft recommends keyless authentication
for production workloads.

## Usage

``` r
foundry_set_token(token, store = FALSE)
```

## Arguments

- token:

  Character string containing a bearer token. Do not include the
  `"Bearer "` prefix.

- store:

  Logical. If `TRUE`, stores the token in `.Renviron` for future
  sessions. Tokens expire, so this is usually only useful for local
  testing.

## Value

Invisibly returns `TRUE` if the token was set successfully.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_set_token("eyJ0eXAiOiJKV1QiLCJhbGciOi...")
} # }
```
