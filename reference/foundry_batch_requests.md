# Write JSONL requests for the Batch API

Convert a data frame of prompts into a JSON Lines file that can be
uploaded with `foundry_file_upload(..., purpose = "batch")` and
submitted with
[`foundry_batch_create()`](https://farach.github.io/foundryR/reference/foundry_batch_create.md).

## Usage

``` r
foundry_batch_requests(
  data,
  input,
  path,
  model,
  endpoint = "/v1/responses",
  custom_id = NULL,
  body = list(),
  schema = NULL,
  schema_name = "ExtractedData",
  strict = TRUE,
  instructions = NULL,
  body_columns = NULL,
  overwrite = FALSE
)
```

## Arguments

- data:

  Data frame containing input rows.

- input:

  Character. Name of the column containing prompt/input text.

- path:

  Character. Path to write the JSONL file.

- model:

  Character. Model deployment name to include in each request.

- endpoint:

  Character. Batch endpoint path. Defaults to `"/v1/responses"`.

- custom_id:

  Character. Optional column name for custom IDs. If omitted, IDs are
  generated as `row-1`, `row-2`, and so on.

- body:

  List. Additional request body fields added to each request.

- schema:

  List. Optional JSON Schema for structured Responses API output.

- schema_name:

  Character. Name for `schema` when supplied.

- strict:

  Logical. Whether structured output should be strict.

- instructions:

  Character. Optional instructions for Responses API requests.

- body_columns:

  Character vector. Optional column names whose per-row values should be
  added to each request body.

- overwrite:

  Logical. Whether to overwrite an existing file.

## Value

A tibble with the JSONL path, request count, and endpoint.

## Examples

``` r
jobs <- data.frame(text = c("Summarize this.", "Extract entities."))
path <- tempfile(fileext = ".jsonl")
foundry_batch_requests(jobs, input = "text", path = path, model = "gpt-5-nano")
#> # A tibble: 1 × 3
#>   path                                   requests endpoint     
#>   <chr>                                     <int> <chr>        
#> 1 /tmp/RtmpHy4gm1/file1a015c36c61a.jsonl        2 /v1/responses
```
