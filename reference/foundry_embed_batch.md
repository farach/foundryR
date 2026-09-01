# Generate Text Embeddings in Parallel Batches

Generate embedding vectors for a large collection of texts using
parallel batch processing. This function is optimized for
high-throughput embedding generation, using
[`httr2::req_perform_parallel()`](https://httr2.r-lib.org/reference/req_perform_parallel.html)
to process multiple batches concurrently while tracking errors
gracefully.

## Usage

``` r
foundry_embed_batch(
  text,
  model = NULL,
  dimensions = NULL,
  batch_size = 100L,
  max_active = 2L,
  progress = TRUE,
  api = c("v1", "deployment"),
  api_key = NULL,
  api_version = NULL
)
```

## Arguments

- text:

  Character vector. The texts to embed.

- model:

  Character. The deployment name of an embedding model. Defaults to the
  environment variable `AZURE_FOUNDRY_EMBED_MODEL`.

- dimensions:

  Integer. Optional. The number of dimensions for the output embeddings.
  Only supported by some models (e.g., text-embedding-3).

- batch_size:

  Integer. Number of texts to include in each batch request. Default:
  100.

- max_active:

  Integer. Maximum number of concurrent requests. Default: 2.

- progress:

  Logical. Whether to show a progress bar. Default: TRUE.

- api:

  Character. Endpoint style. `"v1"` (default) sends requests to
  `/openai/v1/embeddings` with `model` in the JSON body. `"deployment"`
  keeps the legacy deployment-path endpoint.

- api_key:

  Character. Optional API key override.

- api_version:

  Character. Optional API version override.

## Value

A tibble with columns:

- .input_idx:

  Integer. The original index of each text in the input vector.

- text:

  Character. The original input text.

- embedding:

  List. A numeric vector containing the embedding, or NULL if failed.
  May contain multiple embeddings per batch response.

- n_dims:

  Integer. The dimensionality of the embedding, or NA if failed.

- .error:

  Logical. TRUE if the request for this text failed.

- .error_msg:

  Character. Error message if failed, NA otherwise.

- raw_response:

  List. Raw parsed response payload for successful rows, or NULL for
  failed rows.

## Examples

``` r
if (FALSE) { # \dontrun{
# Embed many texts in parallel
texts <- c("Hello, world!", "Data science is fun", "R is great")
embeddings <- foundry_embed_batch(texts, model = "text-embedding-ada-002")

# With custom batch size and concurrency
large_texts <- rep("Sample text", 1000)
embeddings <- foundry_embed_batch(
  large_texts,
  model = "text-embedding-ada-002",
  batch_size = 50,
  max_active = 2
)

# Filter successful embeddings
successful <- embeddings[!embeddings$.error, ]

# Check for errors
failed <- embeddings[embeddings$.error, ]
if (nrow(failed) > 0) {
  message("Some embeddings failed:")
  print(failed[, c(".input_idx", ".error_msg")])
}
} # }
```
