# List Available Models/Deployments

Retrieve information about models deployed in your Azure AI Foundry
resource.

## Usage

``` r
foundry_models(model = NULL, api_key = NULL, api_version = NULL)
```

## Arguments

- model:

  Character. Optional. A specific deployment name to check.

- api_key:

  Character. Optional API key override.

- api_version:

  Character. Optional API version override.

## Value

A tibble with deployment information, or a message about available
functionality.

## Details

Note: Azure AI Foundry doesn't have a direct "list deployments" API
endpoint in the same way that Hugging Face does. This function provides
a placeholder that can be extended when such an API becomes available,
or can be used to validate a specific deployment exists.

## Examples

``` r
if (FALSE) { # \dontrun{
# Check if a deployment exists by making a minimal request
foundry_models("gpt-4")
} # }
```
