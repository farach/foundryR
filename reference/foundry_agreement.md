# Compute agreement metrics for LLM annotation

Compare model labels with reference labels using accuracy, macro
precision/recall/F1, Cohen's kappa, and nominal Krippendorff's alpha for
two coders. These metrics describe agreement with the reference labels;
they do not establish that the reference labels are valid.

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

## Details

Rows with missing labels in either column are dropped and reported; `n`
is the number of complete pairs. If the estimate and truth label sets
differ, a warning reports the labels only seen on one side. Macro
metrics use the union of labels in both columns and follow the yardstick
convention: classes whose per-class denominator is undefined for a given
metric are dropped from that macro average with a warning. If only one
category occurs across both columns, kappa and alpha are returned as
`NA_real_` with a warning.

## Examples

``` r
labels <- data.frame(
  model = c("yes", "no", "yes"),
  human = c("yes", "no", "no")
)
foundry_agreement(labels, estimate = "model", truth = "human")
#> # A tibble: 6 × 3
#>   metric             value     n
#>   <chr>              <dbl> <int>
#> 1 accuracy           0.667     3
#> 2 precision_macro    0.75      3
#> 3 recall_macro       0.75      3
#> 4 f1_macro           0.667     3
#> 5 cohen_kappa        0.4       3
#> 6 krippendorff_alpha 0.444     3
```
