# Compare two codebooks

Print a compact diff of two `foundry_codebook` objects, including both
hashes, a unified diff of instructions, and field-level changes for
schema properties and examples.

## Usage

``` r
codebook_diff(old, new)
```

## Arguments

- old, new:

  `foundry_codebook` objects to compare.

## Value

Invisibly returns the printed diff lines.

## Examples

``` r
old <- foundry_codebook(
  name = "support-sentiment",
  version = "1.0.0",
  instructions = "Label the sentiment of support tickets.",
  schema = foundry_schema(sentiment = type_enum(values = c("pos", "neg")))
)
new <- foundry_codebook(
  name = "support-sentiment",
  version = "1.1.0",
  instructions = "Label the sentiment and urgency of support tickets.",
  schema = foundry_schema(
    sentiment = type_enum(values = c("pos", "neg")),
    urgent = type_boolean()
  )
)
codebook_diff(old, new)
#> Codebook diff
#> old: support-sentiment 1.0.0 59e00aef3af73a552d791a1bc4bf73711075920d4ca79f9a1508f63e2cdc8555
#> new: support-sentiment 1.1.0 22828ea2e41623dd9ff47d3be91983121c540980d48860452079e1afa9c14323
#> 
#> Instructions:
#> --- old instructions
#> +++ new instructions
#> @@
#> -Label the sentiment of support tickets.
#> +Label the sentiment and urgency of support tickets.
#> 
#> Schema:
#>   sentiment: no change
#> + urgent: {"type":"boolean"}
#> 
#> Examples:
#>   (none)
```
