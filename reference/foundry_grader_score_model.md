# Score-model grader

Use a model to assign a numeric score to each row. Rows at or above
`pass_threshold` pass. Scores fall within `range`, which defaults to
`c(0, 1)`.

## Usage

``` r
foundry_grader_score_model(
  name,
  model,
  input,
  pass_threshold = NULL,
  range = NULL
)
```

## Arguments

- name:

  Character. Grader name.

- model:

  Character. Deployment name of the scoring model.

- input:

  List. A list of items from
  [`foundry_eval_item()`](https://farach.github.io/foundryR/reference/foundry_eval_item.md)
  (or a single item) forming the grading prompt.

- pass_threshold:

  Numeric. Optional score at or above which a row passes.

- range:

  Numeric vector of length 2. Optional score range. Defaults to
  `c(0, 1)` on the service when omitted.

## Value

A named list describing a `score_model` grader.

## Examples

``` r
foundry_grader_score_model(
  name = "helpfulness",
  model = "gpt-5.5",
  input = list(
    foundry_eval_item("Rate helpfulness 0-1: {{sample.output_text}}")
  ),
  pass_threshold = 0.7
)
#> $type
#> [1] "score_model"
#> 
#> $name
#> [1] "helpfulness"
#> 
#> $model
#> [1] "gpt-5.5"
#> 
#> $input
#> $input[[1]]
#> $input[[1]]$role
#> [1] "user"
#> 
#> $input[[1]]$content
#> [1] "Rate helpfulness 0-1: {{sample.output_text}}"
#> 
#> 
#> 
#> $pass_threshold
#> [1] 0.7
#> 
```
