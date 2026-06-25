# Check foundryR Setup

Validates your Azure AI Foundry configuration and provides helpful
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

- key_set:

  Logical. TRUE if an API key is configured.

- token_set:

  Logical. TRUE if a bearer token is configured.

- model_tested:

  The deployment name tested, or NA if none.

- api_ok:

  Logical. TRUE if the API test succeeded, NA if not tested.

- all_ok:

  Logical. TRUE if all checks passed.

## Examples

``` r
if (FALSE) { # \dontrun{
# Check basic configuration
foundry_check_setup()

# Also test a specific deployment
foundry_check_setup(model = "my-gpt4")
} # }
```
