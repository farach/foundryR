# Define an R function as a Responses API tool

Create a tool definition for
[`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
or
[`foundry_agent()`](https://farach.github.io/foundryR/reference/foundry_agent.md).
The request sent to Azure uses the Responses API function-tool contract,
while the returned object also keeps the R function needed for local
dispatch.

## Usage

``` r
foundry_tool(fun, name = NULL, description, parameters)
```

## Arguments

- fun:

  Function. The R function to run when the model calls the tool.

- name:

  Character. Tool name exposed to the model. If omitted and `fun` is a
  named function object, the object name is used.

- description:

  Character. Short description of what the tool does.

- parameters:

  List. JSON Schema object describing function arguments.

## Value

A `foundry_tool` object. It is a list containing the JSON tool schema
and the R function used by
[`foundry_agent()`](https://farach.github.io/foundryR/reference/foundry_agent.md).

## Examples

``` r
get_weather <- function(location) {
  list(location = location, temperature = "70 F")
}

weather_tool <- foundry_tool(
  get_weather,
  description = "Get weather for a location",
  parameters = list(
    type = "object",
    properties = list(location = list(type = "string")),
    required = "location"
  )
)
```
