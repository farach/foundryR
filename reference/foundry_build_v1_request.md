# Build Azure AI Foundry v1 Request

Internal function to construct httr2 requests for Azure OpenAI in
Microsoft Foundry's v1 data-plane API.

## Usage

``` r
foundry_build_v1_request(
  path,
  body = NULL,
  method = "POST",
  api_key = NULL,
  endpoint = NULL,
  api_version = NULL
)
```

## Arguments

- path:

  Character. The v1 API path, relative to `/openai/v1/`.

- body:

  List. Optional request body.

- method:

  Character. HTTP method. Default: `"POST"`.

- api_key:

  Character. Optional API key override.

- endpoint:

  Character. Optional endpoint override.

- api_version:

  Character. Optional API version query value. Usually not required for
  v1 endpoints.

## Value

An httr2 request object (not yet performed).
