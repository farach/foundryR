# Retrieve a Microsoft Foundry video generation job

**\[experimental\]**

## Usage

``` r
foundry_video_job_get(
  job_id,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = "preview"
)
```

## Arguments

- job_id:

  Character. Video generation job ID.

- api_key:

  Character. Optional API key override.

- token:

  Character. Optional bearer token override.

- endpoint:

  Character. Optional endpoint override.

- api_version:

  Character. Optional API version. Defaults to `"preview"`.

## Value

A one-row tibble with job metadata.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_video_job_get("videojob_abc123")
} # }
```
