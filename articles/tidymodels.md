# Embeddings in tidymodels recipes

Calls to Azure show output recorded from a live run, and setup code is
shown but not run.

## Why put embeddings in a recipe?

[`step_foundry_embed()`](https://farach.github.io/foundryR/reference/step_foundry_embed.md)
lets text enter a tidymodels workflow as numeric predictors. That helps
when the model should use the meaning of short responses, reviews, or
support tickets rather than exact word counts.

The step belongs in a recipe when you want the preprocessing record to
travel with the model. During `prep()`, the step resolves and keeps the
embedding model deployment name. `tidy()` reports that model, the
selected text column, and the embedding dimension once the recipe has
been baked. During `bake()`, the text values are sent to Foundry. Rows
with missing text or failed embedding requests get `NA` embedding
values, and the step warns with the number of failed rows for that
column.

``` r

install.packages("tidymodels")
```

## Create an embedding recipe

This small example uses course feedback because it matches the package’s
usual data shape: one row per text response and a label supplied by a
human or a previous coding pass.

``` r

library(tidymodels)
library(foundryR)
```

``` r

reviews <- tibble(
  text = c(
    "The examples made the concepts easy to apply.",
    "The assignment instructions were clear and useful.",
    "The instructor explained the hard parts carefully.",
    "The labs helped me practice each method.",
    "The readings connected well to the lectures.",
    "The feedback on drafts helped me improve.",
    "The setup steps were confusing and slow.",
    "The grading rubric was hard to interpret.",
    "The software instructions skipped important details.",
    "The lectures moved too quickly for me.",
    "The final project needed more guidance.",
    "The examples did not match the homework."
  ),
  sentiment = factor(rep(c("positive", "negative"), each = 6))
)
```

[`step_foundry_embed()`](https://farach.github.io/foundryR/reference/step_foundry_embed.md)
replaces the text column with one numeric column per embedding
dimension. The column names are explicit, for example `emb_text_1`,
`emb_text_2`, and so on.

``` r

recipe_spec <- recipe(sentiment ~ text, data = reviews) |>
  step_foundry_embed(
    text,
    model = "text-embedding-3-small",
    keep_original = FALSE
  )

recipe_spec
#> 
#> ── Recipe ──────────────────────────────────────────────────────────────────────
#> 
#> ── Inputs
#> Number of variables by role
#> outcome:   1
#> predictor: 1
#> 
#> ── Operations
#> • Foundry embeddings for: text
```

``` r

prepped_recipe <- prep(recipe_spec, training = reviews)
tidy(prepped_recipe, number = 1)
#> # A tibble: 1 × 4
#>   terms model                  dimensions id                 
#>   <chr> <chr>                       <int> <chr>              
#> 1 text  text-embedding-3-small       1536 foundry_embed_SwlKL

baked_data <- bake(prepped_recipe, new_data = NULL)
baked_data[, c("sentiment", "emb_text_1", "emb_text_2", "emb_text_3")]
#> # A tibble: 12 × 4
#>    sentiment emb_text_1 emb_text_2 emb_text_3
#>    <fct>          <dbl>      <dbl>      <dbl>
#>  1 positive    -0.0137    -0.0141   -0.0173  
#>  2 positive    -0.00496    0.0181   -0.0438  
#>  3 positive     0.00910    0.0153   -0.0321  
#>  4 positive    -0.00889   -0.00995   0.0131  
#>  5 positive    -0.00452    0.00251  -0.0289  
#>  6 positive     0.0225     0.0376    0.00454 
#>  7 negative    -0.0382    -0.0142   -0.0216  
#>  8 negative    -0.0201     0.0108    0.00753 
#>  9 negative     0.00150    0.0316   -0.00584 
#> 10 negative    -0.0180     0.0219   -0.0819  
#> 11 negative     0.0121     0.0203    0.0106  
#> 12 negative    -0.0125    -0.00597   0.000172
```

## Fit a small classifier with PCA

The default `text-embedding-3-small` embedding has 1,536 dimensions.
This example has far fewer rows than predictors, so an unpenalized
logistic regression on the raw embedding columns is a poor fit. The
workflow below reduces the embedding columns to a few principal
components and then fits `logistic_reg()` with the base `glm` engine.

Penalized logistic regression with the `glmnet` engine is another
reasonable choice when you add that optional package. This vignette
keeps the model to packages already needed for the recipe path.

``` r

set.seed(42)
split <- initial_split(reviews, prop = 0.75, strata = sentiment)
train_data <- training(split)
test_data <- testing(split)

embedding_recipe <- recipe(sentiment ~ text, data = train_data) |>
  step_foundry_embed(
    text,
    model = "text-embedding-3-small",
    keep_original = FALSE,
    cache = "disk"
  ) |>
  step_normalize(all_numeric_predictors()) |>
  step_pca(all_numeric_predictors(), num_comp = 3)

log_reg_spec <- logistic_reg() |>
  set_engine("glm") |>
  set_mode("classification")

sentiment_workflow <- workflow() |>
  add_recipe(embedding_recipe) |>
  add_model(log_reg_spec)

fitted_workflow <- fit(sentiment_workflow, data = train_data)
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred

predictions <- predict(fitted_workflow, test_data) |>
  bind_cols(test_data["sentiment"])

predictions
#> # A tibble: 4 × 2
#>   .pred_class sentiment
#>   <fct>       <fct>    
#> 1 positive    positive 
#> 2 positive    positive 
#> 3 negative    negative 
#> 4 negative    negative
```

[`glm()`](https://rdrr.io/r/stats/glm.html) warns when the training rows
can be separated perfectly, as they can be here with eight training
comments and three components. The fitted probabilities reach 0 or 1,
and the coefficients have no finite estimate.

The workflow labels 4 of the 4 held-out comments correctly, but a test
set of 4 rows says almost nothing about accuracy. With real data, use
enough labeled rows for the model you fit, or a penalized model such as
`glmnet`, and estimate accuracy by resampling as shown below.

The fitted workflow stores the recipe, so the same embedding model and
PCA rotation are used when new rows are predicted.

## Control the embedding step

Some embedding deployments support shorter vectors. A smaller dimension
count reduces the number of columns produced by `bake()`, but it may
also remove useful semantic detail.

``` r

compact_recipe <- recipe(sentiment ~ text, data = reviews) |>
  step_foundry_embed(
    text,
    model = "text-embedding-3-small",
    dimensions = 256,
    keep_original = FALSE
  )
```

For more than one text field, add one step per field and choose prefixes
that keep the generated columns readable.

``` r

ticket_data <- tibble(
  subject = c("Login failure", "Billing question"),
  body = c("Password reset link expired.", "Invoice total looks too high."),
  escalated = factor(c("yes", "no"))
)

ticket_recipe <- recipe(escalated ~ ., data = ticket_data) |>
  step_foundry_embed(subject, model = "text-embedding-3-small",
                     prefix = "subject_") |>
  step_foundry_embed(body, model = "text-embedding-3-small",
                     prefix = "body_")
```

Set `keep_original = TRUE` only when a later recipe step or a reviewer
needs the original text column.

## Resampling, caching, and cost

[`step_foundry_embed()`](https://farach.github.io/foundryR/reference/step_foundry_embed.md)
calls the embedding API when a recipe is prepared and when new data is
baked. In a resampling workflow, each fold prepares its own recipe. The
same response can be embedded repeatedly across folds unless you cache
or precompute embeddings.

The default, `cache = "none"`, does not read or write a disk cache. To
reuse embeddings for the same text, model, dimensions, and endpoint, opt
into `cache = "disk"`. Without an explicit `cache_dir`, the cache stays
inside [`tempdir()`](https://rdrr.io/r/base/tempfile.html) for the
current R session. Use an explicit directory when you want reuse across
sessions, then clear it with `foundry_cache_clear(cache_dir)`.

For large or repeated experiments, embed the text once with
[`foundry_embed_batch()`](https://farach.github.io/foundryR/reference/foundry_embed_batch.md),
keep the numeric columns, and resample those columns locally.

``` r

embedded_reviews <- foundry_embed_batch(
  reviews$text,
  model = "text-embedding-3-small",
  batch_size = 6,
  max_active = 2
)

embedding_matrix <- do.call(rbind, embedded_reviews$embedding)
embedding_cols <- tibble::as_tibble(
  embedding_matrix,
  .name_repair = function(x) paste0("emb_", seq_along(x))
)

precomputed <- bind_cols(
  reviews["sentiment"],
  embedding_cols
)

precomputed[, c("sentiment", "emb_1", "emb_2", "emb_3")]
#> # A tibble: 12 × 4
#>    sentiment    emb_1    emb_2     emb_3
#>    <fct>        <dbl>    <dbl>     <dbl>
#>  1 positive  -0.0137  -0.0141  -0.0173  
#>  2 positive  -0.00496  0.0181  -0.0438  
#>  3 positive   0.00854  0.0157  -0.0316  
#>  4 positive  -0.00887 -0.00994  0.0131  
#>  5 positive  -0.00452  0.00252 -0.0289  
#>  6 positive   0.0225   0.0376   0.00454 
#>  7 negative  -0.0382  -0.0142  -0.0216  
#>  8 negative  -0.0201   0.0108   0.00753 
#>  9 negative   0.00150  0.0316  -0.00584 
#> 10 negative  -0.0180   0.0219  -0.0819  
#> 11 negative   0.0121   0.0203   0.0106  
#> 12 negative  -0.0125  -0.00597  0.000172
```

The recipe and
[`foundry_embed_batch()`](https://farach.github.io/foundryR/reference/foundry_embed_batch.md)
embedded the same 12 comments in separate calls, and the vectors are not
identical. The largest difference in any coordinate is 0.00098, though
every pair has a cosine similarity of at least 0.9999. Store the
embeddings you analyze, so that a rerun uses the same numbers.

Use the recipe step when preprocessing needs to be self-contained.
Precompute when cost, rate limits, or repeated resampling runs matter
more than keeping the API call inside the workflow.

The same workflow can be resampled with standard tidymodels functions.
Estimate API calls before running this pattern on live data.

``` r

folds <- vfold_cv(train_data, v = 5, strata = sentiment)

cv_results <- fit_resamples(
  sentiment_workflow,
  resamples = folds,
  metrics = metric_set(accuracy, roc_auc)
)

collect_metrics(cv_results)
```

## Troubleshooting

If you hit rate limits during `prep()`, start with a smaller sample,
turn on `cache = "disk"`, or precompute embeddings with
[`foundry_embed_batch()`](https://farach.github.io/foundryR/reference/foundry_embed_batch.md)
before resampling.

``` r

small_sample <- reviews |> slice_sample(n = 100)
prepped <- prep(recipe_spec, training = small_sample)
```

Credential errors happen before the recipe can call Foundry. Check the
endpoint, key or token provider, and embedding deployment name before
preparing the recipe.

``` r

foundry_check_setup()
foundry_set_endpoint(Sys.getenv("AZURE_FOUNDRY_ENDPOINT"))
foundry_set_key("your-api-key")
```

## Next steps

Read
[`vignette("embeddings", package = "foundryR")`](https://farach.github.io/foundryR/articles/embeddings.md)
for similarity search and clustering patterns. Use
[`vignette("content-safety", package = "foundryR")`](https://farach.github.io/foundryR/articles/content-safety.md)
when model outputs or user inputs need a safety gate.
