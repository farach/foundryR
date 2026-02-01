# Package index

## Authentication & Configuration

Set up your Azure AI Foundry credentials

- [`foundry_check_setup()`](https://farach.github.io/foundryR/reference/foundry_check_setup.md)
  : Check foundryR Setup
- [`foundry_set_key()`](https://farach.github.io/foundryR/reference/foundry_set_key.md)
  : Set Azure AI Foundry API Key
- [`foundry_set_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_endpoint.md)
  : Set Azure AI Foundry Endpoint
- [`foundry_get_endpoint()`](https://farach.github.io/foundryR/reference/foundry_get_endpoint.md)
  : Get Azure AI Foundry Endpoint
- [`foundry_set_content_safety_key()`](https://farach.github.io/foundryR/reference/foundry_set_content_safety_key.md)
  : Set Azure Content Safety API Key
- [`foundry_set_content_safety_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_content_safety_endpoint.md)
  : Set Azure Content Safety Endpoint

## Chat Completions

Interact with chat models

- [`foundry_chat()`](https://farach.github.io/foundryR/reference/foundry_chat.md)
  : Chat with an Azure AI Model

## Embeddings

Generate and work with text embeddings

- [`foundry_embed()`](https://farach.github.io/foundryR/reference/foundry_embed.md)
  : Generate Text Embeddings
- [`foundry_embed_batch()`](https://farach.github.io/foundryR/reference/foundry_embed_batch.md)
  : Generate Text Embeddings in Parallel Batches
- [`foundry_similarity()`](https://farach.github.io/foundryR/reference/foundry_similarity.md)
  : Compute Cosine Similarity Between Embeddings
- [`step_foundry_embed()`](https://farach.github.io/foundryR/reference/step_foundry_embed.md)
  [`tidy(`*`<step_foundry_embed>`*`)`](https://farach.github.io/foundryR/reference/step_foundry_embed.md)
  : Foundry Embedding Recipe Step
- [`bake(`*`<step_foundry_embed>`*`)`](https://farach.github.io/foundryR/reference/bake.step_foundry_embed.md)
  : Apply the Foundry embedding step to new data
- [`prep(`*`<step_foundry_embed>`*`)`](https://farach.github.io/foundryR/reference/prep.step_foundry_embed.md)
  : Prepare the Foundry embedding step
- [`print(`*`<step_foundry_embed>`*`)`](https://farach.github.io/foundryR/reference/print.step_foundry_embed.md)
  : Print method for step_foundry_embed
- [`required_pkgs(`*`<step_foundry_embed>`*`)`](https://farach.github.io/foundryR/reference/required_pkgs.step_foundry_embed.md)
  : Required packages for step_foundry_embed

## Content Safety

Content moderation and responsible AI features

- [`foundry_moderate()`](https://farach.github.io/foundryR/reference/foundry_moderate.md)
  : Moderate Text Content
- [`foundry_groundedness()`](https://farach.github.io/foundryR/reference/foundry_groundedness.md)
  : Detect Groundedness of LLM Responses
- [`foundry_shield()`](https://farach.github.io/foundryR/reference/foundry_shield.md)
  : Shield Prompt from Injection Attacks

## Image Generation

Generate images with DALL-E models

- [`foundry_image()`](https://farach.github.io/foundryR/reference/foundry_image.md)
  : Generate Images with DALL-E
- [`foundry_save_image()`](https://farach.github.io/foundryR/reference/foundry_save_image.md)
  : Save Generated Image to File
- [`foundry_set_image_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_image_endpoint.md)
  : Set Image Generation Endpoint
- [`foundry_set_image_key()`](https://farach.github.io/foundryR/reference/foundry_set_image_key.md)
  : Set Image Generation API Key

## Models

Discover available deployments

- [`foundry_models()`](https://farach.github.io/foundryR/reference/foundry_models.md)
  : List Available Models/Deployments
