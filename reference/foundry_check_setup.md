# Check foundryR Setup

Validates your Microsoft Foundry configuration and provides helpful
guidance if anything is missing or misconfigured.

## Usage

``` r
foundry_check_setup(model = NULL, verbose = TRUE)
```

## Arguments

- model:

  Character. Optional deployment name to test. If provided, will make a
  test API call to verify the deployment works.

- verbose:

  Logical. If TRUE (default), prints detailed status messages.

## Value

Invisibly returns a list with configuration status:

- endpoint:

  The configured endpoint URL, or NA if not set.

- project_endpoint:

  The configured project endpoint URL, or NA if not set.

- key_set:

  Logical. TRUE if an API key is configured.

- token_set:

  Logical. TRUE if a bearer token is configured.

- token_provider_set:

  Logical. TRUE if a resource-scoped bearer token provider is
  configured.

- model_tested:

  The deployment name tested, or NA if none.

- api_ok:

  Logical. TRUE if the API test succeeded, NA if not tested.

- all_ok:

  Logical. TRUE if all checks passed.

## Examples

``` r
if (requireNamespace("withr", quietly = TRUE)) {
  withr::with_options(list(foundryR.config_file = tempfile()), {
    withr::with_envvar(c(
      AZURE_FOUNDRY_ENDPOINT = "https://example.openai.azure.com",
      AZURE_FOUNDRY_KEY = "example-key-not-a-secret",
      AZURE_FOUNDRY_TOKEN = "",
      AZURE_OPENAI_TOKEN = ""
    ), {
      status <- foundry_check_setup(verbose = FALSE)
      status$all_ok
    })
  })
}
#> [1] TRUE

if (FALSE) { # \dontrun{
# Requires an Azure deployment, endpoint, and credentials; makes an API call.
foundry_check_setup(model = "my-gpt4")
} # }
```
