# Save Generated Image to File

Download and save a generated image from
[`foundry_image()`](https://farach.github.io/foundryR/reference/foundry_image.md)
to a local file. Works with both URL and base64-encoded image results.

## Usage

``` r
foundry_save_image(image_result, path, index = 1)
```

## Arguments

- image_result:

  A tibble returned by
  [`foundry_image()`](https://farach.github.io/foundryR/reference/foundry_image.md).

- path:

  Character. The file path where the image should be saved. Should
  include the file extension (e.g., ".png").

- index:

  Integer. Which image to save if multiple were generated (1-based).
  Default: 1 (first image).

## Value

Invisibly returns the path to the saved file.

## Details

This function handles both URL and base64-encoded images automatically.
For URL-based images, it downloads the image from the temporary Azure
URL. For base64-encoded images, it decodes the data and writes it to
file.

**Note**: Image URLs from Azure are temporary and expire after a short
time. Use this function to save images locally before the URLs expire.

## Examples

``` r
if (FALSE) { # \dontrun{
# Generate and save an image
result <- foundry_image("A beautiful landscape", model = "dall-e-3")
foundry_save_image(result, "landscape.png")

# Save a specific image when multiple were generated
result <- foundry_image("Colorful abstract art", model = "dall-e-3", n = 3)
foundry_save_image(result, "art_1.png", index = 1)
foundry_save_image(result, "art_2.png", index = 2)
foundry_save_image(result, "art_3.png", index = 3)

# Save base64-encoded image
result <- foundry_image("A cat", model = "dall-e-3", response_format = "b64_json")
foundry_save_image(result, "cat.png")
} # }
```
