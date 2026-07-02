# List evaluation runs

List evaluation runs

## Usage

``` r
foundry_eval_runs(
  eval_id,
  status = NULL,
  order = NULL,
  limit = NULL,
  after = NULL,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = NULL
)
```

## Arguments

- eval_id:

  Character. Evaluation ID.

- status:

  Character. Optional status filter, one of `"queued"`, `"in_progress"`,
  `"failed"`, `"completed"`, or `"canceled"`.

- order:

  Character. Optional sort order, `"asc"` or `"desc"`.

- limit:

  Integer. Optional maximum number of runs to return.

- after:

  Character. Optional pagination cursor.

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

A tibble with one row per run.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_eval_runs("eval_abc123", status = "completed")
} # }
```
