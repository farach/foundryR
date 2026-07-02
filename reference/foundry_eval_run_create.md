# Create an evaluation run

Run an evaluation against a data source. The eval's `testing_criteria`
are applied to every row in the source.

## Usage

``` r
foundry_eval_run_create(
  eval_id,
  data_source,
  name = NULL,
  metadata = NULL,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = NULL
)
```

## Arguments

- eval_id:

  Character. Evaluation ID to run.

- data_source:

  List. A run data source from
  [`foundry_eval_run_data()`](https://farach.github.io/foundryR/reference/foundry_eval_run_data.md).

- name:

  Character. Optional run name.

- metadata:

  List. Optional metadata attached to the run.

- api_key:

  Character. Optional API key. Falls back to configured auth.

- token:

  Character. Optional bearer token. Falls back to configured auth.

- endpoint:

  Character. Optional endpoint override.

- api_version:

  Character. Optional `api-version` query value. The Foundry v1 evals
  surface is path-versioned, so this is usually left `NULL`.

## Value

A one-row tibble describing the created run.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_eval_run_create(
  eval_id = "eval_abc123",
  data_source = foundry_eval_run_data(file_id = "file-xyz"),
  name = "nightly"
)
} # }
```
