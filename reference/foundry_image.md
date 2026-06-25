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
  size = "1024x1024",
  quality = NULL,
  style = NULL,
  response_format = NULL,
  output_format = NULL,
  output_compression = NULL,
  background = NULL,
  moderation = NULL,
  api = c("v1", "deployment"),
  api_key = NULL,
  token = NULL,
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

  Character. The size of the generated image(s). Modern v1 image models
  support `"auto"`, `"1024x1024"`, `"1536x1024"`, and `"1024x1536"`.
  DALL-E deployments also support older sizes such as `"1792x1024"`,
  `"1024x1792"`, `"512x512"`, and `"256x256"`.

- quality:

  Character. The quality of the image. Modern v1 models support
  `"auto"`, `"low"`, `"medium"`, and `"high"`. DALL-E 3 supports
  `"standard"` and `"hd"`.

- style:

  Character. Optional DALL-E 3 style, `"vivid"` or `"natural"`.

- response_format:

  Character. Optional DALL-E response format, `"url"` or `"b64_json"`.
  This is not supported by `gpt-image-1`-series models, which return
  base64 image data.

- output_format:

  Character. Optional v1 image output format, `"png"`, `"jpeg"`, or
  `"webp"`.

- output_compression:

  Integer. Optional v1 compression level from 0 to 100 for `"jpeg"` or
  `"webp"` output.

- background:

  Character. Optional v1 background mode: `"transparent"`, `"opaque"`,
  or `"auto"`.

- moderation:

  Character. Optional v1 moderation level: `"low"` or `"auto"`.

- api:

  Character. API shape to use. `"v1"` uses
  `/openai/v1/images/generations`; `"deployment"` uses the legacy
  `/openai/deployments/{deployment}/images/generations` endpoint.

- api_key:

  Character. Optional API key override.

- token:

  Character. Optional bearer token override.

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

- output_format:

  Character. Requested or returned output format.

- created:

  POSIXct. Timestamp when the image was created.

- raw_image:

  List. Raw image object returned by the service.

## Details

**Model Requirements**: The `model` parameter must be an image-capable
deployment such as a DALL-E or `gpt-image-1`-series deployment. Chat
models cannot generate images.

**Size Availability**:

- gpt-image-1 series: auto, 1024x1024, 1536x1024, 1024x1536

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
