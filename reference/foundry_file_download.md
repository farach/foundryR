# Download Microsoft Foundry file content

Download Microsoft Foundry file content

## Usage

``` r
foundry_file_download(
  file_id,
  path,
  overwrite = FALSE,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = NULL
)
```

## Arguments

- file_id:

  Character. File ID to download.

- path:

  Character. Local path where the file content should be written.

- overwrite:

  Logical. Whether to overwrite an existing file.

- api_key:

  Character. Optional API key override.

- token:

  Character. Optional bearer token override.

- endpoint:

  Character. Optional endpoint override.

- api_version:

  Character. Optional API version query value.

## Value

A tibble with the local path, number of bytes written, and file ID.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_file_download("file_abc123", "batch-output.jsonl")
} # }
```
