# foundryR 0.0.0.9000

Initial development release of foundryR, a tidy interface to Microsoft Azure AI Foundry.

## New features

- Added Content Safety image moderation, protected-material detection, and text blocklist helpers with `foundry_moderate_image()`, `foundry_protected_material()`, `foundry_blocklists()`, and related blocklist item functions (roadmap 2026 H2).
- Added Responses API conversation and vector store helpers, including `foundry_conversation_create()`, `foundry_conversations()`, `foundry_vector_store_create()`, `foundry_vector_search()`, and `foundry_tool_file_search()` (roadmap 2026 H2).
- Added schema constructors with `foundry_schema()`, `schema_string()`, `schema_enum()`, `schema_number()`, `schema_integer()`, `schema_boolean()`, `schema_array()`, `schema_object()`, and `as_foundry_schema()` for strict structured-output schemas (roadmap 2026 H2).
- Added validation helpers `foundry_agreement()`, `foundry_consistency()`, and `foundry_provenance()` for publication-oriented annotation checks and reproducibility metadata (roadmap 2026 H2).
- Added v1 Batch API workflows with `foundry_batch_create()`, `foundry_batches()`, `foundry_batch_get()`, `foundry_batch_cancel()`, and `foundry_batch_requests()` for large-scale prompt, annotation, extraction, and classification jobs.
- Added v1 Files API support with `foundry_file_upload()`, `foundry_files()`, `foundry_file_get()`, `foundry_file_delete()`, and `foundry_file_download()` for Batch, eval, fine-tuning, and file-search workflows.
- Added `foundry_agent()` and `foundry_tool()` for a bounded Responses API function-calling loop with user-defined R tools.
- Added `foundry_batch_results()`, `foundry_batch_wait()`, `foundry_extract_batch()`, and `foundry_usage()` to complete the batch annotation loop from JSONL requests through parsed tibble results and user-supplied cost summaries (roadmap 2026 H2).
- Added `foundry_image_edit()` for v1 preview image editing with local image and optional mask uploads.
- Added `foundry_response_cancel()` and `foundry_response_input_items()` for background Responses API workflows and response introspection (roadmap 2026 H2).
- Added `foundry_set_project_endpoint()`, `foundry_get_project_endpoint()`, `foundry_set_token_provider()`, and `foundry_token_azure_cli()` for project-scoped APIs and refreshable Microsoft Entra authentication (roadmap 2026 H2).
- Added `foundry_set_speech_endpoint()`, `foundry_set_speech_key()`, `foundry_transcribe()`, and `foundry_translate_audio()` for LLM Speech and MAI-Transcribe workflows.
- Added `foundry_set_token()` for Microsoft Entra ID bearer-token authentication across Foundry requests.
- Added `foundry_speak()` for v1 preview text-to-speech output saved to local audio files.
- Added `foundry_video_job_create()`, `foundry_video_jobs()`, `foundry_video_job_get()`, `foundry_video_job_delete()`, `foundry_video_get()`, and `foundry_video_download()` for preview video job management and content downloads.

## Improvements

- `foundry_chat()` now accepts `reasoning_effort` and returns `reasoning_tokens` and `cached_input_tokens` when chat-completions responses report those fields.
- `foundry_chat()` now defaults to the `/openai/v1/chat/completions` endpoint while keeping `api = "deployment"` as a legacy escape hatch (roadmap 2026 H2).
- `foundry_embed()` now uses the `/openai/v1/embeddings` array endpoint by default, returns row-level `.error` and `.error_msg` fields, and keeps `api = "deployment"` as a legacy escape hatch (roadmap 2026 H2).
- `foundry_extract()` now accepts data frames with `text_col`, preserves original columns, runs requests in parallel, and returns parse or HTTP failures as `.error` rows instead of aborting the whole job (roadmap 2026 H2).
- `foundry_image()` now uses the v1 preview image generation endpoint by default, supports newer image options such as `output_format`, `output_compression`, `background`, and `moderation`, and keeps the legacy deployment endpoint available with `api = "deployment"`.
- `foundry_moderate()` now supports Content Safety blocklists and keeps raw response payloads in list-columns (roadmap 2026 H2).
- `foundry_models()` now calls the v1 model and deployment metadata endpoints instead of sending a dummy chat request.
- `foundry_response()` now accepts background, conversation, prompt-cache, parallel-tool-call, max-tool-call, safety-identifier, and reasoning-summary controls from the v1 Responses API (roadmap 2026 H2).
- `foundry_response()` accepts `foundry_tool()` objects in `tools`, strips local R function references from request bodies, and returns `cached_input_tokens` when the Responses API reports cached input tokens.
- `foundry_similarity()` now computes all pairwise cosine similarities with a single vectorized matrix product, supports `top_k`, and can return a similarity matrix with `as_matrix = TRUE` (roadmap 2026 H2).

## Documentation and package metadata

- Documentation now positions foundryR around Azure AI Content Safety, Responses API workflows, strict extraction, embeddings, batch jobs, and research annotation workflows, with chat completions kept as a maintained convenience layer.
- Key vignettes now render precomputed gt tables and ggplot2 charts from cached illustrative data, so examples show the tibble outputs without calling Azure during documentation builds.
- Media helpers are grouped as experimental media while the core research surface is documented separately.
- Media documentation now uses one image and video generation vignette instead of separate overlapping image and media articles.
- New vignettes compare foundryR with ellmer and show an end-to-end annotation workflow.
- License metadata now uses a single MIT license file so GitHub reports one license.
