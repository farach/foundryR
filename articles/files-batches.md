# Files and Batch API Workflows

``` r

library(foundryR)
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
head(readLines(jsonl), 2)
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

The returned objects include service identifiers, status fields, file
sizes, completion windows, and request counts.

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

output_lines <- readLines("batch-output.jsonl", n = 2)
head(output_lines)
```

## Practical advice

- Start with 10 to 20 rows and inspect the output before scaling up.
- Use stable `custom_id` values so results join back to your data frame.
- Store prompts and schema versions with your analysis code for
  reproducibility.
- Download both output and error files when a batch finishes.
