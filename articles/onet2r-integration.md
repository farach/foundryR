# Match job descriptions to O\*NET occupations

Surveys, job postings, and administrative records often describe work in
free text: “I fix the office computers”, “I teach fourth grade”. Before
those records can be joined to wages, skills, or task measures, each one
needs a standard occupation code. This article matches short job
descriptions to O\*NET-SOC occupations with foundryR embeddings, checks
the matches against hand codes, and pulls the skills profile for a
matched occupation with [onet2r](https://github.com/farach/onet2r).

Calls to O\*NET and Azure show output recorded from a live run; setup
code is shown but not run.

## Setup

onet2r reads O\*NET Web Services and archived O\*NET database releases
into tibbles. It is on GitHub, not CRAN.

``` r

install.packages("foundryR")

# install.packages("pak")
pak::pak("farach/onet2r")
```

Both packages read credentials from the environment. onet2r needs a free
key from the [O\*NET Web Services developer
site](https://services.onetcenter.org/developer/), stored in `.Renviron`
as `ONET_API_KEY`.

``` r

# In .Renviron:
# ONET_API_KEY=your-onet-key

foundry_set_endpoint(Sys.getenv("AZURE_FOUNDRY_ENDPOINT"))
foundry_set_key(Sys.getenv("AZURE_FOUNDRY_KEY"))
```

``` r

library(foundryR)
library(onet2r)
library(dplyr)
```

## Get the candidate occupations

[`onet_occupations_all()`](https://farach.github.io/onet2r/reference/onet_occupations_all.html)
returns the code and title of every occupation in the current O\*NET-SOC
taxonomy in one call.

``` r

catalog <- onet_occupations_all(show_progress = FALSE)
nrow(catalog)
#> [1] 1016
```

This example compares the descriptions with four major groups: computer
and mathematical (15), education (25), healthcare practitioners (29),
and office support (43). The smaller candidate set keeps the recorded
example small. In a study, embed the full catalog once and store the
vectors.

``` r

candidates <- catalog |>
  filter(substr(code, 1, 2) %in% c("15", "25", "29", "43"))

count(candidates, major_group = substr(code, 1, 2))
#> # A tibble: 4 × 2
#>   major_group     n
#>   <chr>       <int>
#> 1 15             38
#> 2 25             68
#> 3 29             96
#> 4 43             55
```

## Write down the hand codes first

The descriptions below were written for this article, each with the code
a person would assign. In a study, draw the validation sample at random
from your data and have people code it before they see any model
matches.

``` r

responses <- tibble::tribble(
  ~id,  ~job_text,                                                                  ~hand_code,
  "r1", "I keep the office computers running, fix printers, and reset passwords.",  "15-1232.00",
  "r2", "I watch our network for intrusions and patch servers after alerts.",       "15-1212.00",
  "r3", "I teach fourth graders reading and math.",                                 "25-2021.00",
  "r4", "I teach statistics courses at a community college.",                       "25-1022.00",
  "r5", "I care for patients on a hospital ward, give medications, and chart vitals.", "29-1141.00",
  "r6", "I clean teeth and take X-rays at a dental clinic.",                        "29-1292.00",
  "r7", "I answer phones, greet visitors, and book appointments at the front desk.", "43-4171.00",
  "r8", "I process invoices and reconcile vendor payments for the accounting team.", "43-3031.00"
)
```

Check that every hand code is a current O\*NET-SOC code. A code from an
older taxonomy can never match, and the miss would look like a model
error.

``` r

setdiff(responses$hand_code, candidates$code)
#> character(0)
```

## Embed both sides with the same settings

Embeddings place texts with similar meanings near each other. Embed the
occupation titles and the job descriptions with the same model and the
same `dimensions`; vectors from different settings are not comparable.
Shorter vectors keep the stored matrix small.

``` r

title_vectors <- foundry_embed(
  candidates$title,
  model = "text-embedding-3-small",
  dimensions = 256
)
job_vectors <- foundry_embed(
  responses$job_text,
  model = "text-embedding-3-small",
  dimensions = 256
)

c(titles_failed = sum(title_vectors$.error), jobs_failed = sum(job_vectors$.error))
#> titles_failed   jobs_failed 
#>             0             0
```

## Rank occupations for each description

Dividing each vector by its length turns a matrix product into a table
of cosine similarities, with one row per description and one column per
occupation. The five highest scores in each row form a shortlist.

``` r

unit_rows <- function(x) {
  m <- do.call(rbind, x$embedding)
  m / sqrt(rowSums(m^2))
}
similarity <- unit_rows(job_vectors) %*% t(unit_rows(title_vectors))

shortlist <- purrr::map_dfr(seq_len(nrow(responses)), function(i) {
  best <- order(similarity[i, ], decreasing = TRUE)[1:5]
  tibble::tibble(
    id = responses$id[[i]],
    rank = 1:5,
    code = candidates$code[best],
    title = candidates$title[best],
    similarity = similarity[i, best]
  )
})

first_choice <- shortlist |>
  filter(rank == 1) |>
  left_join(select(responses, id, hand_code), by = "id") |>
  mutate(agrees = code == hand_code)

first_choice |>
  select(id, title, similarity, agrees)
#> # A tibble: 8 × 4
#>   id    title                                        similarity agrees
#>   <chr> <chr>                                             <dbl> <lgl> 
#> 1 r1    Library Technicians                               0.445 FALSE 
#> 2 r2    Information Security Engineers                    0.485 FALSE 
#> 3 r3    Mathematical Science Teachers, Postsecondary      0.453 FALSE 
#> 4 r4    Mathematical Science Teachers, Postsecondary      0.549 TRUE  
#> 5 r5    Acute Care Nurses                                 0.503 FALSE 
#> 6 r6    Dental Hygienists                                 0.505 TRUE  
#> 7 r7    Receptionists and Information Clerks              0.471 TRUE  
#> 8 r8    Billing and Posting Clerks                        0.505 FALSE
```

## Check the first choices against the hand codes

An O\*NET-SOC code has eight digits. The first six are the federal SOC
code, which wage and employment data such as BLS OEWS use, and the last
two pick out a more detailed O\*NET occupation. A match can miss the
detailed occupation but land in the right SOC occupation, so count
agreement at both levels, along with how often the hand code makes the
shortlist.

``` r

soc <- function(code) substr(code, 1, 7)

on_shortlist <- shortlist |>
  left_join(select(responses, id, hand_code), by = "id") |>
  group_by(id) |>
  summarise(found = any(code == hand_code))

tibble::tibble(
  descriptions = nrow(responses),
  exact = sum(first_choice$agrees),
  same_soc = sum(soc(first_choice$code) == soc(first_choice$hand_code)),
  on_shortlist = sum(on_shortlist$found)
)
#> # A tibble: 1 × 4
#>   descriptions exact same_soc on_shortlist
#>          <int> <int>    <int>        <int>
#> 1            8     3        4            5
```

In this recording the first choice matches the hand code for 3 of 8
descriptions, and the hand code is on the shortlist for 5. The misses:
r1 matched Library Technicians instead of Computer User Support
Specialists; r2 matched Information Security Engineers instead of
Information Security Analysts; r3 matched Mathematical Science Teachers,
Postsecondary instead of Elementary School Teachers, Except Special
Education; r5 matched Acute Care Nurses instead of Registered Nurses; r8
matched Billing and Posting Clerks instead of Bookkeeping, Accounting,
and Auditing Clerks. Titles are short, and many differ by a word or two,
so title similarity alone is a weak final answer. It works better as a
way to build a shortlist.

## Let a model choose from the shortlist

A model can read the whole description and compare it with each
candidate on the shortlist. The schema’s enum lists every shortlisted
code, and the instructions limit each answer to the candidates listed
with that description.

``` r

choice_input <- shortlist |>
  group_by(id) |>
  summarise(options = paste0("- ", code, ": ", title, collapse = "\n")) |>
  left_join(responses, by = "id") |>
  mutate(prompt = paste0("Job description: ", job_text, "\n\nCandidate occupations:\n", options))

choice_schema <- foundry_schema(
  choice = schema_enum(
    sort(unique(shortlist$code)),
    "Code of the candidate occupation that best matches the job description."
  )
)

chosen <- foundry_extract(
  choice_input,
  text_col = "prompt",
  schema = choice_schema,
  instructions = paste(
    "Pick the one candidate occupation that best matches the job description.",
    "Choose only from the candidates listed with the description."
  )
)

chosen |>
  left_join(select(candidates, choice = code, chosen_title = title), by = "choice") |>
  mutate(agrees = choice == hand_code) |>
  select(id, chosen_title, agrees, .error)
#> # A tibble: 8 × 4
#>   id    chosen_title                                    agrees .error
#>   <chr> <chr>                                           <lgl>  <lgl> 
#> 1 r1    Computer Network Support Specialists            FALSE  FALSE 
#> 2 r2    Information Security Analysts                   TRUE   FALSE 
#> 3 r3    Kindergarten Teachers, Except Special Education FALSE  FALSE 
#> 4 r4    Mathematical Science Teachers, Postsecondary    TRUE   FALSE 
#> 5 r5    Acute Care Nurses                               FALSE  FALSE 
#> 6 r6    Dental Hygienists                               TRUE   FALSE 
#> 7 r7    Receptionists and Information Clerks            TRUE   FALSE 
#> 8 r8    Bookkeeping, Accounting, and Auditing Clerks    TRUE   FALSE
```

The model’s choice matches the hand code for 5 of 8 descriptions,
against 3 of 8 for the first embedding match. The misses: r1 chose
Computer Network Support Specialists instead of Computer User Support
Specialists, which was not on its shortlist; r3 chose Kindergarten
Teachers, Except Special Education instead of Elementary School
Teachers, Except Special Education, which was not on its shortlist; r5
chose Acute Care Nurses instead of Registered Nurses, which was not on
its shortlist. A model cannot pick a code the shortlist leaves out, so a
longer shortlist or embeddings of the O\*NET descriptions would give it
a better set to choose from.

## Send disagreements to a person

The two methods fail in different ways, so a row where they disagree
deserves a second look. Review those rows first, then spot-check a
random sample of the rows where they agree.

``` r

review <- chosen |>
  select(id, job_text, choice, hand_code) |>
  left_join(select(first_choice, id, embedding_first = code), by = "id") |>
  mutate(methods_disagree = choice != embedding_first)

review |>
  count(methods_disagree, correct = choice == hand_code)
#> # A tibble: 4 × 3
#>   methods_disagree correct     n
#>   <lgl>            <lgl>   <int>
#> 1 FALSE            FALSE       1
#> 2 FALSE            TRUE        3
#> 3 TRUE             FALSE       2
#> 4 TRUE             TRUE        2
```

Here the methods disagree on 4 of 8 descriptions. Of the 3 rows where
the model’s choice is wrong, 2 are among the flagged rows. \## Pull the
skills profile for a match

Once a description has a code, onet2r can bring in O\*NET’s measures for
that occupation.
[`onet_skills()`](https://farach.github.io/onet2r/reference/onet_skills.html)
returns a code’s skills with an importance score; here are the top five
for the nursing description’s hand code.

``` r

nurse_code <- responses$hand_code[responses$id == "r5"]

onet_skills(nurse_code, end = 5) |>
  select(name, importance)
#> # A tibble: 5 × 2
#>   name                  importance
#>   <chr>                      <int>
#> 1 Social Perceptiveness         78
#> 2 Active Listening              75
#> 3 Coordination                  75
#> 4 Critical Thinking             75
#> 5 Service Orientation           75
```

## Record what you used

O\*NET updates the database several times a year, and occupation codes
can change when the taxonomy is revised. For a study, record the date
you pulled the catalog, the O\*NET release it came from, the embedding
model and `dimensions`, the candidate groups, and the triage rule.
onet2r’s archive functions, such as
[`onet_archive_download()`](https://farach.github.io/onet2r/reference/onet_archive_download.html)
and
[`onet_panel()`](https://farach.github.io/onet2r/reference/onet_panel.html),
let you pin an O\*NET release for longitudinal work.

This article includes information from [O\*NET Web
Services](https://services.onetcenter.org/) by the U.S. Department of
Labor, Employment and Training Administration (USDOL/ETA), used under
the [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) license.
O\*NET® is a trademark of USDOL/ETA.
