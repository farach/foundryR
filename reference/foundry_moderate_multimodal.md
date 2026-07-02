# Moderate an image together with its text

**\[experimental\]**

Analyze an image and optional accompanying text in a single multimodal
Content Safety call. Optical character recognition can read text
embedded in the image so that harmful captions or overlays are caught
alongside the picture.

## Usage

``` r
foundry_moderate_multimodal(
  image,
  text = NULL,
  categories = c("Hate", "Sexual", "SelfHarm", "Violence"),
  enable_ocr = TRUE,
  endpoint = NULL,
  api_key = NULL,
  api_version = "2024-09-15-preview"
)
```

## Arguments

- image:

  Character. Local image path or HTTPS Azure Blob Storage URL.

- text:

  Character. Optional text shown with the image (max 1,000 code points).

- categories:

  Character vector of harm categories. Defaults to all four.

- enable_ocr:

  Logical. When `TRUE`, run OCR on the image to recognize embedded text.
  Default `TRUE`.

- endpoint:

  Character. Optional Content Safety endpoint.

- api_key:

  Character. Optional Content Safety key.

- api_version:

  Character. API version. Defaults to `"2024-09-15-preview"`.

## Value

A tibble with one row per harm category, matching
[`foundry_moderate_image()`](https://farach.github.io/foundryR/reference/foundry_moderate_image.md):
`source`, `category`, `severity`, `label`, and `raw_response`.
Multimodal analysis returns four-level severities (0, 2, 4, 6).

## Preview API

This operation is documented only in the Azure AI Content Safety Learn
quickstarts and has no published OpenAPI specification. It requires the
`2024-09-15-preview` api-version and, at time of writing, is available
only in a subset of Azure regions.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_moderate_multimodal(
  image = "meme.png",
  text = "caption under the image",
  enable_ocr = TRUE
)
} # }
```
