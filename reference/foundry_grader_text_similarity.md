# Text-similarity grader

Grade output text against a reference using a similarity metric such as
fuzzy matching, BLEU, ROUGE, or METEOR. A row passes when its score is
at least `pass_threshold`.

## Usage

``` r
foundry_grader_text_similarity(
  input,
  reference,
  pass_threshold,
  evaluation_metric = c("fuzzy_match", "bleu", "gleu", "meteor", "rouge_1", "rouge_2",
    "rouge_3", "rouge_4", "rouge_5", "rouge_l"),
  name = NULL
)
```

## Arguments

- input:

  Character. Text being graded, typically `"{{sample.output_text}}"`.

- reference:

  Character. Reference text, typically `"{{item.answer}}"`.

- pass_threshold:

  Numeric. Score at or above which a row passes.

- evaluation_metric:

  Character. One of `"fuzzy_match"`, `"bleu"`, `"gleu"`, `"meteor"`,
  `"rouge_1"`, `"rouge_2"`, `"rouge_3"`, `"rouge_4"`, `"rouge_5"`, or
  `"rouge_l"`.

- name:

  Character. Optional grader name.

## Value

A named list describing a `text_similarity` grader.

## Examples

``` r
foundry_grader_text_similarity(
  input = "{{sample.output_text}}",
  reference = "{{item.answer}}",
  pass_threshold = 0.8,
  evaluation_metric = "fuzzy_match"
)
#> $type
#> [1] "text_similarity"
#> 
#> $input
#> [1] "{{sample.output_text}}"
#> 
#> $reference
#> [1] "{{item.answer}}"
#> 
#> $pass_threshold
#> [1] 0.8
#> 
#> $evaluation_metric
#> [1] "fuzzy_match"
#> 
```
