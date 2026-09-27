# Define an evaluation run data source

Point an evaluation run at its rows. Three shapes are supported:

## Usage

``` r
foundry_eval_run_data(
  file_id = NULL,
  content = NULL,
  target = NULL,
  input_messages = NULL,
  response_ids = NULL
)
```

## Arguments

- file_id:

  Character. ID of a JSONL file uploaded with
  [`foundry_file_upload()`](https://farach.github.io/foundryR/reference/foundry_file_upload.md).

- content:

  List. Inline rows, each a list with an `item` element (and an optional
  `sample` element).

- target:

  Optional target that generates a response for each row: a model
  deployment name (character), an agent reference from
  [`foundry_agent_reference()`](https://farach.github.io/foundryR/reference/foundry_agent_reference.md)
  or
  [`foundry_agent_create()`](https://farach.github.io/foundryR/reference/foundry_agent_create.md),
  or a complete target list such as
  `list(type = "azure_ai_model", model = "gpt-5-mini", sampling_params = list(max_completion_tokens = 2048))`.

- input_messages:

  Required with `target`. Either a single template string sent as the
  user message, for example `"{{item.query}}"`, or a complete Foundry
  `input_messages` list.

- response_ids:

  Character vector of stored response IDs (for example the `response_id`
  column returned by
  [`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)).
  Cannot be combined with the other arguments.

## Value

A named list describing a run data source, for use in
[`foundry_eval_run_create()`](https://farach.github.io/foundryR/reference/foundry_eval_run_create.md).

## Details

- **Dataset rows** (`type = "jsonl"`): supply exactly one of `file_id`
  or `content`. Graders read existing fields with `{{item.<field>}}`.

- **Target generation** (`type = "azure_ai_target_completions"`): also
  supply `target` and `input_messages`. Microsoft Foundry sends each row
  to a model deployment or agent and graders read the generated output
  with `{{sample.output_text}}` or, for agents,
  `{{sample.output_items}}` (structured output including tool calls).

- **Stored responses** (`type = "azure_ai_responses"`): supply only
  `response_ids`. Foundry retrieves each stored response and graders
  score it. Pair it with
  `foundry_eval_data_config(type = "azure_ai_source", scenario = "responses")`.

Target and stored-response runs exist only on a Foundry project
endpoint.
[`foundry_eval_run_create()`](https://farach.github.io/foundryR/reference/foundry_eval_run_create.md)
and
[`foundry_evaluate()`](https://farach.github.io/foundryR/reference/foundry_evaluate.md)
use the configured project endpoint for them and say so.

## Examples

``` r
foundry_eval_run_data(file_id = "file-abc123")
#> $type
#> [1] "jsonl"
#> 
#> $source
#> $source$type
#> [1] "file_id"
#> 
#> $source$id
#> [1] "file-abc123"
#> 
#> 

foundry_eval_run_data(content = list(
  list(item = list(question = "2+2?", answer = "4"))
))
#> $type
#> [1] "jsonl"
#> 
#> $source
#> $source$type
#> [1] "file_content"
#> 
#> $source$content
#> $source$content[[1]]
#> $source$content[[1]]$item
#> $source$content[[1]]$item$question
#> [1] "2+2?"
#> 
#> $source$content[[1]]$item$answer
#> [1] "4"
#> 
#> 
#> 
#> 
#> 

foundry_eval_run_data(
  content = list(list(item = list(query = "What is R?"))),
  target = "gpt-5-mini",
  input_messages = "{{item.query}}"
)
#> $type
#> [1] "azure_ai_target_completions"
#> 
#> $source
#> $source$type
#> [1] "file_content"
#> 
#> $source$content
#> $source$content[[1]]
#> $source$content[[1]]$item
#> $source$content[[1]]$item$query
#> [1] "What is R?"
#> 
#> 
#> 
#> 
#> 
#> $input_messages
#> $input_messages$type
#> [1] "template"
#> 
#> $input_messages$template
#> $input_messages$template[[1]]
#> $input_messages$template[[1]]$type
#> [1] "message"
#> 
#> $input_messages$template[[1]]$role
#> [1] "user"
#> 
#> $input_messages$template[[1]]$content
#> $input_messages$template[[1]]$content$type
#> [1] "input_text"
#> 
#> $input_messages$template[[1]]$content$text
#> [1] "{{item.query}}"
#> 
#> 
#> 
#> 
#> 
#> $target
#> $target$type
#> [1] "azure_ai_model"
#> 
#> $target$model
#> [1] "gpt-5-mini"
#> 
#> 

foundry_eval_run_data(response_ids = c("resp_abc123", "resp_def456"))
#> $type
#> [1] "azure_ai_responses"
#> 
#> $item_generation_params
#> $item_generation_params$type
#> [1] "response_retrieval"
#> 
#> $item_generation_params$data_mapping
#> $item_generation_params$data_mapping$response_id
#> [1] "{{item.resp_id}}"
#> 
#> 
#> $item_generation_params$source
#> $item_generation_params$source$type
#> [1] "file_content"
#> 
#> $item_generation_params$source$content
#> $item_generation_params$source$content[[1]]
#> $item_generation_params$source$content[[1]]$item
#> $item_generation_params$source$content[[1]]$item$resp_id
#> [1] "resp_abc123"
#> 
#> 
#> 
#> $item_generation_params$source$content[[2]]
#> $item_generation_params$source$content[[2]]$item
#> $item_generation_params$source$content[[2]]$item$resp_id
#> [1] "resp_def456"
#> 
#> 
#> 
#> 
#> 
#> 
```
