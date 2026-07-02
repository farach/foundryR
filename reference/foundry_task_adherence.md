# Check an agent transcript for task adherence

Evaluate whether an agent's tool calls and responses stayed aligned with
the user's request using the Azure AI Content Safety task-adherence
detector. This flags agents that take unrequested or unsafe actions.

## Usage

``` r
foundry_task_adherence(
  messages,
  tools = NULL,
  endpoint = NULL,
  api_key = NULL,
  api_version = "2025-09-15-preview"
)
```

## Arguments

- messages:

  List. The conversation turns to analyze. Build each turn with
  [`foundry_agent_message()`](https://farach.github.io/foundryR/reference/foundry_agent_message.md),
  or supply raw lists matching the Content Safety schema.

- tools:

  List. Optional tool definitions available to the agent. Build each
  with
  [`foundry_agent_tool()`](https://farach.github.io/foundryR/reference/foundry_agent_tool.md),
  or supply raw lists. Default `NULL`.

- endpoint:

  Character. Optional Content Safety endpoint.

- api_key:

  Character. Optional Content Safety key.

- api_version:

  Character. API version. Defaults to `"2025-09-15-preview"`.

## Value

A tibble with one row:

- task_risk_detected:

  Logical. `TRUE` when misaligned tool use was detected.

- details:

  Character. Explanation of the detected risk, or `NA` when none.

- raw_response:

  List. The parsed API response.

## Preview API

This operation is documented only in the Azure AI Content Safety Learn
quickstart and has no published OpenAPI specification. It requires the
`2025-09-15-preview` api-version and its contract may change.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_task_adherence(
  tools = list(
    foundry_agent_tool("get_credit_card_limit", "Get the user's credit limit")
  ),
  messages = list(
    foundry_agent_message("Prompt", "User", "What is my limit?"),
    foundry_agent_message(
      "Completion", "Assistant", "Checking now",
      tool_calls = list(
        foundry_agent_tool_call("get_credit_card_limit", id = "call_001")
      )
    )
  )
)
} # }
```
