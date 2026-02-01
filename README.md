# foundryR
<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**foundryR** provides a tidy, API-first interface to [Microsoft Azure AI Foundry](https://azure.microsoft.com/en-us/products/ai-foundry/). All functions return tibbles and integrate seamlessly with tidyverse and tidymodels workflows.

## Features

- **API-first**: Pure httr2 implementation, no Python dependencies
- **Tidy outputs**: All functions return tibbles
- **Enterprise-ready**: Designed for Azure environments with compliance/governance needs
- **Multiple models**: Works with GPT, Claude, Llama, Mistral, DeepSeek, Cohere, and more

## Prerequisites

Before using foundryR, you need to set up resources in Azure. This typically takes 5-10 minutes.
### Step 1: Create an Azure OpenAI Resource

1. Go to the [Azure Portal](https://portal.azure.com)
2. Click **Create a resource** > search for **Azure OpenAI**
3. Click **Create** and fill in:
   - **Subscription**: Your Azure subscription
   - **Resource group**: Create new or use existing
   - **Region**: Choose a region (e.g., East US, West Europe)
   - **Name**: A unique name (this becomes part of your endpoint URL)
   - **Pricing tier**: Standard S0
4. Click **Review + create** > **Create**
5. Wait for deployment to complete (1-2 minutes)

> **Note**: Azure OpenAI requires approval for new subscriptions. If you haven't used it before, you may need to [request access](https://aka.ms/oai/access).

### Step 2: Deploy a Model

You need to deploy at least one model before you can use the API.

1. Go to your Azure OpenAI resource in the portal
2. Click **Model deployments** > **Manage Deployments** (opens Azure AI Foundry)
3. Click **+ Deploy model** > **Deploy base model**
4. Select a model (e.g., `gpt-4o-mini` for chat, `text-embedding-3-small` for embeddings)
5. Give it a **Deployment name** - this is what you'll use in foundryR

> **Important**: The **deployment name** is what you pass to foundryR functions, not the model name. For example, if you deploy `gpt-4o-mini` with deployment name `my-gpt4`, you would use `model = "my-gpt4"` in your R code.

### Step 3: Get Your Credentials

You need two pieces of information:

**Endpoint URL:**
1. Go to your Azure OpenAI resource in the portal
2. Click **Keys and Endpoint** in the left sidebar
3. Copy the **Endpoint** (looks like `https://your-resource-name.openai.azure.com/`)

**API Key:**
1. On the same **Keys and Endpoint** page
2. Copy **Key 1** or **Key 2** (either works)

## Installation

```r
# Install from GitHub (development version)
# install.packages("pak")
pak::pak("farach/foundryR")
```

## Quick Start

### 1. Configure your credentials

```r
library(foundryR)

# Option A: Set credentials for current session
foundry_set_endpoint("https://your-resource-name.openai.azure.com")
foundry_set_key("your-api-key-here")

# Option B: Set environment variables (recommended for persistent use)
# Add these to your .Renviron file (usethis::edit_r_environ()):
# AZURE_FOUNDRY_ENDPOINT=https://your-resource-name.openai.azure.com
# AZURE_FOUNDRY_KEY=your-api-key-here

# Verify your setup
foundry_check_setup()
```

### 2. Chat with a model

```r
# Replace "my-gpt4" with YOUR deployment name from Azure
foundry_chat("What is the tidyverse?", model = "my-gpt4")
#> # A tibble: 1 x 7
#>   role      content                    model finish_reason prompt_tokens ...
#>   <chr>     <chr>                      <chr> <chr>                 <int> ...
#> 1 assistant The tidyverse is a collec~ gpt-4 stop                     10 ...

# With system prompt
foundry_chat(
  "Explain dplyr::mutate()",
  system = "You are a helpful R tutor. Be concise.",
  model = "my-gpt4"
)
```

### 3. Generate embeddings

```r
# Replace "my-embeddings" with YOUR embedding model deployment name
foundry_embed("Data science is fun", model = "my-embeddings")
#> # A tibble: 1 x 3
#>   text                embedding      n_dims
#>   <chr>               <list>          <int>
#> 1 Data science is fun <dbl [1,536]>    1536

# Multiple texts
texts <- c(
  "I love R programming",
  "R is great for statistics",
  "Python is also popular"
)
embeddings <- foundry_embed(texts, model = "my-embeddings")

# Compute similarities
foundry_similarity(embeddings)
#> # A tibble: 3 x 3
#>   text_1                  text_2                   similarity
#>   <chr>                   <chr>                         <dbl>
#> 1 I love R programming    R is great for statistics     0.912
#> 2 I love R programming    Python is also popular        0.834
#> 3 R is great for statist~ Python is also popular        0.801
```

## Configuration Reference

### Environment Variables

Set these in your `.Renviron` file for persistent configuration:

| Variable | Required | Description |
|----------|----------|-------------|
| `AZURE_FOUNDRY_ENDPOINT` | Yes | Your resource endpoint URL |
| `AZURE_FOUNDRY_KEY` | Yes | Your API key (Key 1 or Key 2 from Azure Portal) |
| `AZURE_FOUNDRY_MODEL` | No | Default deployment name for `foundry_chat()` |
| `AZURE_FOUNDRY_EMBED_MODEL` | No | Default deployment name for `foundry_embed()` |
| `AZURE_FOUNDRY_API_VERSION` | No | API version (default: `2024-10-21`) |

### Setting Defaults

If you always use the same models, set defaults to avoid repeating the `model` argument:

```r
# In your .Renviron file:
AZURE_FOUNDRY_MODEL=my-gpt4
AZURE_FOUNDRY_EMBED_MODEL=my-embeddings

# Then in R, you can omit the model argument:
foundry_chat("Hello!")
foundry_embed("Some text")
```

## Troubleshooting

### "Deployment not found"

This usually means the deployment name doesn't match. Check:
- Go to Azure AI Foundry > Model deployments
- Copy the exact **Deployment name** (not the model name)
- Deployment names are case-sensitive

### "401 Unauthorized" or "Invalid API key"

- Make sure you copied the full API key from Azure Portal
- Try Key 2 if Key 1 doesn't work
- Check that the key is for the correct resource

### "404 Resource not found"

- Verify your endpoint URL is correct
- It should look like `https://your-resource-name.openai.azure.com` (no trailing path)

### API Version Issues

If you get unexpected errors, try specifying a different API version:

```r
foundry_chat("Hello", model = "my-gpt4", api_version = "2024-10-21")
# or for preview features:
foundry_chat("Hello", model = "my-gpt4", api_version = "2025-01-01-preview")
```

## Roadmap

- [x] Authentication (`foundry_set_key()`, `foundry_set_endpoint()`)
- [x] Chat completions (`foundry_chat()`)
- [x] Text embeddings (`foundry_embed()`)
- [x] Similarity computation (`foundry_similarity()`)
- [ ] Batch embeddings (`foundry_embed_batch()`)
- [ ] tidymodels integration (`step_foundry_embed()`)
- [ ] Streaming responses
- [ ] Image generation
- [ ] Entra ID authentication

## Related Projects

- [huggingfaceR](https://github.com/farach/huggingfaceR) - Similar interface for Hugging Face APIs
- [httr2](https://httr2.r-lib.org/) - HTTP client used internally
- [tidymodels](https://www.tidymodels.org/) - ML framework for recipe integration

## License

MIT
