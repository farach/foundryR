# Annotating open-ended survey responses end to end

Open-ended survey responses are valuable because respondents can say
what the researcher did not anticipate. They are also expensive to code
by hand. This vignette shows a foundryR workflow that keeps each model
step visible in a tibble: extract structured labels, run the same prompt
at scale with Batch, embed text for similarity work, and check that
generated findings are grounded in the source responses.

## Example data

``` r

library(foundryR)
library(dplyr)

responses <- tibble::tibble(
  respondent_id = 1:6,
  response = c(
    "The lectures were clear, but the weekly quizzes felt rushed.",
    "I liked the examples in R. More office hours would help.",
    "The project made the material practical.",
    "I struggled because the instructions changed late.",
    "The instructor explained regression well.",
    "The course needed more examples before the final exam."
  )
)
```

## Extract structured annotations

Start with a JSON Schema. Keep the schema small enough that a human
reviewer can understand it.

``` r

annotation_schema <- list(
  type = "object",
  properties = list(
    sentiment = list(type = "string", enum = c("positive", "negative", "mixed")),
    primary_theme = list(
      type = "string",
      enum = c("instruction", "assessment", "support", "materials")
    ),
    needs_followup = list(type = "boolean"),
    short_summary = list(type = "string")
  ),
  required = c(
    "sentiment",
    "primary_theme",
    "needs_followup",
    "short_summary"
  ),
  additionalProperties = FALSE
)
```

[`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
uses strict JSON Schema mode by default for supported models. The result
is one row per response, with schema fields as columns.

``` r

annotations <- foundry_extract(
  responses$response,
  schema = annotation_schema,
  instructions = paste(
    "Code each survey response for a course evaluation.",
    "Use the respondent's words. Do not infer facts that are not stated."
  ),
  model = "my-gpt4"
)

coded <- bind_cols(responses, annotations)
coded
```

## Move the same job to Azure Batch

Interactive extraction is useful while designing the schema. For larger
jobs, write a JSONL request file and submit it to Azure’s Batch API.

``` r

jsonl <- tempfile(fileext = ".jsonl")

foundry_batch_requests(
  responses,
  input = "response",
  path = jsonl,
  model = "my-gpt4",
  endpoint = "/v1/responses",
  body = list(
    instructions = paste(
      "Code each survey response using the supplied schema.",
      "Return only JSON that conforms to the schema."
    ),
    text = list(
      format = list(
        type = "json_schema",
        name = "CourseEvaluationAnnotation",
        schema = annotation_schema,
        strict = TRUE
      )
    )
  )
)

file <- foundry_file_upload(jsonl, purpose = "batch")
batch <- foundry_batch_create(file$file_id, endpoint = "/v1/responses")
foundry_batch_get(batch$batch_id)
```

The Batch API is the right choice when the schema is stable and the job
is large enough that lower cost and asynchronous execution matter more
than immediate feedback.

## Embed responses for clustering and near-duplicate checks

Embeddings turn text into numeric vectors. For open-ended survey data,
use them to find near-duplicate answers, cluster themes that were not in
the original codebook, or build semantic search over the responses.

``` r

embeddings <- foundry_embed(
  responses$response,
  model = "my-embedding-deployment"
)

similarity <- foundry_similarity(embeddings)
head(similarity, 10)
```

High-similarity pairs are useful audit targets. They can reveal
duplicate responses, repeated complaints, or places where the schema
splits similar answers into different labels.

## Validate generated findings with groundedness

After coding and embedding, a researcher often writes a summary. Treat
that summary as a claim and check it against the source responses.

``` r

finding <- paste(
  "Students generally praised clear instruction and practical examples.",
  "Several asked for more examples and more support before assessments."
)

grounding_text <- paste(responses$response, collapse = "\n")

groundedness <- foundry_groundedness(
  text = finding,
  grounding_sources = grounding_text,
  query = "What did students say about the course?",
  task = "QnA"
)

groundedness
```

If `grounded` is `FALSE`, inspect `ungrounded_segments` before sharing
the finding. This does not replace human review, but it gives you an
auditable check inside the same R workflow.

## Review table

``` r

review <- coded |>
  select(
    respondent_id,
    response,
    sentiment,
    primary_theme,
    needs_followup,
    short_summary
  )

review
```

The rendered table and chart below use precomputed, illustrative data
from a representative run. They are rendered during the documentation
build without Azure credentials.

| Structured annotations from open-ended responses |  |  |  |  |  |
|----|----|----|----|----|----|
| ID | Response | Sentiment | Theme | Follow-up | Summary |
| 1 | The lectures were clear, but the weekly quizzes felt rushed. | mixed | assessment | Review | Clear lectures, rushed quizzes |
| 2 | I liked the examples in R. More office hours would help. | positive | support | Review | R examples helped, office hours requested |
| 3 | The project made the material practical. | positive | instruction | No review | Project connected concepts to practice |
| 4 | I struggled because the instructions changed late. | negative | instruction | Review | Late instruction changes caused confusion |
| 5 | The instructor explained regression well. | positive | instruction | No review | Regression explanation was clear |
| 6 | The course needed more examples before the final exam. | mixed | materials | Review | More exam examples requested |

![Bar chart of survey response themes by
sentiment.](annotation-workflow_files/figure-html/sentiment-theme-chart-1.png)

The workflow leaves a trail: raw response, extracted labels, model
metadata, embedding similarity, and groundedness checks. That trail is
the reason foundryR returns tibbles instead of hiding results inside
client objects.
