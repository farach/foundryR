# foundryR <a href="https://farach.github.io/foundryR/"><img src="man/figures/logo.svg" align="right" height="138" alt="foundryR website" /></a>

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/farach/foundryR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/farach/foundryR/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

A tidy, API-first R interface to [Microsoft Azure AI Foundry](https://azure.microsoft.com/products/ai-foundry/). Build AI-powered applications with chat completions, embeddings, content safety, and image generation - all returning tibbles that integrate seamlessly with tidyverse and tidymodels workflows.

## Features

- **Chat completions** - Interact with GPT, Claude, Llama, Mistral, DeepSeek, Cohere, and other models
- **Text embeddings** - Generate vector embeddings for semantic search, clustering, and ML
- **Content safety** - Moderate content, detect hallucinations (groundedness), and protect against prompt injection
- **Image generation** - Create images with DALL-E models
- **tidymodels integration** - Use `step_foundry_embed()` to add embeddings to your ML pipelines

## Installation

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
foundry_set_endpoint("https://your-resource.openai.azure.com")
foundry_set_key("your-api-key")

# Verify setup
foundry_check_setup()
```
For persistent configuration, add to your `.Renviron` file:

```
AZURE_FOUNDRY_ENDPOINT=https://your-resource.openai.azure.com
AZURE_FOUNDRY_KEY=your-api-key
```

### Chat with a model

```r
foundry_chat("What is the tidyverse?", model = "gpt-4o-mini")
#> # A tibble: 1 x 7
#>   role      content                          model finish_reason prompt_tokens
#>   <chr>     <chr>                            <chr> <chr>                 <int>
#> 1 assistant The tidyverse is a collection... gpt-4 stop                     10
#> # i 2 more variables: completion_tokens <int>, total_tokens <int>
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

foundryR integrates with [Azure AI Content Safety](https://azure.microsoft.com/products/ai-services/ai-content-safety/) for responsible AI features:

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

## Image Generation

Create images with DALL-E:

```r
result <- foundry_image(
  "A serene mountain landscape at sunset",
  model = "dall-e-3"
)
foundry_save_image(result, "landscape.png")
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
- [Text Embeddings](https://farach.github.io/foundryR/articles/embeddings.html) - Semantic search and similarity
- [Content Safety](https://farach.github.io/foundryR/articles/content-safety.html) - Responsible AI features
- [Image Generation](https://farach.github.io/foundryR/articles/image-generation.html) - Creating images with DALL-E
- [tidymodels Integration](https://farach.github.io/foundryR/articles/tidymodels.html) - ML pipelines with embeddings
- [Function Reference](https://farach.github.io/foundryR/reference/index.html) - Complete API documentation

## License

MIT
