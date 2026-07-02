# Describe a bring-your-own Azure OpenAI resource for groundedness

Build the `llm_resource` argument for
[`foundry_groundedness()`](https://farach.github.io/foundryR/reference/foundry_groundedness.md).
Reasoning and correction both rely on an Azure OpenAI deployment
(typically a provisioned GPT-4o) that Content Safety calls on your
behalf.

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
  deployment_name = "gpt-5-nano"
)
#> $resourceType
#> [1] "AzureOpenAI"
#> 
#> $azureOpenAIEndpoint
#> [1] "https://your-openai.openai.azure.com"
#> 
#> $azureOpenAIDeploymentName
#> [1] "gpt-5-nano"
#> 
```
