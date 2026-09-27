# Create an evaluation

Create an evaluation group that pairs a data-source configuration with
one or more graders (`testing_criteria`). Evaluations are run against
data with
[`foundry_eval_run_create()`](https://farach.github.io/foundryR/reference/foundry_eval_run_create.md).

## Usage

``` r
foundry_eval_create(
  name = NULL,
  data_source_config,
  testing_criteria,
  metadata = NULL,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = NULL,
  project_endpoint = NULL
)
```

## Arguments

- name:

  Character. Optional evaluation name.

- data_source_config:

  List. A configuration from
  [`foundry_eval_data_config()`](https://farach.github.io/foundryR/reference/foundry_eval_data_config.md).

- testing_criteria:

  List. A grader from `foundry_grader_*()`, or a list of graders.

- metadata:

  List. Optional metadata attached to the evaluation.

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

A one-row tibble describing the created evaluation.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a configured Azure endpoint and credentials with evals API access.
foundry_eval_create(
  name = "qa-accuracy",
  data_source_config = foundry_eval_data_config(
    type = "custom",
    item_schema = list(
      type = "object",
      properties = list(answer = list(type = "string")),
      required = list("answer")
    ),
    include_sample_schema = TRUE
  ),
  testing_criteria = foundry_grader_string_check(
    name = "exact",
    input = "{{sample.output_text}}",
    reference = "{{item.answer}}",
    operation = "eq"
  )
)
} # }
```
