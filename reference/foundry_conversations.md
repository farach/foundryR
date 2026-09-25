# Manage Responses API conversations

Create, list, retrieve, update, and delete server-side conversations
used by the Responses API.

## Usage

``` r
foundry_conversation_create(metadata = NULL, api_key = NULL, endpoint = NULL)

foundry_conversations(
  limit = NULL,
  after = NULL,
  api_key = NULL,
  endpoint = NULL
)

foundry_conversation_get(conversation_id, api_key = NULL, endpoint = NULL)

foundry_conversation_update(
  conversation_id,
  metadata = NULL,
  api_key = NULL,
  endpoint = NULL
)

foundry_conversation_delete(conversation_id, api_key = NULL, endpoint = NULL)

foundry_conversation_items(
  conversation_id,
  limit = NULL,
  after = NULL,
  api_key = NULL,
  endpoint = NULL
)

foundry_conversation_items_add(
  conversation_id,
  items,
  api_key = NULL,
  endpoint = NULL
)
```

## Arguments

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

## Examples

``` r
# Requires a configured Azure endpoint and credentials with permission
# to create and delete the example conversation.
if (interactive() &&
    nzchar(Sys.getenv("AZURE_FOUNDRY_ENDPOINT")) &&
    nzchar(Sys.getenv("AZURE_FOUNDRY_KEY"))) {
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
