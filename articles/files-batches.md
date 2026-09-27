# Annotate at scale with the Batch API

Calls to Azure show output recorded from a live run, and setup code is
shown but not run.

Batch is worth the extra setup when you have thousands of independent
texts, can wait for the 24-hour processing window, and want the lower
batch price instead of immediate responses. It is a production path for
stable annotation jobs, not the first place to debug a new prompt.

Batch jobs need a deployment made for batch inference. Microsoft Learn
states that the Foundry portal shows batch deployment types as
`Global-Batch` and `Data Zone Batch`, and that the `model` field in each
request line must match the Global Batch deployment name. This article
uses `gpt-4.1-nano-batch`, a Global Batch deployment of `gpt-4.1-nano`.
See Microsoft’s [Azure OpenAI batch deployments
guide](https://learn.microsoft.com/azure/ai-foundry/openai/how-to/batch).

## Prepare requests

[`foundry_batch_requests()`](https://farach.github.io/foundryR/reference/foundry_batch_requests.md)
writes the JSONL file that the service reads. The call is local, so it
can run before credentials are configured.

``` r

library(foundryR)
library(dplyr)
```

``` r

comments <- tibble::tibble(
  comment_id = sprintf("c%02d", 1:6),
  comment = c(
    "The lectures were clear and the examples made regression feel concrete.",
    "The weekly quizzes felt rushed and did not match the homework.",
    "Office hours helped me catch up after I missed the first lab.",
    "The slides were hard to follow because notation changed between weeks.",
    "The final project connected the material to real policy questions.",
    "I needed more feedback before the midterm."
  )
)

course_schema <- foundry_schema(
  theme = schema_enum(
    c("instruction", "assessment", "support", "materials"),
    description = "Primary course evaluation theme."
  ),
  sentiment = schema_enum(
    c("positive", "negative", "mixed"),
    description = "Overall sentiment toward the course element."
  )
)

course_instructions <- paste(
  "Code one course evaluation comment.",
  "Choose exactly one primary theme and one sentiment.",
  "Return only fields that conform to the schema."
)
```

``` r

jsonl <- tempfile(fileext = ".jsonl")

request_info <- foundry_batch_requests(
  comments,
  input = "comment",
  path = jsonl,
  model = "gpt-4.1-nano-batch",
  custom_id = "comment_id",
  schema = course_schema,
  schema_name = "CourseEvaluationCodes",
  instructions = course_instructions,
  overwrite = TRUE
)

request_info |>
  select(requests, endpoint)
#> # A tibble: 1 × 2
#>   requests endpoint     
#>      <int> <chr>        
#> 1        6 /v1/responses
```

Print one request line, formatted for inspection, rather than printing
the temporary path. The request line is the object you need to review.

``` r

jsonlite::prettify(readLines(jsonl, n = 1))
#> {
#>     "custom_id": "c01",
#>     "method": "POST",
#>     "url": "/v1/responses",
#>     "body": {
#>         "model": "gpt-4.1-nano-batch",
#>         "input": "The lectures were clear and the examples made regression feel concrete.",
#>         "instructions": "Code one course evaluation comment. Choose exactly one primary theme and one sentiment. Return only fields that conform to the schema.",
#>         "text": {
#>             "format": {
#>                 "type": "json_schema",
#>                 "name": "CourseEvaluationCodes",
#>                 "schema": {
#>                     "type": "object",
#>                     "properties": {
#>                         "theme": {
#>                             "type": "string",
#>                             "description": "Primary course evaluation theme.",
#>                             "enum": [
#>                                 "instruction",
#>                                 "assessment",
#>                                 "support",
#>                                 "materials"
#>                             ]
#>                         },
#>                         "sentiment": {
#>                             "type": "string",
#>                             "description": "Overall sentiment toward the course element.",
#>                             "enum": [
#>                                 "positive",
#>                                 "negative",
#>                                 "mixed"
#>                             ]
#>                         }
#>                     },
#>                     "required": [
#>                         "theme",
#>                         "sentiment"
#>                     ],
#>                     "additionalProperties": false
#>                 },
#>                 "strict": true
#>             }
#>         }
#>     }
#> }
#> 
```

The `custom_id` is the join key. Use a stable ID from your data instead
of relying on file order.

## Submit and wait with the low-level API

The low-level path makes each service object visible: uploaded file,
batch job, final status, parsed results and usage.

``` r

uploaded_file <- foundry_file_upload(jsonl, purpose = "batch")

batch <- foundry_batch_create(
  input_file_id = uploaded_file$file_id,
  endpoint = request_info$endpoint
)

batch |>
  select(status, completion_window, batch_id)
#> # A tibble: 1 × 3
#>   status     completion_window batch_id                                  
#>   <chr>      <chr>             <chr>                                     
#> 1 validating 24h               batch_4c084697-726e-4b46-b252-54c5df527796
```

[`foundry_batch_wait()`](https://farach.github.io/foundryR/reference/foundry_batch_wait.md)
polls until the batch reaches a terminal state. Batch jobs target
completion within 24 hours, so use a longer polling interval in a large
live workflow.

``` r

completed_batch <- foundry_batch_wait(
  batch$batch_id,
  interval = 60
)

completed_batch |>
  select(
    status,
    request_counts_total,
    request_counts_completed,
    request_counts_failed
  )
#> # A tibble: 1 × 4
#>   status    request_counts_total request_counts_completed request_counts_failed
#>   <chr>                    <int>                    <int>                 <int>
#> 1 completed                    6                        6                     0
```

[`foundry_batch_results()`](https://farach.github.io/foundryR/reference/foundry_batch_results.md)
downloads and parses the output file and, when present, the error file.
Failed request rows have `.error = TRUE` and an `.error_msg`.

``` r

batch_results <- foundry_batch_results(completed_batch$batch_id)

batch_results |>
  select(custom_id, output_text, .error, input_tokens, output_tokens)
#> # A tibble: 6 × 5
#>   custom_id output_text                        .error input_tokens output_tokens
#>   <chr>     <chr>                              <lgl>         <int>         <int>
#> 1 c02       "{\"theme\":\"assessment\",\"sent… FALSE           114            11
#> 2 c04       "{\"theme\":\"materials\",\"senti… FALSE           114            11
#> 3 c03       "{\"theme\":\"support\",\"sentime… FALSE           115            11
#> 4 c06       "{\"theme\":\"assessment\",\"sent… FALSE           111            11
#> 5 c05       "{\"theme\":\"assessment\",\"sent… FALSE           113            11
#> 6 c01       "{\"theme\":\"instruction\",\"sen… FALSE           114            11
```

The results came back in the order c02, c04, c03, c06, c05, c01, not in
the order the requests were written. Join on `custom_id`, never on row
position.

The coded fields arrive as JSON text in `output_text` and, parsed, in
the `structured` list-column. The extraction path below turns them into
ordinary columns joined to your rows.

When the service writes an error file, `completed_batch$error_file_id`
names it. Those rows are included in
[`foundry_batch_results()`](https://farach.github.io/foundryR/reference/foundry_batch_results.md)
with `.error` columns so you can separate successful labels from failed
requests before joining.

Usage is reported in tokens. Pass your own per-token rates because Azure
prices change and differ by deployment. The rates below are
illustrative, not current prices.

``` r

foundry_usage(
  batch_results,
  rates = c(
    input = 0.00000010,
    cached_input = 0.000000025,
    output = 0.00000040
  )
)
#> # A tibble: 1 × 5
#>   input_tokens cached_input_tokens output_tokens total_tokens      cost
#>          <int>               <int>         <int>        <int>     <dbl>
#> 1          681                   0            66          747 0.0000945
```

## Submit now and collect later

Most annotation projects do not need the low-level objects in analysis
code. `foundry_extract_batch(wait = FALSE)` writes the request file,
uploads it and creates the batch. It returns the batch immediately.

``` r

extract_batch <- foundry_extract_batch(
  comments,
  text_col = "comment",
  schema = course_schema,
  model = "gpt-4.1-nano-batch",
  wait = FALSE,
  instructions = course_instructions
)

extract_batch |>
  select(status, completion_window, batch_id)
#> # A tibble: 1 × 3
#>   status     completion_window batch_id                                  
#>   <chr>      <chr>             <chr>                                     
#> 1 validating 24h               batch_5dfcd819-e17a-4b4c-951a-fbbb6c6d0dc1
```

Save `extract_batch$batch_id` with the data and schema. Later, even in a
new R session, check that the batch has finished, then call
[`foundry_extract_batch_results()`](https://farach.github.io/foundryR/reference/foundry_extract_batch_results.md)
with the batch ID, original rows and the same schema. foundryR joins
results back to the original rows using the `row-N` IDs written by
[`foundry_extract_batch()`](https://farach.github.io/foundryR/reference/foundry_extract_batch.md),
and warns about any row that has no result.

``` r

foundry_batch_wait(extract_batch$batch_id, interval = 60) |>
  select(status, request_counts_completed, request_counts_failed)
#> # A tibble: 1 × 3
#>   status    request_counts_completed request_counts_failed
#>   <chr>                        <int>                 <int>
#> 1 completed                        6                     0

extract_results <- foundry_extract_batch_results(
  extract_batch$batch_id,
  data = comments,
  schema = course_schema,
  text_col = "comment"
)

extract_results |>
  select(comment_id, theme, sentiment, .error)
#> # A tibble: 6 × 4
#>   comment_id theme       sentiment .error
#>   <chr>      <chr>       <chr>     <lgl> 
#> 1 c01        instruction positive  FALSE 
#> 2 c02        assessment  negative  FALSE 
#> 3 c03        support     positive  FALSE 
#> 4 c04        materials   negative  FALSE 
#> 5 c05        assessment  positive  FALSE 
#> 6 c06        assessment  mixed     FALSE
```

This path is the one to use in a reproducible analysis. The original
tibble stays in your project, and the service result is collected into
the same row structure after the batch finishes.

## Clean up files

Delete service files that are no longer needed. Keep the batch IDs,
codebook version and schema with your analysis so the results can be
traced.

``` r

file_deletes <- bind_rows(
  foundry_file_delete(uploaded_file$file_id),
  foundry_file_delete(extract_batch$input_file_id)
)

file_deletes
#> # A tibble: 2 × 2
#>   file_id                               deleted
#>   <chr>                                 <lgl>  
#> 1 file-f2656a86733b4d059fe8727280d62316 TRUE   
#> 2 file-deb5fab3618f49938d085614badbf0cd TRUE
```
