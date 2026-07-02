# Describe an agent tool for task adherence

Build a single tool definition for the `tools` argument of
[`foundry_task_adherence()`](https://farach.github.io/foundryR/reference/foundry_task_adherence.md).

## Usage

``` r
foundry_agent_tool(name, description)
```

## Arguments

- name:

  Character. The tool (function) name.

- description:

  Character. What the tool does.

## Value

A named list matching the task-adherence tool schema.

## Examples

``` r
foundry_agent_tool("order_car", "Buy a particular car model")
#> $type
#> [1] "function"
#> 
#> $`function`
#> $`function`$name
#> [1] "order_car"
#> 
#> $`function`$description
#> [1] "Buy a particular car model"
#> 
#> 
```
