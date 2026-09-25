# Getting started with foundryR

## What you need from Azure

foundryR talks to deployed Azure OpenAI resources and Microsoft Foundry
(formerly Azure AI Foundry) projects. Before writing R code, create or
identify:

1.  An Azure OpenAI resource or Microsoft Foundry project with an OpenAI
    endpoint.
2.  At least one chat or Responses API deployment, for example
    `gpt-5-nano`.
3.  An embedding deployment, for example `text-embedding-3-small`, if
    you plan to use embeddings.
4.  A Content Safety resource if you plan to use moderation,
    groundedness, or prompt-shield checks.
5.  Either API keys or a Microsoft Entra ID token.

In the Azure portal, open your Azure OpenAI resource, then use **Keys
and Endpoint** to copy the endpoint URL and an API key. In the Foundry
portal, use the deployments page to create model deployments and record
their deployment names.

> **Deployment name vs base model name**
>
> The value you pass to `model =` is the deployment name you chose in
> Azure, not necessarily the base model name. If you deploy base model
> `gpt-5-nano` with deployment name `my-gpt4`, use `model = "my-gpt4"`
> in foundryR. The same rule applies to embedding deployments.

## Install foundryR

Install the released version from CRAN:

``` r

install.packages("foundryR")
```

To try unreleased changes, install the development version from GitHub:

``` r

# install.packages("pak")
pak::pak("farach/foundryR")
```

## Configure credentials

Set credentials for the current R session. Credential setup is shown but
not run when building this vignette:

``` r

library(foundryR)

foundry_set_endpoint(Sys.getenv("AZURE_FOUNDRY_ENDPOINT"))
foundry_set_key("your-api-key")
```

For persistent local configuration in your own workflow, `store = TRUE`
uses the package configuration file under
`tools::R_user_dir("foundryR", "config")` unless you set the
`foundryR.config_file` option. It does not modify `.Renviron`. The file
is plain text, so prefer session-only credentials or refreshable token
providers for production use.

This demonstration instead uses a temporary file and placeholder values,
then removes the file and restores the previous options and environment
variables:

``` r

local({
  config_file <- tempfile("foundryR-config-", fileext = ".json")
  old_options <- options(foundryR.config_file = config_file)
  old_env <- Sys.getenv(
    c("AZURE_FOUNDRY_ENDPOINT", "AZURE_FOUNDRY_KEY"),
    unset = NA_character_
  )
  on.exit({
    options(old_options)
    Sys.unsetenv(names(old_env)[is.na(old_env)])
    keep <- !is.na(old_env)
    if (any(keep)) {
      do.call(Sys.setenv, as.list(old_env[keep]))
    }
    unlink(config_file)
  }, add = TRUE)

  foundry_set_endpoint("https://example.openai.azure.com", store = TRUE)
  foundry_set_key("example-key-not-a-secret", store = TRUE)
})
```

You can also edit your chosen `.Renviron` file manually with a text
editor. The vignette does not open an editor or write this file. Add
values like these, then restart R:

``` text
AZURE_FOUNDRY_ENDPOINT=https://<resource-name>.openai.azure.com
AZURE_FOUNDRY_KEY=your-api-key
AZURE_FOUNDRY_MODEL=my-gpt4
AZURE_FOUNDRY_EMBED_MODEL=my-embedding-deployment
```

## Keyless authentication with Microsoft Entra ID

API keys are convenient for local testing. For enterprise environments
that already use service principals, managed identity, or Azure
role-based access control, use a Microsoft Entra ID bearer token:

``` r

foundry_set_token("your-entra-token")
```

foundryR sends the token in the `Authorization` header. If both a token
and an API key are configured, the token takes precedence for supported
calls.

## Validate setup

These checks contact your configured Azure resource and are not run
during rendering.

``` r

foundry_check_setup()
```

Test a specific deployment:

``` r

foundry_check_setup(model = "gpt-5-nano")
```

If you need to see deployments exposed by the v1 model metadata
endpoint, use:

``` r

models <- foundry_models()
models[, c("id", "owned_by")]
```

## First Responses API call

The Responses API is the newer v1 surface for stateful turns, strict
structured outputs, tools, and richer token metadata. The examples below
omit `model =`, so foundryR reads the deployment from
`AZURE_FOUNDRY_MODEL`; pass `model =` to target a specific deployment.

``` r

library(foundryR)

response <- foundry_response("Answer in one sentence: what is R?")

response$output_text
#> [1] "R is a free, open-source programming language and environment for statistical computing and graphics, widely used for data analysis and visualization."
```

Chain a follow-up turn with `previous_response_id`:

``` r

follow_up <- foundry_response(
  "Explain why that matters for data analysis in one sentence.",
  previous_response_id = response$response_id
)

follow_up$output_text
#> [1] "Because R<U+2019>s free, open-source nature plus its extensive ecosystem of packages for data manipulation, statistics, modeling, and high-quality graphics enables powerful, reproducible data analysis and visualization without licensing constraints."
```

