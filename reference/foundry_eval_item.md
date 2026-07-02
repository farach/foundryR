# Build an evaluation item for model-based graders

Model-based graders
([`foundry_grader_label_model()`](https://farach.github.io/foundryR/reference/foundry_grader_label_model.md)
and
[`foundry_grader_score_model()`](https://farach.github.io/foundryR/reference/foundry_grader_score_model.md))
accept an `input` list of message-shaped items. Each item has a `role`
and `content`, and the content may embed template references such as
`{{item.question}}` or `{{sample.output_text}}` that Azure resolves per
row at evaluation time.

## Usage

``` r
foundry_eval_item(
  content,
  role = c("user", "assistant", "system", "developer")
)
```

## Arguments

- content:

  Character. The message content. May contain `{{...}}` template
  references.

- role:

  Character. One of `"user"`, `"assistant"`, `"system"`, or
  `"developer"`. Defaults to `"user"`.

## Value

A named list with `role` and `content`, ready to place in a grader
`input` list.

## Examples

``` r
foundry_eval_item("Grade this answer: {{sample.output_text}}", role = "user")
#> $role
#> [1] "user"
#> 
#> $content
#> [1] "Grade this answer: {{sample.output_text}}"
#> 
```
