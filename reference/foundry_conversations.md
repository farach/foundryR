# Manage Responses API conversations

Create, list, retrieve, update, and delete server-side conversations
used by the Responses API.

## Usage

``` r
foundry_conversation_create(
  metadata = NULL,
  api_key = NULL,
  endpoint = NULL,
  token = NULL,
  project_endpoint = NULL
)

foundry_conversations(
  limit = NULL,
  after = NULL,
  api_key = NULL,
  endpoint = NULL,
  token = NULL,
  project_endpoint = NULL
)

foundry_conversation_get(
  conversation_id,
  api_key = NULL,
  endpoint = NULL,
  token = NULL,
  project_endpoint = NULL
)

foundry_conversation_update(
  conversation_id,
  metadata = NULL,
  api_key = NULL,
  endpoint = NULL,
  token = NULL,
  project_endpoint = NULL
)

foundry_conversation_delete(
  conversation_id,
  api_key = NULL,
  endpoint = NULL,
  token = NULL,
  project_endpoint = NULL
)

foundry_conversation_items(
  conversation_id,
  limit = NULL,
  after = NULL,
  api_key = NULL,
  endpoint = NULL,
  token = NULL,
  project_endpoint = NULL
)

foundry_conversation_items_add(
  conversation_id,
  items,
  api_key = NULL,
  endpoint = NULL,
  token = NULL,
  project_endpoint = NULL
)
```

## Arguments

- metadata:

  List. Optional metadata.

- api_key:

  Character. Optional API key override.

- endpoint:

  Character. A project endpoint URL, accepted for compatibility. A
  resource endpoint is an error because conversations do not exist
  there. Prefer `project_endpoint`.

- token:

  Character. Optional project-scoped bearer token override.

- project_endpoint:

  Character. Optional project endpoint override.

- limit:

  Integer. Optional page size.

- after:

  Character. Optional pagination cursor.

- conversation_id:

  Character. Conversation ID.

- items:

  List. Conversation input items to add.

## Value

Conversation create, list, get, and update functions return
`conversation_id`, `object`, `created_at`, `metadata`, and
`raw_conversation`. Delete returns `conversation_id`, `deleted`, and
`raw_conversation`. Item functions return `item_id`, `type`, `role`,
`content`, and `raw_item`.

## Details

Conversations exist only on a Foundry project endpoint, so these
functions always use one: `project_endpoint` if you pass it, otherwise
the endpoint set with
[`foundry_set_project_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_project_endpoint.md).

## Examples

``` r
# Requires a configured project endpoint and credentials with permission
# to create and delete the conversation.
if (interactive() &&
    nzchar(Sys.getenv("AZURE_FOUNDRY_PROJECT_ENDPOINT"))) {
  conversation <- foundry_conversation_create(
    metadata = list(example = "cran")
  )
  id <- conversation$conversation_id[[1]]
  foundry_conversations(limit = 10)
  foundry_conversation_get(id)
  foundry_conversation_update(id, metadata = list(example = "updated"))
  foundry_conversation_items(id)
  foundry_conversation_delete(id)
}
```