## First strict extraction

Use JSON Schema when you need model output to become analyzable columns:

``` r

schema <- list(
  type = "object",
  properties = list(
    sentiment = list(type = "string", enum = c("positive", "negative", "neutral")),
    topic = list(type = "string")
  ),
  required = c("sentiment", "topic"),
  additionalProperties = FALSE
)

foundry_extract(
  c("The tutorial was clear.", "I needed more examples."),
  schema = schema
)
#> # A tibble: 2 × 10
#>   .input_idx .input_text     .response_id .status .output_text .error .error_msg
#>        <int> <chr>           <chr>        <chr>   <chr>        <lgl>  <chr>     
#> 1          1 The tutorial w… resp_0e928a… comple… "{\"sentime… FALSE  NA        
#> 2          2 I needed more … resp_01f233… comple… "{\"sentime… FALSE  NA        
#> # ℹ 3 more variables: raw_response <list>, sentiment <chr>, topic <chr>
```

[`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
uses strict JSON Schema mode by default for supported models.

## First embedding

Embeddings convert text to numeric vectors for clustering, semantic
search, near-duplicate detection, and downstream models:

``` r

texts <- c(
  "The tutorial was clear.",
  "The lecture needed more examples.",
  "The assignment instructions were easy to follow."
)

embeddings <- foundry_embed(texts, model = "text-embedding-3-small")
foundry_similarity(embeddings)
#> # A tibble: 3 × 3
#>   text_1                            text_2                            similarity
#>   <chr>                             <chr>                                  <dbl>
#> 1 The tutorial was clear.           The assignment instructions were…      0.580
#> 2 The tutorial was clear.           The lecture needed more examples.      0.337
#> 3 The lecture needed more examples. The assignment instructions were…      0.290
```

## Configure Content Safety

Content Safety uses a separate Azure AI Content Safety resource. In the
Azure portal, create an Azure AI Content Safety resource, open **Keys
and Endpoint**, then configure foundryR:

``` r

foundry_set_content_safety_endpoint(Sys.getenv("AZURE_CONTENT_SAFETY_ENDPOINT"))
foundry_set_content_safety_key("your-content-safety-key")
```

Use groundedness and shields as auditable safety gates:

``` r

source <- "The program enrolled 82 students in 2026."
answer <- "The program enrolled 82 students in 2026."

grounded <- foundry_groundedness(
  text = answer,
  grounding_sources = source,
  query = "How many students enrolled?",
  task = "QnA"
)

shield <- foundry_shield(user_prompt = "Summarize this document.")

grounded
#> # A tibble: 1 × 6
#>   grounded grounded_pct ungrounded_pct ungrounded_segments ungrounded_reasons
#>   <lgl>           <dbl>          <int> <list>              <list>            
#> 1 TRUE                1              0 <chr [0]>           <chr [0]>         
#> # ℹ 1 more variable: correction_text <chr>
shield
#> # A tibble: 1 × 3
#>   source      content                  attack_detected
#>   <chr>       <chr>                    <lgl>          
#> 1 user_prompt Summarize this document. FALSE
```

Most foundryR calls stay within your Azure OpenAI or Content Safety
resources. Web search is different. Microsoft documents that Grounding
with Bing can send data outside the compliance and geographic boundary
and can incur separate costs. Do not send secrets or regulated data to
web-search prompts.

## Chat completions

Chat completions are still available for simple assistant replies:

``` r

foundry_chat("Answer in one sentence: what is the tidyverse?")
#> # A tibble: 1 × 9
#>   role      content          model finish_reason prompt_tokens completion_tokens
#>   <chr>     <chr>            <chr> <chr>                 <int>             <int>
#> 1 assistant The tidyverse i… gpt-… stop                     17               312
#> # ℹ 3 more variables: reasoning_tokens <int>, cached_input_tokens <int>,
#> #   total_tokens <int>
```

For interactive streaming chat and chat-first agent workflows, use
ellmer.

## Next steps

- [`vignette("foundryr-vs-ellmer")`](https://farach.github.io/foundryR/articles/foundryr-vs-ellmer.md)
  compares foundryR with ellmer.
- [`vignette("annotation-workflow")`](https://farach.github.io/foundryR/articles/annotation-workflow.md)
  shows extract, batch, embed, and validate.
- [`vignette("responses-api")`](https://farach.github.io/foundryR/articles/responses-api.md)
  covers Responses API tools and web search.
- [`vignette("content-safety")`](https://farach.github.io/foundryR/articles/content-safety.md)
  covers moderation, groundedness, and shields.
- [`vignette("tidymodels")`](https://farach.github.io/foundryR/articles/tidymodels.md)
  covers
  [`step_foundry_embed()`](https://farach.github.io/foundryR/reference/step_foundry_embed.md).
