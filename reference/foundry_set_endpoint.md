# Set Azure AI Foundry Endpoint

Set the base endpoint URL for your Azure AI Foundry resource.

## Usage

``` r
foundry_set_endpoint(endpoint, store = FALSE)
```

## Arguments

- endpoint:

  Character string containing the endpoint URL. Example: the endpoint
  URL from your Foundry resource.

- store:

  Logical. If TRUE, stores the endpoint in `.Renviron` for future
  sessions. Default: FALSE (endpoint only available for current
  session).

## Value

Invisibly returns TRUE if endpoint was set successfully.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_set_endpoint("AZURE_FOUNDRY_ENDPOINT")

# Store permanently
foundry_set_endpoint("AZURE_FOUNDRY_ENDPOINT", store = TRUE)
} # }
```
