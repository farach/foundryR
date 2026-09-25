# Get Microsoft Foundry Endpoint

Retrieve the endpoint URL from the environment or a provided value.

## Usage

``` r
foundry_get_endpoint(endpoint = NULL, required = FALSE)
```

## Arguments

- endpoint:

  Character. Optional endpoint to use instead of environment variable.

- required:

  Logical. If TRUE, throws an error when no endpoint is found.

## Value

The endpoint URL string, or NULL if not found and not required.

## Examples

``` r
foundry_get_endpoint("https://example.openai.azure.com/")
#> [1] "https://example.openai.azure.com"
```
