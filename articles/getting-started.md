# Getting Started with foundryR

## Introduction

foundryR provides a tidy, API-first interface to Microsoft Azure AI
Foundry. All functions return tibbles and integrate seamlessly with
tidyverse and tidymodels workflows. This vignette will guide you through
initial setup, configuration, and your first API calls.

## Prerequisites

Before using foundryR, you need to set up resources in Azure AI Foundry.
This typically takes 5-10 minutes and involves:

1.  Creating an Azure OpenAI resource in the Azure Portal
2.  Deploying at least one model (e.g., `gpt-4o-mini` for chat,
    `text-embedding-3-small` for embeddings)
3.  Obtaining your endpoint URL and API key

For detailed step-by-step instructions, see the [foundryR
README](https://github.com/farach/foundryR#prerequisites) which includes
screenshots and guidance for each step.

**Important**: The **deployment name** you create in Azure is what you
pass to foundryR functions, not the base model name. For example, if you
deploy `gpt-4o-mini` with deployment name `my-gpt4`, you would use
`model = "my-gpt4"` in your R code.

## Installation

Install foundryR from GitHub:

``` r
# Install pak if you don't have it
# install.packages("pak")

pak::pak("farach/foundryR")
```

## Configuration

### Setting Credentials

foundryR requires two pieces of information to connect to Azure AI
Foundry:

- **Endpoint URL**: Your Azure OpenAI resource endpoint (e.g.,
  `https://your-resource-name.openai.azure.com`)
- **API Key**: Found in the Azure Portal under “Keys and Endpoint”

There are two ways to configure these credentials:

#### Option A: Session-Only (Interactive Use)

Set credentials for the current R session only:

``` r
library(foundryR)

foundry_set_endpoint("https://your-resource-name.openai.azure.com")
foundry_set_key("your-api-key-here")
```

#### Option B: Persistent Configuration (Recommended)

Store credentials in your `.Renviron` file so they persist across
sessions. You can do this manually or use the `store = TRUE` argument:

``` r
# Store credentials permanently
foundry_set_endpoint("https://your-resource-name.openai.azure.com", store = TRUE)
foundry_set_key("your-api-key-here", store = TRUE)
```

Alternatively, edit your `.Renviron` file directly:

``` r
# Open .Renviron for editing
usethis::edit_r_environ()
```

Add these lines to your `.Renviron`:

    AZURE_FOUNDRY_ENDPOINT=https://your-resource-name.openai.azure.com
    AZURE_FOUNDRY_KEY=your-api-key-here

After editing `.Renviron`, restart R for changes to take effect.

### Setting Default Models (Optional)

If you frequently use the same models, you can set defaults to avoid
specifying the `model` argument each time:

    AZURE_FOUNDRY_MODEL=my-gpt4
    AZURE_FOUNDRY_EMBED_MODEL=my-embeddings

### Validating Your Setup

Use
[`foundry_check_setup()`](https://farach.github.io/foundryR/reference/foundry_check_setup.md)
to verify your configuration:

``` r
library(foundryR)

foundry_check_setup()
```

This function checks that your endpoint and API key are configured and
provides helpful guidance if anything is missing. You can also test a
specific deployment:

``` r
# Test that a specific deployment works
foundry_check_setup(model = "my-gpt4")
```

## Your First Chat

Once configured, sending a chat message is straightforward with
[`foundry_chat()`](https://farach.github.io/foundryR/reference/foundry_chat.md):

``` r
library(foundryR)

# Simple question (replace "my-gpt4" with your deployment name)
response <- foundry_chat("What is the tidyverse?", model = "my-gpt4")
response
#> # A tibble: 1 x 7
#>   role      content                          model finish_reason prompt_tokens
#>   <chr>     <chr>                            <chr> <chr>                 <int>
#> 1 assistant The tidyverse is a collection... gpt-4 stop                     10
#> # ... with 2 more variables: completion_tokens <int>, total_tokens <int>

# Access the response text
response$content
```

### Using a System Prompt

You can guide the model’s behavior with a system prompt:

``` r
foundry_chat(
  "Explain what a tibble is",
  system = "You are a helpful R programming tutor. Be concise and use examples.",
  model = "my-gpt4"
)
```

### Adjusting Parameters

Control the response style with parameters like `temperature`:

``` r
# More creative responses (higher temperature)
foundry_chat(
  "Write a haiku about data science",
  model = "my-gpt4",
  temperature = 0.9,
  max_completion_tokens = 100
)

# More deterministic responses (lower temperature)
foundry_chat(
  "What is 2 + 2?",
  model = "my-gpt4",
  temperature = 0.1
)
```

## Your First Embedding

Embeddings convert text into numerical vectors that capture semantic
meaning. Use
[`foundry_embed()`](https://farach.github.io/foundryR/reference/foundry_embed.md)
to generate embeddings:

``` r
# Single text (replace "my-embeddings" with your embedding model deployment name)
embedding <- foundry_embed("Data science is fascinating", model = "my-embeddings")
embedding
#> # A tibble: 1 x 3
#>   text                       embedding      n_dims
#>   <chr>                      <list>          <int>
#> 1 Data science is fascinating <dbl [1,536]>   1536
```

The embedding is stored as a list-column containing a numeric vector.
You can embed multiple texts at once:

``` r
texts <- c(
  "I love R programming",
  "R is great for statistics",
"Python is also popular for data science"
)

embeddings <- foundry_embed(texts, model = "my-embeddings")
embeddings
#> # A tibble: 3 x 3
#>   text                                    embedding      n_dims
#>   <chr>                                   <list>          <int>
#> 1 I love R programming                    <dbl [1,536]>    1536
#> 2 R is great for statistics               <dbl [1,536]>    1536
#> 3 Python is also popular for data science <dbl [1,536]>    1536
```

## Next Steps

Now that you have foundryR configured and working, explore more advanced
topics:

- **Working with Embeddings**: Learn how to compute similarity scores,
  find related documents, and cluster text in the
  [`vignette("embeddings")`](https://farach.github.io/foundryR/articles/embeddings.md)
  vignette.

- **Conversation History**: Pass previous messages to
  [`foundry_chat()`](https://farach.github.io/foundryR/reference/foundry_chat.md)
  using the `history` argument for multi-turn conversations.

- **Error Handling**: Wrap API calls in
  [`tryCatch()`](https://rdrr.io/r/base/conditions.html) for robust
  production code.

For troubleshooting common issues like “Deployment not found” or “401
Unauthorized” errors, see the [troubleshooting
section](https://github.com/farach/foundryR#troubleshooting) in the
README.
