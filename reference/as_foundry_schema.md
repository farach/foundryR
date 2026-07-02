# Convert an object to a foundryR JSON Schema

`as_foundry_schema()` is a small validation/conversion helper. It
returns raw JSON Schema lists unchanged, so code can accept either
schemas built with foundryR constructors or hand-written JSON Schema
lists.

## Usage

``` r
as_foundry_schema(x)
```

## Arguments

- x:

  Object to convert.

## Value

A JSON Schema represented as an R list.
