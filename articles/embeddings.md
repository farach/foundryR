# Working with Embeddings

## What embeddings are for

Embeddings are numerical representations of text that capture semantic
meaning. When you convert text to an embedding, you get a vector of
numbers (often 1,536 or 3,072 dimensions depending on the model). Texts
with similar meanings tend to have similar vectors.

Use embeddings when you need to:

- Find documents related to a query by meaning, not only keywords.
- Measure how similar two pieces of text are.
- Cluster open-ended responses into themes.
- Find near-duplicate responses or records.
- Feed text-derived numeric predictors into downstream models.

Unlike keyword matching, embeddings understand that “automobile” and
“car” are semantically similar, even though they share no letters.

## Generating embeddings with foundry_embed()

The examples below embed real sentences from Jane Austen’s *Pride and
Prejudice*, available in the `janeaustenr` package. Using a well-known
public-domain text makes the output easy to reason about: the opening
lines share vocabulary and sentiment, so their embeddings should sit
close together.

``` r

library(foundryR)

austen_lines <- c(
  "It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.",
  "However little known the feelings or views of such a man may be on his first entering a neighbourhood.",
  "Mr. Bennet was so odd a mixture of quick parts, sarcastic humour, reserve, and caprice."
)

embedding <- foundry_embed(austen_lines[1], model = "text-embedding-3-small")
embedding
```

The result is a tibble with:

- `text`: the original input text.
- `embedding`: a list-column holding the numeric vector.
- `n_dims`: the dimensionality of the embedding.

### Embedding multiple texts

Pass a character vector to embed several texts in one call:

``` r

doc_embeddings <- foundry_embed(austen_lines, model = "text-embedding-3-small")
doc_embeddings
```

### Controlling dimensions

The `text-embedding-3-small` and `text-embedding-3-large` models can
return shorter vectors. Smaller dimensions mean faster similarity
computations and less storage, with some trade-off in precision:

``` r

compact <- foundry_embed(
  austen_lines[1],
  model = "text-embedding-3-small",
  dimensions = 256
)
compact$n_dims
```

## Computing similarity with foundry_similarity()

Cosine similarity measures how close two embeddings are, from -1
(opposite) to 1 (identical).
[`foundry_similarity()`](https://farach.github.io/foundryR/reference/foundry_similarity.md)
computes every pairwise similarity in a tibble of embeddings. Here we
contrast the Austen lines with two sentences from a different domain so
the split is visible.

``` r

mixed <- c(
  "It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.",
  "Mr. Bennet was so odd a mixture of quick parts, sarcastic humour, reserve, and caprice.",
  "The quarterly revenue report showed a sharp rise in cloud subscriptions.",
  "Analysts raised their earnings forecast after the strong cloud numbers."
)

similarities <- foundry_embed(mixed, model = "text-embedding-3-small") |>
  foundry_similarity()
similarities
```

Results are sorted by similarity. The two Austen lines pair together and
the two finance lines pair together, while cross-domain pairs score
lower.

## Use case: finding similar documents

A common application is ranking documents by relevance to a query. Embed
the documents and the query, then sort by cosine similarity:

``` r

library(dplyr)

documents <- c(
  "How to install R packages using install.packages()",
  "Data visualization with ggplot2 in R",
  "Introduction to machine learning with Python",
  "Statistical hypothesis testing explained",
  "Building web applications with Shiny",
  "Deep learning with TensorFlow and Keras"
)

doc_embeddings <- foundry_embed(documents, model = "text-embedding-3-small")
query_embedding <- foundry_embed(
  "How do I create charts and graphs in R?",
  model = "text-embedding-3-small"
)

cosine <- function(a, b) sum(a * b) / (sqrt(sum(a^2)) * sqrt(sum(b^2)))
query_vec <- query_embedding$embedding[[1]]

doc_embeddings |>
  mutate(similarity = vapply(embedding, cosine, numeric(1), b = query_vec)) |>
  arrange(desc(similarity)) |>
  select(text, similarity) |>
  head(3)
```

## Use case: clustering text

Embeddings work well as features for clustering. Here
[`stats::kmeans()`](https://rdrr.io/r/stats/kmeans.html) groups a mix of
programming, food, and sports sentences without any labels:

``` r

texts <- c(
  "Python is great for machine learning",
  "R excels at statistical analysis",
  "JavaScript powers modern web applications",
  "Italian pasta with tomato sauce",
  "Sushi is a popular Japanese dish",
  "French croissants are flaky and buttery",
  "Soccer is the world's most popular sport",
  "Basketball requires speed and agility",
  "Tennis matches can last for hours"
)

cluster_embeddings <- foundry_embed(texts, model = "text-embedding-3-small")
embedding_matrix <- do.call(rbind, cluster_embeddings$embedding)

set.seed(42)
clusters <- kmeans(embedding_matrix, centers = 3, nstart = 10)

cluster_embeddings |>
  mutate(cluster = clusters$cluster) |>
  arrange(cluster) |>
  select(text, cluster)
```

The clusters recover the three topics from the raw text alone.

## Tips for working with embeddings

### Choosing a model

| Model | Dimensions | Notes |
|----|----|----|
| text-embedding-ada-002 | 1,536 | Previous generation, widely used |
| text-embedding-3-small | 1,536 (configurable) | Newer, supports dimension reduction |
| text-embedding-3-large | 3,072 (configurable) | Highest quality, more expensive |

For most use cases, `text-embedding-3-small` balances quality and cost.

### Dimension trade-offs

Higher dimensions capture more nuance but need more storage, take longer
to compare, and may not improve simple tasks. Consider reduced
dimensions (256-512) for large-scale applications where speed matters
more than precision.

### Handling large collections

1.  **Batch processing**: embed documents in batches to respect rate
    limits.
2.  **Caching**: store embeddings in a database rather than regenerating
    them.
3.  **Approximate nearest neighbors**: use libraries like `RcppAnnoy`
    for fast similarity search on large datasets.

``` r

# Example: process a large collection in batches. Not run here.
batch_embed <- function(texts, model, batch_size = 100) {
  n_batches <- ceiling(length(texts) / batch_size)
  results <- vector("list", n_batches)
  for (i in seq_len(n_batches)) {
    start_idx <- (i - 1) * batch_size + 1
    end_idx <- min(i * batch_size, length(texts))
    results[[i]] <- foundry_embed(texts[start_idx:end_idx], model = model)
    Sys.sleep(0.5)
  }
  dplyr::bind_rows(results)
}
```
