# Capture model and schema provenance

Create a one-row tibble that records the model, schema hash, package
version, and UTC timestamp for a reproducible annotation run. The schema
hash is a SHA-256 digest of the same canonical JSON serialization used
by
[`foundry_codebook()`](https://farach.github.io/foundryR/reference/foundry_codebook.md).

## Usage

``` r
foundry_provenance(model, schema, metadata = NULL)
```

## Arguments

- model:

  Character. Model or deployment name.

- schema:

  List. JSON Schema object.

- metadata:

  List. Optional additional metadata.

## Value

A one-row tibble.

## Examples

``` r
schema <- foundry_schema(label = schema_string())
foundry_provenance(
  model = "gpt-5-nano",
  schema = schema,
  metadata = list(run = "pilot")
)
#> # A tibble: 1 × 5
#>   model      schema_hash        package_version captured_at         metadata    
#>   <chr>      <chr>              <chr>           <dttm>              <list>      
#> 1 gpt-5-nano 931e4a749545c6ad5… 1.0.0.9000      2026-10-01 18:52:06 <named list>
```
