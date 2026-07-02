# Delete an evaluation

Delete an evaluation

## Usage

``` r
foundry_eval_delete(
  eval_id,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = NULL
)
```

## Arguments

- eval_id:

  Character. Evaluation ID to delete.

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

A one-row tibble with `eval_id`, `deleted`, and `object`.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_eval_delete("eval_abc123")
} # }
```
