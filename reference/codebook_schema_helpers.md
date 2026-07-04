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

## Examples

``` r
type_boolean("Whether AI could materially assist the task")
#> $type
#> [1] "boolean"
#> 
#> $description
#> [1] "Whether AI could materially assist the task"
#> 
type_enum("Priority label", values = c("low", "medium", "high"))
#> $type
#> [1] "string"
#> 
#> $description
#> [1] "Priority label"
#> 
#> $enum
#> [1] "low"    "medium" "high"  
#> 
type_number("Confidence score")
#> $type
#> [1] "number"
#> 
#> $description
#> [1] "Confidence score"
#> 
type_string("Short rationale")
#> $type
#> [1] "string"
#> 
#> $description
#> [1] "Short rationale"
#> 
```
