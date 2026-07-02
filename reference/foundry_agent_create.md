# Create a Foundry agent

Create a named, versioned prompt agent on the project-scoped Agent
Service. The agent bundles a model, system instructions, and optional
tools so it can later be run by name through
[`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md).

## Usage

``` r
foundry_agent_create(
  name,
  model = NULL,
  instructions = NULL,
  description = NULL,
  metadata = NULL,
  temperature = NULL,
  top_p = NULL,
  tools = NULL,
  tool_choice = NULL,
  definition = NULL,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = "v1"
)
```

## Arguments

- name:

  Character. Agent name. Up to 63 characters, alphanumeric and hyphens,
  unique within the project.

- model:

  Character. Model deployment name. Required unless `definition` is
  supplied.

- instructions:

  Character. Optional system prompt.

- description:

  Character. Optional human-readable description.

- metadata:

  Named list. Optional key-value metadata (up to 16 pairs).

- temperature:

  Numeric. Optional sampling temperature in `[0, 2]`.

- top_p:

  Numeric. Optional nucleus-sampling value in `[0, 1]`.

- tools:

  List. Optional tools:
  [`foundry_tool()`](https://farach.github.io/foundryR/reference/foundry_tool.md)
  objects or raw tool definition lists.

- tool_choice:

  Character or list. Optional tool-choice control.

- definition:

  List. Optional full agent definition. When supplied, the individual
  `model`/`instructions`/`tools` arguments are ignored and this list is
  sent as-is (must include `kind`).

- api_key:

  Character. Optional API key. Falls back to configured auth.

- token:

  Character. Optional bearer token. Falls back to configured auth.

- endpoint:

  Character. Optional project endpoint override.

- api_version:

  Character. API version query value. Defaults to `"v1"`.

## Value

A one-row tibble describing the created agent.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_agent_create(
  name = "france-facts",
  model = "gpt-4.1-mini",
  instructions = "You answer questions about France concisely."
)
} # }
```
