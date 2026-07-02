# Define an evaluation run data source

Point an evaluation run at its rows: either an uploaded JSONL file (via
`file_id`) or inline `content`. Exactly one of `file_id` or `content`
must be supplied.

## Usage

``` r
foundry_eval_run_data(file_id = NULL, content = NULL)
```

## Arguments

- file_id:

  Character. ID of a JSONL file uploaded with
  [`foundry_file_upload()`](https://farach.github.io/foundryR/reference/foundry_file_upload.md).

- content:

  List. Inline rows, each a list with an `item` element (and an optional
  `sample` element).

## Value

A named list describing a `jsonl` run data source, for use in
[`foundry_eval_run_create()`](https://farach.github.io/foundryR/reference/foundry_eval_run_create.md).

## Examples

``` r
foundry_eval_run_data(file_id = "file-abc123")
#> $type
#> [1] "jsonl"
#> 
#> $source
#> $source$type
#> [1] "file_id"
#> 
#> $source$id
#> [1] "file-abc123"
#> 
#> 

foundry_eval_run_data(content = list(
  list(item = list(question = "2+2?", answer = "4"))
))
#> $type
#> [1] "jsonl"
#> 
#> $source
#> $source$type
#> [1] "file_content"
#> 
#> $source$content
#> $source$content[[1]]
#> $source$content[[1]]$item
#> $source$content[[1]]$item$question
#> [1] "2+2?"
#> 
#> $source$content[[1]]$item$answer
#> [1] "4"
#> 
#> 
#> 
#> 
#> 
```
