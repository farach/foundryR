# Get Azure Content Safety API Key

Retrieve the Content Safety API key from the environment or a provided
value. This is primarily an internal function used by other foundryR
functions.

## Usage

``` r
get_content_safety_key(key = NULL, required = FALSE)
```

## Arguments

- key:

  Character. Optional key to use instead of environment variable.

- required:

  Logical. If TRUE, throws an error when no key is found.

## Value

The API key string, or NULL if not found and not required.
