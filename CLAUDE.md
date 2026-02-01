# foundryR - Claude Code Project Context

## Project Overview

**foundryR** is an R package providing a tidy, API-first interface to Microsoft Azure AI Foundry. It follows the patterns established in [huggingfaceR](https://github.com/farach/huggingfaceR) v2.0.

### Design Principles

1. **API-first**: Pure httr2-based implementation, no Python/reticulate dependencies
2. **Tidy outputs**: All functions return tibbles, never raw JSON or lists
3. **Tidyverse integration**: Works seamlessly with dplyr, purrr, tidymodels
4. **Enterprise-ready**: Designed for Azure enterprise environments with compliance/governance needs
5. **Research-friendly**: Enables AI and labor productivity research using Azure-hosted models

### Target Audience

- Enterprise R users already in Azure environments
- Researchers studying AI/LLM applications
- Data scientists needing compliant, governed AI access

---

## Azure API Reference

### Base URL Pattern

```
https://{resource-name}.openai.azure.com/openai/deployments/{deployment-id}/{endpoint}?api-version={version}
```

**User's endpoint**: `https://foundryr-resource.cognitiveservices.azure.com`

### Authentication

**API Key** (Header):
```
api-key: {AZURE_FOUNDRY_KEY}
```

**Microsoft Entra ID** (future, Phase 3):
```
Authorization: Bearer {token}
```

### Key Endpoints

| Endpoint | Path | Method |
|----------|------|--------|
| Chat Completions | `/openai/deployments/{deployment}/chat/completions` | POST |
| Embeddings | `/openai/deployments/{deployment}/embeddings` | POST |
| Completions | `/openai/deployments/{deployment}/completions` | POST |
| Images | `/openai/deployments/{deployment}/images/generations` | POST |

### API Versions

- GA: `2024-10-21`
- Preview: `2025-01-01-preview` (user confirmed working)

---

## Architecture Decisions

### Deployment vs Model Abstraction

Azure uses **deployment names** in URLs, not model names. The package abstracts this:

```r
# User-facing API (simple)
foundry_chat("Hello", model = "gpt-5-nano")

# Internal translation
# model -> deployment mapping via config or environment
# POST /openai/deployments/gpt-5-nano/chat/completions
```

**Decision**: For v1.0, treat `model` parameter as deployment name directly. Users specify their deployment name. Future versions may support a registry/mapping.

### Response Structure

All responses are tibbles with consistent columns:

```r
# Chat response
tibble(
  role = "assistant",
  content = "Response text...",
  model = "gpt-5-nano",
  finish_reason = "stop",
  prompt_tokens = 10,
  completion_tokens = 50,
  total_tokens = 60
)

# Embeddings response
tibble(
  text = "input text",
  embedding = list(c(0.1, 0.2, ...)),  # list-column
n_dims = 1536
)
```

### Error Handling Strategy

1. **Request-level**: httr2 `req_error()` with contextual messages
2. **Batch-level**: Track errors per item with `.error` and `.error_msg` columns
3. **Content filtering**: Parse Azure's content filter responses and surface clearly

### Streaming

**Decision**: Defer streaming to v1.1+. For v1.0, all responses are synchronous.

---

## Package Structure

```
foundryR/
├── R/
│   ├── auth.R              # foundry_set_key(), foundry_get_key()
│   ├── config.R            # Configuration management
│   ├── utils.R             # Internal helpers, request builders
│   ├── utils-pipe.R        # Pipe operator export
│   ├── globals.R           # globalVariables()
│   ├── chat.R              # foundry_chat()
│   ├── embed.R             # foundry_embed()
│   ├── embed-batch.R       # foundry_embed_batch()
│   ├── models.R            # foundry_models(), foundry_model_info()
│   ├── similarity.R        # foundry_similarity()
│   ├── tidymodels.R        # step_foundry_embed()
│   └── zzz.R               # .onAttach startup message
├── tests/testthat/
│   ├── helper.R            # Test helpers, mock setup
│   ├── test-auth.R
│   ├── test-chat.R
│   ├── test-embed.R
│   └── fixtures/           # httptest2 mock responses
├── vignettes/
│   ├── getting-started.Rmd
│   └── embeddings.Rmd
├── man/                    # Auto-generated roxygen2 docs
├── DESCRIPTION
├── NAMESPACE
├── LICENSE
├── README.md
├── _pkgdown.yml
└── CLAUDE.md               # This file
```

---

## Function Naming Conventions

Following huggingfaceR patterns:

| Function | Purpose |
|----------|---------|
| `foundry_set_key()` | Set API key for session |
| `foundry_get_key()` | Retrieve API key (internal) |
| `foundry_chat()` | Chat completions |
| `foundry_embed()` | Text embeddings |
| `foundry_embed_batch()` | Batch embeddings with parallel requests |
| `foundry_models()` | List available deployments |
| `foundry_similarity()` | Compute cosine similarity |
| `step_foundry_embed()` | tidymodels recipe step |

**Internal functions**: Prefix with `.` or don't export

---

## Environment Variables

| Variable | Purpose | Required |
|----------|---------|----------|
| `AZURE_FOUNDRY_KEY` | API key for authentication | Yes (for API key auth) |
| `AZURE_FOUNDRY_ENDPOINT` | Base endpoint URL | Yes |
| `AZURE_FOUNDRY_API_VERSION` | API version (default: 2024-10-21) | No |

---

## Testing Strategy

### Approach: httptest2 for Mocking

Since API calls cost money, use [httptest2](https://enpiar.com/httptest2/) to mock responses:

```r
# In tests/testthat/helper.R
library(httptest2)

# Record fixtures once with real credentials
# httptest2::start_capturing()
# foundry_chat("test")
# httptest2::stop_capturing()

# Tests run against fixtures
with_mock_dir("chat", {
  test_that("foundry_chat returns tibble", {
    result <- foundry_chat("Hello")
    expect_s3_class(result, "tbl_df")
  })
})
```

### Test Categories

1. **Unit tests**: Input validation, tibble structure, edge cases
2. **Integration tests**: Skip on CRAN, require real credentials
3. **Fixture tests**: Mock API responses for reliable CI

### Skip Patterns

```r
skip_on_cran()
skip_if(Sys.getenv("AZURE_FOUNDRY_KEY") == "", "No API key")
skip_if(Sys.getenv("AZURE_FOUNDRY_ENDPOINT") == "", "No endpoint")
```

---

## Documentation Standards

### Roxygen2 Template

```r
#' Chat with an Azure AI model
#'
#' Send a message to an Azure AI Foundry deployed model and receive a response.
#'
#' @param message Character. The user message to send.
#' @param system Character. Optional system prompt.
#' @param model Character. The deployment name (default from env or "gpt-4").
#' @param temperature Numeric. Sampling temperature 0-2 (default: 1).
#' @param max_tokens Integer. Maximum tokens in response.
#' @param ... Additional parameters passed to the API.
#'
#' @return A tibble with columns: role, content, model, finish_reason,
#'   prompt_tokens, completion_tokens, total_tokens.
#'
#' @export
#' @examples
#' \dontrun{
#' foundry_chat("What is R?")
#' foundry_chat("Explain tidyverse", system = "You are a helpful R tutor")
#' }
```

### pkgdown Structure

- **Get Started**: Authentication, first API call
- **Core Functions**: chat, embed, models
- **Advanced**: Batch processing, tidymodels integration
- **Reference**: Full function documentation

---

## Development Milestones

### Phase 1: MVP (v0.1.0)

- [ ] Package skeleton (DESCRIPTION, NAMESPACE)
- [ ] Authentication module (`foundry_set_key()`, `foundry_get_key()`)
- [ ] Configuration (`foundry_set_endpoint()`)
- [ ] Core request builder (internal)
- [ ] `foundry_chat()` - single message
- [ ] `foundry_embed()` - single/batch text
- [ ] Basic tests with httptest2 mocks
- [ ] README with quickstart

### Phase 2: Completeness (v0.2.0)

- [ ] `foundry_models()` - list deployments
- [ ] `foundry_chat()` - conversation history support
- [ ] `foundry_embed_batch()` - parallel requests
- [ ] `foundry_similarity()` - cosine similarity helper
- [ ] `step_foundry_embed()` - tidymodels integration
- [ ] Vignettes: getting-started, embeddings
- [ ] pkgdown site

### Phase 3: Polish (v1.0.0)

- [ ] Comprehensive error messages
- [ ] Rate limiting / retry logic
- [ ] Content filter handling
- [ ] Entra ID authentication (via AzureAuth)
- [ ] CRAN submission preparation
- [ ] Full test coverage

### Future (v1.x+)

- Streaming responses
- Image generation
- Audio transcription
- Fine-tuning API
- Agents API

---

## Code Patterns to Follow

### Request Builder (from huggingfaceR)

```r
foundry_request <- function(endpoint, body, method = "POST") {
  base_url <- foundry_get_endpoint()
  api_key <- foundry_get_key(required = TRUE)
  api_version <- Sys.getenv("AZURE_FOUNDRY_API_VERSION", "2024-10-21")

  httr2::request(base_url) |>
    httr2::req_url_path_append("openai", "deployments", deployment, endpoint) |>
    httr2::req_url_query(`api-version` = api_version) |>
    httr2::req_headers(`api-key` = api_key) |>
    httr2::req_body_json(body) |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_error(body = foundry_error_body)
}
```

### Response Parser

```r
foundry_parse_chat <- function(resp) {
  result <- httr2::resp_body_json(resp)
  choice <- result$choices[[1]]

  tibble::tibble(
    role = choice$message$role,
    content = choice$message$content,
    model = result$model,
    finish_reason = choice$finish_reason,
    prompt_tokens = result$usage$prompt_tokens,
    completion_tokens = result$usage$completion_tokens,
    total_tokens = result$usage$total_tokens
  )
}
```

### Vectorization Pattern

```r
foundry_embed <- function(text, model = NULL, ...) {
  purrr::map_dfr(text, function(single_text) {
    if (is.na(single_text)) {
      return(tibble::tibble(text = single_text, embedding = list(NULL), n_dims = NA_integer_))
    }
    # ... API call ...
  })
}
```

---

## Design Questions Resolved

| Question | Decision |
|----------|----------|
| Model vs deployment naming? | Use deployment name directly in v1.0 |
| Legacy `/openai/deployments/` vs unified `/models/`? | Use `/openai/deployments/` (confirmed working) |
| Streaming in v1.0? | Defer to v1.1+ |
| Multiple deployments of same model? | User specifies deployment name |
| Test mocking strategy? | httptest2 with recorded fixtures |

---

## Commands for Development

```bash
# Build and check
R CMD build .
R CMD check foundryR_*.tar.gz

# Document
devtools::document()

# Test
devtools::test()

# Install locally
devtools::install()

# pkgdown site
pkgdown::build_site()
```

---

## References

- [huggingfaceR source](https://github.com/farach/huggingfaceR)
- [Azure OpenAI REST API](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference)
- [httr2 documentation](https://httr2.r-lib.org/)
- [httptest2 for mocking](https://enpiar.com/httptest2/)
- [tidymodels custom steps](https://recipes.tidymodels.org/articles/Custom_Steps.html)
