# String-check grader

Compare a templated input string against a reference string with an
exact or pattern operation. Useful for deterministic pass/fail checks
such as verifying an extracted field matches a known value.

## Usage

``` r
foundry_grader_string_check(
  name,
  input,
  reference,
  operation = c("eq", "ne", "like", "ilike")
)
```

## Arguments

- name:

  Character. Grader name shown in results.

- input:

  Character. Input text, typically a template such as
  `"{{sample.output_text}}"`.

- reference:

  Character. Reference text, typically a template such as
  `"{{item.expected}}"`.

- operation:

  Character. One of `"eq"`, `"ne"`, `"like"`, or `"ilike"`.

## Value

A named list describing a `string_check` grader, for use in the
`testing_criteria` of
[`foundry_eval_create()`](https://farach.github.io/foundryR/reference/foundry_eval_create.md).

## Examples

``` r
foundry_grader_string_check(
  name = "exact-match",
  input = "{{sample.output_text}}",
  reference = "{{item.answer}}",
  operation = "eq"
)
#> $type
#> [1] "string_check"
#> 
#> $name
#> [1] "exact-match"
#> 
#> $input
#> [1] "{{sample.output_text}}"
#> 
#> $reference
#> [1] "{{item.answer}}"
#> 
#> $operation
#> [1] "eq"
#> 
```
