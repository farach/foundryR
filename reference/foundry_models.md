# List or retrieve models available to a Foundry resource

List the models that the Microsoft Foundry v1 data-plane API reports for
your resource, or retrieve metadata for one model. The list covers
models the resource can use, including models you have not deployed, so
it is not a list of your deployments. The `model` argument of
[`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
and other v1 helpers takes a deployment name, which you choose when you
deploy a model; see your deployments in the Foundry portal.

## Usage

``` r
foundry_models(
  model = NULL,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = NULL
)
```

## Arguments

- model:

  Character. Optional model name to retrieve.

- api_key:

  Character. Optional API key override.

- token:

  Character. Optional bearer token override.

- endpoint:

  Character. Optional endpoint override.

- api_version:

  Character. Optional API version query value.

## Value

A tibble with model metadata and the raw model object in a list-column.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a configured Azure endpoint and credentials.
foundry_models()
foundry_models("gpt-5-nano")
} # }
```
