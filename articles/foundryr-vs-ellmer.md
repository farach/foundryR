# foundryR vs ellmer

``` r

library(foundryR)
#> 
#> foundryR - Tidy Azure AI Foundry workflows
#> ==========================================
#> * Check your setup:
#>   foundry_check_setup()
#> * Set your API key: foundry_set_key()
#> * Set your endpoint: foundry_set_endpoint()
#> * Get started: ?foundry_response, ?foundry_groundedness
#> 
#> New to Azure? See the README for setup instructions.
```

foundryR and ellmer both make language-model work possible from R. They
are not substitutes for every use case. ellmer is the better fit for
provider-portable chat. foundryR is the better fit when the work is tied
to Azure AI Foundry and the output needs to become data. The two are
complementary: you can describe a structure once with ellmer’s type
system and hand it to foundryR for strict, tibble-shaped extraction.

## Comparison

| Question | Use foundryR | Use ellmer |
|----|----|----|
| Are you committed to Azure AI Foundry? | Yes | Sometimes |
| Do you need Azure AI Content Safety? | Yes | No |
| Do you need Azure’s Files and Batch APIs? | Yes | No |
| Do you need strict schema-constrained extraction as tibbles? | Yes | Sometimes |
| Do you need embeddings inside a dataframe workflow? | Yes | Sometimes |
| Do you need [`step_foundry_embed()`](https://farach.github.io/foundryR/reference/step_foundry_embed.md) in a tidymodels recipe? | Yes | No |
| Do you need multi-provider chat? | No | Yes |
| Do you need interactive streaming chat? | No | Yes |
| Do you need a chat-first tool-calling agent interface? | Basic Responses API loop | Yes |

## Where foundryR fits

Use foundryR when your work starts or ends in a dataframe. Common
examples are:

- Coding open-ended survey responses with a strict JSON Schema.
- Running low-cost batch annotation jobs through Azure’s Batch API.
- Embedding documents for clustering, semantic search, or near-duplicate
  checks.
- Adding embeddings to tidymodels recipes.
- Moderating user text, detecting prompt injection, or checking
  groundedness.
- Keeping model metadata, citations, tool calls, and token use in tibble
  columns.

Azure’s own Batch API matters here. ellmer supports batch workflows for
native OpenAI and Anthropic endpoints, but it does not target Azure’s
Files and Batch API surface.

## Where ellmer fits

Use ellmer when chat is the product interface. It gives you a
provider-neutral chat abstraction, interactive streaming, and a mature
chat-first tool-calling workflow. That is the right shape for
assistants, notebooks where you want token streaming, or applications
that may move between providers.

foundryR deliberately does not implement streaming. For streaming chat
in R, use ellmer.

## Interop: reuse an ellmer type as a foundryR schema

If you already describe your data with ellmer’s type system, you do not
have to rewrite it.
[`as_foundry_schema()`](https://farach.github.io/foundryR/reference/as_foundry_schema.md)
converts an
[`ellmer::type_object()`](https://ellmer.tidyverse.org/reference/type_boolean.html)
into the strict JSON Schema that
[`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
expects. This conversion is a local operation – no network, no
credentials – so its output is shown here directly.

``` r

library(ellmer)

# Describe the structure you want with ellmer's type system.
sentiment_spec <- type_object(
  sentiment = type_enum(
    c("positive", "negative", "neutral"),
    description = "Overall sentiment of the response."
  ),
  theme = type_string("A short theme label for the response.")
)

# Convert it into a foundryR schema for strict extraction.
sentiment_schema <- as_foundry_schema(sentiment_spec)
str(sentiment_schema)
#> List of 4
#>  $ type                : chr "object"
#>  $ properties          :List of 2
#>   ..$ sentiment:List of 3
#>   .. ..$ type       : chr "string"
#>   .. ..$ enum       : 'AsIs' chr [1:3] "positive" "negative" "neutral"
#>   .. ..$ description: chr "Overall sentiment of the response."
#>   ..$ theme    :List of 2
#>   .. ..$ type       : chr "string"
#>   .. ..$ description: chr "A short theme label for the response."
#>  $ required            : 'AsIs' chr [1:2] "sentiment" "theme"
#>  $ additionalProperties: logi FALSE
```

## Extraction with foundryR

Hand the converted schema to
[`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md).
foundryR sends each input through the Responses API with strict decoding
and returns one tidy row per input – the model’s output has already
become data.

``` r

foundry_extract(
  c("The lesson was clear.", "I wanted more examples."),
  schema = sentiment_schema,
  model = "gpt-5.5"
)
```

You can also build the same schema natively with foundryR’s
[`foundry_schema()`](https://farach.github.io/foundryR/reference/foundry_schema.md)
and `schema_*()` constructors when you would rather not depend on
ellmer. See
[`vignette("responses-api")`](https://farach.github.io/foundryR/articles/responses-api.md)
for the native path, and
[`vignette("content-safety")`](https://farach.github.io/foundryR/articles/content-safety.md)
for using Azure Content Safety as a pipeline gate.

The practical rule is simple: use ellmer when you need the best R chat
client, and use foundryR when you need Azure AI Foundry results as data
– and use
[`as_foundry_schema()`](https://farach.github.io/foundryR/reference/as_foundry_schema.md)
when you want both.
