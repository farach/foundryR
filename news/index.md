# Changelog

## foundryR 0.0.0.9000

Initial development release of foundryR, a tidy interface to Microsoft
Azure AI Foundry.

### New features

- Added v1 Batch API workflows with
  [`foundry_batch_create()`](https://farach.github.io/foundryR/reference/foundry_batch_create.md),
  [`foundry_batches()`](https://farach.github.io/foundryR/reference/foundry_batches.md),
  [`foundry_batch_get()`](https://farach.github.io/foundryR/reference/foundry_batch_get.md),
  [`foundry_batch_cancel()`](https://farach.github.io/foundryR/reference/foundry_batch_cancel.md),
  and
  [`foundry_batch_requests()`](https://farach.github.io/foundryR/reference/foundry_batch_requests.md)
  for large-scale prompt, annotation, extraction, and classification
  jobs.
- Added v1 Files API support with
  [`foundry_file_upload()`](https://farach.github.io/foundryR/reference/foundry_file_upload.md),
  [`foundry_files()`](https://farach.github.io/foundryR/reference/foundry_files.md),
  [`foundry_file_get()`](https://farach.github.io/foundryR/reference/foundry_file_get.md),
  [`foundry_file_delete()`](https://farach.github.io/foundryR/reference/foundry_file_delete.md),
  and
  [`foundry_file_download()`](https://farach.github.io/foundryR/reference/foundry_file_download.md)
  for Batch, eval, fine-tuning, and file-search workflows.
- Added
  [`foundry_agent()`](https://farach.github.io/foundryR/reference/foundry_agent.md)
  and
  [`foundry_tool()`](https://farach.github.io/foundryR/reference/foundry_tool.md)
  for a bounded Responses API function-calling loop with user-defined R
  tools.
- Added
  [`foundry_image_edit()`](https://farach.github.io/foundryR/reference/foundry_image_edit.md)
  for v1 preview image editing with local image and optional mask
  uploads.
- Added
  [`foundry_set_speech_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_speech_endpoint.md),
  [`foundry_set_speech_key()`](https://farach.github.io/foundryR/reference/foundry_set_speech_key.md),
  [`foundry_transcribe()`](https://farach.github.io/foundryR/reference/foundry_transcribe.md),
  and
  [`foundry_translate_audio()`](https://farach.github.io/foundryR/reference/foundry_translate_audio.md)
  for LLM Speech and MAI-Transcribe workflows.
- Added
  [`foundry_set_token()`](https://farach.github.io/foundryR/reference/foundry_set_token.md)
  for Microsoft Entra ID bearer-token authentication across Foundry
  requests.
- Added
  [`foundry_speak()`](https://farach.github.io/foundryR/reference/foundry_speak.md)
  for v1 preview text-to-speech output saved to local audio files.
- Added
  [`foundry_video_job_create()`](https://farach.github.io/foundryR/reference/foundry_video_job_create.md),
  [`foundry_video_jobs()`](https://farach.github.io/foundryR/reference/foundry_video_jobs.md),
  [`foundry_video_job_get()`](https://farach.github.io/foundryR/reference/foundry_video_job_get.md),
  [`foundry_video_job_delete()`](https://farach.github.io/foundryR/reference/foundry_video_job_delete.md),
  [`foundry_video_get()`](https://farach.github.io/foundryR/reference/foundry_video_get.md),
  and
  [`foundry_video_download()`](https://farach.github.io/foundryR/reference/foundry_video_download.md)
  for preview video job management and content downloads.

### Improvements

- [`foundry_chat()`](https://farach.github.io/foundryR/reference/foundry_chat.md)
  now accepts `reasoning_effort` and returns `reasoning_tokens` and
  `cached_input_tokens` when chat-completions responses report those
  fields.
- [`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
  uses strict JSON Schema mode by default for supported Responses API
  models.
- [`foundry_image()`](https://farach.github.io/foundryR/reference/foundry_image.md)
  now uses the v1 preview image generation endpoint by default, supports
  newer image options such as `output_format`, `output_compression`,
  `background`, and `moderation`, and keeps the legacy deployment
  endpoint available with `api = "deployment"`.
- [`foundry_models()`](https://farach.github.io/foundryR/reference/foundry_models.md)
  now calls the v1 model and deployment metadata endpoints instead of
  sending a dummy chat request.
- [`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
  accepts
  [`foundry_tool()`](https://farach.github.io/foundryR/reference/foundry_tool.md)
  objects in `tools`, strips local R function references from request
  bodies, and returns `cached_input_tokens` when the Responses API
  reports cached input tokens.
- [`foundry_similarity()`](https://farach.github.io/foundryR/reference/foundry_similarity.md)
  now computes all pairwise cosine similarities with a single vectorized
  matrix product instead of a nested R loop.

### Documentation and package metadata

- Documentation now positions foundryR around Azure AI Content Safety,
  Responses API workflows, strict extraction, embeddings, batch jobs,
  and research annotation workflows, with chat completions kept as a
  maintained convenience layer.
- Key vignettes now render precomputed gt tables and ggplot2 charts from
  cached illustrative data, so examples show the tibble outputs without
  calling Azure during documentation builds.
- Media helpers are grouped as experimental media while the core
  research surface is documented separately.
- Media documentation now uses one image and video generation vignette
  instead of separate overlapping image and media articles.
- New vignettes compare foundryR with ellmer and show an end-to-end
  annotation workflow.
- License metadata now uses a single MIT license file so GitHub reports
  one license.
