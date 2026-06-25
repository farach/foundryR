# Parse Image Generation Response

Internal function to parse image generation API response into a tibble.

## Usage

``` r
foundry_parse_image_response(
  result,
  original_prompt,
  response_format = NULL,
  output_format = NULL
)
```

## Arguments

- result:

  List. The parsed JSON response.

- original_prompt:

  Character. The original prompt provided.

- response_format:

  Character. The response format requested.

## Value

A tibble with image response data.
