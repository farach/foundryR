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
