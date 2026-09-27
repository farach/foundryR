# foundryR

foundryR is a tibble-native R client for research and measurement work
with Microsoft Foundry from data frames: structured extraction,
agreement checks, batch annotation, embeddings, cloud evaluations, and
content safety.

Calls to Azure in the examples show output recorded from a live run, and
setup code is shown but not run.

## Measurement

The package is built for workflows where model output becomes data you
have to inspect, join, and defend. This example codes a few course
comments, then compares the model labels with hand labels.

``` r

comments <- data.frame(
  comment = c(
    "The examples made the statistics much easier to understand.",
    "The labs moved too fast and the instructions were unclear.",
    "The course was fine, but I wanted more feedback."
  ),
  hand_label = c("positive", "negative", "neutral")
)

schema <- foundry_schema(
  sentiment = schema_enum(c("positive", "negative", "neutral")),
  theme = schema_string("A short theme label.")
)

coded <- foundry_extract(comments, text_col = "comment", schema = schema)
coded[, c("hand_label", "sentiment", "theme")]
#> # A tibble: 3 × 3
#>   hand_label sentiment theme
#>   <chr>      <chr>     <chr>
#> 1 positive   positive  clarity
#> 2 negative   negative  instruction_clarity
#> 3 neutral    neutral   need for more feedback

foundry_agreement(coded, estimate = "sentiment", truth = "hand_label")
#> # A tibble: 6 × 3
#>   metric             value     n
#>   <chr>              <dbl> <int>
#> 1 accuracy               1     3
#> 2 precision_macro        1     3
#> 3 recall_macro           1     3
#> 4 f1_macro               1     3
#> 5 cohen_kappa            1     3
#> 6 krippendorff_alpha     1     3
```

The free-text `theme` field has no fixed label set, so its values can
vary in form from row to row. Give any field you plan to count an enum,
as `sentiment` has.

