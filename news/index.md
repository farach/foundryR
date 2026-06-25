# Changelog

## foundryR (development version)

## foundryR 0.0.0.9000

Initial development release of foundryR, a tidy interface to Microsoft
Azure AI Foundry.

- [`foundry_batch_create()`](https://farach.github.io/foundryR/reference/foundry_batch_create.md),
  [`foundry_batches()`](https://farach.github.io/foundryR/reference/foundry_batches.md),
  [`foundry_batch_get()`](https://farach.github.io/foundryR/reference/foundry_batch_get.md),
  [`foundry_batch_cancel()`](https://farach.github.io/foundryR/reference/foundry_batch_cancel.md),
  and
  [`foundry_batch_requests()`](https://farach.github.io/foundryR/reference/foundry_batch_requests.md)
  add v1 Batch API workflows for large-scale prompt, annotation,
  extraction, and classification jobs.
- [`foundry_file_upload()`](https://farach.github.io/foundryR/reference/foundry_file_upload.md),
  [`foundry_files()`](https://farach.github.io/foundryR/reference/foundry_files.md),
  [`foundry_file_get()`](https://farach.github.io/foundryR/reference/foundry_file_get.md),
  [`foundry_file_delete()`](https://farach.github.io/foundryR/reference/foundry_file_delete.md),
  and
  [`foundry_file_download()`](https://farach.github.io/foundryR/reference/foundry_file_download.md)
  add v1 Files API support for Batch, eval, fine-tuning, and
  assistant/file-search workflows.
- [`foundry_image()`](https://farach.github.io/foundryR/reference/foundry_image.md)
  now uses the v1 preview image generation endpoint by default, supports
  newer image options such as `output_format`, `output_compression`,
  `background`, and `moderation`, and keeps the legacy deployment
  endpoint available with `api = "deployment"`.
- [`foundry_image_edit()`](https://farach.github.io/foundryR/reference/foundry_image_edit.md)
  adds v1 preview image editing with local image and optional mask
  uploads.
- [`foundry_models()`](https://farach.github.io/foundryR/reference/foundry_models.md)
  now calls the v1 model/deployment metadata endpoints instead of
  sending a dummy chat request.
- [`foundry_set_speech_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_speech_endpoint.md),
  [`foundry_set_speech_key()`](https://farach.github.io/foundryR/reference/foundry_set_speech_key.md),
  [`foundry_transcribe()`](https://farach.github.io/foundryR/reference/foundry_transcribe.md),
  and
  [`foundry_translate_audio()`](https://farach.github.io/foundryR/reference/foundry_translate_audio.md)
  add LLM Speech and MAI-Transcribe workflows for interview, lecture,
  meeting, and multilingual research audio.
- [`foundry_set_token()`](https://farach.github.io/foundryR/reference/foundry_set_token.md)
  adds Microsoft Entra ID bearer-token support for keyless
  authentication across Foundry requests.
- [`foundry_speak()`](https://farach.github.io/foundryR/reference/foundry_speak.md)
  adds v1 preview text-to-speech output saved directly to local audio
  files.
- [`foundry_video_job_create()`](https://farach.github.io/foundryR/reference/foundry_video_job_create.md),
  [`foundry_video_jobs()`](https://farach.github.io/foundryR/reference/foundry_video_jobs.md),
  [`foundry_video_job_get()`](https://farach.github.io/foundryR/reference/foundry_video_job_get.md),
  [`foundry_video_job_delete()`](https://farach.github.io/foundryR/reference/foundry_video_job_delete.md),
  [`foundry_video_get()`](https://farach.github.io/foundryR/reference/foundry_video_get.md),
  and
  [`foundry_video_download()`](https://farach.github.io/foundryR/reference/foundry_video_download.md)
  add preview video generation job management and content download
  helpers. \## Core Features

#### Chat Completions

- [`foundry_chat()`](https://farach.github.io/foundryR/reference/foundry_chat.md)
  for interacting with LLMs (GPT-4, Claude, Llama, Mistral, etc.)
- Support for system prompts and conversation history
- Compatible with both `max_tokens` and `max_completion_tokens`
  parameters

#### Responses API

- [`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
  for Microsoft Foundry’s newer `/openai/v1/responses` endpoint,
  including stateful turns, tools, structured output formats, token
  usage, citations, tool-call metadata, and raw response capture.
- [`foundry_response_retrieve()`](https://farach.github.io/foundryR/reference/foundry_response_retrieve.md)
  and
  [`foundry_response_delete()`](https://farach.github.io/foundryR/reference/foundry_response_delete.md)
  for managing stored Responses API objects.
- [`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
  for JSON Schema-constrained structured extraction from text vectors,
  returning one tidy row per input with schema fields as columns.
- [`foundry_web_search()`](https://farach.github.io/foundryR/reference/foundry_web_search.md)
  for Responses API web search with citations and tool-call metadata.
  Documentation calls out Microsoft Grounding with Bing
  compliance-boundary and cost considerations.

#### Text Embeddings

- [`foundry_embed()`](https://farach.github.io/foundryR/reference/foundry_embed.md)
  for generating text embeddings
- [`foundry_embed_batch()`](https://farach.github.io/foundryR/reference/foundry_embed_batch.md)
  for parallel batch processing with progress tracking
- [`foundry_similarity()`](https://farach.github.io/foundryR/reference/foundry_similarity.md)
  for computing pairwise cosine similarities

#### Performance

- [`foundry_similarity()`](https://farach.github.io/foundryR/reference/foundry_similarity.md)
  now computes all pairwise cosine similarities with a single vectorized
  matrix product instead of a nested R loop, making it dramatically
  faster for larger embedding sets (e.g. hundreds of texts).
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

- Comprehensive vignettes: Getting Started, Responses API, Embeddings,
  Content Safety, Image Generation, tidymodels
- Full roxygen2 documentation for all exported functions
- pkgdown site with Azure-inspired styling
