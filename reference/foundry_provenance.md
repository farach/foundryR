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
