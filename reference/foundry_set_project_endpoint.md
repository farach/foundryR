# Set Azure AI Foundry project endpoint

Set the project endpoint used by project-scoped Foundry APIs such as
Azure evaluators and Agent Service operations. Prefer copying the full
endpoint from the Foundry portal because Azure's project endpoint shape
can vary by service generation.

## Usage

``` r
foundry_set_project_endpoint(endpoint, store = FALSE)
```

## Arguments

- endpoint:

  Character string containing the project endpoint URL.

- store:

  Logical. If `TRUE`, stores the endpoint in foundryR's package-specific
  user configuration file.

## Value

Invisibly returns `TRUE` if the endpoint was set successfully.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_set_project_endpoint(Sys.getenv("AZURE_FOUNDRY_PROJECT_ENDPOINT"))
} # }
```
