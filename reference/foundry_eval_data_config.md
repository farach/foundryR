# Define an evaluation data-source configuration

Describe the shape of the data an evaluation expects. `type = "custom"`
declares an item schema you populate per run; `type = "logs"` sources
rows from stored completions matching a metadata filter;
`type = "azure_ai_source"` lets Microsoft Foundry supply the rows for a
service scenario, such as stored responses.

## Usage

``` r
foundry_eval_data_config(
  type = c("custom", "logs", "azure_ai_source"),
  item_schema = NULL,
  include_sample_schema = FALSE,
  metadata = NULL,
  scenario = NULL
)
```

## Arguments

- type:

  Character. One of `"custom"`, `"logs"`, or `"azure_ai_source"`.

- item_schema:

  List. For `type = "custom"`, a JSON Schema (as an R list) describing
  each row.

- include_sample_schema:

  Logical. For `type = "custom"`, whether the eval should expect a
  populated `sample` namespace (generated responses). Defaults to
  `FALSE`.

- metadata:

  List. For `type = "logs"`, the stored-completions metadata filter.

- scenario:

  Character. For `type = "azure_ai_source"`, the Foundry scenario, for
  example `"responses"` to evaluate stored responses by ID (see
  [`foundry_eval_run_data()`](https://farach.github.io/foundryR/reference/foundry_eval_run_data.md)).
  Requires the project Evals route.

## Value

A named list describing a `data_source_config`, for use in
[`foundry_eval_create()`](https://farach.github.io/foundryR/reference/foundry_eval_create.md).

## Examples

``` r
foundry_eval_data_config(
  type = "custom",
  item_schema = list(
    type = "object",
    properties = list(
      question = list(type = "string"),
      answer = list(type = "string")
    ),
    required = list("question", "answer")
  ),
  include_sample_schema = TRUE
)
#> $type
#> [1] "custom"
#> 
#> $item_schema
#> $item_schema$type
#> [1] "object"
#> 
#> $item_schema$properties
#> $item_schema$properties$question
#> $item_schema$properties$question$type
#> [1] "string"
#> 
#> 
#> $item_schema$properties$answer
#> $item_schema$properties$answer$type
#> [1] "string"
#> 
#> 
#> 
#> $item_schema$required
#> $item_schema$required[[1]]
#> [1] "question"
#> 
#> $item_schema$required[[2]]
#> [1] "answer"
#> 
#> 
#> 
#> $include_sample_schema
#> [1] TRUE
#> 

foundry_eval_data_config(type = "azure_ai_source", scenario = "responses")
#> $type
#> [1] "azure_ai_source"
#> 
#> $scenario
#> [1] "responses"
#> 
```
