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
  api_version = NULL
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

  Character. Optional endpoint override.

- api_version:

  Character. Optional `api-version` query value. The Foundry v1 evals
  surface is path-versioned, so this is usually left `NULL`.

## Value

A one-row tibble describing the created evaluation.

## Examples

``` r
if (FALSE) { # \dontrun{
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
