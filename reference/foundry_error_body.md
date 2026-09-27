# Parse API Error Response

Internal function that turns a failed response into the lines shown
under httr2's `HTTP <status>` error. The HTTP status picks the category,
the service's own message is always kept, and a hint depends on the
status and the endpoint that was called.

## Usage

``` r
foundry_error_body(resp)
```

## Arguments

- resp:

  An httr2 response object.

## Value

A named character vector of message lines.
