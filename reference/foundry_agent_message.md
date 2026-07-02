# Describe an agent message for task adherence

Build a single conversation turn for the `messages` argument of
[`foundry_task_adherence()`](https://farach.github.io/foundryR/reference/foundry_task_adherence.md).

## Usage

``` r
foundry_agent_message(
  source,
  role,
  contents = NULL,
  tool_calls = NULL,
  tool_call_id = NULL
)
```

## Arguments

- source:

  Character. `"Prompt"` for the original user request or `"Completion"`
  for anything the agent produced.

- role:

  Character. `"User"`, `"Assistant"`, or `"Tool"`.

- contents:

  Character. Optional message text.

- tool_calls:

  List. Optional tool calls issued by an assistant turn. Build each with
  [`foundry_agent_tool_call()`](https://farach.github.io/foundryR/reference/foundry_agent_tool_call.md).

- tool_call_id:

  Character. Optional identifier tying a `Tool` turn back to the tool
  call it answers.

## Value

A named list matching the task-adherence message schema.

## Examples

``` r
foundry_agent_message("Prompt", "User", "How many can I buy?")
#> $source
#> [1] "Prompt"
#> 
#> $role
#> [1] "User"
#> 
#> $contents
#> [1] "How many can I buy?"
#> 
```
