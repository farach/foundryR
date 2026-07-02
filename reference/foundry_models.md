# List or retrieve available model deployments

List model deployments available through the Microsoft Foundry v1
data-plane API, or retrieve metadata for one deployment by name. Use the
deployment name shown in the Foundry portal as the `model` value in
[`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
and other v1 helpers.

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

  Character. Optional deployment name to retrieve.

- api_key:

  Character. Optional API key override.

- token:

  Character. Optional bearer token override.

- endpoint:

  Character. Optional endpoint override.

- api_version:

  Character. Optional API version query value.

## Value

A tibble with model or deployment metadata and the raw model object in a
list-column.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_models()
foundry_models("gpt-5.5")
} # }
```