Agreement metrics describe how the model labels compare with the
reference labels. They do not prove the reference labels are correct.
Three comments are enough to show the output but not to validate the
model. A real check codes a random sample of your data, large enough to
put an interval on agreement, as in [From text to defensible
estimates](https://farach.github.io/foundryR/articles/annotation-workflow.html).

## Features

- Strict JSON Schema extraction with one row per input and metadata
  columns for audit trails.
- Agreement and consistency helpers for measurement workflows with human
  labels.
- Batch annotation through Azure Files and Batch APIs when you need
  lower-cost asynchronous runs.
- Embeddings and pairwise similarity for search, semantic groups,
  duplicate checks, and tidymodels recipes.
- Microsoft Foundry evaluation runs for models, agents, stored
  responses, and built-in evaluators.
- Azure AI Content Safety helpers for moderation, groundedness, prompt
  shields, blocklists, and protected material checks.
- Responses API support for stateful turns, tool calls, web search,
  token accounting, and raw response capture.
- Audio, image, and other modality helpers where the Microsoft Foundry
  service exposes them.

## Installation

Install the released version from CRAN:

``` r

install.packages("foundryR")
```

Install the development version from GitHub:

``` r

# install.packages("pak")
pak::pak("farach/foundryR")
```

## Quick start

``` r

library(foundryR)
foundry_set_endpoint(Sys.getenv("AZURE_FOUNDRY_ENDPOINT"), store = TRUE)
foundry_set_key("your-api-key", store = TRUE)
foundry_check_setup()
```

For Microsoft Entra ID, replace the key line with a refreshable token
provider:

``` r

foundry_set_token_provider(foundry_token_azure_cli(), scope = "resource")
```

Set `AZURE_FOUNDRY_MODEL` and `AZURE_FOUNDRY_EMBED_MODEL` to your
deployment names, or pass deployment names through `model =`. A
deployment can be named `course-coder` even when it runs base model
`gpt-5-nano`.

Streaming is an intentional scope choice. foundryR focuses on
reproducible, tibble-returning analytical workflows; use ellmer when an
interactive streaming chat interface is the main product.

## When to use foundryR

The ellmer reference index lists provider chat constructors, stream
helpers, tool definitions, structured-data type specifications, and
batch chat helpers. It does not list embedding helpers, Azure Content
Safety helpers, tidymodels recipe steps, or Microsoft Foundry cloud
evaluation helpers.

| Need | foundryR | ellmer |
|----|----|----|
| Work tied to Microsoft Foundry resource and project APIs | Broad data-frame client for Foundry APIs | Azure OpenAI chat provider, without the broader Foundry data-plane coverage |
| Structured extraction into analysis rows | [`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md) returns tibbles with schema fields and metadata | Chat objects can extract structured data with ellmer type specifications |
| Reuse ellmer type specifications | [`as_foundry_schema()`](https://farach.github.io/foundryR/reference/as_foundry_schema.md) converts [`ellmer::type_object()`](https://ellmer.tidyverse.org/reference/type_boolean.html) specifications | Defines the type specifications |
| Agreement checks for model labels | [`foundry_agreement()`](https://farach.github.io/foundryR/reference/foundry_agreement.md) and related measurement helpers | No agreement metrics in the reference index |
| Batch annotation on Azure | Uses Azure Files and Batch APIs | Batch chat helpers where the selected provider supports them, not Azure Files and Batch APIs |
| Embeddings in data frames | [`foundry_embed()`](https://farach.github.io/foundryR/reference/foundry_embed.md), [`foundry_embed_batch()`](https://farach.github.io/foundryR/reference/foundry_embed_batch.md), and [`foundry_similarity()`](https://farach.github.io/foundryR/reference/foundry_similarity.md) | No embedding helper in the reference index |
| Embeddings in tidymodels recipes | [`step_foundry_embed()`](https://farach.github.io/foundryR/reference/step_foundry_embed.md) | No recipe step in the reference index |
| Azure AI Content Safety | Moderation, groundedness, shields, blocklists, image checks, and protected material | No Content Safety helpers in the reference index |
| Foundry cloud evaluations | Model, agent, stored-response, and built-in evaluator workflows | No Microsoft Foundry evaluation helpers in the reference index |
| Provider-portable chat | No | Yes, through `chat_*()` providers |
| Interactive streaming chat | No | Yes, through streaming helpers and Chat methods |
| Chat-first tool calling | Basic Responses API tool loop | Yes, through chat tools |

Use foundryR when the result needs to live in a data frame, use
Microsoft Foundry APIs, or feed a measurement workflow. Use ellmer when
provider-portable chat, interactive streaming, or a chat-first agent
interface is the main need.

For retrieval-augmented generation, look at
[ragnar](https://ragnar.tidyverse.org/), from the ellmer team. It has
`embed_azure_openai()`, document stores, and retrieval functions.
foundryR’s embedding functions return tibbles for analysis, similarity
checks, and tidymodels recipes.

## Articles

- [Get started with
  foundryR](https://farach.github.io/foundryR/articles/getting-started.html)
- [From text to defensible
  estimates](https://farach.github.io/foundryR/articles/annotation-workflow.html)
- [Annotate at scale with the Batch
  API](https://farach.github.io/foundryR/articles/files-batches.html)
- [Embeddings for
  research](https://farach.github.io/foundryR/articles/embeddings.html)
- [Embeddings in tidymodels
  recipes](https://farach.github.io/foundryR/articles/tidymodels.html)
- [Evaluate models and agents in Microsoft
  Foundry](https://farach.github.io/foundryR/articles/evaluations.html)
- [Analyze evaluation results with
  uncertainty](https://farach.github.io/foundryR/articles/evaluation-analysis.html)
- [Content Safety gates in a research
  pipeline](https://farach.github.io/foundryR/articles/content-safety.html)
- [Responses
  API](https://farach.github.io/foundryR/articles/responses-api.html)
- [API support
  matrix](https://farach.github.io/foundryR/articles/api-support.html)
- [Transcribe and translate
  audio](https://farach.github.io/foundryR/articles/audio.html)
- [Generate
  images](https://farach.github.io/foundryR/articles/media-generation.html)

## License

MIT
