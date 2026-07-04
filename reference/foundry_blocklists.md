# Manage Content Safety text blocklists

Create, list, retrieve, delete, and edit Azure AI Content Safety
blocklists.

## Usage

``` r
foundry_blocklists(endpoint = NULL, api_key = NULL, api_version = "2024-09-01")

foundry_blocklist_create(
  name,
  description = NULL,
  endpoint = NULL,
  api_key = NULL,
  api_version = "2024-09-01"
)

foundry_blocklist_get(
  name,
  endpoint = NULL,
  api_key = NULL,
  api_version = "2024-09-01"
)

foundry_blocklist_delete(
  name,
  endpoint = NULL,
  api_key = NULL,
  api_version = "2024-09-01"
)

foundry_blocklist_items(
  name,
  endpoint = NULL,
  api_key = NULL,
  api_version = "2024-09-01"
)

foundry_blocklist_add_items(
  name,
  items,
  is_regex = FALSE,
  endpoint = NULL,
  api_key = NULL,
  api_version = "2024-09-01"
)

foundry_blocklist_remove_items(
  name,
  item_ids,
  endpoint = NULL,
  api_key = NULL,
  api_version = "2024-09-01"
)
```

## Arguments

- endpoint:

  Character. Optional Content Safety endpoint.

- api_key:

  Character. Optional Content Safety key.

- api_version:

  Character. API version. Defaults to `"2024-09-01"`.

- name:

  Character. Blocklist name.

- description:

  Character. Optional blocklist description.

- items:

  Character vector of blocklist item text values.

- is_regex:

  Logical. Whether added items are regular expressions.

- item_ids:

  Character vector of blocklist item IDs to remove.

## Value

A tibble with blocklist or blocklist-item metadata.

## Examples

``` r
if (interactive() &&
    nzchar(Sys.getenv("AZURE_CONTENT_SAFETY_ENDPOINT")) &&
    nzchar(Sys.getenv("AZURE_CONTENT_SAFETY_KEY"))) {
  foundry_blocklists()
  foundry_blocklist_create("example-blocklist", description = "Example")
  foundry_blocklist_get("example-blocklist")
  items <- foundry_blocklist_add_items("example-blocklist", "blocked phrase")
  foundry_blocklist_items("example-blocklist")
  if (nrow(items) > 0 && !is.na(items$item_id[[1]])) {
    foundry_blocklist_remove_items("example-blocklist", items$item_id)
  }
  foundry_blocklist_delete("example-blocklist")
}
```
