# Set Azure Content Safety API Key

Set or update your Azure Content Safety API key for authentication. The
key can be obtained from the Azure Portal under your Content Safety
resource.

## Usage

``` r
foundry_set_content_safety_key(key = NULL, store = FALSE)
```

## Arguments

- key:

  Character string containing your API key, or NULL to set
  interactively. If NULL in an interactive session, will prompt for
  input.

- store:

  Logical. If `TRUE`, stores the key in foundryR's package-specific user
  configuration file. Default: `FALSE`.

## Value

Invisibly returns TRUE if key was set successfully.

## Examples

``` r
withr::with_envvar(c(AZURE_CONTENT_SAFETY_KEY = NA_character_), {
  foundry_set_content_safety_key("example-key-not-a-secret")
})
#> ✔ Content Safety API key set for current session.
```
