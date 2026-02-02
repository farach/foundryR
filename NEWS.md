# foundryR (development version)
# foundryR 0.0.0.9000

Initial development release of foundryR, a tidy interface to Microsoft Azure AI Foundry.
## Core Features

### Chat Completions
- `foundry_chat()` for interacting with LLMs (GPT-4, Claude, Llama, Mistral, etc.)
- Support for system prompts and conversation history
- Compatible with both `max_tokens` and `max_completion_tokens` parameters

### Text Embeddings
- `foundry_embed()` for generating text embeddings
- `foundry_embed_batch()` for parallel batch processing with progress tracking
- `foundry_similarity()` for computing pairwise cosine similarities
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
- Comprehensive vignettes: Getting Started, Embeddings, Content Safety, Image Generation, tidymodels
- Full roxygen2 documentation for all exported functions
- pkgdown site with Azure-inspired styling
