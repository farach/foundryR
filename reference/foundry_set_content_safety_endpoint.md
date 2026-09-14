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

  Logical. If `TRUE`, stores the endpoint in foundryR's package-specific
  user configuration file. Default: `FALSE`.

## Value

Invisibly returns TRUE if endpoint was set successfully.

## Examples

``` r
withr::with_envvar(c(AZURE_CONTENT_SAFETY_ENDPOINT = NA_character_), {
  foundry_set_content_safety_endpoint(
    "https://example.cognitiveservices.azure.com"
  )
})
#> ✔ Content Safety endpoint set to <https://example.cognitiveservices.azure.com>
```
