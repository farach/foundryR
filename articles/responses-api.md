# Responses API, Structured Extraction, and Web Search

## Why the Responses API matters

Microsoft Foundry now exposes a newer v1 data-plane endpoint for Azure
OpenAI:

``` text
https://<resource>.openai.azure.com/openai/v1/responses
```

Unlike the older deployment-path chat API, the v1 Responses API sends
the model deployment in the JSON body. It also adds stateful response
chaining, built-in tools, structured output formats, and richer output
metadata.

foundryR wraps this with
[`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
while preserving the package’s tidy interface: generated text,
citations, tool calls, token usage, and the raw response are returned as
tibble columns.

## Basic response

``` r

library(foundryR)

foundry_set_endpoint("AZURE_FOUNDRY_ENDPOINT")
foundry_set_key("your-api-key")

foundry_response(
  "Summarize retrieval-augmented generation in two sentences.",
  model = "gpt-4.1"
)
```

The result includes:

- `response_id`: the stored Responses API object ID
- `output_text`: generated text aggregated from the response output
  items
- `citations`: a list-column of URL citations, when present
- `tool_calls`: a list-column of tool calls, such as web-search calls
- token usage columns and a `raw_response` list-column

## Stateful turns

Responses are stored by the service by default. You can chain turns by
passing the previous `response_id`:

``` r

first <- foundry_response(
  "Define catastrophic forgetting.",
  model = "gpt-4.1"
)

second <- foundry_response(
  "Explain it for a college freshman.",
  model = "gpt-4.1",
  previous_response_id = first$response_id
)

second$output_text
```

If you do not want the service to store a response, pass
`store = FALSE`. Stateful chaining with `previous_response_id` requires
the previous response to be stored.

## Structured extraction with JSON Schema

[`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
is designed for data scientists and researchers who need to turn free
text into analyzable variables. You provide a JSON Schema as an R list;
foundryR sends it through the Responses API structured output format and
returns one row per input text.

``` r

schema <- list(
  type = "object",
  properties = list(
    sentiment = list(
      type = "string",
      enum = c("positive", "negative", "neutral")
    ),
    entities = list(
      type = "array",
      items = list(type = "string")
    ),
    summary = list(type = "string")
  ),
  required = c("sentiment", "entities", "summary"),
  additionalProperties = FALSE
)

texts <- c(
  "The new data pipeline reduced manual coding time by half.",
  "Participants reported confusion about the consent form."
)

foundry_extract(
  texts,
  schema = schema,
  model = "gpt-4.1"
)
```

Top-level scalar fields become regular tibble columns. Arrays and nested
objects become list-columns, which work naturally with tidyverse
workflows.

## Web-grounded answers with citations

[`foundry_web_search()`](https://farach.github.io/foundryR/reference/foundry_web_search.md)
uses the Responses API `web_search` tool and parses URL citations into a
tidy list-column:

``` r

answer <- foundry_web_search(
  "What changed recently in Azure AI Foundry Responses API?",
  model = "gpt-4.1",
  search_context_size = "high"
)

answer$output_text
answer$citations[[1]]
answer$tool_calls[[1]]
```

You can optionally provide approximate location fields:

``` r

foundry_web_search(
  "Find a recent AI research event near me.",
  model = "gpt-4.1",
  country = "US",
  region = "Washington",
  city = "Seattle",
  timezone = "America/Los_Angeles"
)
```

## Responsible use of web search

Microsoft documents that web search uses Grounding with Bing Search
and/or Grounding with Bing Custom Search. The Data Protection Addendum
does not apply to data sent to these services, data can leave compliance
and geographic boundaries, and tool usage can incur additional costs.
Avoid sending secrets or sensitive research data in web-search prompts.

## When to use `foundry_chat()` vs `foundry_response()`

Use
[`foundry_chat()`](https://farach.github.io/foundryR/reference/foundry_chat.md)
when you want the established chat-completions interface and simple
assistant replies.

Use
[`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
when you need newer v1 capabilities: stateful response IDs, built-in
tools, structured output formats, richer output items, or a
forward-looking API surface for new Microsoft Foundry model
capabilities.
