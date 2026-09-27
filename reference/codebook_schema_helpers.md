# Codebook schema helpers

**\[deprecated\]**

`type_boolean()`, `type_enum()`, `type_number()`, and `type_string()`
are deprecated because they mask ellmer's functions of the same names
when both packages are attached. Use
[`schema_boolean()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
[`schema_enum()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
[`schema_number()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
and
[`schema_string()`](https://farach.github.io/foundryR/reference/schema_constructors.md)
instead; they take the description as `description`. If you already
describe fields with `ellmer::type_*()`, pass the ellmer type object to
[`as_foundry_schema()`](https://farach.github.io/foundryR/reference/as_foundry_schema.md).

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
# Use the schema_*() helpers instead:
schema_boolean(description = "Whether AI could materially assist the task")
#> $type
#> [1] "boolean"
#> 
#> $description
#> [1] "Whether AI could materially assist the task"
#> 
schema_enum(c("low", "medium", "high"), description = "Priority label")
#> $type
#> [1] "string"
#> 
#> $description
#> [1] "Priority label"
#> 
#> $enum
#> [1] "low"    "medium" "high"  
#> 
```
