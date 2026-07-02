# Detect protected material in code

Check source code for matches against public code repositories using the
Azure AI Content Safety protected-material-for-code detector. This is
the code counterpart to
[`foundry_protected_material()`](https://farach.github.io/foundryR/reference/foundry_protected_material.md),
useful for flagging LLM-generated code that reproduces licensed
material.

## Usage

``` r
foundry_protected_code(
  code,
  endpoint = NULL,
  api_key = NULL,
  api_version = "2024-09-15-preview"
)
```

## Arguments

- code:

  Character vector. One or more code snippets to check.

- endpoint:

  Character. Optional Content Safety endpoint. Defaults to the
  `AZURE_CONTENT_SAFETY_ENDPOINT` environment variable.

- api_key:

  Character. Optional Content Safety key. Defaults to the
  `AZURE_CONTENT_SAFETY_KEY` environment variable.

- api_version:

  Character. API version. Defaults to `"2024-09-15-preview"`.

## Value

A tibble with one row per input snippet:

- code:

  Character. The input snippet.

- detected:

  Logical. `TRUE` when protected material was detected.

- citations:

  List. A tibble of `license` and `source_urls` for each matched code
  citation.

- raw_response:

  List. The parsed API response.

## Preview API

This operation is documented only in the Azure AI Content Safety Learn
quickstarts and has no published OpenAPI specification. It requires the
`2024-09-15-preview` api-version and its contract may change.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_protected_code("import pygame\npygame.init()")
} # }
```
