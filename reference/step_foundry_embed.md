# Foundry Embedding Recipe Step

Create text embeddings using an Azure AI Foundry model as part of a
tidymodels recipe. This step converts text columns into embedding
features for downstream modeling tasks such as classification,
regression, or clustering.

## Usage

``` r
step_foundry_embed(
  recipe,
  ...,
  role = "predictor",
  trained = FALSE,
  model = NULL,
  dimensions = NULL,
  prefix = "emb_",
  keep_original = FALSE,
  columns = NULL,
  skip = FALSE,
  id = recipes::rand_id("foundry_embed")
)

# S3 method for class 'step_foundry_embed'
tidy(x, ...)
```

## Arguments

- recipe:

  A recipe object. The step will be added to the sequence of operations
  for this recipe.

- ...:

  Not used

- role:

  Character. Role for the new embedding variables. Default:
  `"predictor"`.

- trained:

  Logical. Internal use only. Indicates whether the step has been
  trained.

- model:

  Character. The deployment name of an Azure AI Foundry embedding model
  (e.g., "text-embedding-ada-002", "text-embedding-3-small"). If `NULL`,
  defaults to the `AZURE_FOUNDRY_EMBED_MODEL` environment variable.

- dimensions:

  Integer or NULL. The number of dimensions for the output embeddings.
  Only supported by some models (e.g., text-embedding-3-\*). If `NULL`,
  uses the model's default dimensionality.

- prefix:

  Character. Prefix for the new embedding column names. Default:
  `"emb_"`. Columns will be named `{prefix}{original_col}_{1}`,
  `{prefix}{original_col}_{2}`, etc.

- keep_original:

  Logical. Should the original text column(s) be retained? Default:
  `FALSE`.

- columns:

  Character vector. Internal use only. Stores column names after
  training.

- skip:

  Logical. Should the step be skipped when the recipe is baked? While
  all operations are baked when
  [`recipes::prep()`](https://recipes.tidymodels.org/reference/prep.html)
  is run, some operations may not be applicable to new data (e.g.,
  processing the outcome variable). Default: `FALSE`.

- id:

  Character. Unique identifier for this step. Automatically generated if
  not provided.

- x:

  A `step_foundry_embed` object

## Value

An updated recipe object with the new step appended to the sequence of
existing steps.

A tibble with columns: `terms`, `model`, `dimensions`, `id`

## Details

This step uses
[`foundry_embed()`](https://farach.github.io/foundryR/reference/foundry_embed.md)
to generate embeddings for each text column specified. During the `bake`
phase, each text value is sent to the Azure AI Foundry API, and the
resulting embedding vector is expanded into multiple numeric columns.

### Column naming

For a text column named `"description"` with 1536-dimensional embeddings
and the default prefix `"emb_"`, the output columns will be named:
`emb_description_1`, `emb_description_2`, ..., `emb_description_1536`.

### Handling failures

If an embedding request fails for a particular row (e.g., due to API
errors), the corresponding embedding columns will be filled with `NA`
values for that row.

### Performance considerations

Embedding generation requires API calls for each row of data. For large
datasets, consider:

- Using `skip = TRUE` during cross-validation to avoid redundant API
  calls

- Pre-computing embeddings for training data and caching the results

- Using batch processing strategies for very large datasets

## See also

[`foundry_embed()`](https://farach.github.io/foundryR/reference/foundry_embed.md)
for the underlying embedding function,
[`recipes::recipe()`](https://recipes.tidymodels.org/reference/recipe.html)
for creating recipes,
[`recipes::prep()`](https://recipes.tidymodels.org/reference/prep.html)
and
[`recipes::bake()`](https://recipes.tidymodels.org/reference/bake.html)
for processing recipes.

## Examples

``` r
if (FALSE) { # \dontrun{
library(recipes)

# Sample data
df <- data.frame(
  text = c("Hello world", "Machine learning is great", "R is awesome"),
  category = c("greeting", "tech", "tech")
)

# Create a recipe with Foundry embeddings
rec <- recipe(~ text, data = df) %>%
  step_foundry_embed(text, model = "text-embedding-ada-002")

# Prepare and bake the recipe
prepped <- prep(rec, training = df)
baked <- bake(prepped, new_data = df)

# With custom dimensions (model-dependent)
rec_custom <- recipe(~ text, data = df) %>%
  step_foundry_embed(
    text,
    model = "text-embedding-3-small",
    dimensions = 256,
    prefix = "vec_"
  )

# Keep original text column
rec_keep <- recipe(~ text, data = df) %>%
  step_foundry_embed(text, model = "text-embedding-ada-002", keep_original = TRUE)

# Use in a tidymodels workflow
library(tidymodels)

wf <- workflow() %>%
  add_recipe(rec) %>%
  add_model(logistic_reg()) %>%
  fit(data = train_data)
} # }
```
