# Changelog

## foundryR (development version)

## foundryR 0.0.0.9000

Initial development release of foundryR, a tidy interface to Microsoft
Azure AI Foundry. \## Core Features

#### Chat Completions

- [`foundry_chat()`](https://farach.github.io/foundryR/reference/foundry_chat.md)
  for interacting with LLMs (GPT-4, Claude, Llama, Mistral, etc.)
- Support for system prompts and conversation history
- Compatible with both `max_tokens` and `max_completion_tokens`
  parameters

#### Text Embeddings

- [`foundry_embed()`](https://farach.github.io/foundryR/reference/foundry_embed.md)
  for generating text embeddings
- [`foundry_embed_batch()`](https://farach.github.io/foundryR/reference/foundry_embed_batch.md)
  for parallel batch processing with progress tracking
- [`foundry_similarity()`](https://farach.github.io/foundryR/reference/foundry_similarity.md)
  for computing pairwise cosine similarities
- Support for configurable embedding dimensions

#### tidymodels Integration

- [`step_foundry_embed()`](https://farach.github.io/foundryR/reference/step_foundry_embed.md)
  recipe step for embedding text columns in ML pipelines
- Full compatibility with tidymodels cross-validation and tuning
  workflows

#### Content Safety (Responsible AI)

- [`foundry_moderate()`](https://farach.github.io/foundryR/reference/foundry_moderate.md)
  for content moderation across hate, violence, sexual, and self-harm
  categories
- [`foundry_groundedness()`](https://farach.github.io/foundryR/reference/foundry_groundedness.md)
  for hallucination detection in AI responses
- [`foundry_shield()`](https://farach.github.io/foundryR/reference/foundry_shield.md)
  for prompt injection and jailbreak detection

#### Image Generation

- [`foundry_image()`](https://farach.github.io/foundryR/reference/foundry_image.md)
  for generating images with DALL-E models
- [`foundry_save_image()`](https://farach.github.io/foundryR/reference/foundry_save_image.md)
  for saving generated images locally
- Support for separate image endpoint/key configuration

#### Configuration & Setup

- [`foundry_set_key()`](https://farach.github.io/foundryR/reference/foundry_set_key.md)
  and
  [`foundry_set_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_endpoint.md)
  for credential management
- [`foundry_check_setup()`](https://farach.github.io/foundryR/reference/foundry_check_setup.md)
  for validating configuration
- Environment variable support for persistent configuration
- Separate configuration for Content Safety and Image Generation
  resources

### Documentation

- Comprehensive vignettes: Getting Started, Embeddings, Content Safety,
  Image Generation, tidymodels
- Full roxygen2 documentation for all exported functions
- pkgdown site with Azure-inspired styling
