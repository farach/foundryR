# List versions of a Foundry agent

List versions of a Foundry agent

## Usage

``` r
foundry_agent_versions(
  name,
  limit = NULL,
  after = NULL,
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = "v1"
)
```

## Arguments

- name:

  Character. Agent name.

- limit:

  Integer. Optional maximum number of agent versions to return.

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

A tibble with one row per agent version.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_agent_versions("france-facts")
} # }
```
