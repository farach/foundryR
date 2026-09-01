# Create an Azure CLI token provider

Create a provider function for
[`foundry_set_token_provider()`](https://farach.github.io/foundryR/reference/foundry_set_token_provider.md)
that shells out to `az account get-access-token`. Tokens are cached
until five minutes before expiry.

## Usage

``` r
foundry_token_azure_cli(
  resource = "https://cognitiveservices.azure.com",
  az = "az"
)
```

## Arguments

- resource:

  Character. Azure resource used for the access token. Defaults to
  `"https://cognitiveservices.azure.com"` for resource-level v1 and
  Content Safety APIs. Use `"https://ai.azure.com"` for project APIs and
  register that provider with `scope = "project"`.

- az:

  Character. Azure CLI executable name or path.

## Value

A zero-argument token provider function.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_set_token_provider(
  foundry_token_azure_cli("https://ai.azure.com"),
  scope = "project"
)
} # }
```
