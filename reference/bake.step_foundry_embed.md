# Apply the Foundry embedding step to new data

Apply the Foundry embedding step to new data

## Usage

``` r
# S3 method for class 'step_foundry_embed'
bake(object, new_data, ...)
```

## Arguments

- object:

  A trained `step_foundry_embed` object

- new_data:

  A tibble to apply the step to

- ...:

  Not used

## Value

A tibble with embedding columns added (and optionally original text
columns removed)
