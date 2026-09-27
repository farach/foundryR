# Retrieve a Microsoft Foundry file

Retrieve a Microsoft Foundry file

## Usage

``` r
foundry_file_get(
  file_id,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = NULL,
  project_endpoint = NULL
)
```

## Arguments

- file_id:

  Character. File ID to retrieve.

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

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a configured Azure endpoint, credentials, and an uploaded file ID.
foundry_file_get("file_abc123")
} # }
```
