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

## Examples

``` r
responses <- data.frame(
  input_tokens = c(10, 20),
  cached_input_tokens = c(0, 5),
  output_tokens = c(3, 7)
)
foundry_usage(responses)
#> # A tibble: 1 × 4
#>   input_tokens cached_input_tokens output_tokens total_tokens
#>          <dbl>               <dbl>         <dbl>        <dbl>
#> 1           30                   5            10           40
foundry_usage(
  responses,
  rates = c(input = 0.000001, cached_input = 0.0000001, output = 0.000004)
)
#> # A tibble: 1 × 5
#>   input_tokens cached_input_tokens output_tokens total_tokens      cost
#>          <dbl>               <dbl>         <dbl>        <dbl>     <dbl>
#> 1           30                   5            10           40 0.0000705
```
