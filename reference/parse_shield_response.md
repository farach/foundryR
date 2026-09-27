# Parse Shield API Response

Internal function to parse the Shield API response into a tidy tibble.

## Usage

``` r
parse_shield_response(
  result,
  user_prompt,
  documents,
  document_indices = seq_along(documents)
)
```

## Arguments

- result:

  List. The parsed JSON response from the API.

- user_prompt:

  Character. The original user prompt.

- documents:

  Character vector. The original documents (or NULL).

- document_indices:

  Integer vector. Original indices for `documents`.

## Value

A tibble with source, content, and attack_detected columns.
