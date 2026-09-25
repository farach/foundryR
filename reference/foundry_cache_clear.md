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

  Character. Cache directory. Defaults to the session's temporary
  embedding cache. Supply the same explicit directory used by
  [`step_foundry_embed()`](https://farach.github.io/foundryR/reference/step_foundry_embed.md)
  to clear a persistent cache.

## Value

Invisibly, the number of cache files removed.

## Examples

``` r
local({
  cache_dir <- tempfile("foundryR-cache-")
  dir.create(cache_dir)
  on.exit(unlink(cache_dir, recursive = TRUE))
  saveRDS(c(1, 0, 0), file.path(cache_dir, "example.rds"))
  foundry_cache_clear(cache_dir)
})
#> Removed 1 cached embedding from /tmp/RtmpXHEusg/foundryR-cache-1b29490f9463.
```
