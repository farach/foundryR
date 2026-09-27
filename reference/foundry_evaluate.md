# Evaluate a data frame with Microsoft Foundry cloud evaluation

**\[experimental\]**

Run a Microsoft Foundry cloud evaluation from a data frame and get the
grader results back joined to your rows. `foundry_evaluate()` creates
the evaluation, starts a run, waits for it, and returns one row per
input row and grader, so pass rates, failure reasons, and generated
responses can be summarised with ordinary data-frame tools.

There are two modes:

- **Grade existing columns** (`target = NULL`). Graders read fields of
  `data` with `{{item.<column>}}`, for example a `response` column that
  your application already produced.

- **Generate, then grade** (`target` supplied). Foundry sends `input`
  for each row to a model deployment or agent, then graders read the
  generated output with `{{sample.output_text}}` or, for agents,
  `{{sample.output_items}}` (structured output including tool calls).

## Usage

``` r
foundry_evaluate(
  data,
  graders = NULL,
  target = NULL,
  input = NULL,
  instructions = NULL,
  sampling_params = NULL,
  item_schema = NULL,
  eval_id = NULL,
  name = NULL,
  metadata = NULL,
  wait = TRUE,
  interval = 10,
  timeout = Inf,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  project_endpoint = NULL
)
```

## Arguments

- data:

  Data frame with one row per test case. Every column is sent as a field
  of the evaluation item.

- graders:

  A grader from `foundry_grader_*()` or a list of graders. Required
  unless `eval_id` is supplied.

- target:

  Optional target that generates a response for each row: a model
  deployment name, an agent reference from
  [`foundry_agent_reference()`](https://farach.github.io/foundryR/reference/foundry_agent_reference.md)
  (pin `version` for reproducible runs), a one-row agent tibble from
  [`foundry_agent_create()`](https://farach.github.io/foundryR/reference/foundry_agent_create.md),
  or a complete target list (see
  [`foundry_eval_run_data()`](https://farach.github.io/foundryR/reference/foundry_eval_run_data.md)).

- input:

  Required with `target`. The user message: either the name of a column
  in `data`, sent as `{{item.<column>}}`, or a template string such as
  `"Classify this comment: {{item.comment}}"`.

- instructions:

  Optional developer message sent before `input` when a target generates
  responses.

- sampling_params:

  Optional named list of sampling parameters for a model target, for
  example `list(max_completion_tokens = 2048)`.

- item_schema:

  Optional JSON Schema list describing every column of `data`. Required
  when `data` has list columns. The reserved `foundryr_row_id` field is
  added automatically.

- eval_id:

  Optional ID of an evaluation created by `foundry_evaluate()`. A new
  run is added to it, reusing its graders, so runs can be compared in
  the Foundry portal. `graders` and `item_schema` must then be `NULL`.

- name:

  Optional name for the evaluation and the run. Defaults to
  `"foundryR evaluation <UTC date-time>"`, because target runs need a
  name.

- metadata:

  Optional named list of metadata attached to the evaluation and the
  run.

- wait:

  Logical. If `TRUE` (the default), wait for the run and return the
  joined results. If `FALSE`, return the run immediately; collect it
  later with
  [`foundry_eval_run_wait()`](https://farach.github.io/foundryR/reference/foundry_eval_run_wait.md)
  and
  [`foundry_eval_run_results()`](https://farach.github.io/foundryR/reference/foundry_eval_run_results.md).

- interval:

  Numeric. Seconds between status checks while waiting.

- timeout:

  Numeric. Maximum seconds to wait. Use `Inf` to wait indefinitely. On
  timeout the run keeps going; resume with
  [`foundry_eval_run_wait()`](https://farach.github.io/foundryR/reference/foundry_eval_run_wait.md).

- api_key:

  Character. Optional API key. Falls back to configured auth.

- token:

  Character. Optional bearer token. Falls back to configured auth.

- endpoint:

  Character. Optional resource endpoint. Supplying it selects the
  resource-scoped Evals route (`<resource>/openai/v1/evals`). Supply at
  most one of `endpoint` and `project_endpoint`.

- project_endpoint:

  Character. Optional Microsoft Foundry project endpoint, such as
  `"https://<account>.services.ai.azure.com/api/projects/<project>"`.
  Supplying it selects the project-scoped Evals route
  (`<project>/openai/v1/evals`), which needs a Microsoft Entra ID token:
  the service answers HTTP 403 to API keys there. Without it, evaluation
  calls use the resource endpoint, as in foundryR 0.1.0, unless
  [`foundry_set_route()`](https://farach.github.io/foundryR/reference/foundry_set_route.md)
  selected the project or the call needs a feature that exists only on a
  project endpoint: built-in `azure_ai_evaluator` graders, model or
  agent targets, or stored responses. Those calls use the endpoint set
  with
  [`foundry_set_project_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_project_endpoint.md)
  and print a message. Evaluations created on the project endpoint are
  not visible from the resource endpoint, so pass `project_endpoint` (or
  set the route) when you look them up later.

## Value

With `wait = TRUE`, the tibble returned by
[`foundry_eval_run_results()`](https://farach.github.io/foundryR/reference/foundry_eval_run_results.md).
With `wait = FALSE`, the one-row run tibble returned by
[`foundry_eval_run_create()`](https://farach.github.io/foundryR/reference/foundry_eval_run_create.md).

## Details

`foundry_evaluate()` creates a persistent evaluation and run in your
project; both stay visible in the Foundry portal and nothing is deleted
afterwards. Target generation and model-graded evaluators consume tokens
on your deployments.

Evaluations that only use OpenAI graders on existing columns run on the
resource endpoint by default. Built-in evaluators and model or agent
targets exist only on a Foundry project endpoint, so those evaluations
use the endpoint set with
[`foundry_set_project_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_project_endpoint.md)
and print a message. Pass the same `project_endpoint` (or call
[`foundry_set_route()`](https://farach.github.io/foundryR/reference/foundry_set_route.md))
when you look the evaluation up later.

Every item sent to the service carries a reserved `foundryr_row_id`
field (`"row-1"`, `"row-2"`, ...), and results are matched to rows of
`data` only through that field as the service echoes it back. Results
are never matched by position. Column types map to JSON Schema types
(character and factor to `string`, logical to `boolean`, integer to
`integer`, finite double to `number`, list columns of named lists to
`object`, other list columns to `array`). Missing values are rejected
rather than silently dropped; recode them first. Supply `item_schema`
when a list column needs a more specific schema.

In target runs, a character column that holds only numeric-looking
values (such as ZIP codes) triggers a warning, because the service can
convert such strings to numbers and then reject them.

Before anything is created, every `{{item.<field>}}` reference in the
graders and `input` is checked against the columns of `data`.

## See also

[`foundry_eval_run_results()`](https://farach.github.io/foundryR/reference/foundry_eval_run_results.md)
for the result columns,
[`vignette("evaluations", package = "foundryR")`](https://farach.github.io/foundryR/articles/evaluations.md)
for a worked example.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a Foundry project endpoint and credentials, plus deployments for
# the target and the judge model.
tickets <- data.frame(
  ticket = c("I was charged twice this month.", "The app crashes on login."),
  label = c("billing", "technical")
)

foundry_evaluate(
  tickets,
  graders = foundry_grader_string_check(
    name = "label-match",
    input = "{{sample.output_text}}",
    reference = "{{item.label}}",
    # "ilike" passes when the output contains the label, ignoring case.
    operation = "ilike"
  ),
  target = "gpt-5-mini",
  input = "ticket",
  instructions = "Reply with one word: billing, technical, or account."
)
} # }
```
