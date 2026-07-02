# List evaluations

List evaluations

## Usage

``` r
foundry_evals(
  limit = NULL,
  after = NULL,
  order = NULL,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = NULL
)
```

## Arguments

- limit:

  Integer. Optional maximum number of evaluations to return.

- after:

  Character. Optional pagination cursor.

- order:

  Character. Optional sort order, `"asc"` or `"desc"`.

- api_key:

  Character. Optional API key. Falls back to configured auth.

- token:

  Character. Optional bearer token. Falls back to configured auth.

- endpoint:

  Character. Optional endpoint override.

- api_version:

  Character. Optional `api-version` query value. The Foundry v1 evals
  surface is path-versioned, so this is usually left `NULL`.

## Value

A tibble with one row per evaluation.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_evals(limit = 10)
} # }
```
