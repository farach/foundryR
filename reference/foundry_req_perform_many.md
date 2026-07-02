# Perform Many Requests

Internal helper that performs a list of httr2 requests. By default it
uses
[`httr2::req_perform_parallel()`](https://httr2.r-lib.org/reference/req_perform_parallel.html)
for speed. When the option `foundryR.sequential_requests` is `TRUE`, the
requests are performed one at a time with
[`httr2::req_perform()`](https://httr2.r-lib.org/reference/req_perform.html)
instead.

## Usage

``` r
foundry_req_perform_many(reqs, progress = FALSE, max_active = 10)
```

## Arguments

- reqs:

  A list of httr2 request objects.

- progress:

  Passed to
  [`httr2::req_perform_parallel()`](https://httr2.r-lib.org/reference/req_perform_parallel.html).

- max_active:

  Passed to
  [`httr2::req_perform_parallel()`](https://httr2.r-lib.org/reference/req_perform_parallel.html).

## Value

A list of responses or error conditions, in the order of `reqs`.

## Details

Parallel requests bypass httr2's mocking hook, so the sequential path is
what lets httptest2 record and replay documentation fixtures for batched
calls such as
[`foundry_embed()`](https://farach.github.io/foundryR/reference/foundry_embed.md)
and
[`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
(see `inst/httptest2/start-vignette.R`). Both paths return a list, in
request order, whose elements are either an httr2 response or the error
condition raised for that request, mirroring
`req_perform_parallel(on_error = "continue")`.
