# Cancel an evaluation run

Cancel an evaluation run

## Usage

``` r
foundry_eval_run_cancel(
  eval_id,
  run_id,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = NULL
)
```

## Arguments

- eval_id:

  Character. Evaluation ID.

- run_id:

  Character. Run ID to cancel.

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

A one-row tibble describing the run after cancellation.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_eval_run_cancel("eval_abc123", "evalrun_xyz")
} # }
```
