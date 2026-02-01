# Parse Chat Completion Response

Internal function to parse chat completion API response into a tibble.

## Usage

``` r
foundry_parse_chat_response(result, model)
```

## Arguments

- result:

  List. The parsed JSON response.

- model:

  Character. The model/deployment name.

## Value

A tibble with chat response data.
