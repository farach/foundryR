# Generate Images with DALL-E

Generate images using an Azure AI Foundry deployed DALL-E model. Returns
a tibble with the generated image URLs or base64-encoded data, along
with metadata about the generation.

## Usage

``` r
foundry_image(
  prompt,
  model = NULL,
  n = 1L,
  size = c("1024x1024", "1792x1024", "1024x1792", "512x512", "256x256"),
  quality = c("standard", "hd"),
  style = c("vivid", "natural"),
  response_format = c("url", "b64_json"),
  api_key = NULL,
  api_version = NULL
)
```

## Arguments

- prompt:

  Character. A text description of the desired image(s).

- model:

  Character. The deployment name of a DALL-E model. Defaults to the
  environment variable `AZURE_FOUNDRY_IMAGE_MODEL`.

- n:

  Integer. Number of images to generate (1-10). Default: 1.

- size:

  Character. The size of the generated image(s). One of: "1024x1024"
  (default), "1792x1024", "1024x1792", "512x512", "256x256". Note: Not
  all sizes are supported by all DALL-E versions.

- quality:

  Character. The quality of the image. One of: "standard" (default),
  "hd". HD quality provides finer details and greater consistency. Only
  supported by DALL-E 3.

- style:

  Character. The style of the generated image. One of: "vivid"
  (default), "natural". Vivid creates hyper-real and dramatic images.
  Natural produces more realistic, less hyper-real images. Only
  supported by DALL-E 3.

- response_format:

  Character. The format of the generated images. One of: "url" (default)
  or "b64_json" (base64-encoded).

- api_key:

  Character. Optional API key override.

- api_version:

  Character. Optional API version override.

## Value

A tibble with columns:

- prompt:

  Character. The original prompt provided.

- revised_prompt:

  Character. DALL-E's interpretation/revision of the prompt (DALL-E 3
  only).

- url:

  Character. URL to the generated image (NA if response_format is
  "b64_json").

- b64_json:

  Character. Base64-encoded image data (NA if response_format is "url").

- created:

  POSIXct. Timestamp when the image was created.

## Details

**Model Requirements**: The `model` parameter must be a deployment of a
DALL-E model (e.g., dall-e-2, dall-e-3). Chat models cannot generate
images.

**Size Availability**:

- DALL-E 3: 1024x1024, 1792x1024, 1024x1792

- DALL-E 2: 256x256, 512x512, 1024x1024

**URL Expiration**: Image URLs returned by the API are temporary and
will expire. Use
[`foundry_save_image()`](https://farach.github.io/foundryR/reference/foundry_save_image.md)
to download and save images locally.

## Examples

``` r
if (FALSE) { # \dontrun{
# Generate a single image
result <- foundry_image("A sunset over mountains", model = "dall-e-3")

# View the image URL
result$url

# Generate multiple images with HD quality
result <- foundry_image(
  "A futuristic cityscape",
  model = "dall-e-3",
  n = 2,
  quality = "hd",
  style = "vivid"
)

# Get base64-encoded images instead of URLs
result <- foundry_image(
  "An abstract painting",
  model = "dall-e-3",
  response_format = "b64_json"
)

# Save an image to disk
result <- foundry_image("A cat wearing a hat", model = "dall-e-3")
foundry_save_image(result, "cat_hat.png")
} # }
```
