# Schema constructors for structured outputs

Build JSON Schema field definitions for use with
[`foundry_schema()`](https://farach.github.io/foundryR/reference/foundry_schema.md)
or raw schema lists passed to
[`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
and
[`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md).

## Usage

``` r
schema_string(description = NULL, enum = NULL)

schema_enum(values, description = NULL)

schema_number(description = NULL)

schema_integer(description = NULL)

schema_boolean(description = NULL)

schema_array(items, description = NULL, min_items = NULL, max_items = NULL)

schema_object(
  ...,
  required = NULL,
  additional_properties = FALSE,
  description = NULL
)
```

## Arguments

- description:

  Character. Optional field description.

- enum:

  Character vector of allowed values.

- values:

  Character vector of allowed values for `schema_enum()`.

- items:

  List. Item schema for `schema_array()`.

- min_items, max_items:

  Integer. Optional array length bounds.

- ...:

  Named child fields for `schema_object()`.

- required:

  Character vector of required child fields. Defaults to all supplied
  fields.

- additional_properties:

  Logical. Whether undeclared object properties are allowed.

## Value

A JSON Schema fragment represented as an R list.

## Examples

``` r
schema_string("Free-text label")
#> $type
#> [1] "string"
#> 
#> $description
#> [1] "Free-text label"
#> 
schema_enum(c("positive", "negative", "neutral"))
#> $type
#> [1] "string"
#> 
#> $enum
#> [1] "positive" "negative" "neutral" 
#> 
schema_object(
  sentiment = schema_enum(c("positive", "negative", "neutral")),
  confidence = schema_number()
)
#> $type
#> [1] "object"
#> 
#> $properties
#> $properties$sentiment
#> $properties$sentiment$type
#> [1] "string"
#> 
#> $properties$sentiment$enum
#> [1] "positive" "negative" "neutral" 
#> 
#> 
#> $properties$confidence
#> $properties$confidence$type
#> [1] "number"
#> 
#> 
#> 
#> $required
#> [1] "sentiment"  "confidence"
#> 
#> $additionalProperties
#> [1] FALSE
#> 
```
