# Set a Microsoft Entra ID token provider

Register a function that returns a Microsoft Entra ID bearer token when
foundryR needs to authenticate without an API key. This is useful for
long polling jobs and keyless production environments where tokens
should be refreshed automatically.

## Usage

``` r
foundry_set_token_provider(provider)
```

## Arguments

- provider:

  Function or `NULL`. A zero-argument function that returns a bearer
  token string. Use `NULL` to clear the provider.

## Value

Invisibly returns the previous provider.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_set_token_provider(foundry_token_azure_cli())
} # }
```
