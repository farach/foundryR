# Clear the foundryR embedding cache

Delete cached embeddings written by
[`step_foundry_embed()`](https://farach.github.io/foundryR/reference/step_foundry_embed.md)
with `cache = "disk"`.

## Usage

``` r
foundry_cache_clear(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Cache directory. Defaults to
  `tools::R_user_dir("foundryR", "cache")`.

## Value

Invisibly, the number of cache files removed.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_cache_clear()
} # }
```
