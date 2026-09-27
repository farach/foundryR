# Get started with foundryR

Work through this article once before the task-specific ones. It sets up
credentials, gets one response, extracts two fields from course
comments, and compares three short texts by embedding. Calls to Azure
show output recorded from a live run, and setup code is shown but not
run.

## Install

Install the released package from CRAN:

``` r

install.packages("foundryR")
```

The development version on GitHub has the newest fixes.

``` r

# install.packages("pak")
pak::pak("farach/foundryR")
```

## Configure credentials

For API-key authentication, store the resource endpoint and key once:

``` r

library(foundryR)
foundry_set_endpoint(Sys.getenv("AZURE_FOUNDRY_ENDPOINT"), store = TRUE)
foundry_set_key("your-api-key", store = TRUE)
```

`store = TRUE` writes package settings under
`tools::R_user_dir("foundryR", "config")`; the file is plain text, so
use session-only credentials or a refreshable token provider when that
fits your security policy.

Microsoft Entra ID uses a token provider instead of a static key.

``` r

foundry_set_endpoint(Sys.getenv("AZURE_FOUNDRY_ENDPOINT"), store = TRUE)
foundry_set_token_provider(foundry_token_azure_cli(), scope = "resource")
foundry_set_token_provider(foundry_token_azure_cli("https://ai.azure.com"), scope = "project")
```

The resource token uses the Cognitive Services audience. The project
token uses the `https://ai.azure.com` audience. A provider is a function
that asks the Azure CLI for a fresh token when the cached one is about
to expire, so it lasts for the R session rather than being stored; put
the two provider lines in your project’s `.Rprofile` if you want them
every session.

