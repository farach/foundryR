# Create a response with the Azure OpenAI Responses API

Use Microsoft Foundry's newer `/openai/v1/responses` API to generate
model responses, chain stateful turns with `previous_response_id`, call
built-in tools such as web search, and request schema-constrained
structured output.

## Usage

``` r
foundry_response(
  input,
  model = NULL,
  instructions = NULL,
  previous_response_id = NULL,
  tools = NULL,
  text_format = NULL,
  max_output_tokens = NULL,
  temperature = NULL,
  top_p = NULL,
  reasoning_effort = NULL,
  reasoning_summary = NULL,
  store = NULL,
  background = NULL,
  conversation = NULL,
  prompt_cache_key = NULL,
  prompt_cache_retention = NULL,
  parallel_tool_calls = NULL,
  max_tool_calls = NULL,
  safety_identifier = NULL,
  metadata = NULL,
  include = NULL,
  parse_json = !is.null(text_format),
  api_key = NULL,
  endpoint = NULL,
  ...
)
```

## Arguments

- input:

  Character scalar or list. The user input for the response. A character
  scalar is sent directly. A list can contain Responses API input items
  for advanced use cases.

- model:

  Character. The model deployment name. Defaults to the
  `AZURE_FOUNDRY_MODEL` environment variable.

- instructions:

  Character. Optional system/developer instructions.

- previous_response_id:

  Character. Optional response ID to continue a stored conversation.

- tools:

  List. Optional Responses API tools, for example
  `list(list(type = "web_search"))` or a list of
  [`foundry_tool()`](https://farach.github.io/foundryR/reference/foundry_tool.md)
  objects.

- text_format:

  List. Optional Responses API text format object. Use
  `list(type = "json_object")` for JSON mode or
  `list(type = "json_schema", name = ..., schema = ..., strict = TRUE)`
  for structured outputs.

- max_output_tokens:

  Integer. Optional maximum generated output tokens.

- temperature:

  Numeric. Optional sampling temperature. Do not use with reasoning-only
  models that reject sampling parameters.

- top_p:

  Numeric. Optional nucleus sampling parameter. Do not use with
  reasoning-only models that reject sampling parameters.

- reasoning_effort:

  Character. Optional reasoning effort (`"low"`, `"medium"`, `"high"`,
  or a newer value supported by your model). Sent as
  `reasoning = list(effort = ...)`.

- reasoning_summary:

  Character. Optional reasoning summary mode for models that support it.

- store:

  Logical or NULL. Whether the service should store the response. The
  API stores responses by default when this is omitted. Set `FALSE` for
  stateless calls; use `TRUE` or omit it when chaining with
  `previous_response_id`.

- background:

  Logical. Whether to run the response in the background.

- conversation:

  Character. Optional conversation ID for server-side conversation
  state.

- prompt_cache_key, prompt_cache_retention:

  Optional prompt-cache controls.

- parallel_tool_calls:

  Logical. Whether the service may call tools in parallel.

- max_tool_calls:

  Integer. Optional maximum number of tool calls.

- safety_identifier:

  Character. Optional stable end-user identifier for safety monitoring.

- metadata:

  List. Optional metadata to attach to the response.

- include:

  Character vector. Optional additional response fields to include.

- parse_json:

  Logical. Whether to parse `output_text` as JSON into the `structured`
  list-column. Defaults to `TRUE` when `text_format` is supplied.

- api_key:

  Character. Optional API key override.

- endpoint:

  Character. Optional endpoint override.

- ...:

  Additional request body parameters passed to the Responses API.

## Value

A one-row tibble with response metadata, generated text, parsed
structured output (if requested), citations, tool calls, token usage,
and the raw response as a list-column.

## Details

The Responses API uses the v1 endpoint style:
`https://<resource>.openai.azure.com/openai/v1/responses`. Unlike the
older chat-completions API, the model deployment is supplied in the JSON
body as `model`.

**Stored responses and privacy:** Microsoft Foundry stores Responses API
objects by default. Set `store = FALSE` for stateless calls when you do
not need server-side conversation state. To use `previous_response_id`
chaining, the previous response must have been stored.

## References

- Azure OpenAI Responses API:
  <https://learn.microsoft.com/azure/foundry/openai/how-to/responses>

- Azure OpenAI REST API reference:
  <https://learn.microsoft.com/azure/foundry/openai/reference>

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_response("Summarize retrieval-augmented generation.", model = "gpt-4.1")

first <- foundry_response("Define catastrophic forgetting.", model = "gpt-4.1")
foundry_response(
  "Explain it for a college freshman.",
  model = "gpt-4.1",
  previous_response_id = first$response_id
)
} # }
```
