# Get Azure AI Foundry API Key

Retrieve the API key from the environment or a provided value. This is
primarily an internal function used by other foundryR functions.

## Usage

``` r
foundry_get_key(key = NULL, required = FALSE)
```

## Arguments

- key:

  Character. Optional key to use instead of environment variable.

- required:

  Logical. If TRUE, throws an error when no key is found.

## Value

The API key string, or NULL if not found and not required.
