# Extract structured data from text using JSON Schema

Apply a JSON Schema to one or more text inputs and return
model-extracted fields as a tidy tibble. This is useful for research
coding tasks such as sentiment annotation, entity extraction, study
abstraction, and converting free-text records into analyzable variables.

## Usage

``` r
foundry_extract(
  text,
  schema,
  instructions = NULL,
  schema_name = "ExtractedData",
  strict = TRUE,
  model = NULL,
  flatten = TRUE,
  store = FALSE,
  api_key = NULL,
  endpoint = NULL,
  ...
)
```

## Arguments

- text:

  Character vector. Texts to extract from.

- schema:

  List. JSON Schema object describing the fields to extract.

- instructions:

  Character. Optional extraction instructions. If omitted, a concise
  default extraction instruction is used.

- schema_name:

  Character. Name for the JSON Schema format.

- strict:

  Logical. Whether the model must strictly follow the schema.

- model:

  Character. The model deployment name. Defaults to
  `AZURE_FOUNDRY_MODEL`.

- flatten:

  Logical. If `TRUE`, top-level schema fields are returned as tibble
  columns. Nested objects and arrays become list-columns. If `FALSE`,
  parsed data is returned in a `.data` list-column.

- store:

  Logical. Whether to store Responses API objects. Defaults to `FALSE`
  because bulk extraction often processes sensitive research data.

- api_key:

  Character. Optional API key override.

- endpoint:

  Character. Optional endpoint override.

- ...:

  Additional parameters passed to
  [`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md).

## Value

A tibble with one row per input text. Metadata columns are prefixed with
`.`, followed by extracted schema fields when `flatten = TRUE`.

## References

- Structured outputs:
  <https://learn.microsoft.com/azure/foundry/openai/how-to/structured-outputs>

## Examples

``` r
if (FALSE) { # \dontrun{
schema <- list(
  type = "object",
  properties = list(
    sentiment = list(type = "string", enum = c("positive", "negative", "neutral")),
    entities = list(type = "array", items = list(type = "string"))
  ),
  required = c("sentiment", "entities"),
  additionalProperties = FALSE
)

foundry_extract(
  c("I love using R with Azure.", "The workflow was slow and confusing."),
  schema = schema,
  model = "gpt-4.1"
)
} # }
```
