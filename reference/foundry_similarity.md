# Compute Cosine Similarity Between Embeddings

Compute pairwise cosine similarity between all embeddings in a tibble.
Useful for finding semantically similar texts.

## Usage

``` r
foundry_similarity(data, text_col = "text", top_k = NULL, as_matrix = FALSE)
```

## Arguments

- data:

  A tibble from
  [`foundry_embed()`](https://farach.github.io/foundryR/reference/foundry_embed.md)
  containing an `embedding` list-column.

- text_col:

  Character. Name of the column containing text labels. Default: "text".

- top_k:

  Integer. Optional maximum number of most-similar pairs to return.

- as_matrix:

  Logical. If `TRUE`, return the full cosine-similarity matrix instead
  of a long pairwise tibble.

## Value

If `as_matrix = FALSE`, a tibble with columns:

- text_1:

  Character. First text.

- text_2:

  Character. Second text.

- similarity:

  Numeric. Cosine similarity between -1 and 1.

If `as_matrix = TRUE`, a numeric cosine-similarity matrix with row and
column names from `text_col`.

## Examples

``` r
# Toy vectors demonstrate local computation without calling Azure.
embeddings <- tibble::tibble(
  text = c("Vector A", "Vector B", "Vector C"),
  embedding = list(c(1, 0), c(1, 1), c(0, 1))
)
foundry_similarity(embeddings)
#> # A tibble: 3 × 3
#>   text_1   text_2   similarity
#>   <chr>    <chr>         <dbl>
#> 1 Vector A Vector B      0.707
#> 2 Vector B Vector C      0.707
#> 3 Vector A Vector C      0    
foundry_similarity(embeddings, top_k = 1)
#> # A tibble: 1 × 3
#>   text_1   text_2   similarity
#>   <chr>    <chr>         <dbl>
#> 1 Vector A Vector B      0.707
foundry_similarity(embeddings, as_matrix = TRUE)
#>           Vector A  Vector B  Vector C
#> Vector A 1.0000000 0.7071068 0.0000000
#> Vector B 0.7071068 1.0000000 0.7071068
#> Vector C 0.0000000 0.7071068 1.0000000
```
