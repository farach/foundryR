# Retrieve a Microsoft Foundry file

Retrieve a Microsoft Foundry file

## Usage

``` r
foundry_file_get(
  file_id,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = NULL
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

## Value

A one-row tibble with file metadata.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_file_get("file_abc123")
} # }
```
