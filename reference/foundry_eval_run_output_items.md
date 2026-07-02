# List evaluation run output items

Return the per-row grader results for a completed run. The result is
unnested to one row per grader outcome, so a row that was scored by
three graders yields three rows.

## Usage

``` r
foundry_eval_run_output_items(
  eval_id,
  run_id,
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

- run_id:

  Character. Run ID.

- status:

  Character. Optional status filter, `"fail"` or `"pass"`.

- order:

  Character. Optional sort order, `"asc"` or `"desc"`.

- limit:

  Integer. Optional maximum number of output items to return.

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

A tibble with one row per grader result, including `score`, `label`,
`passed`, and `reason` where the grader supplies them.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_eval_run_output_items("eval_abc123", "evalrun_xyz")
} # }
```
