# Build a strict JSON Schema object

Create a strict object schema for structured outputs. All supplied
fields are required by default and additional properties are disabled by
default, matching the strict schema shape expected by Azure OpenAI
structured outputs.

## Usage

``` r
foundry_schema(
  ...,
  required = NULL,
  additional_properties = FALSE,
  description = NULL
)
```

## Arguments

- ...:

  Named schema fields, usually created with `schema_*()` helpers.

- required:

  Character vector of required field names. Defaults to all supplied
  fields.

- additional_properties:

  Logical. Whether properties outside `...` are allowed.

- description:

  Character. Optional schema description.

## Value

A JSON Schema represented as an R list.

## Examples

``` r
schema <- foundry_schema(
  sentiment = schema_enum(c("positive", "negative", "neutral")),
  score = schema_number()
)
```
