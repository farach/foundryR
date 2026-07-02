# Compute agreement metrics for LLM annotation

Compare model labels with human or gold-standard labels using common
publication-friendly metrics.

## Usage

``` r
foundry_agreement(data, estimate, truth)
```

## Arguments

- data:

  Data frame containing estimates and truth.

- estimate:

  Character. Column name with model labels.

- truth:

  Character. Column name with reference labels.

## Value

A tibble with one row per metric.

## Examples

``` r
labels <- data.frame(
  model = c("yes", "no", "yes"),
  human = c("yes", "no", "no")
)
foundry_agreement(labels, estimate = "model", truth = "human")
#> # A tibble: 5 × 3
#>   metric          value     n
#>   <chr>           <dbl> <int>
#> 1 accuracy        0.667     3
#> 2 precision_macro 0.75      3
#> 3 recall_macro    0.75      3
#> 4 f1_macro        0.667     3
#> 5 cohen_kappa     0.4       3
```
