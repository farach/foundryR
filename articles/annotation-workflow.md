# From text to defensible estimates

Calls to Azure show output recorded from a live run, and setup code is
shown but not run.

This article codes course evaluation comments for one primary theme and
sentiment, then turns those labels into an estimate. The same pattern
applies to interview transcripts, support tickets and open-ended survey
answers. The sections below add, in order, a versioned codebook,
readable labels, a check against hand codes, a stability check, an
interval and a provenance record. A reviewer can ask about each one.

## Start with a versioned codebook

The codebook is the measurement instrument. It records the instructions,
schema, examples and version that define what a label means.

``` r

library(foundryR)
library(dplyr)
```

``` r

comments <- tibble::tibble(
  comment_id = sprintf("c%02d", 1:10),
  comment = c(
    "The lectures were clear and the examples made regression feel concrete.",
    "The weekly quizzes felt rushed and did not match the homework.",
    "Office hours helped me catch up after I missed the first lab.",
    "The slides were hard to follow because notation changed between weeks.",
    "The final project connected the material to real policy questions.",
    "I needed more feedback before the midterm.",
    "The instructor explained difficult topics patiently.",
    "The reading packet was useful, but several links were broken.",
    "Group work helped, although the grading rubric came too late.",
    "More examples before the final exam would have helped."
  )
)
```

``` r

course_schema <- foundry_schema(
  theme = schema_enum(
    c("instruction", "assessment", "support", "materials"),
    description = paste(
      "Primary theme: instruction, assessment, support, or materials."
    )
  ),
  sentiment = schema_enum(
    c("positive", "negative", "mixed"),
    description = "Overall sentiment toward the course element."
  )
)

course_instructions <- paste(
  "Code one course evaluation comment.",
  "Choose exactly one primary theme.",
  "Use instruction for teaching clarity or examples.",
  "Use assessment for quizzes, exams, projects, grading or feedback.",
  "Use support for office hours or help outside class.",
  "Use materials for slides, readings, links or course files.",
  "Choose positive, negative or mixed sentiment from the student's wording."
)

course_codebook <- foundry_codebook(
  name = "course-evaluation-codes",
  version = "1.0.0",
  instructions = course_instructions,
  schema = course_schema,
  examples = list(
    list(
      text = "The lectures were clear.",
      theme = "instruction",
      sentiment = "positive"
    ),
    list(
      text = "The rubric came too late.",
      theme = "assessment",
      sentiment = "negative"
    )
  )
)

course_codebook
#> foundry codebook: course-evaluation-codes
#> version: 1.0.0
#> hash: 44dc8b370cb4
#> variables:
#>   - theme: string [instruction, assessment, support, materials] (Primary theme: instruction, assessment, support, or materials.)
#>   - sentiment: string [positive, negative, mixed] (Overall sentiment toward the course element.)
#> examples: 2
```

Versioning matters because label changes change the estimand. If
“workload” becomes a valid theme, yesterday’s “assessment” labels are no
longer directly comparable with tomorrow’s labels.

``` r

course_schema_v2 <- foundry_schema(
  theme = schema_enum(
    c("instruction", "assessment", "support", "materials", "workload"),
    description = paste(
      "Primary theme: instruction, assessment, support, materials, or workload."
    )
  ),
  sentiment = schema_enum(
    c("positive", "negative", "mixed"),
    description = "Overall sentiment toward the course element."
  )
)

course_codebook_v2 <- foundry_codebook(
  name = "course-evaluation-codes",
  version = "1.1.0",
  instructions = paste(
    course_instructions,
    "Use workload for comments about pacing or volume that are not mainly assessment."
  ),
  schema = course_schema_v2,
  examples = course_codebook$examples
)

codebook_diff(course_codebook, course_codebook_v2)
#> Codebook diff
#> old: course-evaluation-codes 1.0.0 44dc8b370cb45b83fccb26264225d07b7af182a050fd67a6e222a6776e4dad89
#> new: course-evaluation-codes 1.1.0 25a223fd7de1c485c3112ba0bf59597ad13322c9dffa6f4b0612f14f16f27282
#> 
#> Instructions:
#> --- old instructions
#> +++ new instructions
#> @@
#> -Code one course evaluation comment. Choose exactly one primary theme. Use instruction for teaching clarity or examples. Use assessment for quizzes, exams, projects, grading or feedback. Use support for office hours or help outside class. Use materials for slides, readings, links or course files. Choose positive, negative or mixed sentiment from the student's wording.
#> +Code one course evaluation comment. Choose exactly one primary theme. Use instruction for teaching clarity or examples. Use assessment for quizzes, exams, projects, grading or feedback. Use support for office hours or help outside class. Use materials for slides, readings, links or course files. Choose positive, negative or mixed sentiment from the student's wording. Use workload for comments about pacing or volume that are not mainly assessment.
#> 
#> Schema:
#> ~ theme.description: "Primary theme: instruction, assessment, support, or materials." -> "Primary theme: instruction, assessment, support, materials, or workload."
#> ~ theme.enum: +workload
#>   sentiment: no change
#> 
#> Examples:
#>   (no changes)
```

