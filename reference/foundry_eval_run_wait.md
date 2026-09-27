# Wait for an evaluation run to finish

**\[experimental\]**

Poll an evaluation run until it reaches a terminal state (`"completed"`,
`"failed"`, or `"canceled"`).

## Usage

``` r
foundry_eval_run_wait(
  eval_id,
  run_id,
  interval = 10,
  timeout = Inf,
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

- interval:

  Numeric. Seconds between status checks.

- timeout:

  Numeric. Maximum seconds to wait. Use `Inf` to wait indefinitely. On
  timeout the run keeps going on the service.

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

The final one-row run tibble from
[`foundry_eval_run_get()`](https://farach.github.io/foundryR/reference/foundry_eval_run_get.md).
Check its `status` column: failed and canceled runs are returned, not
raised.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a configured Foundry endpoint and credentials, plus an evaluation
# run. Polling may take several minutes.
foundry_eval_run_wait("eval_abc123", "evalrun_xyz", interval = 15)
} # }
```
