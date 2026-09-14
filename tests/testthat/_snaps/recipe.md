# cache directories must be nonempty paths

    Code
      foundry_cache_dir("")
    Condition
      Error in `foundry_check_character_scalar()`:
      ! `cache_dir` must be a single non-empty character string.

# disk cache directory failures are explicit

    Code
      foundry_embed_cached("text", "test", NULL, cache = "disk", cache_dir = "occupied")
    Condition
      Error in `foundry_embed_cached()`:
      ! Could not create embedding cache directory: 'occupied'.

