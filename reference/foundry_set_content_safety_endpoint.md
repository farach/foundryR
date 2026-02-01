# Set Azure Content Safety Endpoint

Set the base endpoint URL for your Azure Content Safety resource.

## Usage

``` r
foundry_set_content_safety_endpoint(endpoint, store = FALSE)
```

## Arguments

- endpoint:

  Character string containing the endpoint URL. Example:
  "https://your-resource.cognitiveservices.azure.com"

- store:

  Logical. If TRUE, stores the endpoint in `.Renviron` for future
  sessions. Default: FALSE (endpoint only available for current
  session).

## Value

Invisibly returns TRUE if endpoint was set successfully.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_set_content_safety_endpoint("https://my-resource.cognitiveservices.azure.com")

# Store permanently
foundry_set_content_safety_endpoint("https://my-resource.cognitiveservices.azure.com", store = TRUE)
} # }
```
