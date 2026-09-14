# Measure repeated-extraction consistency

Run the same extraction multiple times and summarize how often each
input receives the same structured result. Use batch execution
externally for large jobs; this helper intentionally keeps the local
loop simple.

## Usage

``` r
foundry_consistency(text, schema, n = 3L, ...)
```

## Arguments

- text:

  Character vector of inputs.

- schema:

  List. JSON Schema object.

- n:

  Integer. Number of repeated extractions.

- ...:

  Additional arguments passed to
  [`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md).

## Value

A tibble with one row per input.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a configured Azure endpoint, credentials, and AZURE_FOUNDRY_MODEL
# naming a deployment that supports structured outputs.
schema <- foundry_schema(label = schema_enum(c("yes", "no")))
foundry_consistency(c("Example text"), schema, n = 3)
} # }
```
