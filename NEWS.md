# foundryR (development version)
# foundryR 0.0.0.9000

Initial development release of foundryR, a tidy interface to Microsoft Azure AI Foundry.
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
