# Set Azure Content Safety Endpoint

Set the base endpoint URL for your Azure Content Safety resource.

## Usage

``` r
foundry_set_content_safety_endpoint(endpoint, store = FALSE)
```

## Arguments

- endpoint:

  Character string containing the endpoint URL. Example: the endpoint
  URL from your Content Safety resource.

- store:

  Logical. If TRUE, stores the endpoint in `.Renviron` for future
  sessions. Default: FALSE (endpoint only available for current
  session).

## Value

Invisibly returns TRUE if endpoint was set successfully.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_set_content_safety_endpoint(Sys.getenv("AZURE_CONTENT_SAFETY_ENDPOINT"))

# Store permanently
foundry_set_content_safety_endpoint(
  Sys.getenv("AZURE_CONTENT_SAFETY_ENDPOINT"),
  store = TRUE
)
} # }
```
