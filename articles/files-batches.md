# Files and Batch API Workflows

``` r

library(foundryR)
#> 
#> foundryR - Tidy Azure AI Foundry workflows
#> ==========================================
#> * Check your setup:
#>   foundry_check_setup()
#> * Set your API key: foundry_set_key()
#> * Set your endpoint: foundry_set_endpoint()
#> * Get started: ?foundry_response, ?foundry_groundedness
#> 
#> New to Azure? See the README for setup instructions.
```

The Batch API is useful when your research task has hundreds or
thousands of independent rows: survey coding, abstract screening, entity
extraction, document classification, or large-scale summarization.

## Prepare JSONL locally

[`foundry_batch_requests()`](https://farach.github.io/foundryR/reference/foundry_batch_requests.md)
runs locally. It converts a data frame into the JSON Lines shape
expected by the Batch API.

``` r

survey <- data.frame(
  id = c("resp-001", "resp-002", "resp-003"),
  response = c(
    "The workshop was clear and practical.",
    "I liked the examples but wanted more time.",
    "The setup instructions were confusing."
  )
)

jsonl <- tempfile(fileext = ".jsonl")

request_file <- foundry_batch_requests(
  survey,
  input = "response",
  path = jsonl,
  model = "gpt-4.1",
  custom_id = "id",
  body = list(
    instructions = "Classify the response sentiment as positive, neutral, or negative."
  )
)

request_file
#> # A tibble: 1 × 3
#>   path                                   requests endpoint     
#>   <chr>                                     <int> <chr>        
#> 1 /tmp/RtmpHzzdkr/file21a12ba9a216.jsonl        3 /v1/responses
head(readLines(jsonl), 2)
#> [1] "{\"custom_id\":\"resp-001\",\"method\":\"POST\",\"url\":\"/v1/responses\",\"body\":{\"model\":\"gpt-4.1\",\"input\":\"The workshop was clear and practical.\",\"instructions\":\"Classify the response sentiment as positive, neutral, or negative.\"}}"     
#> [2] "{\"custom_id\":\"resp-002\",\"method\":\"POST\",\"url\":\"/v1/responses\",\"body\":{\"model\":\"gpt-4.1\",\"input\":\"I liked the examples but wanted more time.\",\"instructions\":\"Classify the response sentiment as positive, neutral, or negative.\"}}"
```

## Upload and create a batch

Uploading and batch creation call the Foundry service, so these chunks
are not run while building the vignette.

``` r

file <- foundry_file_upload(jsonl, purpose = "batch")

batch <- foundry_batch_create(
  input_file_id = file$file_id,
  endpoint = "/v1/responses"
)
```

The returned objects are tidy tibbles:

``` r

file <- tibble::tibble(
  file_id = "file_abc123",
  filename = basename(jsonl),
  purpose = "batch",
  status = "processed",
  bytes = file.size(jsonl),
  created_at = as.POSIXct("2026-06-24 12:00:00", tz = "UTC")
)

batch <- tibble::tibble(
  batch_id = "batch_abc123",
  status = "validating",
  endpoint = "/v1/responses",
  input_file_id = file$file_id,
  output_file_id = NA_character_,
  error_file_id = NA_character_,
  completion_window = "24h",
  request_counts_total = 3L,
  request_counts_completed = 0L,
  request_counts_failed = 0L
)

file
#> # A tibble: 1 × 6
#>   file_id     filename               purpose status    bytes created_at         
#>   <chr>       <chr>                  <chr>   <chr>     <dbl> <dttm>             
#> 1 file_abc123 file21a12ba9a216.jsonl batch   processed   672 2026-06-24 12:00:00
batch
#> # A tibble: 1 × 10
#>   batch_id     status     endpoint    input_file_id output_file_id error_file_id
#>   <chr>        <chr>      <chr>       <chr>         <chr>          <chr>        
#> 1 batch_abc123 validating /v1/respon… file_abc123   NA             NA           
#> # ℹ 4 more variables: completion_window <chr>, request_counts_total <int>,
#> #   request_counts_completed <int>, request_counts_failed <int>
```

## Poll and download results

``` r

foundry_batch_get(batch$batch_id)

foundry_file_download(
  file_id = batch$output_file_id,
  path = "batch-output.jsonl"
)
```

Output files are JSONL too. Read a few lines first before parsing a
large job:

``` r

output_lines <- c(
  '{"custom_id":"resp-001","response":{"body":{"output_text":"positive"}}}',
  '{"custom_id":"resp-002","response":{"body":{"output_text":"neutral"}}}'
)

head(output_lines)
#> [1] "{\"custom_id\":\"resp-001\",\"response\":{\"body\":{\"output_text\":\"positive\"}}}"
#> [2] "{\"custom_id\":\"resp-002\",\"response\":{\"body\":{\"output_text\":\"neutral\"}}}"
```

## Practical advice

- Start with 10 to 20 rows and inspect the output before scaling up.
- Use stable `custom_id` values so results join back to your data frame.
- Store prompts and schema versions with your analysis code for
  reproducibility.
- Download both output and error files when a batch finishes.
