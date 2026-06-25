# List uploaded Microsoft Foundry files

List uploaded Microsoft Foundry files

## Usage

``` r
foundry_files(
  purpose = NULL,
  limit = NULL,
  order = NULL,
  after = NULL,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = NULL
)
```

## Arguments

- purpose:

  Character. Optional purpose filter.

- limit:

  Integer. Optional maximum number of files to return.

- order:

  Character. Optional sort order, `"asc"` or `"desc"`.

- after:

  Character. Optional pagination cursor.

- api_key:

  Character. Optional API key override.

- token:

  Character. Optional bearer token override.

- endpoint:

  Character. Optional endpoint override.

- api_version:

  Character. Optional API version query value.

## Value

A tibble with one row per file.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_files(purpose = "batch", limit = 10)
} # }
```
