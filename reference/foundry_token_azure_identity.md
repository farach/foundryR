# Create a Microsoft Entra ID token provider using AzureAuth

Create a provider function for
[`foundry_set_token_provider()`](https://farach.github.io/foundryR/reference/foundry_set_token_provider.md)
that acquires Microsoft Entra ID access tokens through the AzureAuth
package. This supports service principals (client secret or
certificate), managed identity, and interactive or device-code flows,
and refreshes tokens automatically as they approach expiry.

## Usage

``` r
foundry_token_azure_identity(
  resource = "https://cognitiveservices.azure.com",
  tenant = Sys.getenv("AZURE_TENANT_ID"),
  app = Sys.getenv("AZURE_CLIENT_ID"),
  password = NULL,
  username = NULL,
  certificate = NULL,
  auth_type = NULL,
  managed_identity = FALSE,
  version = 1,
  ...
)
```

## Arguments

- resource:

  Character. The token audience. Defaults to
  `"https://cognitiveservices.azure.com"` for resource-level v1 and
  Content Safety APIs. Use `"https://ai.azure.com"` for project APIs and
  register the provider with `scope = "project"`.

- tenant:

  Character. Microsoft Entra ID tenant. Defaults to the
  `AZURE_TENANT_ID` environment variable. Ignored when
  `managed_identity = TRUE`.

- app:

  Character. Application (client) ID. Defaults to the `AZURE_CLIENT_ID`
  environment variable. Ignored when `managed_identity = TRUE`.

- password:

  Character or `NULL`. Client secret for a service principal, or the
  resource-owner password. `NULL` selects an interactive or device-code
  flow.

- username:

  Character or `NULL`. Username for the resource-owner flow.

- certificate:

  Character or `NULL`. Path to, or contents of, a certificate for
  certificate-based service-principal authentication.

- auth_type:

  Character or `NULL`. Explicit AzureAuth authentication type. `NULL`
  lets AzureAuth choose based on the other arguments.

- managed_identity:

  Logical. If `TRUE`, acquire a token from an Azure managed identity via
  [`AzureAuth::get_managed_token()`](https://rdrr.io/pkg/AzureAuth/man/get_azure_token.html)
  and ignore `tenant` and `app`. Default `FALSE`.

- version:

  Integer. Microsoft Entra ID endpoint version, `1` or `2`. Default `1`,
  matching the resource-style `resource` above.

- ...:

  Additional arguments passed to
  [`AzureAuth::get_azure_token()`](https://rdrr.io/pkg/AzureAuth/man/get_azure_token.html)
  or
  [`AzureAuth::get_managed_token()`](https://rdrr.io/pkg/AzureAuth/man/get_azure_token.html).

## Value

A zero-argument token provider function suitable for
[`foundry_set_token_provider()`](https://farach.github.io/foundryR/reference/foundry_set_token_provider.md).

## Details

The token is acquired lazily on first use, so building the provider
never triggers a network call. Tokens are re-acquired within five
minutes of expiry; AzureAuth reuses its on-disk cache and refresh tokens
under the hood, so re-acquisition is inexpensive and does not re-prompt
for interactive flows.

## See also

[`foundry_token_azure_cli()`](https://farach.github.io/foundryR/reference/foundry_token_azure_cli.md)
for a provider that shells out to the Azure CLI instead.

## Examples

``` r
if (FALSE) { # \dontrun{
# Service principal with a client secret
foundry_set_token_provider(
  foundry_token_azure_identity(
    tenant = "your-tenant-id",
    app = "your-client-id",
    password = Sys.getenv("AZURE_CLIENT_SECRET")
  )
)

# Managed identity inside Azure
foundry_set_token_provider(
  foundry_token_azure_identity(managed_identity = TRUE)
)

# Project-scoped APIs use a different audience and provider slot
foundry_set_token_provider(
  foundry_token_azure_identity(
    resource = "https://ai.azure.com",
    managed_identity = TRUE
  ),
  scope = "project"
)
} # }
```
