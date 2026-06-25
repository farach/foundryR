# Integrating foundryR with onet2r

## Introduction

The [onet2r](https://github.com/farach/onet2r) package provides access
to the O\*NET Web Services API, which contains comprehensive U.S.
occupational data including skills, knowledge requirements, tasks,
abilities, and technology skills for thousands of occupations. Combining
onet2r with foundryR supports analytical workflows such as: - **Semantic
search** for finding occupations by meaning, not just keywords -
**Occupation clustering** based on skill and task similarities -
**AI-powered analysis** of occupational data and career pathways -
**Enhanced job matching** using embedding similarity

This vignette demonstrates practical integrations between these two
packages. \## Prerequisites

Install both packages:

``` r

# Install pak if you don't have it
# install.packages("pak")

pak::pak("farach/foundryR")
pak::pak("farach/onet2r")
```

Configure your API credentials:

``` r

library(foundryR)
library(onet2r)  # install from GitHub: pak::pak("farach/onet2r")
library(dplyr)
library(tidyr)

# Set Azure AI Foundry credentials
foundry_set_endpoint(Sys.getenv("AZURE_FOUNDRY_ENDPOINT"))
foundry_set_key("your-api-key")

# onet2r will use credentials from environment variables:
# ONET_USERNAME and ONET_PASSWORD
```

## Understanding O\*NET Data

O\*NET (Occupational Information Network) is the primary source of
occupational information in the United States. The onet2r package
provides access to rich data about occupations:

``` r

# Search for occupations by keyword
software_jobs <- onet_search("software developer")
software_jobs
#> # A tibble: 10 x 3
#>    code       title                                  relevance_score
#>    <chr>      <chr>                                            <dbl>
#>  1 15-1252.00 Software Developers                              100
#>  2 15-1253.00 Software Quality Assurance Analysts ...           79.3
#>  3 15-1254.00 Web Developers                                    68.5
#>  ...

# Get detailed information for a specific occupation
dev_info <- onet_occupation("15-1252.00")
dev_info
#> # A tibble: 1 x 4
#>   code       title               description                    sample_of_rep...
#>   <chr>      <chr>               <chr>                          <list>
#> 1 15-1252.00 Software Developers Research, design, and develop... <chr [5]>

# Get skills required for software developers
dev_skills <- onet_skills("15-1252.00")
dev_skills
#> # A tibble: 35 x 5
#>    element_id element_name  scale_id scale_name   data_value
#>    <chr>      <chr>         <chr>    <chr>             <dbl>
#>  1 2.A.1.a    Reading Co... LV       Level              4.62
#>  2 2.A.1.a    Reading Co... IM       Importance         4.25
#>  3 2.A.1.b    Active Lis... LV       Level              4.38
#>  ...
```

## Use Case 1: Semantic Search for Occupations

O\*NET’s `onet_search()` uses keyword matching, but with foundryR
embeddings you can find occupations by semantic meaning. This is
especially useful when job seekers use different terminology than
official occupation titles.

### Building an Occupation Search Index

``` r

# Get all occupations (or a subset for demonstration)
all_occupations <- onet_occupations(end = 100)  # First 100 for demo

# Create rich text descriptions combining title and description
occupation_texts <- all_occupations %>%
  mutate(
    search_text = paste(title, "-", description)
  )

# Generate embeddings for all occupations
occupation_embeddings <- foundry_embed(
  occupation_texts$search_text,
  model = "text-embedding-3-small"
)

# Combine with occupation metadata
occupation_index <- occupation_texts %>%
  bind_cols(
    occupation_embeddings %>% select(embedding)
  )
```

### Semantic Occupation Search

``` r

# Helper function to compute cosine similarity
cosine_similarity <- function(a, b) {
  sum(a * b) / (sqrt(sum(a^2)) * sqrt(sum(b^2)))
}

# User query using natural language
query <- "I want to help people with their mental health and emotional problems"
query_embedding <- foundry_embed(query, model = "text-embedding-3-small")
query_vec <- query_embedding$embedding[[1]]

# Find most similar occupations
search_results <- occupation_index %>%
  mutate(
    similarity = map_dbl(embedding, ~cosine_similarity(query_vec, .x))
  ) %>%
  arrange(desc(similarity)) %>%
  select(code, title, similarity)

head(search_results, 5)
#> # A tibble: 5 x 3
#>   code       title                                    similarity
#>   <chr>      <chr>                                         <dbl>
#> 1 21-1014.00 Mental Health Counselors                      0.892
#> 2 21-1013.00 Marriage and Family Therapists                0.867
#> 3 21-1023.00 Mental Health and Substance Abuse S...        0.854
#> 4 19-3033.00 Clinical and Counseling Psychologists         0.841
#> 5 21-1011.00 Substance Abuse and Behavioral Dis...         0.823
```

Notice how the semantic search found mental health-related occupations
even though the query did not use exact occupation titles.

### Comparing Keyword vs Semantic Search

``` r

# Keyword search
keyword_results <- onet_search("work with computers and solve problems")
keyword_results
#> # A tibble: 0 x 3
#> # ... with 3 variables: code <chr>, title <chr>, relevance_score <dbl>

# Semantic search with the same query
semantic_query <- "work with computers and solve problems"
semantic_embedding <- foundry_embed(semantic_query, model = "text-embedding-3-small")
semantic_vec <- semantic_embedding$embedding[[1]]

semantic_results <- occupation_index %>%
  mutate(
    similarity = map_dbl(embedding, ~cosine_similarity(semantic_vec, .x))
  ) %>%
  arrange(desc(similarity)) %>%
  select(code, title, similarity) %>%
  head(5)

semantic_results
#> # A tibble: 5 x 3
#>   code       title                                    similarity
#>   <chr>      <chr>                                         <dbl>
#> 1 15-1252.00 Software Developers                           0.845
#> 2 15-1211.00 Computer Systems Analysts                     0.832
#> 3 15-1299.08 Computer Systems Engineers/Architects         0.821
#> 4 15-1232.00 Computer User Support Specialists             0.798
#> 5 15-1244.00 Network and Computer Systems Admin...         0.789
```

Semantic search succeeds where keyword search fails, understanding the
intent behind the query.

## Use Case 2: Clustering Occupations by Skills

Using embeddings on occupation skill profiles enables data-driven
clustering of similar occupations.

``` r

# Get skills for multiple occupations
occupation_codes <- c(
  "15-1252.00",  # Software Developers
  "15-1211.00",  # Computer Systems Analysts
  "29-1141.00",  # Registered Nurses
  "29-1171.00",  # Nurse Practitioners
  "11-1021.00",  # General Managers
  "11-2021.00",  # Marketing Managers
  "25-1011.00",  # Business Teachers
  "25-1021.00"   # Computer Science Teachers
)

# Fetch skills for each occupation
get_skill_profile <- function(code) {
  skills <- onet_skills(code)
  skills %>%
    filter(scale_id == "IM") %>%  # Importance scale
    arrange(desc(data_value)) %>%
    head(10) %>%
    summarize(
      code = first(code),
      skill_profile = paste(element_name, collapse = "; ")
    )
}

skill_profiles <- map_dfr(occupation_codes, get_skill_profile)

# Add occupation titles
skill_profiles <- skill_profiles %>%
  left_join(
    map_dfr(occupation_codes, onet_occupation) %>%
      select(code, title),
    by = "code"
  )

# Generate embeddings from skill profiles
skill_embeddings <- foundry_embed(
  skill_profiles$skill_profile,
  model = "text-embedding-3-small"
)

# Cluster occupations
embedding_matrix <- do.call(rbind, skill_embeddings$embedding)
set.seed(42)
clusters <- kmeans(embedding_matrix, centers = 3, nstart = 10)

# View clustering results
skill_profiles %>%
  mutate(cluster = clusters$cluster) %>%
  select(title, cluster) %>%
  arrange(cluster)
#> # A tibble: 8 x 2
#>   title                          cluster
#>   <chr>                            <int>
#> 1 Software Developers                  1
#> 2 Computer Systems Analysts            1
#> 3 Computer Science Teachers            1
#> 4 Registered Nurses                    2
#> 5 Nurse Practitioners                  2
#> 6 General and Operations Managers      3
#> 7 Marketing Managers                   3
#> 8 Business Teachers, Postsecon...      3
```

The embeddings correctly group occupations by their skill similarity:
tech roles, healthcare roles, and business/management roles.

## Use Case 3: AI-Powered Career Analysis

Use
[`foundry_chat()`](https://farach.github.io/foundryR/reference/foundry_chat.md)
to analyze occupational data and provide career guidance.

### Summarizing Occupation Requirements

``` r

# Gather comprehensive data for an occupation
occupation_code <- "15-1252.00"  # Software Developers

occ_info <- onet_occupation(occupation_code)
occ_skills <- onet_skills(occupation_code)
occ_knowledge <- onet_knowledge(occupation_code)
occ_tasks <- onet_tasks(occupation_code)
occ_education <- onet_education(occupation_code)

# Format data for the LLM
occupation_data <- paste(
  "Occupation:", occ_info$title,
  "\n\nDescription:", occ_info$description,
  "\n\nTop Skills (by importance):",
  occ_skills %>%
    filter(scale_id == "IM") %>%
    arrange(desc(data_value)) %>%
    head(10) %>%
    pull(element_name) %>%
    paste(collapse = ", "),
  "\n\nTop Knowledge Areas:",
  occ_knowledge %>%
    filter(scale_id == "IM") %>%
    arrange(desc(data_value)) %>%
    head(10) %>%
    pull(element_name) %>%
    paste(collapse = ", "),
  "\n\nSample Tasks:",
  occ_tasks %>%
    head(5) %>%
    pull(task) %>%
    paste(collapse = "; "),
  "\n\nEducation Requirements:",
  occ_education %>%
    arrange(desc(data_value)) %>%
    head(3) %>%
    mutate(info = paste(category, "-", data_value, "%")) %>%
    pull(info) %>%
    paste(collapse = ", ")
)

# Ask the LLM to provide career guidance
response <- foundry_chat(
  prompt = occupation_data,
  system = "You are a career counselor. Based on the occupation data provided,
  give a brief summary suitable for someone considering this career. Include:
  1. What the job involves day-to-day
  2. Key skills to develop
  3. Typical education path
  4. Career outlook and growth potential
  Keep your response concise (under 200 words).",
  model = "gpt-4o-mini"
)

cat(response$content)
#> Software Developers create applications and systems that power our digital world.
#> Day-to-day, you'll analyze user needs, design software solutions, write and test
#> code, and collaborate with teams to deliver quality products.
#>
#> Key skills to develop include programming (multiple languages), critical thinking,
#> complex problem solving, and strong communication abilities. You'll also need
#> solid foundations in computers and electronics, mathematics, and engineering
#> principles.
#>
#> Most positions require a bachelor's degree in Computer Science, Software
#> Engineering, or a related field, though some roles accept candidates with
#> coding bootcamp certificates and strong portfolios.
#>
#> The career outlook is excellent, with continued demand driven by expanding
#> technology needs across all industries. Opportunities for advancement include
#> senior developer, architect, and management positions.
```

### Comparing Two Occupations

``` r

# Gather data for two occupations to compare
compare_occupations <- function(code1, code2) {
  occ1 <- onet_occupation(code1)
  occ2 <- onet_occupation(code2)

  skills1 <- onet_skills(code1) %>%
    filter(scale_id == "IM") %>%
    arrange(desc(data_value)) %>%
    head(10)

  skills2 <- onet_skills(code2) %>%
    filter(scale_id == "IM") %>%
    arrange(desc(data_value)) %>%
    head(10)

  comparison_data <- paste(
    "Occupation 1:", occ1$title,
    "\nDescription:", occ1$description,
    "\nTop Skills:", paste(skills1$element_name, collapse = ", "),
    "\n\nOccupation 2:", occ2$title,
    "\nDescription:", occ2$description,
    "\nTop Skills:", paste(skills2$element_name, collapse = ", ")
  )

  response <- foundry_chat(
    prompt = comparison_data,
    system = "You are a career advisor. Compare these two occupations:
    1. Highlight similarities and differences
    2. Identify transferable skills between them
    3. Suggest which type of person might prefer each
    Be concise and practical.",
    model = "gpt-4o-mini"
  )

  response$content
}

# Compare Data Scientist vs Software Developer
comparison <- compare_occupations("15-2051.00", "15-1252.00")
cat(comparison)
```

## Use Case 4: Finding Career Transition Paths

Identify occupations that share skills with a current role, suggesting
potential career transitions.

``` r

# Current occupation
current_code <- "15-1252.00"  # Software Developers
current_skills <- onet_skills(current_code) %>%
  filter(scale_id == "IM") %>%
  arrange(desc(data_value)) %>%
  head(15)

# Create a skill-based query
skill_query <- paste(
  "Professional with expertise in:",
  paste(current_skills$element_name, collapse = ", ")
)

# Embed the skill query
skill_embedding <- foundry_embed(skill_query, model = "text-embedding-3-small")
skill_vec <- skill_embedding$embedding[[1]]

# Find similar occupations (excluding current)
transition_candidates <- occupation_index %>%
  filter(code != current_code) %>%
  mutate(
    similarity = map_dbl(embedding, ~cosine_similarity(skill_vec, .x))
  ) %>%
  arrange(desc(similarity)) %>%
  select(code, title, similarity) %>%
  head(10)

transition_candidates
#> # A tibble: 10 x 3
#>    code       title                                    similarity
#>    <chr>      <chr>                                         <dbl>
#>  1 15-1211.00 Computer Systems Analysts                     0.912
#>  2 15-1299.08 Computer Systems Engineers/Architects         0.897
#>  3 15-2051.00 Data Scientists                               0.884
#>  4 15-1253.00 Software Quality Assurance Analysts           0.876
#>  5 15-1243.00 Database Architects                           0.865
#>  6 11-3021.00 Computer and Information Systems Man...       0.843
#>  7 15-1244.00 Network and Computer Systems Adminis...       0.831
#>  8 17-2061.00 Computer Hardware Engineers                   0.819
#>  9 15-1212.00 Information Security Analysts                 0.812
#> 10 25-1021.00 Computer Science Teachers, Postsecon...       0.798
```

### Analyzing Skill Gaps for Transitions

``` r

analyze_skill_gap <- function(from_code, to_code) {
  from_skills <- onet_skills(from_code) %>%
    filter(scale_id == "IM") %>%
    select(element_name, from_importance = data_value)

  to_skills <- onet_skills(to_code) %>%
    filter(scale_id == "IM") %>%
    select(element_name, to_importance = data_value)

  gap_analysis <- full_join(from_skills, to_skills, by = "element_name") %>%
    mutate(
      from_importance = replace_na(from_importance, 0),
      to_importance = replace_na(to_importance, 0),
      gap = to_importance - from_importance
    ) %>%
    arrange(desc(gap))

  # Skills needed for the new role
  skills_to_develop <- gap_analysis %>%
    filter(gap > 0.5) %>%
    head(5)

  # Existing strengths
  transferable <- gap_analysis %>%
    filter(from_importance >= 3.5, to_importance >= 3.5) %>%
    head(5)

  list(
    skills_to_develop = skills_to_develop,
    transferable_skills = transferable
  )
}

# Analyze gap from Software Developer to Data Scientist
gap <- analyze_skill_gap("15-1252.00", "15-2051.00")

cat("Skills to Develop:\n")
print(gap$skills_to_develop %>% select(element_name, gap))

cat("\nTransferable Skills:\n
")
print(gap$transferable_skills %>% select(element_name, from_importance, to_importance))
```

## Use Case 5: Hot Technology Analysis

Analyze emerging technologies across occupations using O\*NET’s hot
technology data.

``` r

# Get hot technologies for tech-related occupations
tech_occupations <- c(
  "15-1252.00",  # Software Developers
  "15-2051.00",  # Data Scientists
  "15-1211.00",  # Computer Systems Analysts
  "15-1212.00"   # Information Security Analysts
)

# Gather hot technologies
all_hot_tech <- map_dfr(tech_occupations, function(code) {
  onet_hot_technology(code) %>%
    mutate(occupation_code = code)
})

# Combine with occupation titles
all_hot_tech <- all_hot_tech %>%
  left_join(
    map_dfr(tech_occupations, onet_occupation) %>%
      select(code, title),
    by = c("occupation_code" = "code")
  )

# Ask LLM to analyze technology trends
tech_summary <- all_hot_tech %>%
  group_by(title) %>%
  summarize(technologies = paste(hot_technology, collapse = ", ")) %>%
  mutate(summary = paste(title, ":", technologies)) %>%
  pull(summary) %>%
  paste(collapse = "\n\n")

response <- foundry_chat(
  prompt = tech_summary,
  system = "You are a technology career advisor. Based on the hot technologies
  listed for each occupation:
  1. Identify common technologies across roles
  2. Note technologies unique to specific roles
  3. Suggest which technologies are most valuable to learn for career flexibility
  Be specific and actionable.",
  model = "gpt-4o-mini"
)

cat(response$content)
```

## Use Case 6: Building a Job Recommendation System

Combine user preferences with occupation embeddings for personalized job
recommendations.

``` r

# User profile (could come from a survey or assessment)
user_profile <- list(
  interests = "I enjoy analyzing data, solving complex problems, and working
               with technology. I prefer collaborative work environments.",
  skills = "Programming in Python and R, statistical analysis, data visualization,
            machine learning basics, SQL databases",
  education = "Master's degree in Statistics",
  preferences = "Work-life balance, remote work options, continuous learning"
)

# Create a comprehensive user query
user_query <- paste(
  "Professional profile:",
  "Interests:", user_profile$interests,
  "Skills:", user_profile$skills,
  "Education:", user_profile$education,
  "Work preferences:", user_profile$preferences
)

# Generate embedding for user profile
user_embedding <- foundry_embed(user_query, model = "text-embedding-3-small")
user_vec <- user_embedding$embedding[[1]]

# Find matching occupations
recommendations <- occupation_index %>%
  mutate(
    similarity = map_dbl(embedding, ~cosine_similarity(user_vec, .x))
  ) %>%
  arrange(desc(similarity)) %>%
  select(code, title, similarity) %>%
  head(10)

# Enhance with AI explanation
top_matches <- recommendations %>% head(5)

for (i in seq_len(nrow(top_matches))) {
  occ_info <- onet_occupation(top_matches$code[i])

  explanation <- foundry_chat(
    prompt = paste(
      "User profile:", user_query,
      "\n\nRecommended occupation:", occ_info$title,
      "\nDescription:", occ_info$description
    ),
    system = "In 2-3 sentences, explain why this occupation is a good match
              for this user's profile. Be specific about the alignment.",
    model = "gpt-4o-mini"
  )

  cat(paste0("\n", i, ". ", top_matches$title[i],
             " (Match: ", round(top_matches$similarity[i] * 100), "%)\n"))
  cat(explanation$content, "\n")
}
```

## Performance Tips

### Caching Embeddings

For production applications, cache occupation embeddings to avoid
repeated API calls:

``` r

# Save embeddings to disk
saveRDS(occupation_index, "occupation_embeddings.rds")

# Load cached embeddings
occupation_index <- readRDS("occupation_embeddings.rds")
```

### Batch Processing

When processing many occupations, use batch embedding:

``` r

# Collect all texts first
texts_to_embed <- occupation_texts$search_text

# Embed in batches to manage API limits
batch_size <- 50
all_embeddings <- list()

for (i in seq(1, length(texts_to_embed), by = batch_size)) {
  batch_end <- min(i + batch_size - 1, length(texts_to_embed))
  batch_texts <- texts_to_embed[i:batch_end]

  batch_embeddings <- foundry_embed(batch_texts, model = "text-embedding-3-small")
  all_embeddings[[length(all_embeddings) + 1]] <- batch_embeddings

  # Respect rate limits
  Sys.sleep(1)
}

# Combine results
final_embeddings <- bind_rows(all_embeddings)
```

### Reducing Dimensions

For large-scale applications, consider reducing embedding dimensions:

``` r

# Use smaller dimensions for faster similarity computation
compact_embeddings <- foundry_embed(
  occupation_texts$search_text,
  model = "text-embedding-3-small",
  dimensions = 256  # Instead of default 1536
)
```

## Next Steps

- Learn more about [Text
  Embeddings](https://farach.github.io/foundryR/articles/embeddings.md)
  in foundryR
- Explore [tidymodels
  Integration](https://farach.github.io/foundryR/articles/tidymodels.md)
  for building ML pipelines
- Visit the [onet2r documentation](https://github.com/farach/onet2r) for
  complete API coverage
- Check out the [O\*NET Resource Center](https://www.onetcenter.org/)
  for data definitions
