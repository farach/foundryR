# Collect evaluation results joined to the evaluated rows

**\[experimental\]**

Retrieve every output item of a completed run and join the grader
results to the data frame that was evaluated with
[`foundry_evaluate()`](https://farach.github.io/foundryR/reference/foundry_evaluate.md).
Rows are matched only through the `foundryr_row_id` field that
[`foundry_evaluate()`](https://farach.github.io/foundryR/reference/foundry_evaluate.md)
adds to each item, and the echoed item fields are checked against
`data`, so passing a reordered or different data frame is an error
rather than a silent mismatch.

## Usage

``` r
foundry_eval_run_results(
  eval_id,
  run_id,
  data,
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

- data:

  The data frame passed to
  [`foundry_evaluate()`](https://farach.github.io/foundryR/reference/foundry_evaluate.md),
  in the same row order.

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

A tibble with one row per row of `data` and grader, in the row order of
`data`. It contains every column of `data` followed by:

- .eval_id, .run_id, .output_item_id:

  Evaluation, run, and output item identifiers.

- .status:

  Output item status reported by the service.

- .grader, .grader_type, .metric:

  Grader name, type, and metric. `.grader` is the name you gave the
  grader; the resource endpoint's appended ID is removed.

- .score, .label, .passed, .threshold, .reason:

  Grader result. Not every grader reports every field. For `label_model`
  and `score_model` graders, `.label` is the judge's chosen label and
  `.reason` joins the conclusions of the judge's reasoning steps.

- .output_text, .output_items:

  The generated response for target runs: plain text and the structured
  output (a list-column).

Rows of `data` without an output item are kept with missing result
fields, with a warning. The final run tibble, including per-criterion
pass rates, target latency, and estimated target cost, is attached as
the `"run"` attribute.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a configured Foundry endpoint and credentials, plus a completed
# run started by foundry_evaluate(tickets, ..., wait = FALSE).
foundry_eval_run_results("eval_abc123", "evalrun_xyz", data = tickets)
} # }
```
