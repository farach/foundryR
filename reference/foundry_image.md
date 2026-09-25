# Generate Images with Microsoft Foundry

Generate images with an image-generation deployment such as a
GPT-image-series model. Returns a tibble with base64-encoded image data,
a URL only if a legacy deployment returned one, and metadata about the
generation.

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

  Character. The image-generation deployment name, for example a
  GPT-image-series deployment. Defaults to the environment variable
  `AZURE_FOUNDRY_IMAGE_MODEL`.

- n:

  Integer. Number of images to generate (1-10). Default: 1.

- size:

  Character. The size of the generated image(s). This version of
  foundryR accepts `"auto"`, `"1024x1024"`, `"1536x1024"`, and
  `"1024x1536"` for GPT-image models. GPT-Image-2 and GPT-Image-2.5
  support custom dimensions in the service, but this version validates
  only these fixed sizes. Older `"256x256"`, `"512x512"`, `"1792x1024"`,
  and `"1024x1792"` sizes applied to retired DALL-E models.

- quality:

  Character. The quality of the image. GPT-image models support
  `"auto"`, `"low"`, `"medium"`, and `"high"`. `"standard"` and `"hd"`
  applied to retired DALL-E 3 deployments. GPT-Image-2.5 also supports
  `"xhigh"` and `"max"` in the service, but this version of foundryR
  does not yet accept those values.

- style:

  Character. Optional DALL-E style, `"vivid"` or `"natural"`. DALL-E
  models were retired by Azure on March 4, 2026; this argument is kept
  for compatibility with legacy deployments.

- response_format:

  Character. Optional legacy DALL-E response format, `"url"` or
  `"b64_json"`. DALL-E models were retired by Azure on March 4, 2026;
  GPT-image models return base64 image data.

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

  Character. Revised prompt when the service returns one, usually `NA`
  for GPT-image models.

- url:

  Character. URL to the generated image, `NA` unless a legacy deployment
  returns a URL.

- b64_json:

  Character. Base64-encoded image data.

- output_format:

  Character. Requested or returned output format.

- created:

  POSIXct. Timestamp when the image was created.

- raw_image:

  List. Raw image object returned by the service.

## Details

**Model Requirements**: The `model` parameter must be an image-capable
deployment such as a GPT-image-series deployment. Chat models cannot
generate images. Azure retired DALL-E 3 on March 4, 2026; see
<https://learn.microsoft.com/azure/foundry/openai/how-to/dall-e>.

**Size Availability**:

- GPT-image models in this version of foundryR: auto, 1024x1024,
  1536x1024, 1024x1536.

- GPT-Image-2 and GPT-Image-2.5 support custom dimensions in the
  service, but this version validates only the fixed sizes above.

- Retired DALL-E models used older sizes such as 256x256, 512x512,
  1792x1024, and 1024x1792.

GPT-image results are returned as base64 image data. Use
[`foundry_save_image()`](https://farach.github.io/foundryR/reference/foundry_save_image.md)
to decode and write them to disk; saving base64 data requires the
base64enc package.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a configured Azure image endpoint and credentials,
# plus an image-generation deployment.
# Generate a single image
result <- foundry_image("A sunset over mountains", model = "gpt-image-2")

# View the base64 image data
result$b64_json

# Generate a smaller JPEG output
result <- foundry_image(
  "A futuristic cityscape",
  model = "gpt-image-2",
  quality = "low",
  output_format = "jpeg",
  output_compression = 60
)

# Save an image to disk
result <- foundry_image("A cat wearing a hat", model = "gpt-image-2")
local({
  path <- tempfile(fileext = ".png")
  on.exit(unlink(path))
  foundry_save_image(result, path)
})
} # }
```
