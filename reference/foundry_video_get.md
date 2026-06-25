# Retrieve a Microsoft Foundry video generation

Retrieve a Microsoft Foundry video generation

## Usage

``` r
foundry_video_get(
  generation_id,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = "preview"
)
```

## Arguments

- generation_id:

  Character. Video generation ID.

- api_key:

  Character. Optional API key override.

- token:

  Character. Optional bearer token override.

- endpoint:

  Character. Optional endpoint override.

- api_version:

  Character. Optional API version. Defaults to `"preview"`.

## Value

A one-row tibble with generation metadata.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_video_get("vidgen_abc123")
} # }
```
