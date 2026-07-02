# Wait for a Microsoft Foundry batch to finish

Poll a batch until it reaches a terminal state.

## Usage

``` r
foundry_batch_wait(
  batch_id,
  interval = 60,
  timeout = Inf,
  api_key = NULL,
  token = NULL,
  endpoint_url = NULL,
  api_version = NULL
)
```

## Arguments

- batch_id:

  Character. Batch ID to poll.

- interval:

  Numeric. Seconds between polling attempts.

- timeout:

  Numeric. Maximum seconds to wait. Use `Inf` to wait indefinitely.

- api_key:

  Character. Optional API key override.

- token:

  Character. Optional bearer token override.

- endpoint_url:

  Character. Optional Foundry endpoint override.

- api_version:

  Character. Optional API version query value.

## Value

The final one-row batch tibble.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_batch_wait("batch_abc123", interval = 60)
} # }
```
