# Summarise token usage for foundryR results

Sum token columns returned by foundryR chat, Responses, extraction, and
batch helpers. Pass your own `rates` to compute spend; foundryR does not
hardcode Azure prices because they change over time.

## Usage

``` r
foundry_usage(x, rates = NULL)
```

## Arguments

- x:

  Data frame with foundryR token columns.

- rates:

  Optional named numeric vector with any of `input`, `cached_input`, and
  `output` rates per token.

## Value

A one-row tibble with token totals and optional `cost`.
