# Manage Azure OpenAI vector stores

Create, list, retrieve, update, delete, and search hosted vector stores.

## Usage

``` r
foundry_vector_store_create(
  name,
  file_ids = NULL,
  expires_after_days = NULL,
  metadata = NULL,
  api_key = NULL,
  endpoint = NULL
)

foundry_vector_stores(
  limit = NULL,
  after = NULL,
  api_key = NULL,
  endpoint = NULL
)

foundry_vector_store_get(vector_store_id, api_key = NULL, endpoint = NULL)

foundry_vector_store_modify(
  vector_store_id,
  name = NULL,
  metadata = NULL,
  expires_after_days = NULL,
  api_key = NULL,
  endpoint = NULL
)

foundry_vector_store_delete(vector_store_id, api_key = NULL, endpoint = NULL)

foundry_vector_store_files(
  vector_store_id,
  limit = NULL,
  after = NULL,
  api_key = NULL,
  endpoint = NULL
)

foundry_vector_store_file_add(
  vector_store_id,
  file_id,
  api_key = NULL,
  endpoint = NULL
)

foundry_vector_store_file_remove(
  vector_store_id,
  file_id,
  api_key = NULL,
  endpoint = NULL
)

foundry_vector_store_file_batch(
  vector_store_id,
  file_ids,
  api_key = NULL,
  endpoint = NULL
)

foundry_vector_search(
  vector_store_id,
  query,
  top_k = 10L,
  filters = NULL,
  rewrite_query = FALSE,
  api_key = NULL,
  endpoint = NULL
)
```

## Arguments

- name:

  Character. Vector store name.

- file_ids:

  Character vector of uploaded file IDs.

- expires_after_days:

  Integer. Optional expiry in days from last active time.

- metadata:

  List. Optional metadata.

- api_key:

  Character. Optional API key override.

- endpoint:

  Character. Optional endpoint override.

- limit:

  Integer. Optional page size.

- after:

  Character. Optional pagination cursor.

- vector_store_id:

  Character. Vector store ID.

- file_id:

  Character. Uploaded file ID.

- query:

  Character. Search query.

- top_k:

  Integer. Maximum search results.

- filters:

  List. Optional search filters.

- rewrite_query:

  Logical. Whether the service may rewrite the query.

## Value

A tibble with vector store, file, or search-result metadata.
