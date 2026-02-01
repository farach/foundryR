# Convert Severity Score to Label

Internal function to convert numeric severity scores to human-readable
labels.

## Usage

``` r
severity_to_label(severity, output_type = "FourSeverityLevels")
```

## Arguments

- severity:

  Numeric. The severity score (0-7 for EightSeverityLevels, 0-6 for
  FourSeverityLevels where values are 0, 2, 4, 6).

- output_type:

  Character. The output type used in the API call.

## Value

Character. One of "safe", "low", "medium", or "high".
