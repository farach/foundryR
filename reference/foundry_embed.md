# Generate Text Embeddings

Generate embedding vectors for one or more text inputs using an Azure AI
Foundry deployed embedding model. Returns a tibble with the input text
and corresponding embedding vectors stored as a list-column.

## Usage

``` r
foundry_embed(
  text,
  model = NULL,
  dimensions = NULL,
  batch_size = 100L,
  api = c("v1", "deployment"),
  api_key = NULL,
  api_version = NULL
)
```

## Arguments

- text:

  Character vector. The text(s) to embed.

- model:

  Character. The deployment name of an embedding model. Defaults to the
  environment variable `AZURE_FOUNDRY_EMBED_MODEL`.

- dimensions:

  Integer. Optional. The number of dimensions for the output embeddings.
  Only supported by some models (e.g., text-embedding-3).

- batch_size:

  Integer. Number of texts to include in each request. Default: 100.

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

- text:

  Character. The original input text.

- embedding:

  List. A numeric vector containing the embedding.

- n_dims:

  Integer. The dimensionality of the embedding.

- .input_idx:

  Integer. Original input index.

- .error:

  Logical. Whether the row failed.

- .error_msg:

  Character. Error message for failed rows.

## Details

**Important**: The `model` parameter must be a deployment of an
**embedding model**, not a chat model. Common embedding models include:

- `text-embedding-ada-002`

- `text-embedding-3-small`

- `text-embedding-3-large`

Chat models (GPT-4, Claude, Llama, etc.) cannot generate embeddings. If
you only have chat models deployed, you'll need to deploy an embedding
model in Azure AI Foundry first.

## Examples

``` r
if (FALSE) { # \dontrun{
# Single text
foundry_embed("Hello, world!", model = "text-embedding-ada-002")

# Multiple texts
texts <- c("Data science is fun", "R is great for statistics")
foundry_embed(texts, model = "text-embedding-ada-002")

# With reduced dimensions (model-dependent)
foundry_embed("Hello", model = "text-embedding-3-small", dimensions = 256)
} # }
```