The diff is short enough for a methods appendix or code review. It shows
the schema and instruction changes behind any shift in label rates.

## Extract only the coded fields

[`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
returns input columns, extracted fields, dot-prefixed metadata and the
raw response. Print the fields needed for the next decision, not the
whole object.

``` r

coding_model <- "gpt-5-nano" # your deployment name

model_labels <- foundry_extract(
  comments,
  text_col = "comment",
  schema = course_codebook$schema,
  instructions = course_codebook$instructions,
  model = coding_model
)

model_labels |>
  select(comment_id, theme, sentiment)
#> # A tibble: 10 × 3
#>    comment_id theme       sentiment
#>    <chr>      <chr>       <chr>    
#>  1 c01        instruction positive 
#>  2 c02        assessment  negative 
#>  3 c03        support     positive 
#>  4 c04        materials   negative 
#>  5 c05        assessment  positive 
#>  6 c06        assessment  negative 
#>  7 c07        instruction positive 
#>  8 c08        materials   mixed    
#>  9 c09        assessment  mixed    
#> 10 c10        instruction negative
```

Readable output is a quality control step. It lets a reviewer notice a
systematic problem, such as materials comments being coded as
instruction, before the labels become an estimate.

## Compare with hand codes on a sample

The next check is agreement with a reference sample. The labels below
are hand codes written for this example. In a study, draw this sample
before looking at model errors, and keep a second labeled sample if you
tune the prompt or codebook.

``` r

hand_codes <- tibble::tibble(
  comment_id = c("c01", "c02", "c03", "c04", "c05", "c06"),
  human_theme = c(
    "instruction",
    "assessment",
    "support",
    "materials",
    "assessment",
    "assessment"
  ),
  human_sentiment = c(
    "positive",
    "negative",
    "positive",
    "negative",
    "positive",
    "negative"
  )
)

hand_codes
#> # A tibble: 6 × 3
#>   comment_id human_theme human_sentiment
#>   <chr>      <chr>       <chr>          
#> 1 c01        instruction positive       
#> 2 c02        assessment  negative       
#> 3 c03        support     positive       
#> 4 c04        materials   negative       
#> 5 c05        assessment  positive       
#> 6 c06        assessment  negative
```

``` r

validation_sample <- model_labels |>
  select(comment_id, theme, sentiment) |>
  inner_join(hand_codes, by = "comment_id")

theme_agreement <- foundry_agreement(
  validation_sample,
  estimate = "theme",
  truth = "human_theme"
) |>
  mutate(variable = "theme")

sentiment_agreement <- foundry_agreement(
  validation_sample,
  estimate = "sentiment",
  truth = "human_sentiment"
) |>
  mutate(variable = "sentiment")

bind_rows(theme_agreement, sentiment_agreement) |>
  select(variable, metric, value, n)
#> # A tibble: 12 × 4
#>    variable  metric             value     n
#>    <chr>     <chr>              <dbl> <int>
#>  1 theme     accuracy               1     6
#>  2 theme     precision_macro        1     6
#>  3 theme     recall_macro           1     6
#>  4 theme     f1_macro               1     6
#>  5 theme     cohen_kappa            1     6
#>  6 theme     krippendorff_alpha     1     6
#>  7 sentiment accuracy               1     6
#>  8 sentiment precision_macro        1     6
#>  9 sentiment recall_macro           1     6
#> 10 sentiment f1_macro               1     6
#> 11 sentiment cohen_kappa            1     6
#> 12 sentiment krippendorff_alpha     1     6
```

All 6 theme pairs agree in this recording. That says little on its own,
because 6 comments written to be unambiguous are an easy test. A real
validation sample is drawn at random from the data being coded and is
large enough for an interval on accuracy to be informative.

Accuracy is the share of complete pairs where the model and human label
match. Macro precision, recall and F1 compute a per-class value and
average across classes, so a rare class can matter as much as a common
class. foundryR follows the yardstick convention: when a class has an
undefined denominator for a macro metric, that class is dropped from
that macro average with a warning.

Cohen’s kappa discounts the agreement you would expect by chance, given
how often each coder uses each label. foundryR computes Krippendorff’s
alpha for nominal labels from two coders. Both are useful when a high
raw accuracy could come from a dominant class. None of these metrics
proves the hand codes are true, unbiased or complete. They measure
agreement with the reference labels you supplied.

## Check repeated-run stability

Agreement checks accuracy against people. Stability checks whether the
same instrument gives the same label when it is run again. A model can
be stable and wrong.

``` r

stability <- foundry_consistency(
  comments$comment[1:4],
  schema = course_codebook$schema,
  n = 3,
  instructions = course_codebook$instructions,
  model = coding_model
)

stability |>
  select(.input_idx, successful_runs, failed_runs, modal_share, entropy)
#> # A tibble: 4 × 5
#>   .input_idx successful_runs failed_runs modal_share entropy
#>        <int>           <int>       <int>       <dbl>   <dbl>
#> 1          1               3           0           1       0
#> 2          2               3           0           1       0
#> 3          3               3           0           1       0
#> 4          4               3           0           1       0
```

In this recording 4 of 4 comments received the same record in all 3
runs. Short, clear comments are the easy case; run the same check on the
ambiguous comments your hand coders disagreed about.

`modal_share` is the largest repeated-label pattern’s share of
successful runs. With `n = 3` and all three runs successful, it can only
be one third, two thirds or one. `entropy` is in bits and increases when
repeated runs split across several distinct records. These values
summarize stability only. They do not say whether the modal label
matches a human code.

## Estimate a theme share with an interval

Once the codebook is fixed and the labels have passed enough checks for
the decision at hand, label counts become estimates. The interval below
is an exact binomial interval from
[`binom.test()`](https://rdrr.io/r/stats/binom.test.html), computed
separately for each theme.

``` r

theme_levels <- course_codebook$schema$properties$theme$enum |> as.character()

theme_estimates <- lapply(theme_levels, function(level) {
  x <- sum(model_labels$theme == level, na.rm = TRUE)
  n <- sum(!is.na(model_labels$theme))
  interval <- binom.test(x, n)$conf.int
  tibble::tibble(
    theme = level,
    labels = x,
    total = n,
    share = x / n,
    conf_low = interval[[1]],
    conf_high = interval[[2]]
  )
}) |>
  bind_rows()

theme_estimates
#> # A tibble: 4 × 6
#>   theme       labels total share conf_low conf_high
#>   <chr>        <int> <int> <dbl>    <dbl>     <dbl>
#> 1 instruction      3    10   0.3  0.0667      0.652
#> 2 assessment       4    10   0.4  0.122       0.738
#> 3 support          1    10   0.1  0.00253     0.445
#> 4 materials        2    10   0.2  0.0252      0.556
```

With 10 comments, each interval is wide; the width comes from the small
sample, not from the model. This interval covers sampling error for the
share of comments assigned each theme, given the labels as recorded. It
does not cover systematic model mislabeling. That is what the hand-coded
sample is for. If you need an estimate corrected with a validation
sample, the CRAN package `ipd` is a useful pointer for inference on
predicted data.

## Record provenance

The final estimate should carry the instrument and model that produced
it. That record lets another analyst connect a table of estimates back
to the exact schema.

``` r

run_provenance <- foundry_provenance(
  model = coding_model,
  schema = course_codebook$schema,
  metadata = list(
    codebook = course_codebook$name,
    codebook_version = course_codebook$version,
    codebook_hash = course_codebook$hash
  )
)

run_provenance |>
  select(model, schema_hash, package_version, captured_at)
#> # A tibble: 1 × 4
#>   model      schema_hash                     package_version captured_at        
#>   <chr>      <chr>                           <chr>           <dttm>             
#> 1 gpt-5-nano c5ee5dc66f90546f2c3f053bd61847… 1.0.0           2026-10-01 15:55:06
```

The codebook hash and schema hash are not substitutes for archiving the
codebook. They are compact checks that the labels and report refer to
the same instrument.

## What to report

For a defensible text-to-estimate workflow, report the choices that
affect the estimate. A short methods note should cover:

- the data source, unit of analysis, sample size and sampling frame;
- the codebook name, version, hash, instructions, schema and examples;
- the model deployment, package version, date, endpoint route and
  sampling settings;
- the validation sample design, hand-coding process, agreement metrics,
  label confusions and any classes dropped from macro metrics;
- the stability design, including `n`, successful runs, failed runs,
  modal share and entropy;
- the estimate, interval method, interval interpretation and what the
  interval omits;
- any correction method used for model mislabeling, and the validation
  sample it depends on.
