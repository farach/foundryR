# foundryR <a href="https://farach.github.io/foundryR/"><img src="man/figures/logo.svg" align="right" height="138" alt="foundryR website" /></a>

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/farach/foundryR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/farach/foundryR/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

A tidy, API-first R interface to [Microsoft Azure AI Foundry](https://azure.microsoft.com/en-us/products/ai-foundry/). Build AI-powered applications with chat completions, the newer Responses API, structured extraction, web-grounded answers, audio transcription, image and video generation, embeddings, content safety, and batch workflows - all returning tibbles that integrate seamlessly with tidyverse and tidymodels workflows.

## Features

- **Chat completions** - Interact with GPT, Claude, Llama, Mistral, DeepSeek, Cohere, and other models
- **Responses API** - Use Microsoft Foundry's v1 `/openai/v1/responses` endpoint for stateful turns, tools, and structured outputs
- **Structured extraction** - Convert free text into schema-constrained tidy columns for annotation and research workflows
- **Web-grounded responses** - Use the Responses API `web_search` tool and get citations as tidy list-columns
- **Audio workflows** - Transcribe interviews, translate recordings, and synthesize speech with Foundry audio APIs including MAI-Transcribe
- **Files and batches** - Upload JSONL files and run large-scale annotation or extraction jobs through the v1 Files and Batch APIs
- **Text embeddings** - Generate vector embeddings for semantic search, clustering, and ML
- **Content safety** - Moderate content, detect hallucinations (groundedness), and protect against prompt injection
- **Image and video generation** - Create or edit images with modern v1 image models and manage preview video generation jobs
- **tidymodels integration** - Use `step_foundry_embed()` to add embeddings to your ML pipelines

## Installation

Install from CRAN after release:

```r
install.packages("foundryR")
```

Install the development version from GitHub:

```r
# install.packages("pak")
pak::pak("farach/foundryR")
```

## Quick Start

### Configure credentials

```r
library(foundryR)

# Set credentials for current session
foundry_set_endpoint("AZURE_FOUNDRY_ENDPOINT")
foundry_set_key("your-api-key")

# Or use a Microsoft Entra ID bearer token for keyless auth
foundry_set_token("your-access-token")

# Verify setup
foundry_check_setup()
```
For persistent configuration, add to your `.Renviron` file:

```
AZURE_FOUNDRY_ENDPOINT=<your Foundry endpoint URL>
AZURE_FOUNDRY_KEY=your-api-key
AZURE_FOUNDRY_MODEL=my-gpt-deployment
AZURE_FOUNDRY_EMBED_MODEL=my-embedding-deployment
```

### Find your deployments

Foundry model deployment names are the values you pass to `model =`. If your
resource exposes the v1 model metadata endpoint, list them from R:

```r
models <- foundry_models()
models[, c("id", "owned_by")]
```

You still need a deployed model in Foundry, but the package helps once the
resource exists: configure endpoint/auth once, run `foundry_models()`, set
default deployment names in `.Renviron`, and then omit `model =` in day-to-day
analysis code.

### Chat with a model

```r
foundry_chat("What is the tidyverse?", model = "gpt-4o-mini")
#> # A tibble: 1 x 7
#>   role      content                          model finish_reason prompt_tokens
#>   <chr>     <chr>                            <chr> <chr>                 <int>
#> 1 assistant The tidyverse is a collection... gpt-4 stop                     10
#> # i 2 more variables: completion_tokens <int>, total_tokens <int>
```

### Use the Responses API

The newer Microsoft Foundry Responses API supports stateful turns, built-in tools, and schema-constrained output through the v1 endpoint:

```r
first <- foundry_response(
  "Define catastrophic forgetting.",
  model = "gpt-4.1"
)

foundry_response(
  "Explain it for a college freshman.",
  model = "gpt-4.1",
  previous_response_id = first$response_id
)
```

### Extract structured data

Use JSON Schema to turn free text into analyzable variables:

```r
schema <- list(
  type = "object",
  properties = list(
    sentiment = list(type = "string", enum = c("positive", "negative", "neutral")),
    entities = list(type = "array", items = list(type = "string"))
  ),
  required = c("sentiment", "entities"),
  additionalProperties = FALSE
)

foundry_extract(
  c("I love using R with Azure.", "The workflow was slow and confusing."),
  schema = schema,
  model = "gpt-4.1"
)
```

### Search the web with citations

```r
web_answer <- foundry_web_search(
  "What changed recently in Azure AI Foundry Responses API?",
  model = "gpt-4.1"
)

web_answer$citations[[1]]
```

`foundry_web_search()` uses Grounding with Bing services. Microsoft documents that this can leave compliance/geographic boundaries and incur additional costs.

### Transcribe research audio

```r
transcript <- foundry_transcribe(
  "interview.mp3",
  model = "mai-transcribe-1.5",
  locales = "en-US"
)

transcript$text
head(transcript$phrases[[1]])
```

Use `foundry_translate_audio()` for multilingual recordings and
`foundry_speak()` to synthesize audio stimuli or accessibility assets.

### Prepare a batch annotation job

```r
survey <- data.frame(
  response = c("The course was clear.", "I needed more examples.")
)

jsonl <- tempfile(fileext = ".jsonl")
foundry_batch_requests(
  survey,
  input = "response",
  path = jsonl,
  model = "gpt-4.1",
  body = list(
    instructions = "Classify sentiment as positive, neutral, or negative."
  )
)

file <- foundry_file_upload(jsonl, purpose = "batch")
foundry_batch_create(file$file_id, endpoint = "/v1/responses")
```

### Generate embeddings

```r
texts <- c("I love R programming", "R is great for statistics")
foundry_embed(texts, model = "text-embedding-3-small")
#> # A tibble: 2 x 3
#>   text                       embedding      n_dims
#>   <chr>                      <list>          <int>
#> 1 I love R programming       <dbl [1,536]>    1536
#> 2 R is great for statistics  <dbl [1,536]>    1536
```

### Compute similarity

```r
embeddings <- foundry_embed(texts, model = "text-embedding-3-small")
foundry_similarity(embeddings)
#> # A tibble: 1 x 3
#>   text_1               text_2                     similarity
#>   <chr>                <chr>                           <dbl>
#> 1 I love R programming R is great for statistics       0.912
```

## Content Safety

foundryR integrates with [Azure AI Content Safety](https://azure.microsoft.com/en-us/products/ai-services/ai-content-safety/) for responsible AI features:

```r
# Content moderation
foundry_moderate("Sample text to analyze")

# Hallucination detection
foundry_groundedness(
  text = "AI-generated response",
  grounding_sources = "Source document",
  query = "User question",
  task = "QnA"
)

# Prompt injection detection
foundry_shield(user_prompt = "User input to check")
```

## Image and Video Generation

Create images with current v1 image models:

```r
result <- foundry_image(
  "A serene mountain landscape at sunset",
  model = "gpt-image-1",
  output_format = "png",
  size = "1024x1024"
)
foundry_save_image(result, "landscape.png")
```

Preview video generation jobs are long-running:

```r
job <- foundry_video_job_create(
  "A calm ocean at sunrise",
  model = "my-video-model",
  width = 1280,
  height = 720
)

foundry_video_job_get(job$job_id)
```

## tidymodels Integration

Add text embeddings to your ML pipelines:

```r
library(tidymodels)

recipe(sentiment ~ text, data = reviews) |>
  step_foundry_embed(text, model = "text-embedding-3-small") |>
  step_normalize(all_numeric_predictors())
```

## Learn More

- [Getting Started](https://farach.github.io/foundryR/articles/getting-started.html) - Setup and first API calls
- [Responses API](https://farach.github.io/foundryR/articles/responses-api.html) - Stateful turns, structured extraction, and web search
- [Audio Workflows](https://farach.github.io/foundryR/articles/index.html) - Transcription, translation, and speech
- [Files and Batch API](https://farach.github.io/foundryR/articles/index.html) - Large-scale async workflows
- [Text Embeddings](https://farach.github.io/foundryR/articles/embeddings.html) - Semantic search and similarity
- [Content Safety](https://farach.github.io/foundryR/articles/content-safety.html) - Responsible AI features
- [Image and Video Generation](https://farach.github.io/foundryR/articles/index.html) - Modern image and preview video APIs
- [tidymodels Integration](https://farach.github.io/foundryR/articles/tidymodels.html) - ML pipelines with embeddings
- [Function Reference](https://farach.github.io/foundryR/reference/index.html) - Complete API documentation

## License

MIT
