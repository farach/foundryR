# foundryR 0.0.0.9000

Initial development release of foundryR, a tidy interface to Microsoft Azure AI Foundry.

## New features

- Added Agent Service support for named, versioned prompt agents with `foundry_agent_create()`, `foundry_agents()`, `foundry_agent_get()`, `foundry_agent_delete()`, and `foundry_agent_versions()`, plus a new `agent` argument on `foundry_response()` (backed by `foundry_agent_reference()`) that runs a stored agent by name through the project-scoped Responses endpoint (roadmap 2026 H2).
- Added Content Safety image moderation, protected-material detection, and text blocklist helpers with `foundry_moderate_image()`, `foundry_protected_material()`, `foundry_blocklists()`, and related blocklist item functions (roadmap 2026 H2).
- Added cloud evaluation workflows with grader constructors (`foundry_grader_string_check()`, `foundry_grader_text_similarity()`, `foundry_grader_label_model()`, `foundry_grader_score_model()`, and `foundry_grader_azure_ai()` for `builtin.*` evaluators), evaluation and run lifecycle functions (`foundry_eval_create()`, `foundry_evals()`, `foundry_eval_get()`, `foundry_eval_delete()`, `foundry_eval_run_create()`, `foundry_eval_runs()`, `foundry_eval_run_get()`, `foundry_eval_run_cancel()`), and `foundry_eval_run_output_items()`, which returns per-row grader scores as a tibble (roadmap 2026 H2).
- Added preview Content Safety operations: `foundry_protected_code()` for protected-material-in-code detection, `foundry_moderate_multimodal()` for image-with-text moderation, and `foundry_task_adherence()` (with `foundry_agent_tool()`, `foundry_agent_tool_call()`, and `foundry_agent_message()` builders) for agent task-adherence checks (roadmap 2026 H2).
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
- Added `foundry_token_azure_identity()`, a refreshable Microsoft Entra ID token provider backed by \pkg{AzureAuth} that supports service principals, managed identity, and interactive or device-code flows (roadmap 2026 H2).
- Added `foundry_set_speech_endpoint()`, `foundry_set_speech_key()`, `foundry_transcribe()`, and `foundry_translate_audio()` for LLM Speech and MAI-Transcribe workflows.
- Added `foundry_set_token()` for Microsoft Entra ID bearer-token authentication across Foundry requests.
- Added `foundry_speak()` for v1 preview text-to-speech output saved to local audio files.
- Added `foundry_cache_clear()` to remove embeddings cached on disk by `step_foundry_embed(cache = "disk")` (roadmap 2026 H2).
- Added `foundry_video_job_create()`, `foundry_video_jobs()`, `foundry_video_job_get()`, `foundry_video_job_delete()`, `foundry_video_get()`, and `foundry_video_download()` for preview video job management and content downloads.

## Improvements

- `foundry_groundedness()` now supports the Content Safety correction feature via `correction = TRUE` with a bring-your-own Azure OpenAI deployment described by the new `foundry_llm_resource()`, returning a `correction_text` column, and surfaces per-segment `ungrounded_reasons` when `reasoning = TRUE` (roadmap 2026 H2).

- `as_foundry_schema()` now converts `ellmer::type_object()` specifications to strict JSON Schema, so ellmer users can reuse existing type definitions in `foundry_extract()` and `foundry_response()` (roadmap 2026 H2).
- `foundry_agreement()` now reports Krippendorff's alpha alongside Cohen's and Fleiss' kappa, using \pkg{irr} when installed and a base-R nominal fallback otherwise (roadmap 2026 H2).
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
- `step_foundry_embed()` now supports `cache = "disk"` with an optional `cache_dir` to persist embeddings across bakes, and builds embedding columns from a single matrix instead of a per-cell fill loop (roadmap 2026 H2).

## Documentation and package metadata

- Documentation now positions foundryR around Azure AI Content Safety, Responses API workflows, strict extraction, embeddings, batch jobs, and research annotation workflows, with chat completions kept as a maintained convenience layer.
- The README, vignettes, and website articles now show real Azure AI Foundry output. Each documentation page runs once against live resources with `data-raw/record-doc-outputs.R`, which captures every API response as a sanitized \pkg{httptest2} fixture; all later builds (R CMD check, pkgdown, CRAN, CI) replay those fixtures and render the real tibbles, images, and audio with no credentials and no network calls. When fixtures are absent the API chunks simply do not evaluate, so nothing is fabricated.
- Added an onet2r integration as a website-only pkgdown article that pulls real occupation data from O\*NET, embeds it with `foundry_embed()`, ranks occupations by semantic similarity, and summarizes the top match with `foundry_chat()`; the redactor now strips the O\*NET `X-API-Key` header so its fixtures carry no secrets.
- Media helpers are grouped as experimental media while the core research surface is documented separately.
- Media documentation now uses one image and video generation vignette instead of separate overlapping image and media articles.
- New vignettes compare foundryR with ellmer and show an end-to-end annotation workflow.
- License metadata now uses a single MIT license file so GitHub reports one license.
