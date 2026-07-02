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

A tibble with conversation metadata or conversation items.
