# Upload a file to Microsoft Foundry

Upload a local file for use with Foundry APIs such as Batch,
fine-tuning, evals, or assistants/file-search workflows.

## Usage

``` r
foundry_file_upload(
  path,
  purpose = c("assistants", "batch", "fine-tune", "evals"),
  expires_after_seconds = 30 * 24 * 60 * 60,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = NULL
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
  should expire. Azure's v1 Files API accepts this as an `expires_after`
  object.

- api_key:

  Character. Optional API key override.

- token:

  Character. Optional bearer token override.

- endpoint:

  Character. Optional endpoint override.

- api_version:

  Character. Optional API version query value.

## Value

A one-row tibble with file metadata.

## Examples

``` r
if (FALSE) { # \dontrun{
path <- tempfile(fileext = ".jsonl")
writeLines('{"custom_id":"row-1","method":"POST","url":"/v1/responses"}', path)
foundry_file_upload(path, purpose = "batch")
} # }
```
