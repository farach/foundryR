# Changelog

## foundryR 0.0.0.9000

Initial development release of foundryR, a tidy interface to Microsoft
Azure AI Foundry.

### New features

- Added Content Safety image moderation, protected-material detection,
  and text blocklist helpers with
  [`foundry_moderate_image()`](https://farach.github.io/foundryR/reference/foundry_moderate_image.md),
  [`foundry_protected_material()`](https://farach.github.io/foundryR/reference/foundry_protected_material.md),
  [`foundry_blocklists()`](https://farach.github.io/foundryR/reference/foundry_blocklists.md),
  and related blocklist item functions (roadmap 2026 H2).
- Added Responses API conversation and vector store helpers, including
  [`foundry_conversation_create()`](https://farach.github.io/foundryR/reference/foundry_conversations.md),
  [`foundry_conversations()`](https://farach.github.io/foundryR/reference/foundry_conversations.md),
  [`foundry_vector_store_create()`](https://farach.github.io/foundryR/reference/foundry_vector_stores.md),
  [`foundry_vector_search()`](https://farach.github.io/foundryR/reference/foundry_vector_stores.md),
  and
  [`foundry_tool_file_search()`](https://farach.github.io/foundryR/reference/foundry_tool_file_search.md)
  (roadmap 2026 H2).
- Added schema constructors with
  [`foundry_schema()`](https://farach.github.io/foundryR/reference/foundry_schema.md),
  [`schema_string()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
  [`schema_enum()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
  [`schema_number()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
  [`schema_integer()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
  [`schema_boolean()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
  [`schema_array()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
  [`schema_object()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
  and
  [`as_foundry_schema()`](https://farach.github.io/foundryR/reference/as_foundry_schema.md)
  for strict structured-output schemas (roadmap 2026 H2).
- Added validation helpers
  [`foundry_agreement()`](https://farach.github.io/foundryR/reference/foundry_agreement.md),
  [`foundry_consistency()`](https://farach.github.io/foundryR/reference/foundry_consistency.md),
  and
  [`foundry_provenance()`](https://farach.github.io/foundryR/reference/foundry_provenance.md)
  for publication-oriented annotation checks and reproducibility
  metadata (roadmap 2026 H2).
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
  [`foundry_batch_results()`](https://farach.github.io/foundryR/reference/foundry_batch_results.md),
  [`foundry_batch_wait()`](https://farach.github.io/foundryR/reference/foundry_batch_wait.md),
  [`foundry_extract_batch()`](https://farach.github.io/foundryR/reference/foundry_extract_batch.md),
  and
  [`foundry_usage()`](https://farach.github.io/foundryR/reference/foundry_usage.md)
  to complete the batch annotation loop from JSONL requests through
  parsed tibble results and user-supplied cost summaries (roadmap 2026
  H2).
- Added
  [`foundry_image_edit()`](https://farach.github.io/foundryR/reference/foundry_image_edit.md)
  for v1 preview image editing with local image and optional mask
  uploads.
- Added
  [`foundry_response_cancel()`](https://farach.github.io/foundryR/reference/foundry_response_cancel.md)
  and
  [`foundry_response_input_items()`](https://farach.github.io/foundryR/reference/foundry_response_input_items.md)
  for background Responses API workflows and response introspection
  (roadmap 2026 H2).
- Added
  [`foundry_set_project_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_project_endpoint.md),
  [`foundry_get_project_endpoint()`](https://farach.github.io/foundryR/reference/foundry_get_project_endpoint.md),
  [`foundry_set_token_provider()`](https://farach.github.io/foundryR/reference/foundry_set_token_provider.md),
  and
  [`foundry_token_azure_cli()`](https://farach.github.io/foundryR/reference/foundry_token_azure_cli.md)
  for project-scoped APIs and refreshable Microsoft Entra authentication
  (roadmap 2026 H2).
- Added
  [`foundry_token_azure_identity()`](https://farach.github.io/foundryR/reference/foundry_token_azure_identity.md),
  a refreshable Microsoft Entra ID token provider backed by that
  supports service principals, managed identity, and interactive or
  device-code flows (roadmap 2026 H2).
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
  [`foundry_cache_clear()`](https://farach.github.io/foundryR/reference/foundry_cache_clear.md)
  to remove embeddings cached on disk by
  `step_foundry_embed(cache = "disk")` (roadmap 2026 H2).
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

- [`foundry_groundedness()`](https://farach.github.io/foundryR/reference/foundry_groundedness.md)
  now supports the Content Safety correction feature via
  `correction = TRUE` with a bring-your-own Azure OpenAI deployment
  described by the new
  [`foundry_llm_resource()`](https://farach.github.io/foundryR/reference/foundry_llm_resource.md),
  returning a `correction_text` column, and surfaces per-segment
  `ungrounded_reasons` when `reasoning = TRUE` (roadmap 2026 H2).

- [`as_foundry_schema()`](https://farach.github.io/foundryR/reference/as_foundry_schema.md)
  now converts
  [`ellmer::type_object()`](https://ellmer.tidyverse.org/reference/type_boolean.html)
  specifications to strict JSON Schema, so ellmer users can reuse
  existing type definitions in
  [`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
  and
  [`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
  (roadmap 2026 H2).

- [`foundry_agreement()`](https://farach.github.io/foundryR/reference/foundry_agreement.md)
  now reports Krippendorff’s alpha alongside Cohen’s and Fleiss’ kappa,
  using when installed and a base-R nominal fallback otherwise (roadmap
  2026 H2).

- [`foundry_chat()`](https://farach.github.io/foundryR/reference/foundry_chat.md)
  now accepts `reasoning_effort` and returns `reasoning_tokens` and
  `cached_input_tokens` when chat-completions responses report those
  fields.

- [`foundry_chat()`](https://farach.github.io/foundryR/reference/foundry_chat.md)
  now defaults to the `/openai/v1/chat/completions` endpoint while
  keeping `api = "deployment"` as a legacy escape hatch (roadmap 2026
  H2).

- [`foundry_embed()`](https://farach.github.io/foundryR/reference/foundry_embed.md)
  now uses the `/openai/v1/embeddings` array endpoint by default,
  returns row-level `.error` and `.error_msg` fields, and keeps
  `api = "deployment"` as a legacy escape hatch (roadmap 2026 H2).

- [`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
  now accepts data frames with `text_col`, preserves original columns,
  runs requests in parallel, and returns parse or HTTP failures as
  `.error` rows instead of aborting the whole job (roadmap 2026 H2).

- [`foundry_image()`](https://farach.github.io/foundryR/reference/foundry_image.md)
  now uses the v1 preview image generation endpoint by default, supports
  newer image options such as `output_format`, `output_compression`,
  `background`, and `moderation`, and keeps the legacy deployment
  endpoint available with `api = "deployment"`.

- [`foundry_moderate()`](https://farach.github.io/foundryR/reference/foundry_moderate.md)
  now supports Content Safety blocklists and keeps raw response payloads
  in list-columns (roadmap 2026 H2).

- [`foundry_models()`](https://farach.github.io/foundryR/reference/foundry_models.md)
  now calls the v1 model and deployment metadata endpoints instead of
  sending a dummy chat request.

- [`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
  now accepts background, conversation, prompt-cache,
  parallel-tool-call, max-tool-call, safety-identifier, and
  reasoning-summary controls from the v1 Responses API (roadmap 2026
  H2).

- [`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
  accepts
  [`foundry_tool()`](https://farach.github.io/foundryR/reference/foundry_tool.md)
  objects in `tools`, strips local R function references from request
  bodies, and returns `cached_input_tokens` when the Responses API
  reports cached input tokens.

- [`foundry_similarity()`](https://farach.github.io/foundryR/reference/foundry_similarity.md)
  now computes all pairwise cosine similarities with a single vectorized
  matrix product, supports `top_k`, and can return a similarity matrix
  with `as_matrix = TRUE` (roadmap 2026 H2).

- [`step_foundry_embed()`](https://farach.github.io/foundryR/reference/step_foundry_embed.md)
  now supports `cache = "disk"` with an optional `cache_dir` to persist
  embeddings across bakes, and builds embedding columns from a single
  matrix instead of a per-cell fill loop (roadmap 2026 H2).

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
