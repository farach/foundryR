# Azure AI built-in evaluator grader

Reference an Azure AI Foundry built-in evaluator (a `builtin.*` ID such
as `builtin.coherence` or `builtin.groundedness`) as a grader. This
grader type is only available on the project-scoped Foundry endpoint.

## Usage

``` r
foundry_grader_azure_ai(
  name,
  evaluator_name,
  initialization_parameters = NULL,
  data_mapping = NULL,
  evaluator_version = NULL
)
```

## Arguments

- name:

  Character. Grader name shown in results.

- evaluator_name:

  Character. The evaluator ID, e.g. `"builtin.coherence"`.

- initialization_parameters:

  List. Optional parameters passed to the evaluator, e.g.
  `list(model = "gpt-4.1-mini")` for model-graded evaluators.

- data_mapping:

  Named list. Optional mapping from evaluator inputs to dataset
  templates, e.g.
  `list(query = "{{item.query}}", response = "{{sample.output_text}}")`.

- evaluator_version:

  Character. Optional evaluator version. Defaults to the latest version
  on the service when omitted.

## Value

A named list describing an `azure_ai_evaluator` grader.

## Examples

``` r
foundry_grader_azure_ai(
  name = "coherence",
  evaluator_name = "builtin.coherence",
  initialization_parameters = list(model = "gpt-4.1-mini"),
  data_mapping = list(
    query = "{{item.query}}",
    response = "{{sample.output_text}}"
  )
)
#> $type
#> [1] "azure_ai_evaluator"
#> 
#> $name
#> [1] "coherence"
#> 
#> $evaluator_name
#> [1] "builtin.coherence"
#> 
#> $initialization_parameters
#> $initialization_parameters$model
#> [1] "gpt-4.1-mini"
#> 
#> 
#> $data_mapping
#> $data_mapping$query
#> [1] "{{item.query}}"
#> 
#> $data_mapping$response
#> [1] "{{sample.output_text}}"
#> 
#> 
```
