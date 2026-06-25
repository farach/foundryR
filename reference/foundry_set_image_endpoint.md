# Set Image Generation Endpoint

Set the Azure endpoint for image generation (DALL-E). Use this when your
DALL-E model is deployed on a different Azure resource than your
chat/embedding models.

## Usage

``` r
foundry_set_image_endpoint(endpoint)
```

## Arguments

- endpoint:

  Character. The full Azure endpoint URL for image generation.

## Value

Invisibly returns the endpoint that was set.

## Details

If not set,
[`foundry_image()`](https://farach.github.io/foundryR/reference/foundry_image.md)
will fall back to `AZURE_FOUNDRY_ENDPOINT`. Use this function when
DALL-E is deployed on a separate Azure resource.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_set_image_endpoint("AZURE_FOUNDRY_IMAGE_ENDPOINT")
} # }
```
