# Image and Video Generation

``` r

library(foundryR)
```

foundryR supports current v1 preview image generation and editing
parameters, while keeping the legacy deployment-style image endpoint
available with `api = "deployment"`.

## Configure image resources

Image models may be deployed on the same Azure OpenAI resource as your
text models, or on a separate resource. Use the image-specific helpers
only when the resource or key differs. This setup chunk is illustrative
and is not run:

``` r

foundry_set_image_endpoint(Sys.getenv("AZURE_FOUNDRY_IMAGE_ENDPOINT"))
foundry_set_image_key("your-image-api-key")

Sys.setenv(AZURE_FOUNDRY_IMAGE_MODEL = "my-image-deployment")
```

## Generate an image

[`foundry_image()`](https://farach.github.io/foundryR/reference/foundry_image.md)
returns one row per generated image with the prompt, any model-revised
prompt, the output format, and the image bytes (as a URL or base64,
depending on the model). Here we ask for a small, compressed JPEG so the
recorded fixture stays light.

``` r

image <- foundry_image(
  "A friendly red panda reading a book, flat vector illustration",
  model = "gpt-image-1",
  size = "1024x1024",
  quality = "low",
  output_format = "jpeg",
  output_compression = 40
)

image[, c("prompt", "revised_prompt", "output_format", "created")]
```

Decode the returned bytes to a file with
[`foundry_save_image()`](https://farach.github.io/foundryR/reference/foundry_save_image.md)
and display the result:

``` r

img_path <- tempfile(fileext = ".jpeg")
foundry_save_image(image, img_path)
knitr::include_graphics(img_path)
```

Image URLs are temporary. Save images that belong in reports, stimuli,
or audited records.

## Edit an image

[`foundry_image_edit()`](https://farach.github.io/foundryR/reference/foundry_image_edit.md)
takes an existing image and a prompt. The call below is illustrative (it
needs an image file on disk) and is not run here:

``` r

edited <- foundry_image_edit(
  image = img_path,
  prompt = "Use a blue, Microsoft-inspired color palette.",
  model = "gpt-image-1",
  output_format = "jpeg"
)

foundry_save_image(edited, "red-panda-blue.jpeg")
```

## Generate video (preview)

Video generation is a preview, long-running workflow: create a job, poll
it, and download the content once a generation succeeds. Because the job
is asynchronous these calls are shown for reference and are not run
here:

``` r

job <- foundry_video_job_create(
  "A short animation of dots clustering into groups",
  model = "my-video-model",
  width = 1280,
  height = 720,
  n_seconds = 5
)

job <- foundry_video_job_get(job$job_id)

foundry_video_download(
  generation_id = job$generation_id,
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
