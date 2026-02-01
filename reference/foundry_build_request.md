# Build Azure AI Foundry Request

Internal function to construct httr2 requests for Azure AI Foundry API.

## Usage

``` r
foundry_build_request(
  deployment,
  endpoint_path,
  body,
  api_key = NULL,
  api_version = NULL
)
```

## Arguments

- deployment:

  Character. The deployment name.

- endpoint_path:

  Character. The API endpoint path (e.g., "chat/completions").

- body:

  List. The request body.

- api_key:

  Character. Optional API key override.

- api_version:

  Character. Optional API version override.

## Value

An httr2 request object (not yet performed).
