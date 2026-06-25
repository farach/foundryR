# Package index

## Setup & Configuration

Configure your Azure AI Foundry credentials and verify your setup. These
functions manage authentication for all API calls.

- [`foundry_check_setup()`](https://farach.github.io/foundryR/reference/foundry_check_setup.md)
  : Check foundryR Setup
- [`foundry_set_key()`](https://farach.github.io/foundryR/reference/foundry_set_key.md)
  : Set Azure AI Foundry API Key
- [`foundry_set_token()`](https://farach.github.io/foundryR/reference/foundry_set_token.md)
  : Set Azure AI Foundry Bearer Token
- [`foundry_set_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_endpoint.md)
  : Set Azure AI Foundry Endpoint
- [`foundry_get_endpoint()`](https://farach.github.io/foundryR/reference/foundry_get_endpoint.md)
  : Get Azure AI Foundry Endpoint
- [`foundry_set_speech_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_speech_endpoint.md)
  : Set Microsoft Foundry Speech endpoint
- [`foundry_set_speech_key()`](https://farach.github.io/foundryR/reference/foundry_set_speech_key.md)
  : Set Microsoft Foundry Speech API key

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

## Audio and Speech

Transcribe and translate research audio, including MAI-Transcribe models
through LLM Speech, and synthesize text-to-speech audio files.

- [`foundry_transcribe()`](https://farach.github.io/foundryR/reference/foundry_transcribe.md)
  : Transcribe an audio file with Microsoft Foundry
- [`foundry_translate_audio()`](https://farach.github.io/foundryR/reference/foundry_translate_audio.md)
  : Translate an audio file with Microsoft Foundry
- [`foundry_speak()`](https://farach.github.io/foundryR/reference/foundry_speak.md)
  : Generate speech audio from text

## Files and Batch API

Upload files, prepare JSONL request files, and manage asynchronous batch
jobs for large-scale annotation, extraction, and classification.

- [`foundry_file_upload()`](https://farach.github.io/foundryR/reference/foundry_file_upload.md)
  : Upload a file to Microsoft Foundry
- [`foundry_files()`](https://farach.github.io/foundryR/reference/foundry_files.md)
  : List uploaded Microsoft Foundry files
- [`foundry_file_get()`](https://farach.github.io/foundryR/reference/foundry_file_get.md)
  : Retrieve a Microsoft Foundry file
- [`foundry_file_delete()`](https://farach.github.io/foundryR/reference/foundry_file_delete.md)
  : Delete a Microsoft Foundry file
- [`foundry_file_download()`](https://farach.github.io/foundryR/reference/foundry_file_download.md)
  : Download Microsoft Foundry file content
- [`foundry_batch_requests()`](https://farach.github.io/foundryR/reference/foundry_batch_requests.md)
  : Write JSONL requests for the Batch API
- [`foundry_batch_create()`](https://farach.github.io/foundryR/reference/foundry_batch_create.md)
  : Create a Microsoft Foundry batch
- [`foundry_batches()`](https://farach.github.io/foundryR/reference/foundry_batches.md)
  : List Microsoft Foundry batches
- [`foundry_batch_get()`](https://farach.github.io/foundryR/reference/foundry_batch_get.md)
  : Retrieve a Microsoft Foundry batch
- [`foundry_batch_cancel()`](https://farach.github.io/foundryR/reference/foundry_batch_cancel.md)
  : Cancel a Microsoft Foundry batch

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

## Image and Video Generation

Generate and edit images with v1 preview image models, and manage
preview video generation jobs.

- [`foundry_image()`](https://farach.github.io/foundryR/reference/foundry_image.md)
  : Generate Images with DALL-E
- [`foundry_image_edit()`](https://farach.github.io/foundryR/reference/foundry_image_edit.md)
  : Edit an image with Microsoft Foundry
- [`foundry_save_image()`](https://farach.github.io/foundryR/reference/foundry_save_image.md)
  : Save Generated Image to File
- [`foundry_set_image_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_image_endpoint.md)
  : Set Image Generation Endpoint
- [`foundry_set_image_key()`](https://farach.github.io/foundryR/reference/foundry_set_image_key.md)
  : Set Image Generation API Key
- [`foundry_video_job_create()`](https://farach.github.io/foundryR/reference/foundry_video_job_create.md)
  : Create a Microsoft Foundry video generation job
- [`foundry_video_jobs()`](https://farach.github.io/foundryR/reference/foundry_video_jobs.md)
  : List Microsoft Foundry video generation jobs
- [`foundry_video_job_get()`](https://farach.github.io/foundryR/reference/foundry_video_job_get.md)
  : Retrieve a Microsoft Foundry video generation job
- [`foundry_video_job_delete()`](https://farach.github.io/foundryR/reference/foundry_video_job_delete.md)
  : Delete a Microsoft Foundry video generation job
- [`foundry_video_get()`](https://farach.github.io/foundryR/reference/foundry_video_get.md)
  : Retrieve a Microsoft Foundry video generation
- [`foundry_video_download()`](https://farach.github.io/foundryR/reference/foundry_video_download.md)
  : Download Microsoft Foundry generated video content

## Model Discovery

Explore available model deployments in your Azure AI Foundry resource.

- [`foundry_models()`](https://farach.github.io/foundryR/reference/foundry_models.md)
  : List or retrieve available model deployments
