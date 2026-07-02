# Detect Groundedness of LLM Responses

Check whether an LLM-generated response is grounded in the provided
source documents using the Azure AI Content Safety groundedness
detection API. This helps identify hallucinations or unsupported claims
in AI-generated text.

## Usage

``` r
foundry_groundedness(
  text,
  grounding_sources,
  query = NULL,
  domain = c("Generic", "Medical"),
  task = c("QnA", "Summarization"),
  reasoning = FALSE,
  correction = FALSE,
  llm_resource = NULL,
  endpoint = NULL,
  api_key = NULL,
  api_version = "2024-09-15-preview"
)
```

## Arguments

- text:

  Character. The LLM-generated response text to check for groundedness.

- grounding_sources:

  Character vector. One or more source documents that the response
  should be grounded in.

- query:

  Character. Optional. The user's original question. Required when
  `task = "QnA"`.

- domain:

  Character. The domain context for groundedness detection.

  - `"Generic"` (default): General-purpose groundedness detection.

  - `"Medical"`: Optimized for medical/healthcare content.

- task:

  Character. The type of task being evaluated.

  - `"QnA"` (default): Question-and-answer task. Requires `query`
    parameter.

  - `"Summarization"`: Text summarization task. `query` is optional.

- reasoning:

  Logical. If `TRUE`, includes reasoning for ungrounded segments in the
  response. Requires a linked or supplied `llm_resource`. Default:
  `FALSE`.

- correction:

  Logical. If `TRUE`, requests corrected text that is consistent with
  the grounding sources (the Content Safety "mitigating" feature).
  Requires `llm_resource` and `api_version >= "2024-09-15-preview"`. The
  corrected text is returned in the `correction_text` column. Default:
  `FALSE`.

- llm_resource:

  List or `NULL`. Connection details for a bring-your-own Azure OpenAI
  deployment, used when `reasoning = TRUE` or `correction = TRUE`. Build
  it with
  [`foundry_llm_resource()`](https://farach.github.io/foundryR/reference/foundry_llm_resource.md).
  Default: `NULL`.

- endpoint:

  Character. Optional. The Azure Content Safety endpoint URL.

  Defaults to the `AZURE_CONTENT_SAFETY_ENDPOINT` environment variable.

- api_key:

  Character. Optional. The Azure Content Safety API key.

  Defaults to the `AZURE_CONTENT_SAFETY_KEY` environment variable.

- api_version:

  Character. The API version to use. Default: `"2024-09-15-preview"`.

## Value

A tibble with one row containing:

- grounded:

  Logical. `TRUE` if the text is fully grounded (no ungrounded content
  detected). `FALSE` if any ungrounded segments were found.

- grounded_pct:

  Numeric. The percentage of text that is grounded (1 -
  ungroundedPercentage). Value between 0 and 1.

- ungrounded_pct:

  Numeric. The percentage of text that is ungrounded. Value between 0
  and 1.

- ungrounded_segments:

  List. A character vector of text segments identified as ungrounded.
  Empty character vector if fully grounded.

- ungrounded_reasons:

  List. A character vector, aligned with `ungrounded_segments`, holding
  the model's explanation for each segment when `reasoning = TRUE`. `NA`
  entries appear when no explanation was returned.

- correction_text:

  Character. The corrected, grounding-consistent text returned when
  `correction = TRUE`, otherwise `NA`.

## Details

### Authentication

This function uses Azure Content Safety credentials, which are separate
from the Azure AI Foundry (OpenAI) credentials used by other foundryR
functions.

Set environment variables:

    AZURE_CONTENT_SAFETY_ENDPOINT=<your Content Safety endpoint URL>
    AZURE_CONTENT_SAFETY_KEY=your-api-key

Or pass `endpoint` and `api_key` directly to the function.

### Task Types

- **QnA**: Use when checking an answer to a specific question. The
  `query` parameter provides context about what question was being
  answered.

- **Summarization**: Use when checking a summary of source documents.
  The `query` parameter is optional.

### Domain Settings

- **Generic**: Default setting for most use cases.

- **Medical**: Use for healthcare-related content. May apply stricter
  groundedness requirements.

## Examples

``` r
if (FALSE) { # \dontrun{
# Check groundedness of a QnA response
result <- foundry_groundedness(
  text = "The capital of France is Paris. It has a population of 12 million.",
  grounding_sources = c("Paris is the capital and largest city of France."),
  query = "What is the capital of France?",
  task = "QnA"
)

# Check if fully grounded
result$grounded

# See what percentage is grounded
result$grounded_pct

# View ungrounded segments
result$ungrounded_segments[[1]]

# Check groundedness of a summarization
summary_result <- foundry_groundedness(
  text = "The study found significant improvements in patient outcomes.",
  grounding_sources = c(
    "A clinical trial showed 40% improvement in recovery time.",
    "Patient satisfaction increased by 25% compared to control group."
  ),
  task = "Summarization",
  domain = "Medical"
)

# With reasoning enabled
detailed_result <- foundry_groundedness(
  text = "The product was released in 2020 and has sold millions of units.",
  grounding_sources = c("The product launched in 2021 with strong initial sales."),
  query = "When was the product released?",
  reasoning = TRUE
)

# Request corrected text (requires a bring-your-own Azure OpenAI deployment)
corrected <- foundry_groundedness(
  text = "The patient name is Kevin.",
  grounding_sources = "The patient name is Jane.",
  task = "Summarization",
  domain = "Medical",
  correction = TRUE,
  llm_resource = foundry_llm_resource(
    endpoint = "https://your-openai.openai.azure.com",
    deployment_name = "gpt-5.5"
  )
)
corrected$correction_text
} # }
```
