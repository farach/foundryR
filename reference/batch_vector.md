# Split Vector into Batches with Indices

Internal helper function to split a vector into batches, preserving the
original indices of each element.

## Usage

``` r
batch_vector(x, batch_size)
```

## Arguments

- x:

  A vector to split into batches.

- batch_size:

  Integer. The maximum size of each batch.

## Value

A list of lists, where each element contains:

- indices:

  Integer vector of original indices for this batch.

- values:

  The corresponding values from the input vector.

## Examples

``` r
if (FALSE) { # \dontrun{
x <- letters[1:7]
batches <- batch_vector(x, batch_size = 3)
# Returns:
# [[1]] list(indices = 1:3, values = c("a", "b", "c"))
# [[2]] list(indices = 4:6, values = c("d", "e", "f"))
# [[3]] list(indices = 7, values = "g")
} # }
```
