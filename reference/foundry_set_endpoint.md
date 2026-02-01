# Set Azure AI Foundry Endpoint

Set the base endpoint URL for your Azure AI Foundry resource.

## Usage

``` r
foundry_set_endpoint(endpoint, store = FALSE)
```

## Arguments

- endpoint:

  Character string containing the endpoint URL. Example:
  "https://your-resource.openai.azure.com"

- store:

  Logical. If TRUE, stores the endpoint in `.Renviron` for future
  sessions. Default: FALSE (endpoint only available for current
  session).

## Value

Invisibly returns TRUE if endpoint was set successfully.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_set_endpoint("https://my-resource.openai.azure.com")

# Store permanently
foundry_set_endpoint("https://my-resource.openai.azure.com", store = TRUE)
} # }
```
