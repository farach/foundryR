# Warn if Model Looks Like a Chat Model

Internal function to warn users if they appear to be using a chat model
for embedding operations.

## Usage

``` r
warn_if_chat_model(model, calling_fn = "foundry_embed")
```

## Arguments

- model:

  Character. The model/deployment name.

- calling_fn:

  Character. The function name for the warning message.

## Value

NULL (invisibly). Called for side effect of warning.
