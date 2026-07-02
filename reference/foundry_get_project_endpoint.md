# Get Azure AI Foundry project endpoint

Retrieve the project endpoint URL from the environment or a provided
value.

## Usage

``` r
foundry_get_project_endpoint(endpoint = NULL, required = FALSE)
```

## Arguments

- endpoint:

  Character. Optional endpoint to use instead of
  `AZURE_FOUNDRY_PROJECT_ENDPOINT`.

- required:

  Logical. If `TRUE`, throws an error when no endpoint is found.

## Value

The project endpoint URL string, or `NULL`.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_get_project_endpoint()
} # }
```
