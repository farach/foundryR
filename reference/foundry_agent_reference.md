# Reference a Foundry agent from the Responses API

Build the `agent_reference` object used to run a stored Azure AI Foundry
agent through
[`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md).
Pass the resulting object (or simply the agent name) to the `agent`
argument of
[`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md).

## Usage

``` r
foundry_agent_reference(name, version = NULL)
```

## Arguments

- name:

  Character. The agent name.

- version:

  Character. Optional version identifier. Omit to use the latest
  version.

## Value

A named list describing an `agent_reference`.

## Examples

``` r
foundry_agent_reference("my-agent")
#> $type
#> [1] "agent_reference"
#> 
#> $name
#> [1] "my-agent"
#> 
foundry_agent_reference("my-agent", version = "2")
#> $type
#> [1] "agent_reference"
#> 
#> $name
#> [1] "my-agent"
#> 
#> $version
#> [1] "2"
#> 
```