[`foundry_check_setup()`](https://farach.github.io/foundryR/reference/foundry_check_setup.md)
confirms that the resource endpoint, credentials, and default deployment
work.

``` r

foundry_check_setup()
```

## Understand endpoints and routes

Microsoft Foundry exposes two endpoint shapes. A resource endpoint looks
like `https://<resource>.openai.azure.com`. It is the default route for
Responses API calls, files, vector stores, and most evaluation workflows
that use OpenAI graders on existing columns. A project endpoint looks
like `https://<resource>.services.ai.azure.com/api/projects/<project>`.
You need it for conversations, server-side agents, agent-backed
responses, Foundry built-in evaluators, model-target evaluations, agent
evaluations, and stored-response evaluations.

Set a project endpoint when your workflow needs project objects:

``` r

foundry_set_project_endpoint(Sys.getenv("AZURE_FOUNDRY_PROJECT_ENDPOINT"), store = TRUE)
```

Conversations, agents, and the evaluations that need the project use it
automatically. Responses, files, vector stores, and other evaluations
stay on the resource endpoint unless you pass `project_endpoint =` on a
call, or call `foundry_set_route("project")` to send them to the project
for the rest of the R session.

Project evaluations need a Microsoft Entra ID token. In live tests on
the default project, responses, conversations, files, vector stores, and
agents all accepted the resource API key.

## Know deployment names

The `model =` argument takes a deployment name, not a base model name.
For example, if you deploy base model `gpt-5-nano` with deployment name
`course-coder`, call:

``` r

foundry_response("Code this comment.", model = "course-coder")
```

[`foundry_models()`](https://farach.github.io/foundryR/reference/foundry_models.md)
lists models available to the resource. It does not list the deployments
you created in the Foundry portal.

``` r

models <- foundry_models()
models[, c("id", "owned_by")]
```

## Get a first response

The Responses API returns a tibble. Print the answer column when you
want the text a reader or analyst will see:

``` r

response <- foundry_response("Answer in one sentence: what is R?")

response$output_text
#> [1] "R is a free, open-source programming language and environment for statistical computing and graphics."
```

Token columns support cost checks and audit logs.

``` r

response[, c(
  "input_tokens",
  "output_tokens",
  "reasoning_tokens",
  "cached_input_tokens",
  "total_tokens"
)]
#> # A tibble: 1 × 5
#>   input_tokens output_tokens reasoning_tokens cached_input_tokens total_tokens
#>          <int>         <int>            <int>               <int>        <int>
#> 1           15           205              128                   0          220
```

`gpt-5-nano` is a reasoning model. Hidden reasoning tokens are included
in `output_tokens`, so they are part of the output-token cost even
though they are not visible in `output_text`.

## Extract structured fields

Use structured extraction when free text needs to become analysis
columns. This small schema codes course comments into sentiment and one
short issue label:

``` r

schema <- foundry_schema(
  sentiment = schema_enum(c("positive", "negative", "mixed")),
  issue = schema_string("A short label for what the comment is about.")
)

comments <- c(
  "The lecture made regression much clearer.",
  "The homework instructions were hard to follow.",
  "The examples helped, but I wanted more time for practice."
)

coded <- foundry_extract(comments, schema = schema)
coded[, c("sentiment", "issue")]
#> # A tibble: 3 × 2
#>   sentiment issue                        
#>   <chr>     <chr>                        
#> 1 positive  regression                   
#> 2 negative  homework instructions clarity
#> 3 mixed     Need more time for practice
```

The enum keeps `sentiment` to three values you can count. The free-text
`issue` field comes back in whatever form the model chooses, so two
runs, or two similar comments, can produce labels that do not match.
When a field needs to be counted, give it an enum and a codebook, as in
[`vignette("annotation-workflow")`](https://farach.github.io/foundryR/articles/annotation-workflow.md).

The returned tibble also contains dot-prefixed metadata such as response
IDs, status, and raw response payloads. Keep those columns when you need
provenance. Check `.error` before you analyze the fields. A failed row
has missing fields, and `.error_msg` says why it failed.

## Embed and compare text

Embeddings turn text into numeric vectors. For a first check, inspect
the dimensions and ask which pair is most similar:

``` r

texts <- c(
  "The lecture made regression much clearer.",
  "Regression finally made sense after this class.",
  "The homework instructions were hard to follow."
)

embeddings <- foundry_embed(texts, model = "text-embedding-3-small")
embeddings[, c("text", "n_dims")]
#> # A tibble: 3 × 2
#>   text                                            n_dims
#>   <chr>                                            <int>
#> 1 The lecture made regression much clearer.         1536
#> 2 Regression finally made sense after this class.   1536
#> 3 The homework instructions were hard to follow.    1536

foundry_similarity(embeddings, top_k = 1)
#> # A tibble: 1 × 3
#>   text_1                                    text_2                    similarity
#>   <chr>                                     <chr>                          <dbl>
#> 1 The lecture made regression much clearer. Regression finally made …      0.560
```

`text-embedding-3-small` returns 1536 dimensions.
[`foundry_similarity()`](https://farach.github.io/foundryR/reference/foundry_similarity.md)
computes cosine similarity from the embedding list-column.

## Choose the next article

| Task | Read next |
|----|----|
| Learn the main workflow | [From text to defensible estimates](https://farach.github.io/foundryR/articles/annotation-workflow.md) |
| Annotate many rows | [Annotate at scale with the Batch API](https://farach.github.io/foundryR/articles/files-batches.md) |
| Search, cluster, or compare text | [Embeddings for research](https://farach.github.io/foundryR/articles/embeddings.md) |
| Put embeddings in a model recipe | [Embeddings in tidymodels recipes](https://farach.github.io/foundryR/articles/tidymodels.md) |
| Evaluate models or agents in Foundry | [Evaluate models and agents in Microsoft Foundry](https://farach.github.io/foundryR/articles/evaluations.md) |
| Analyze evaluation results | [Analyze evaluation results with uncertainty](https://farach.github.io/foundryR/articles/evaluation-analysis.md) |
| Gate outputs for safety | [Content Safety gates in a research pipeline](https://farach.github.io/foundryR/articles/content-safety.md) |
| Use tools, web search, or stateful turns | [Responses API](https://farach.github.io/foundryR/articles/responses-api.md) |
| Check endpoint and authentication coverage | [API support matrix](https://farach.github.io/foundryR/articles/api-support.md) |
| Transcribe or translate audio | [Transcribe and translate audio](https://farach.github.io/foundryR/articles/audio.md) |
| Generate images | [Generate images](https://farach.github.io/foundryR/articles/media-generation.md) |
