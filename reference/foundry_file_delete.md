# Delete a Microsoft Foundry file

Delete a Microsoft Foundry file

## Usage

``` r
foundry_file_delete(
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

  Character. File ID to delete.

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

A tibble with deletion status.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a configured Azure endpoint and credentials,
# plus the ID of a file you can delete.
foundry_file_delete("file_abc123")
} # }
```
