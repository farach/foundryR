# Download Microsoft Foundry generated video content

**\[experimental\]**

## Usage

``` r
foundry_video_download(
  generation_id,
  path,
  content = c("video", "thumbnail"),
  overwrite = FALSE,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = "preview"
)
```

## Arguments

- generation_id:

  Character. Video generation ID.

- path:

  Character. Local file path for the downloaded content.

- content:

  Character. `"video"` for video bytes or `"thumbnail"` for the
  generated thumbnail.

- overwrite:

  Logical. Whether to overwrite an existing file.

- api_key:

  Character. Optional API key override.

- token:

  Character. Optional bearer token override.

- endpoint:

  Character. Optional endpoint override.

- api_version:

  Character. Optional API version. Defaults to `"preview"`.

## Value

A tibble with the local path, bytes written, generation ID, and content
type.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a configured Azure endpoint and credentials,
# plus a completed video generation ID.
local({
  path <- tempfile(fileext = ".mp4")
  on.exit(unlink(path))
  foundry_video_download("vidgen_abc123", path)
})
} # }
```
