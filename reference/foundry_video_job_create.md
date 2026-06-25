# Create a Microsoft Foundry video generation job

Start a v1 preview video generation job. Video generation is a preview
feature and returns a job that should be polled with
[`foundry_video_job_get()`](https://farach.github.io/foundryR/reference/foundry_video_job_get.md).

## Usage

``` r
foundry_video_job_create(
  prompt,
  model = NULL,
  width,
  height,
  n_seconds = 5L,
  n_variants = 1L,
  files = NULL,
  inpaint_items = NULL,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = "preview"
)
```

## Arguments

- prompt:

  Character. Prompt for the generated video.

- model:

  Character. Video model deployment name.

- width, height:

  Integer. Output video dimensions.

- n_seconds:

  Integer. Duration in seconds, between 1 and 20.

- n_variants:

  Integer. Number of video variants, between 1 and 5.

- files:

  Character vector. Optional local files for image-to-video or
  inpainting workflows.

- inpaint_items:

  List. Optional inpainting items for multipart requests.

- api_key:

  Character. Optional API key override.

- token:

  Character. Optional bearer token override.

- endpoint:

  Character. Optional endpoint override.

- api_version:

  Character. Optional API version. Defaults to `"preview"`.

## Value

A one-row tibble with job metadata and the raw job in a list-column.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_video_job_create(
  "A calm ocean at sunrise",
  model = "my-video-model",
  width = 1280,
  height = 720
)
} # }
```
