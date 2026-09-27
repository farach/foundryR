# List evaluation run output items

Return the per-row grader results for a completed run. The result is
unnested to one row per grader outcome, so a row that was scored by
three graders yields three rows. The service returns output items in
pages; this function follows the pagination cursor, so by default every
output item is returned.

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
  api_version = NULL,
  project_endpoint = NULL
)
```

## Arguments

- eval_id:

  Character. Evaluation ID.

- run_id:

  Character. Run ID.

- status:

  Character. Optional output-item processing status passed to the
  service, for example `"completed"` or `"failed"`. It reports whether
  the item was processed, not whether it passed; the service rejects
  `"fail"` and `"pass"`. To find failing grades, filter the returned
  `passed` column.

- order:

  Character. Optional sort order, `"asc"` or `"desc"`.

- limit:

  Integer. Optional maximum number of output items to return. `NULL`
  (the default) returns all output items.

- after:

  Character. Optional output item ID to start after.

- api_key:

  Character. Optional API key. Falls back to configured auth.

- token:

  Character. Optional bearer token. Falls back to configured auth.

- endpoint:

  Character. Optional resource endpoint. Supplying it selects the
  resource-scoped Evals route (`<resource>/openai/v1/evals`). Supply at
  most one of `endpoint` and `project_endpoint`.

- api_version:

  Character. Optional `api-version` query value. The Foundry v1 evals
  surface is path-versioned, so this is usually left `NULL`.

- project_endpoint:

  Character. Optional Microsoft Foundry project endpoint, such as
  `"https://<account>.services.ai.azure.com/api/projects/<project>"`.
  Supplying it selects the project-scoped Evals route
  (`<project>/openai/v1/evals`), which needs a Microsoft Entra ID token:
  the service answers HTTP 403 to API keys there. Without it, evaluation
  calls use the resource endpoint, as in foundryR 0.1.0, unless
  [`foundry_set_route()`](https://farach.github.io/foundryR/reference/foundry_set_route.md)
  selected the project or the call needs a feature that exists only on a
  project endpoint: built-in `azure_ai_evaluator` graders, model or
  agent targets, or stored responses. Those calls use the endpoint set
  with
  [`foundry_set_project_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_project_endpoint.md)
  and print a message. Evaluations created on the project endpoint are
  not visible from the resource endpoint, so pass `project_endpoint` (or
  set the route) when you look them up later.

## Value

A tibble with one row per grader result, including `score`, `label`,
`passed`, and `reason` where the grader supplies them.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a configured Azure endpoint and credentials, an evaluation ID,
# and a completed run ID.
foundry_eval_run_output_items("eval_abc123", "evalrun_xyz")
} # }
```
