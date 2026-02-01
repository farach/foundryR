# Compute Cosine Similarity Between Embeddings

Compute pairwise cosine similarity between all embeddings in a tibble.
Useful for finding semantically similar texts.

## Usage

``` r
foundry_similarity(data, text_col = "text")
```

## Arguments

- data:

  A tibble from
  [`foundry_embed()`](https://farach.github.io/foundryR/reference/foundry_embed.md)
  containing an `embedding` list-column.

- text_col:

  Character. Name of the column containing text labels. Default: "text".

## Value

A tibble with columns:

- text_1:

  Character. First text.

- text_2:

  Character. Second text.

- similarity:

  Numeric. Cosine similarity between -1 and 1.

## Examples

``` r
if (FALSE) { # \dontrun{
texts <- c("I love R", "R is my favorite language", "Python is also good")
embeddings <- foundry_embed(texts, model = "text-embedding-ada-002")
foundry_similarity(embeddings)
} # }
```
