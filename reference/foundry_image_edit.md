# Edit an image with Microsoft Foundry

**\[experimental\]**

Use the v1 preview image edits endpoint to edit one or more input images
with a text prompt.

## Usage

``` r
foundry_image_edit(
  image,
  prompt,
  model = NULL,
  mask = NULL,
  n = 1L,
  size = "1024x1024",
  quality = NULL,
  output_format = NULL,
  background = NULL,
  api_key = NULL,
  token = NULL,
  api_version = "preview"
)
```

## Arguments

- image:

  Character vector of local image paths.

- prompt:

  Character. Edit instruction.

- model:

  Character. Image model deployment name.

- mask:

  Character. Optional local mask image path.

- n:

  Integer. Number of images to generate.

- size:

  Character. Output image size.

- quality:

  Character. Optional quality value.

- output_format:

  Character. Optional output format, such as `"png"`, `"jpeg"`, or
  `"webp"`.

- background:

  Character. Optional background mode.

- api_key:

  Character. Optional API key override.

- token:

  Character. Optional bearer token override.

- api_version:

  Character. Optional API version. Defaults to `"preview"`.

## Value

A tibble with edited image data and metadata.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_image_edit("input.png", "Make the sky more dramatic", model = "gpt-image-1")
} # }
```
