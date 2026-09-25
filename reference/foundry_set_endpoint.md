# Set Microsoft Foundry Endpoint

Set the base endpoint URL for your Microsoft Foundry resource.

## Usage

``` r
foundry_set_endpoint(endpoint, store = FALSE)
```

## Arguments

- endpoint:

  Character string containing the endpoint URL. Example: the endpoint
  URL from your Foundry resource.

- store:

  Logical. If `TRUE`, stores the endpoint in foundryR's package-specific
  user configuration file. Default: `FALSE`.

## Value

Invisibly returns TRUE if endpoint was set successfully.

## Examples

``` r
withr::with_envvar(c(AZURE_FOUNDRY_ENDPOINT = NA_character_), {
  foundry_set_endpoint("https://example.openai.azure.com")
  foundry_get_endpoint()
})
#> ✔ Endpoint set to <https://example.openai.azure.com>
#> [1] "https://example.openai.azure.com"

local({
  config_file <- tempfile("foundryR-config-", fileext = ".json")
  on.exit(unlink(config_file))
  withr::with_options(list(foundryR.config_file = config_file), {
    withr::with_envvar(c(AZURE_FOUNDRY_ENDPOINT = NA_character_), {
      foundry_set_endpoint("https://example.openai.azure.com", store = TRUE)
    })
  })
})
#> ✔ Endpoint set to <https://example.openai.azure.com>
#> ✔ Endpoint stored in /tmp/RtmpYeO30b/foundryR-config-1b07290ca2b5.json
```
