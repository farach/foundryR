# Moderate image content

Analyze an image for harmful content with Azure AI Content Safety.
`image` can be a local file path or an HTTPS Azure Blob Storage URL.

## Usage

``` r
foundry_moderate_image(
  image,
  categories = c("Hate", "Sexual", "SelfHarm", "Violence"),
  output_type = c("FourSeverityLevels", "EightSeverityLevels"),
  endpoint = NULL,
  api_key = NULL,
  api_version = "2024-09-01"
)
```

## Arguments

- image:

  Character. Local image path or HTTPS Azure Blob Storage URL.

- categories:

  Character vector of harm categories.

- output_type:

  Character. Severity level granularity.

- endpoint:

  Character. Optional Content Safety endpoint.

- api_key:

  Character. Optional Content Safety key.

- api_version:

  Character. API version. Defaults to `"2024-09-01"`.

## Value

A tibble with one row per category and raw response payloads.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_moderate_image("image.png")
} # }
```
