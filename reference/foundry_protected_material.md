# Detect protected material in text

Call the Azure AI Content Safety protected-material detector.

## Usage

``` r
foundry_protected_material(
  text,
  endpoint = NULL,
  api_key = NULL,
  api_version = "2024-09-01"
)
```

## Arguments

- text:

  Character vector.

- endpoint:

  Character. Optional Content Safety endpoint.

- api_key:

  Character. Optional Content Safety key.

- api_version:

  Character. API version. Defaults to `"2024-09-01"`.

## Value

A tibble with one row per input text.
