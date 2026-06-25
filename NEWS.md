# foundryR (development version)
# foundryR 0.0.0.9000

Initial development release of foundryR, a tidy interface to Microsoft Azure AI Foundry.

- `foundry_batch_create()`, `foundry_batches()`, `foundry_batch_get()`, `foundry_batch_cancel()`, and `foundry_batch_requests()` add v1 Batch API workflows for large-scale prompt, annotation, extraction, and classification jobs.
- `foundry_file_upload()`, `foundry_files()`, `foundry_file_get()`, `foundry_file_delete()`, and `foundry_file_download()` add v1 Files API support for Batch, eval, fine-tuning, and assistant/file-search workflows.
- `foundry_image()` now uses the v1 preview image generation endpoint by default, supports newer image options such as `output_format`, `output_compression`, `background`, and `moderation`, and keeps the legacy deployment endpoint available with `api = "deployment"`.
- `foundry_image_edit()` adds v1 preview image editing with local image and optional mask uploads.
- `foundry_models()` now calls the v1 model/deployment metadata endpoints instead of sending a dummy chat request.
- `foundry_set_speech_endpoint()`, `foundry_set_speech_key()`, `foundry_transcribe()`, and `foundry_translate_audio()` add LLM Speech and MAI-Transcribe workflows for interview, lecture, meeting, and multilingual research audio.
- `foundry_set_token()` adds Microsoft Entra ID bearer-token support for keyless authentication across Foundry requests.
- `foundry_speak()` adds v1 preview text-to-speech output saved directly to local audio files.
- `foundry_video_job_create()`, `foundry_video_jobs()`, `foundry_video_job_get()`, `foundry_video_job_delete()`, `foundry_video_get()`, and `foundry_video_download()` add preview video generation job management and content download helpers.
## Core Features

### Chat Completions
- `foundry_chat()` for interacting with LLMs (GPT-4, Claude, Llama, Mistral, etc.)
- Support for system prompts and conversation history
- Compatible with both `max_tokens` and `max_completion_tokens` parameters

### Responses API
- `foundry_response()` for Microsoft Foundry's newer `/openai/v1/responses`
  endpoint, including stateful turns, tools, structured output formats, token
  usage, citations, tool-call metadata, and raw response capture.
- `foundry_response_retrieve()` and `foundry_response_delete()` for managing
  stored Responses API objects.
- `foundry_extract()` for JSON Schema-constrained structured extraction from
  text vectors, returning one tidy row per input with schema fields as columns.
- `foundry_web_search()` for Responses API web search with citations and
  tool-call metadata. Documentation calls out Microsoft Grounding with Bing
  compliance-boundary and cost considerations.

### Text Embeddings
- `foundry_embed()` for generating text embeddings
- `foundry_embed_batch()` for parallel batch processing with progress tracking
- `foundry_similarity()` for computing pairwise cosine similarities

### Performance
- `foundry_similarity()` now computes all pairwise cosine similarities with a
  single vectorized matrix product instead of a nested R loop, making it
  dramatically faster for larger embedding sets (e.g. hundreds of texts).
- Support for configurable embedding dimensions

### tidymodels Integration
- `step_foundry_embed()` recipe step for embedding text columns in ML pipelines
- Full compatibility with tidymodels cross-validation and tuning workflows

### Content Safety (Responsible AI)
- `foundry_moderate()` for content moderation across hate, violence, sexual, and self-harm categories
- `foundry_groundedness()` for hallucination detection in AI responses
- `foundry_shield()` for prompt injection and jailbreak detection

### Image Generation
- `foundry_image()` for generating images with DALL-E models
- `foundry_save_image()` for saving generated images locally
- Support for separate image endpoint/key configuration

### Configuration & Setup
- `foundry_set_key()` and `foundry_set_endpoint()` for credential management
- `foundry_check_setup()` for validating configuration
- Environment variable support for persistent configuration
- Separate configuration for Content Safety and Image Generation resources

## Documentation
- Comprehensive vignettes: Getting Started, Responses API, Embeddings, Content Safety, Image Generation, tidymodels
- Full roxygen2 documentation for all exported functions
- pkgdown site with Azure-inspired styling
