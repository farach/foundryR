# List evaluations

List evaluations

## Usage

``` r
foundry_evals(
  limit = NULL,
  after = NULL,
  order = NULL,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = NULL,
  project_endpoint = NULL
)
```

## Arguments

- limit:

  Integer. Optional maximum number of evaluations to return.

- after:

  Character. Optional pagination cursor.

- order:

  Character. Optional sort order, `"asc"` or `"desc"`.

- api_key:

  Character. Optional API key. Falls back to configured auth.

- token:

  Character. Optional bearer token. Falls back to configured auth.

- endpoint:

  Character. Optional resource endpoint. Supplying it selects the
  resource-scoped Evals route (`<resource>/openai/v1/evals`). Supply at
  most one of `endpoint` and `project_endpoint`.

- api_version:

  Character. Optional `api-version` query value. The Foundry v1 evals
  surface is path-versioned, so this is usually left `NULL`.

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

A tibble with one row per evaluation.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a configured Azure endpoint and credentials with evals API access.
foundry_evals(limit = 10)
} # }
```
