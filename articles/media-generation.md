# Image and Video Generation

``` r

library(foundryR)
#> 
#> foundryR - Tidy Azure AI Foundry workflows
#> ==========================================
#> * Check your setup:
#>   foundry_check_setup()
#> * Set your API key: foundry_set_key()
#> * Set your endpoint: foundry_set_endpoint()
#> * Get started: ?foundry_response, ?foundry_groundedness
#> 
#> New to Azure? See the README for setup instructions.
```

foundryR supports current v1 preview image generation and editing
parameters, while keeping the legacy deployment-style image endpoint
available with `api = "deployment"`.

## Configure image resources

Image models may be deployed on the same Azure OpenAI resource as your
text models, or on a separate resource. Use the image-specific helpers
only when the resource or key differs.

``` r

foundry_set_endpoint(Sys.getenv("AZURE_FOUNDRY_ENDPOINT"))
foundry_set_key("your-api-key")

foundry_set_image_endpoint(Sys.getenv("AZURE_FOUNDRY_IMAGE_ENDPOINT"))
foundry_set_image_key("your-image-api-key")

Sys.setenv(AZURE_FOUNDRY_IMAGE_MODEL = "my-image-deployment")
```

## Generate images

``` r

image <- foundry_image(
  "A clean data science illustration of survey responses becoming a chart",
  model = "gpt-image-1",
  size = "1024x1024",
  output_format = "png",
  background = "opaque"
)
```

``` r

image <- tibble::tibble(
  prompt = "A clean data science illustration of survey responses becoming a chart",
  revised_prompt = NA_character_,
  url = NA_character_,
  b64_json = "<base64 image bytes>",
  output_format = "png",
  created = as.POSIXct("2026-06-24 12:00:00", tz = "UTC")
)

image[, c("prompt", "url", "b64_json", "output_format", "created")]
#> # A tibble: 1 × 5
#>   prompt                        url   b64_json output_format created            
#>   <chr>                         <chr> <chr>    <chr>         <dttm>             
#> 1 A clean data science illustr… NA    <base64… png           2026-06-24 12:00:00
```

Use model-supported options such as `size`, `quality`, `output_format`,
`background`, and `moderation` when you need a specific asset format:

``` r

foundry_image(
  "A simple report illustration showing coded survey responses",
  model = "gpt-image-1",
  size = "1792x1024",
  output_format = "png",
  background = "opaque",
  moderation = "auto"
)
```

Save generated image bytes with
[`foundry_save_image()`](https://farach.github.io/foundryR/reference/foundry_save_image.md):

``` r

foundry_save_image(image, "survey-chart.png")
```

Image URLs are temporary. Save images that belong in reports, stimuli,
or audited records.

## Edit images

``` r

edited <- foundry_image_edit(
  image = "survey-chart.png",
  prompt = "Use a blue Microsoft-inspired color palette.",
  model = "gpt-image-1",
  output_format = "png"
)
```

``` r

edited <- tibble::tibble(
  prompt = "Use a blue Microsoft-inspired color palette.",
  revised_prompt = NA_character_,
  url = NA_character_,
  b64_json = "<base64 edited image bytes>",
  output_format = "png",
  created = as.POSIXct("2026-06-24 12:05:00", tz = "UTC")
)

edited[, c("prompt", "b64_json", "output_format", "created")]
#> # A tibble: 1 × 4
#>   prompt                              b64_json output_format created            
#>   <chr>                               <chr>    <chr>         <dttm>             
#> 1 Use a blue Microsoft-inspired colo… <base64… png           2026-06-24 12:05:00
```

## Start a video generation job

Video generation is a preview, long-running workflow. Create a job, poll
it, and download content after a generation succeeds.

``` r

job <- foundry_video_job_create(
  "A short animation of dots clustering into groups",
  model = "my-video-model",
  width = 1280,
  height = 720,
  n_seconds = 5
)

foundry_video_job_get(job$job_id)
```

``` r

job <- tibble::tibble(
  job_id = "videojob_abc123",
  status = "running",
  model = "my-video-model",
  prompt = "A short animation of dots clustering into groups",
  width = 1280L,
  height = 720L,
  n_seconds = 5L,
  n_variants = 1L,
  created_at = as.POSIXct("2026-06-24 12:10:00", tz = "UTC")
)

job
#> # A tibble: 1 × 9
#>   job_id          status  model         prompt width height n_seconds n_variants
#>   <chr>           <chr>   <chr>         <chr>  <int>  <int>     <int>      <int>
#> 1 videojob_abc123 running my-video-mod… A sho…  1280    720         5          1
#> # ℹ 1 more variable: created_at <dttm>
```

``` r

foundry_video_download(
  generation_id = "vidgen_abc123",
  path = "cluster-animation.mp4"
)
```

## When to use these APIs

- Generate research stimuli or report illustrations with
  [`foundry_image()`](https://farach.github.io/foundryR/reference/foundry_image.md).
- Iterate on existing figures or image stimuli with
  [`foundry_image_edit()`](https://farach.github.io/foundryR/reference/foundry_image_edit.md).
- Treat video as experimental: keep prompts, job IDs, and output files
  together so generated assets remain reproducible and auditable.
- Track costs separately from text calls. Image and video generation are
  usually more expensive than text and embedding calls.
