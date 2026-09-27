# Upload a file to Microsoft Foundry

Upload a local file for use with Foundry APIs such as Batch,
fine-tuning, evals, or assistants/file-search workflows.

## Usage

``` r
foundry_file_upload(
  path,
  purpose = c("assistants", "batch", "fine-tune", "evals"),
  expires_after_seconds = NULL,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = NULL,
  project_endpoint = NULL
)
```

## Arguments

- path:

  Character. Local file path to upload.

- purpose:

  Character. File purpose. One of `"assistants"`, `"batch"`,
  `"fine-tune"`, or `"evals"`.

- expires_after_seconds:

  Integer. Optional number of seconds after creation when the file
  should expire, sent as an `expires_after` object. Default `NULL` sends
  no expiry. The service rejects an expiry for `purpose = "assistants"`.

- api_key:

  Character. Optional API key override.

- token:

  Character. Optional bearer token override.

- endpoint:

  Character. Optional endpoint override.

- api_version:

  Character. Optional API version query value.

- project_endpoint:

  Character. Optional project endpoint. When supplied, the call uses the
  project endpoint instead of the resource endpoint.

## Value

A one-row tibble with file metadata.

## Details

Files live on the endpoint where you upload them. Server-side agents
search files on the project endpoint, so upload files for an agent's
vector store with `project_endpoint` (or after
`foundry_set_route("project")`).

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a configured Azure endpoint and credentials.
local({
  path <- tempfile(fileext = ".jsonl")
  on.exit(unlink(path))
  jobs <- data.frame(text = "Summarize this.")
  foundry_batch_requests(
    jobs, input = "text", path = path, model = "gpt-5-nano"
  )
  foundry_file_upload(path, purpose = "batch")
})
} # }
```
