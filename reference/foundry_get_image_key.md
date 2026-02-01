# Get Image Generation API Key

Retrieve the API key for image generation.

## Usage

``` r
foundry_get_image_key(key = NULL, required = FALSE)
```

## Arguments

- key:

  Character. Optional key to use directly instead of environment
  variable.

- required:

  Logical. If TRUE and no key is found, throws an error.

## Value

Character string with the API key, or NULL if not found and not
required.

## Details

Checks in order: provided key, `AZURE_FOUNDRY_IMAGE_KEY`,
`AZURE_FOUNDRY_KEY`.
