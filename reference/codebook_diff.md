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
if (FALSE) { # \dontrun{
codebook_diff(old_codebook, new_codebook)
} # }
```
