# Create an evaluation run

Run an evaluation against a data source. The eval's `testing_criteria`
are applied to every row in the source.

## Usage

``` r
foundry_eval_run_create(
  eval_id,
  data_source,
  name = NULL,
  metadata = NULL,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = NULL,
  project_endpoint = NULL
)
```

## Arguments

- eval_id:

  Character. Evaluation ID to run.

- data_source:

  List. A run data source from
  [`foundry_eval_run_data()`](https://farach.github.io/foundryR/reference/foundry_eval_run_data.md).

- name:

  Character. Optional run name. Target and stored-response runs need a
  name, so one is generated from the current UTC time when `NULL`.

- metadata:

  List. Optional metadata attached to the run.

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

A one-row tibble describing the created run.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a configured Azure endpoint and credentials, an evaluation ID,
# and an uploaded JSONL file matching its data-source configuration.
foundry_eval_run_create(
  eval_id = "eval_abc123",
  data_source = foundry_eval_run_data(file_id = "file-xyz"),
  name = "nightly"
)
} # }
```
