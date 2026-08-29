# Capture model and schema provenance

Create a one-row tibble that records the model, schema hash, package
version, and timestamp for a reproducible annotation run.

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
#> 1 gpt-5-nano b633f54253aaf4d37… 0.1.0           2026-08-29 14:44:40 <named list>
```
