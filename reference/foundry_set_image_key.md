# Set Image Generation API Key

Set the API key for image generation. Use this when your DALL-E model
uses a different API key than your chat/embedding models.

## Usage

``` r
foundry_set_image_key(key)
```

## Arguments

- key:

  Character. The API key for image generation.

## Value

Invisibly returns TRUE on success.

## Details

If not set,
[`foundry_image()`](https://farach.github.io/foundryR/reference/foundry_image.md)
will fall back to `AZURE_FOUNDRY_KEY`.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_set_image_key("your-dalle-api-key")
} # }
```
