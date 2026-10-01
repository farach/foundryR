# Describe a bring-your-own Azure OpenAI resource for groundedness

**\[deprecated\]**

Build the `llm_resource` argument for
[`foundry_groundedness()`](https://farach.github.io/foundryR/reference/foundry_groundedness.md).
Reasoning and correction both rely on an Azure OpenAI GPT-4o deployment
that Content Safety calls on your behalf. The service currently accepts
only GPT-4o versions 0513 and 0806. This bring-your-own-LLM feature is
deprecated and will be removed in a future release.

## Usage

``` r
foundry_llm_resource(endpoint, deployment_name, resource_type = "AzureOpenAI")
```

## Arguments

- endpoint:

  Character. The Azure OpenAI resource endpoint, for example
  `"https://your-openai.openai.azure.com"`.

- deployment_name:

  Character. The Azure OpenAI deployment name to use.

- resource_type:

  Character. The resource type. Only `"AzureOpenAI"` is currently
  supported.

## Value

A named list matching the Content Safety `LLMResource` schema.

## Examples

``` r
foundry_llm_resource(
  endpoint = "https://your-openai.openai.azure.com",
  deployment_name = "gpt-4o"
)
#> Warning: `foundry_llm_resource()` was deprecated in foundryR 1.0.0.
#> ℹ This feature requires an Azure OpenAI GPT-4o deployment (the service
#>   currently accepts only GPT-4o versions 0513 and 0806) and will be removed in
#>   a future release; the core groundedness check (ungrounded detection and
#>   percentage) stays.
#> $resourceType
#> [1] "AzureOpenAI"
#> 
#> $azureOpenAIEndpoint
#> [1] "https://your-openai.openai.azure.com"
#> 
#> $azureOpenAIDeploymentName
#> [1] "gpt-4o"
#> 
```
