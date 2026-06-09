# Package index

## Setup & Configuration

Configure your Azure AI Foundry credentials and verify your setup. These
functions manage authentication for all API calls.

- [`foundry_check_setup()`](https://farach.github.io/foundryR/reference/foundry_check_setup.md)
  : Check foundryR Setup
- [`foundry_set_key()`](https://farach.github.io/foundryR/reference/foundry_set_key.md)
  : Set Azure AI Foundry API Key
- [`foundry_set_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_endpoint.md)
  : Set Azure AI Foundry Endpoint
- [`foundry_get_endpoint()`](https://farach.github.io/foundryR/reference/foundry_get_endpoint.md)
  : Get Azure AI Foundry Endpoint

## Chat Completions

Interact with large language models like GPT-4, Claude, Llama, and more.
Send messages and receive AI-generated responses as tidy tibbles.

- [`foundry_chat()`](https://farach.github.io/foundryR/reference/foundry_chat.md)
  : Chat with an Azure AI Model

## Responses API

Use Microsoft Foundry’s newer v1 Responses API for stateful turns, tool
calls, schema-constrained extraction, and web-grounded answers.

- [`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
  : Create a response with the Azure OpenAI Responses API
- [`foundry_response_retrieve()`](https://farach.github.io/foundryR/reference/foundry_response_retrieve.md)
  : Retrieve a stored Responses API response
- [`foundry_response_delete()`](https://farach.github.io/foundryR/reference/foundry_response_delete.md)
  : Delete a stored Responses API response
- [`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
  : Extract structured data from text using JSON Schema
- [`foundry_web_search()`](https://farach.github.io/foundryR/reference/foundry_web_search.md)
  : Search the web with the Responses API

## Text Embeddings

Generate vector embeddings for semantic search, clustering, and machine
learning. Includes batch processing and similarity computation.

- [`foundry_embed()`](https://farach.github.io/foundryR/reference/foundry_embed.md)
  : Generate Text Embeddings
- [`foundry_embed_batch()`](https://farach.github.io/foundryR/reference/foundry_embed_batch.md)
  : Generate Text Embeddings in Parallel Batches
- [`foundry_similarity()`](https://farach.github.io/foundryR/reference/foundry_similarity.md)
  : Compute Cosine Similarity Between Embeddings

## tidymodels Integration

Seamlessly integrate text embeddings into your tidymodels workflows
using recipe steps.

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

Azure AI Content Safety features for responsible AI deployment. Moderate
content, detect hallucinations, and protect against prompt injection.

- [`foundry_moderate()`](https://farach.github.io/foundryR/reference/foundry_moderate.md)
  : Moderate Text Content
- [`foundry_groundedness()`](https://farach.github.io/foundryR/reference/foundry_groundedness.md)
  : Detect Groundedness of LLM Responses
- [`foundry_shield()`](https://farach.github.io/foundryR/reference/foundry_shield.md)
  : Shield Prompt from Injection Attacks
- [`foundry_set_content_safety_key()`](https://farach.github.io/foundryR/reference/foundry_set_content_safety_key.md)
  : Set Azure Content Safety API Key
- [`foundry_set_content_safety_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_content_safety_endpoint.md)
  : Set Azure Content Safety Endpoint

## Image Generation

Create images with DALL-E models. Generate, customize, and save
AI-generated artwork and visualizations.

- [`foundry_image()`](https://farach.github.io/foundryR/reference/foundry_image.md)
  : Generate Images with DALL-E
- [`foundry_save_image()`](https://farach.github.io/foundryR/reference/foundry_save_image.md)
  : Save Generated Image to File
- [`foundry_set_image_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_image_endpoint.md)
  : Set Image Generation Endpoint
- [`foundry_set_image_key()`](https://farach.github.io/foundryR/reference/foundry_set_image_key.md)
  : Set Image Generation API Key

## Model Discovery

Explore available model deployments in your Azure AI Foundry resource.

- [`foundry_models()`](https://farach.github.io/foundryR/reference/foundry_models.md)
  : List Available Models/Deployments
