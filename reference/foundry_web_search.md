# Search the web with the Responses API

Ask a model to use Microsoft Foundry's `web_search` tool and return a
tidy response with extracted citations and tool-call metadata.

## Usage

``` r
foundry_web_search(
  query,
  model = NULL,
  instructions = NULL,
  search_context_size = c("medium", "low", "high"),
  country = NULL,
  city = NULL,
  region = NULL,
  timezone = NULL,
  reasoning_effort = NULL,
  store = FALSE,
  api_key = NULL,
  endpoint = NULL,
  ...
)
```

## Arguments

- query:

  Character. The question or task that needs current web information.

- model:

  Character. The model deployment name. Defaults to
  `AZURE_FOUNDRY_MODEL`.

- instructions:

  Character. Optional instructions for how to use and cite web results.

- search_context_size:

  Character. Search context budget: `"low"`, `"medium"`, or `"high"`.

- country, city, region, timezone:

  Optional approximate user location fields for localized results.

- reasoning_effort:

  Character. Optional reasoning effort for reasoning models.

- store:

  Logical. Whether to store the response. Defaults to `FALSE`.

- api_key:

  Character. Optional API key override.

- endpoint:

  Character. Optional endpoint override.

- ...:

  Additional parameters passed to
  [`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md).

## Value

A one-row tibble parsed like
[`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md),
including `citations` and `tool_calls` list-columns.

## Details

Web search uses Grounding with Bing Search and/or Grounding with Bing
Custom Search. Microsoft documents that the Data Protection Addendum
does not apply to data sent to these services, data can leave compliance
and geographic boundaries, and tool usage can incur additional costs.

## References

- Web search with the Responses API:
  <https://learn.microsoft.com/azure/foundry/openai/how-to/web-search>

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_web_search(
  "What are the latest Azure AI Foundry Responses API updates?",
  model = "gpt-4.1"
)
} # }
```
