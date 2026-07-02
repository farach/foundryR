# Describe an agent tool call for task adherence

Build a single tool-call entry for the `tool_calls` argument of
[`foundry_agent_message()`](https://farach.github.io/foundryR/reference/foundry_agent_message.md).

## Usage

``` r
foundry_agent_tool_call(name, id, arguments = "")
```

## Arguments

- name:

  Character. The called function name.

- id:

  Character. The tool-call identifier, referenced later by a `Tool`
  message's `tool_call_id`.

- arguments:

  Character. The serialized call arguments. Default `""`.

## Value

A named list matching the task-adherence tool-call schema.

## Examples

``` r
foundry_agent_tool_call("get_credit_card_limit", id = "call_001")
#> $type
#> [1] "function"
#> 
#> $`function`
#> $`function`$name
#> [1] "get_credit_card_limit"
#> 
#> $`function`$arguments
#> [1] ""
#> 
#> 
#> $id
#> [1] "call_001"
#> 
```
