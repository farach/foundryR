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

## Details

The comparison covers the whole structured record after canonical JSON
serialization: object names are sorted recursively, arrays keep their
order, and numbers are serialized with `digits = NA`. Only successful
runs count toward `modal_share` and entropy; failed runs are reported
separately. With `n` runs, `modal_share` can only take values `k / n`.
Entropy is the plug-in estimate in bits, has maximum `log2(n)`, and is
biased low for small `n`. Sampling settings passed through `...` define
what a repeat means. Stability is not accuracy: a model can be
consistently wrong.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a configured Azure endpoint, credentials, and AZURE_FOUNDRY_MODEL
# naming a deployment that supports structured outputs.
schema <- foundry_schema(label = schema_enum(c("yes", "no")))
foundry_consistency(c("Example text"), schema, n = 3)
} # }
```
