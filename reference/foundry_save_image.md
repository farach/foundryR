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
# Save a one-pixel PNG without calling Azure.
if (requireNamespace("base64enc", quietly = TRUE)) {
  local({
    image <- tibble::tibble(
      url = NA_character_,
      b64_json = paste0(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8",
        "/x8AAwMCAO+ip1sAAAAASUVORK5CYII="
      )
    )
    path <- tempfile(fileext = ".png")
    on.exit(unlink(path))
    foundry_save_image(image, path)
    file.exists(path)
  })
}
#> ✔ Image saved to /tmp/RtmpouSIgk/file1b02752682de.png (from base64)
#> [1] TRUE

if (FALSE) { # \dontrun{
# Requires a configured Azure image endpoint and credentials,
# plus DALL-E deployments.
local({
  paths <- replicate(5, tempfile(fileext = ".png"))
  on.exit(unlink(paths))

  # Generate and save an image
  result <- foundry_image("A beautiful landscape", model = "dall-e-3")
  foundry_save_image(result, paths[1])

  # DALL-E 2 supports generating several images per request.
  result <- foundry_image("Colorful abstract art", model = "dall-e-2", n = 3)
  foundry_save_image(result, paths[2], index = 1)
  foundry_save_image(result, paths[3], index = 2)
  foundry_save_image(result, paths[4], index = 3)

  # Save a base64-encoded image
  if (requireNamespace("base64enc", quietly = TRUE)) {
    result <- foundry_image(
      "A cat", model = "dall-e-3", response_format = "b64_json"
    )
    foundry_save_image(result, paths[5])
  }
})
} # }
```
