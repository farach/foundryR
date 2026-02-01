# Get Azure Content Safety Endpoint

Retrieve the Content Safety endpoint URL from the environment or a
provided value.

## Usage

``` r
get_content_safety_endpoint(endpoint = NULL, required = FALSE)
```

## Arguments

- endpoint:

  Character. Optional endpoint to use instead of environment variable.

- required:

  Logical. If TRUE, throws an error when no endpoint is found.

## Value

The endpoint URL string, or NULL if not found and not required.
