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
Base64-encoded image data is the normal GPT-image path; it is decoded
and written to `path`. URL handling is kept for legacy deployments whose
temporary image URLs expire.

**Note**: If a legacy deployment returns a URL, use this function to
save the image locally before the temporary URL expires.

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
#> ✔ Image saved to /tmp/RtmpYeO30b/file1b07301fde18.png (from base64)
#> [1] TRUE

if (FALSE) { # \dontrun{
# Requires a configured Azure image endpoint and credentials,
# plus an image-generation deployment.
local({
  paths <- replicate(3, tempfile(fileext = ".png"))
  on.exit(unlink(paths))

  result <- foundry_image(
    "Colorful abstract art",
    model = "gpt-image-2",
    n = 3
  )
  if (requireNamespace("base64enc", quietly = TRUE)) {
    foundry_save_image(result, paths[1], index = 1)
    foundry_save_image(result, paths[2], index = 2)
    foundry_save_image(result, paths[3], index = 3)
  }
})
} # }
```
