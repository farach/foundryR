# Retrieve a Foundry agent

Retrieve a Foundry agent

## Usage

``` r
foundry_agent_get(
  name,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = "v1"
)
```

## Arguments

- name:

  Character. Agent name.

- api_key:

  Character. Optional API key. Falls back to configured auth.

- token:

  Character. Optional bearer token. Falls back to configured auth.

- endpoint:

  Character. Optional project endpoint override.

- api_version:

  Character. API version query value. Defaults to `"v1"`.

## Value

A one-row tibble describing the agent.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_agent_get("france-facts")
} # }
```
