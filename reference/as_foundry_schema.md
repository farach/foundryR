# Convert an object to a foundryR JSON Schema

`as_foundry_schema()` is a small validation/conversion helper. It
returns raw JSON Schema lists unchanged, so code can accept either
schemas built with foundryR constructors or hand-written JSON Schema
lists. If the ellmer package is installed,
[`ellmer::type_object()`](https://ellmer.tidyverse.org/reference/type_boolean.html)
specifications are converted to the equivalent strict JSON Schema, so
ellmer users can pass their existing type definitions to
[`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
and
[`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md).

## Usage

``` r
as_foundry_schema(x)
```

## Arguments

- x:

  Object to convert. Either a foundryR/JSON Schema list or an ellmer
  `type_object()` specification.

## Value

A JSON Schema represented as an R list.
