# Label-model grader

Use a model to assign one of a fixed set of labels to each row, then
treat a subset of those labels as passing. The model must support
structured outputs.

## Usage

``` r
foundry_grader_label_model(name, model, input, labels, passing_labels)
```

## Arguments

- name:

  Character. Grader name.

- model:

  Character. Deployment name of a model that supports structured
  outputs.

- input:

  List. A list of items from
  [`foundry_eval_item()`](https://farach.github.io/foundryR/reference/foundry_eval_item.md)
  (or a single item), forming the grading prompt.

- labels:

  Character vector. The complete set of labels the model may assign.

- passing_labels:

  Character vector. The labels that count as a pass. Must be a subset of
  `labels`.

## Value

A named list describing a `label_model` grader.

## Examples

``` r
foundry_grader_label_model(
  name = "relevance-label",
  model = "gpt-5-nano",
  input = list(
    foundry_eval_item("Is the answer relevant? {{sample.output_text}}")
  ),
  labels = c("relevant", "irrelevant"),
  passing_labels = "relevant"
)
#> $type
#> [1] "label_model"
#> 
#> $name
#> [1] "relevance-label"
#> 
#> $model
#> [1] "gpt-5-nano"
#> 
#> $input
#> $input[[1]]
#> $input[[1]]$role
#> [1] "user"
#> 
#> $input[[1]]$content
#> [1] "Is the answer relevant? {{sample.output_text}}"
#> 
#> 
#> 
#> $labels
#> $labels[[1]]
#> [1] "relevant"
#> 
#> $labels[[2]]
#> [1] "irrelevant"
#> 
#> 
#> $passing_labels
#> $passing_labels[[1]]
#> [1] "relevant"
#> 
#> 
```
