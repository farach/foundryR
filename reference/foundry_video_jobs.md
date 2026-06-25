# List Microsoft Foundry video generation jobs

List Microsoft Foundry video generation jobs

## Usage

``` r
foundry_video_jobs(
  limit = 20L,
  before = NULL,
  after = NULL,
  statuses = NULL,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = "preview"
)
```

## Arguments

- limit:

  Integer. Maximum number of jobs to return.

- before, after:

  Character. Optional pagination cursors.

- statuses:

  Character vector. Optional status filters.

- api_key:

  Character. Optional API key override.

- token:

  Character. Optional bearer token override.

- endpoint:

  Character. Optional endpoint override.

- api_version:

  Character. Optional API version. Defaults to `"preview"`.

## Value

A tibble with one row per video job.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_video_jobs(limit = 10)
} # }
```
