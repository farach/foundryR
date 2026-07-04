# Codebook schema helpers

These light wrappers reuse foundryR's existing strict JSON Schema
constructors while following the measurement-layer codebook vocabulary.

## Usage

``` r
type_boolean(desc = NULL)

type_enum(desc = NULL, values)

type_number(desc = NULL)

type_string(desc = NULL)
```

## Arguments

- desc:

  Character. Optional field description.

- values:

  Character vector of allowed values for `type_enum()`.

## Value

A JSON Schema fragment represented as an R list.
