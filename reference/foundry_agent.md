# Run a bounded Responses API tool-calling loop

`foundry_agent()` sends a prompt to the Responses API with user-defined
R tools, executes any returned function calls locally, sends matching
`function_call_output` items back to the service, and repeats until the
model returns a final answer or `max_iterations` is reached.

## Usage

``` r
foundry_agent(
  input,
  tools,
  model = NULL,
  instructions = NULL,
  max_iterations = 8L,
  store = TRUE,
  reasoning_effort = NULL,
  max_output_tokens = NULL,
  temperature = NULL,
  top_p = NULL,
  api_key = NULL,
  endpoint = NULL,
  ...
)
```

## Arguments

- input:

  Character scalar or list. Initial user input for the response.

- tools:

  A
  [`foundry_tool()`](https://farach.github.io/foundryR/reference/foundry_tool.md)
  object or list of `foundry_tool` objects.

- model:

  Character. The model deployment name. Defaults to the
  `AZURE_FOUNDRY_MODEL` environment variable.

- instructions:

  Character. Optional system/developer instructions.

- max_iterations:

  Integer. Maximum number of model responses in the loop.

- store:

  Logical. Whether Responses API objects should be stored. Defaults to
  `TRUE` because the loop uses `previous_response_id`.

- reasoning_effort:

  Character. Optional reasoning effort for reasoning models.

- max_output_tokens, temperature, top_p:

  Optional generation controls passed to
  [`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md).

- api_key:

  Character. Optional API key override.

- endpoint:

  Character. Optional endpoint override.

- ...:

  Additional request body parameters passed to
  [`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md).

## Value

A tibble with one row per model response. It includes the standard
[`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
columns plus `iteration`, `final`, and `tool_results` list-columns for
executed R tools.

## References

- Responses API function calling:
  <https://learn.microsoft.com/azure/foundry/openai/how-to/responses#function-calling>

## Examples

``` r
if (FALSE) { # \dontrun{
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

foundry_agent(
  "What is the weather in San Francisco?",
  tools = list(weather_tool),
  model = "gpt-5.5"
)
} # }
```
