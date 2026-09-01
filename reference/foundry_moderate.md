# Moderate Text Content

Analyze text content for potentially harmful material using the Azure
Content Safety API. Returns severity scores for multiple harm categories
including hate speech, sexual content, self-harm, and violence.

## Usage

``` r
foundry_moderate(
  text,
  categories = c("Hate", "Sexual", "SelfHarm", "Violence"),
  output_type = c("FourSeverityLevels", "EightSeverityLevels"),
  blocklists = NULL,
  halt_on_blocklist = FALSE,
  endpoint = NULL,
  api_key = NULL,
  api_version = "2024-09-01"
)
```

## Arguments

- text:

  Character vector. The text(s) to analyze. Each text must be 10,000
  characters or less.

- categories:

  Character vector. Categories to analyze. Must be a subset of
  `c("Hate", "Sexual", "SelfHarm", "Violence")`. Default: all four
  categories.

- output_type:

  Character. Severity level granularity. One of `"FourSeverityLevels"`
  (returns 0, 2, 4, 6) or `"EightSeverityLevels"` (returns 0-7).
  Default: `"FourSeverityLevels"`.

- blocklists:

  Character vector of Content Safety blocklist names to apply.

- halt_on_blocklist:

  Logical. Whether the service should halt category analysis when
  blocklist content is found.

- endpoint:

  Character. Optional endpoint URL override. If NULL, uses the
  `AZURE_CONTENT_SAFETY_ENDPOINT` environment variable.

- api_key:

  Character. Optional API key override. If NULL, uses the
  `AZURE_CONTENT_SAFETY_KEY` environment variable.

- api_version:

  Character. API version to use. Default: `"2024-09-01"`.

## Value

A tibble with columns:

- text:

  Character. The input text (truncated to 50 chars if longer).

- category:

  Character. The harm category: "Hate", "Sexual", "SelfHarm", or
  "Violence".

- severity:

  Integer. Severity score. Range depends on `output_type`: 0-6 for
  FourSeverityLevels (values: 0, 2, 4, 6) or 0-7 for
  EightSeverityLevels.

- label:

  Character. Human-readable severity label: "safe", "low", "medium", or
  "high".

## Details

The Azure Content Safety API analyzes text for four types of harmful
content:

- **Hate**: Content that attacks or discriminates against individuals or
  groups based on protected attributes.

- **Sexual**: Sexually explicit or adult content.

- **SelfHarm**: Content that promotes or describes self-harm behaviors.

- **Violence**: Content that describes or promotes violence.

**Severity Labels:**

- **safe** (0): No harmful content detected.

- **low** (1-2): Mildly concerning content.

- **medium** (3-4): Moderately harmful content.

- **high** (5+): Severely harmful content.

## Authentication

You need an Azure Content Safety resource to use this function. Set up
the endpoint and either an API key or a resource-scoped bearer-token
provider:

- Environment variables: `AZURE_CONTENT_SAFETY_ENDPOINT` and
  `AZURE_CONTENT_SAFETY_KEY`

- Helper functions:
  [`foundry_set_content_safety_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_content_safety_endpoint.md)
  and
  [`foundry_set_content_safety_key()`](https://farach.github.io/foundryR/reference/foundry_set_content_safety_key.md)

- Microsoft Entra ID:
  [`foundry_set_token_provider()`](https://farach.github.io/foundryR/reference/foundry_set_token_provider.md)
  with `scope = "resource"`

## Examples

``` r
if (FALSE) { # \dontrun{
# Analyze a single text
foundry_moderate("This is a friendly message.")

# Analyze multiple texts
texts <- c(
  "Hello, how are you today?",
  "This is another message to check."
)
results <- foundry_moderate(texts)

# Filter for specific categories
foundry_moderate("Some text", categories = c("Hate", "Violence"))

# Use finer-grained severity levels
foundry_moderate("Some text", output_type = "EightSeverityLevels")

# Check results
library(dplyr)
results %>%
  filter(severity > 0) %>%
  arrange(desc(severity))
} # }
```
