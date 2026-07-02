# List Foundry agents

List Foundry agents

## Usage

``` r
foundry_agents(
  limit = NULL,
  after = NULL,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = "v1"
)
```

## Arguments

- limit:

  Integer. Optional maximum number of agents to return.

- after:

  Character. Optional pagination cursor.

- api_key:

  Character. Optional API key. Falls back to configured auth.

- token:

  Character. Optional bearer token. Falls back to configured auth.

- endpoint:

  Character. Optional project endpoint override.

- api_version:

  Character. API version query value. Defaults to `"v1"`.

## Value

A tibble with one row per agent.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_agents(limit = 20)
} # }
```
