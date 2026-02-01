# Get Image Generation Endpoint

Retrieve the Azure endpoint for image generation.

## Usage

``` r
foundry_get_image_endpoint(required = FALSE)
```

## Arguments

- required:

  Logical. If TRUE and no endpoint is set, throws an error.

## Value

Character string with the endpoint, or NULL if not set and not required.

## Details

Checks `AZURE_FOUNDRY_IMAGE_ENDPOINT` first, then falls back to
`AZURE_FOUNDRY_ENDPOINT`.
