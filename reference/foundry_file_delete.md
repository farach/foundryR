# Delete a Microsoft Foundry file

Delete a Microsoft Foundry file

## Usage

``` r
foundry_file_delete(
  file_id,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = NULL
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

## Value

A tibble with deletion status.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_file_delete("file_abc123")
} # }
```
