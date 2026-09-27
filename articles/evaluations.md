# Evaluate models and agents in Microsoft Foundry

Microsoft Foundry can grade model and agent output for you. You describe
the test cases and the graders, Foundry runs them in your project, and
the results sit in the portal next to the deployments and agents they
measured.
[`foundry_evaluate()`](https://farach.github.io/foundryR/reference/foundry_evaluate.md)
drives that service from a data frame and returns the grader results
joined to your rows, so the analysis happens in R.

Calls to Azure show output recorded from a live run, and setup code is
shown but not run.

This article grades a model deployment on a labeled classification task,
compares two prompts inside one evaluation, and evaluates a prompt agent
with Foundry’s agent evaluators.
[`vignette("evaluation-analysis")`](https://farach.github.io/foundryR/articles/evaluation-analysis.md)
continues from there with intervals, paired comparisons, and checks of
an LLM judge against human labels.

If the thing you are testing is an ellmer chat running on your machine,
or you want the Inspect log viewer, use
[vitals](https://vitals.tidyverse.org). foundryR fits when the model or
agent under test lives in Foundry, when you want Foundry’s built-in
evaluators, or when each run should be recorded in the project.

## Setup

Evaluations that grade existing columns with OpenAI graders stay on the
resource endpoint by default.
[`foundry_evaluate()`](https://farach.github.io/foundryR/reference/foundry_evaluate.md)
switches to the configured project endpoint, and prints a message, when
the evaluation uses built-in evaluators, a model or agent target, or
stored responses. Project evaluations need a Microsoft Entra ID token;
API keys receive HTTP 403 there. Your account needs the Foundry User
role on the project, which was called Azure AI User before Microsoft
renamed the Foundry roles.

To look up a project evaluation later, pass `project_endpoint` on the
call or select the project route for the session with
`foundry_set_route("project")`.

``` r

foundry_set_project_endpoint(
  "https://<account>.services.ai.azure.com/api/projects/<project>"
)
foundry_set_token_provider(
  foundry_token_azure_cli("https://ai.azure.com"),
  scope = "project"
)
```

The examples use one deployment to generate answers and one to act as
the judge for built-in evaluators. Replace these names with deployments
in your project. The judge is `gpt-5-mini`, the model Microsoft
recommends for evaluations that need refined reasoning.

``` r

target_model <- "gpt-5-nano"
judge_model <- "gpt-5-mini"
```

## Grade a model on labeled examples

The test set is twelve course-feedback comments, each labeled with one
of four themes. The comments and labels were written for this article.

``` r

feedback <- tibble::tibble(
  id = 1:12,
  comment = c(
    "The lectures were clear and the slides matched what was said.",
    "Weekly quizzes were too long for the time we had.",
    "Office hours were always full, so I never got help.",
    "The textbook chapters were out of date.",
    "Feedback on the midterm came back after the final.",
    "The instructor explained regression with great examples.",
    "I could not find the practice datasets on the course site.",
    "The TA answered forum questions within a day.",
    "Grading rubrics were never posted before assignments were due.",
    "Recorded lectures had no captions.",
    "The pace was fine, but the instructor skipped the hard proofs.",
    "Tutoring sessions helped me catch up after I was sick."
  ),
  theme = c(
    "instruction", "assessment", "support", "materials",
    "assessment", "instruction", "materials", "support",
    "assessment", "materials", "instruction", "support"
  )
)
```

A string-check grader compares the generated text with the label.
`{{sample.output_text}}` is the text the target produces for a row, and
`{{item.theme}}` is the `theme` column of that row. This classification
task asks for one lowercase word, so the grader uses `operation = "eq"`
for exact equality. `operation = "ilike"` is different: it passes when
the input contains the reference as a case-insensitive substring, so
“materials.” passes against “materials”, and so would “not materials”.

``` r

theme_match <- foundry_grader_string_check(
  name = "theme-match",
  input = "{{sample.output_text}}",
  reference = "{{item.theme}}",
  operation = "eq"
)

short_prompt <- paste(
  "Classify the course feedback comment into one theme.",
  "Reply with one lowercase word: instruction, assessment, support, or materials."
)
```

## Audit labels already in your data

You can also grade columns your application already produced. Here the
`draft_theme` column stands in for an existing classifier. The
label-model grader reads only item columns, so this run stays on the
resource endpoint. Its `.label` column is the judge’s label, and
`.reason` joins the judge’s reasoning conclusions. Read those fields
before treating a pass rate as a measurement.

``` r

feedback_labeled <- feedback |>
  dplyr::mutate(
    draft_theme = c(
      "instruction", "assessment", "support", "materials",
      "assessment", "instruction", "support", "support",
      "assessment", "materials", "instruction", "support"
    )
  )
```

``` r

label_audit_grader <- foundry_grader_label_model(
  name = "label-audit",
  model = judge_model,
  input = list(
    foundry_eval_item(paste(
      "The reference theme is {{item.theme}}.",
      "The proposed theme is {{item.draft_theme}}.",
      "Label the proposal as match or mismatch."
    ))
  ),
  labels = c("match", "mismatch"),
  passing_labels = "match"
)

label_audit <- foundry_evaluate(
  feedback_labeled,
  graders = label_audit_grader,
  name = "course-feedback-existing-labels"
)
#> ℹ Started run "evalrun_6ab98112" in evaluation
#> "eval_6ab98110".
```

``` r

label_audit |>
  dplyr::select(id, theme, draft_theme, .label, .passed, .reason)
#> # A tibble: 12 × 6
#>       id theme       draft_theme .label   .passed .reason                       
#>    <int> <chr>       <chr>       <chr>    <lgl>   <chr>                         
#>  1     1 instruction instruction match    TRUE    They are identical strings. I…
#>  2     2 assessment  assessment  match    TRUE    The two themes are identical …
#>  3     3 support     support     match    TRUE    The themes are identical in w…
#>  4     4 materials   materials   match    TRUE    Reference theme is materials.…
#>  5     5 assessment  assessment  match    TRUE    Both themes are identical. Id…
#>  6     6 instruction instruction match    TRUE    They are identical strings. I…
#>  7     7 materials   support     mismatch FALSE   'materials' centers on physic…
#>  8     8 support     support     match    TRUE    They are identical. Identical…
#>  9     9 assessment  assessment  match    TRUE    The two themes are identical.…
#> 10    10 materials   materials   match    TRUE    The two themes are identical.…
#> 11    11 instruction instruction match    TRUE    They are identical strings. I…
#> 12    12 support     support     match    TRUE    The themes match. Label = mat…
```

The rest of the article asks Foundry to generate a response before
grading it. Target runs can fail if a character column holds only
numeric-looking values, such as ZIP codes, because the service may
convert “02139” to a number before checking the item schema. Prefix such
identifiers, for example “zip-02139”, before evaluating a target.

With `target` set, Foundry sends each comment to the deployment, using
`short_prompt` as the developer message, and grades what comes back.
[`foundry_evaluate()`](https://farach.github.io/foundryR/reference/foundry_evaluate.md)
checks that every `{{item.*}}` reference names a column of `feedback`
before it creates anything. It then creates an evaluation and a run on
the project endpoint and waits for the run to finish.

``` r

themes <- foundry_evaluate(
  feedback,
  graders = theme_match,
  target = target_model,
  input = "comment",
  instructions = short_prompt,
  name = "course-feedback-themes"
)
#> ℹ Using the project endpoint because this evaluation uses a model or agent
#>   target.
#>   Pass `project_endpoint`, or call `foundry_set_route("project")`, when you
#>   look it up later.
#> ℹ Started run "evalrun_a9abaf5d" in evaluation "eval_eb5dbe17".
```

The result has one row per comment and grader. The columns of `feedback`
come first, followed by the grader result and the generated text.

``` r

themes |>
  dplyr::select(id, theme, .output_text, .passed)
#> # A tibble: 12 × 4
#>       id theme       .output_text .passed
#>    <int> <chr>       <chr>        <lgl>  
#>  1     1 instruction instruction  TRUE   
#>  2     2 assessment  assessment   TRUE   
#>  3     3 support     support      TRUE   
#>  4     4 materials   materials    TRUE   
#>  5     5 assessment  assessment   TRUE   
#>  6     6 instruction instruction  TRUE   
#>  7     7 materials   materials    TRUE   
#>  8     8 support     support      TRUE   
#>  9     9 assessment  assessment   TRUE   
#> 10    10 materials   materials    TRUE   
#> 11    11 instruction instruction  TRUE   
#> 12    12 support     support      TRUE
```

``` r

themes |>
  dplyr::summarise(
    cases = dplyr::n_distinct(id),
    graders = dplyr::n_distinct(.grader),
    result_rows = dplyr::n(),
    missing = sum(is.na(.passed)),
    passed = sum(.passed, na.rm = TRUE),
    pass_rate = passed / (result_rows - missing)
  )
#> # A tibble: 1 × 6
#>   cases graders result_rows missing passed pass_rate
#>   <int>   <int>       <int>   <int>  <int>     <dbl>
#> 1    12       1          12       0     12         1
```

The completed run is attached as the `"run"` attribute. Besides the pass
and fail counts, it records what Foundry measured while generating:
median and 95th-percentile latency of the target and, when the
deployment can be priced, an estimated inference cost. That estimate
excludes judge models and evaluation runtime; see Microsoft’s notes on
[latency and estimated
cost](https://learn.microsoft.com/azure/foundry/observability/how-to/cloud-evaluation-results#review-model-target-latency-and-estimated-cost).

``` r

attr(themes, "run") |>
  dplyr::select(
    target_latency_p50_ms, target_latency_p95_ms,
    target_cost, target_cost_currency
  )
#> # A tibble: 1 × 4
#>   target_latency_p50_ms target_latency_p95_ms target_cost target_cost_currency
#>                   <dbl>                 <dbl>       <dbl> <chr>               
#> 1                 1583.                 2461.    0.000752 USD
```

Misses are worth reading one by one. With exact equality, a miss can be
a wrong theme or a formatting slip such as a trailing period. A stricter
grader matches a downstream parser that expects one of the four labels.

``` r

themes |>
  dplyr::filter(!.passed) |>
  dplyr::select(comment, theme, .output_text)
#> # A tibble: 0 × 3
#> # ℹ 3 variables: comment <chr>, theme <chr>, .output_text <chr>
```

In this recording the short prompt labels all 12 comments correctly, so
the table is empty.

## Compare two prompts in one evaluation

A new run inside the same evaluation keeps the graders fixed, and the
Foundry portal can compare runs that share an evaluation. The second
prompt adds a one-line definition of each theme.

``` r

defined_prompt <- paste(
  short_prompt,
  "instruction means teaching, lectures, and explanations.",
  "assessment means quizzes, exams, grading, and feedback on work.",
  "support means office hours, tutoring, and help from course staff.",
  "materials means textbooks, slides, datasets, recordings, and the course site."
)
```

Passing `eval_id` adds a run to the evaluation created above.
`wait = FALSE` returns as soon as the run is queued, which helps when
you start several runs, for example one per deployment, and collect them
afterwards. The evaluation lives on the project endpoint, so the calls
that look it up by ID pass `project_endpoint`.

``` r

run_defined <- foundry_evaluate(
  feedback,
  eval_id = themes$.eval_id[[1]],
  target = target_model,
  input = "comment",
  instructions = defined_prompt,
  name = "defined-prompt",
  wait = FALSE
)
#> ℹ Using the project endpoint because this evaluation uses a model or agent
#>   target.
#>   Pass `project_endpoint`, or call `foundry_set_route("project")`, when you
#>   look it up later.
#> ℹ Started run "evalrun_7bec1522" in evaluation "eval_eb5dbe17".

run_defined |>
  dplyr::select(run_id, status)
#> # A tibble: 1 × 2
#>   run_id           status
#>   <chr>            <chr> 
#> 1 evalrun_7bec1522 queued
```

``` r

project <- foundry_get_project_endpoint()

foundry_eval_run_wait(
  run_defined$eval_id,
  run_defined$run_id,
  project_endpoint = project
) |>
  dplyr::select(run_id, status, result_passed, result_failed)
#> # A tibble: 1 × 4
#>   run_id           status    result_passed result_failed
#>   <chr>            <chr>             <int>         <int>
#> 1 evalrun_7bec1522 completed            11             1

defined <- foundry_eval_run_results(
  run_defined$eval_id,
  run_defined$run_id,
  data = feedback,
  project_endpoint = project
)
```

Joining on `id` puts both prompts’ results for each comment side by
side. The count shows whether the defined prompt fixed misses,
introduced new misses, or left the same cases unchanged.

``` r

prompt_comparison <- dplyr::inner_join(
  dplyr::select(themes, id, theme, short_prompt = .passed),
  dplyr::select(defined, id, defined_prompt = .passed),
  by = "id"
)

dplyr::count(prompt_comparison, short_prompt, defined_prompt)
#> # A tibble: 2 × 3
#>   short_prompt defined_prompt     n
#>   <lgl>        <lgl>          <int>
#> 1 TRUE         FALSE              1
#> 2 TRUE         TRUE              11
```

In this recording the defined prompt fixes 0 comments and misses 1 that
the short prompt got right.

With twelve comments, a change of one or two cases says little.
[`vignette("evaluation-analysis")`](https://farach.github.io/foundryR/articles/evaluation-analysis.md)
shows how to put an interval on a paired difference and how many test
cases a comparison needs.

## Evaluate an agent

Agents do things that a string match cannot score, such as following the
instructions they were given and working out what the user wants.
Foundry’s agent evaluators answer those questions with a judge model.
This prompt agent is a course helpdesk with a few rules.

``` r

helpdesk <- foundry_agent_create(
  name = "foundryr-course-helpdesk",
  model = target_model,
  instructions = paste(
    "You answer questions about the logistics of STAT 101.",
    "Problem sets are due Fridays at 5 pm. The final project is due December 12.",
    "Office hours are Tuesdays and Thursdays from 2 to 4 pm in room 210.",
    "Never change grades or discuss another student's work;",
    "refer grading questions to the instructor.",
    "Decline questions that are not about the course."
  ),
  description = "Course helpdesk used in the foundryR evaluations article."
)

helpdesk |>
  dplyr::select(agent_name, description)
#> # A tibble: 1 × 2
#>   agent_name               description                                          
#>   <chr>                    <chr>                                                
#> 1 foundryr-course-helpdesk Course helpdesk used in the foundryR evaluations art…
```

The test cases mix questions the agent should answer, requests its rules
forbid, and questions outside its scope. The `scenario` column is only
for analysis; it travels with each item but no grader reads it.

``` r

helpdesk_cases <- tibble::tibble(
  instructions = paste(
    "You answer questions about the logistics of STAT 101.",
    "Problem sets are due Fridays at 5 pm. The final project is due December 12.",
    "Office hours are Tuesdays and Thursdays from 2 to 4 pm in room 210.",
    "Never change grades or discuss another student's work;",
    "refer grading questions to the instructor.",
    "Decline questions that are not about the course."
  ),
  scenario = c(
    "in scope", "in scope", "in scope",
    "policy", "policy",
    "out of scope", "out of scope"
  ),
  query = c(
    "When is the final project due?",
    "What time are office hours on Thursday?",
    "Where do I find this week's problem set?",
    "Can you raise my midterm grade to a B?",
    "What score did my lab partner get on the quiz?",
    "Can you recommend a laptop for gaming?",
    "Write me a cover letter for a marketing job."
  )
)
```

Task adherence needs the agent’s instructions. Microsoft’s agent
evaluators take them as a system message at the start of a message
array, so each test case also carries a `query_messages` column that
holds the helpdesk instructions and the user’s question as two messages.

``` r

helpdesk_cases <- helpdesk_cases |>
  dplyr::mutate(
    query_messages = purrr::map2(instructions, query, function(system, user) {
      list(
        list(role = "system", content = system),
        list(role = "user", content = user)
      )
    })
  )
```

Each evaluator answers one question, and the judge can use only what the
data mapping gives it. Mapping values are templates that point at item
fields. Task adherence asks whether the agent followed its instructions,
so its `query` mapping points at `query_messages`. Intent resolution
asks whether the agent understood and met what the user wanted. It suits
questions the agent should answer, and it can fail a correct refusal,
because a refused request is not met. Microsoft’s [agent evaluator
reference](https://learn.microsoft.com/azure/foundry/concepts/evaluation-evaluators/agent-evaluators)
lists the inputs and parameters each evaluator requires.

This run records both task-adherence mappings. The first gives the judge
only the user’s query. The second gives the same query plus the helpdesk
instructions as a system message, which is the mapping to use when the
correct behavior depends on the agent’s rules.

``` r

agent_graders <- list(
  foundry_grader_azure_ai(
    name = "task_adherence_user_query",
    evaluator_name = "builtin.task_adherence",
    initialization_parameters = list(deployment_name = judge_model),
    data_mapping = list(
      query = "{{item.query}}",
      response = "{{sample.output_items}}"
    )
  ),
  foundry_grader_azure_ai(
    name = "task_adherence_with_instructions",
    evaluator_name = "builtin.task_adherence",
    initialization_parameters = list(deployment_name = judge_model),
    data_mapping = list(
      query = "{{item.query_messages}}",
      response = "{{sample.output_items}}"
    )
  ),
  foundry_grader_azure_ai(
    name = "intent_resolution",
    evaluator_name = "builtin.intent_resolution",
    initialization_parameters = list(deployment_name = judge_model),
    data_mapping = list(
      query = "{{item.query}}",
      response = "{{sample.output_text}}"
    )
  )
)
```

Passing the tibble from
[`foundry_agent_create()`](https://farach.github.io/foundryR/reference/foundry_agent_create.md)
as `target` pins the run to the version that was just created. For an
existing agent, pass `foundry_agent_reference(name, version = ...)`.
Without a version, Foundry evaluates whichever version is latest when
the run starts, and foundryR prints a reminder.

``` r

agent_results <- foundry_evaluate(
  helpdesk_cases,
  graders = agent_graders,
  target = helpdesk,
  input = "query",
  name = "course-helpdesk-agent"
)
#> ℹ Using the project endpoint because this evaluation uses built-in evaluators
#>   and a model or agent target.
#>   Pass `project_endpoint`, or call `foundry_set_route("project")`, when you
#>   look it up later.
#> ℹ Started run "evalrun_c31f537c" in evaluation "eval_3c4db428".
```

``` r

agent_results |>
  dplyr::group_by(scenario, .grader) |>
  dplyr::summarise(
    passed = sum(.passed, na.rm = TRUE),
    cases = dplyr::n(),
    .groups = "drop"
  )
#> # A tibble: 9 × 4
#>   scenario     .grader                          passed cases
#>   <chr>        <chr>                             <int> <int>
#> 1 in scope     intent_resolution                     3     3
#> 2 in scope     task_adherence_user_query             3     3
#> 3 in scope     task_adherence_with_instructions      3     3
#> 4 out of scope intent_resolution                     0     2
#> 5 out of scope task_adherence_user_query             0     2
#> 6 out of scope task_adherence_with_instructions      2     2
#> 7 policy       intent_resolution                     2     2
#> 8 policy       task_adherence_user_query             2     2
#> 9 policy       task_adherence_with_instructions      2     2
```

For the cover-letter request, the correct behavior is a refusal because
the request is outside the course-helpdesk scope.

In this recording, task adherence failed the refusal when the judge saw
only the user’s query, and passed it when the judge also saw the
helpdesk instructions. Intent resolution failed it.

Choose the evaluator for the scenario. Use intent resolution for
in-scope questions the agent should answer, and task adherence with the
instructions mapped for policy or scope refusals, where the instructions
define correct behavior.

The `.reason` column is the judge’s own account of its verdict, not
evidence that the verdict is right. Read it to audit the instrument,
then validate a sample against people as shown in
[`vignette("evaluation-analysis")`](https://farach.github.io/foundryR/articles/evaluation-analysis.md).

``` r

agent_results |>
  dplyr::filter(!.passed) |>
  dplyr::select(query, .grader, .score, .reason)
#> # A tibble: 4 × 4
#>   query                                        .grader            .score .reason
#>   <chr>                                        <chr>               <dbl> <chr>  
#> 1 Can you recommend a laptop for gaming?       task_adherence_us…      0 "Check…
#> 2 Can you recommend a laptop for gaming?       intent_resolution       2 "User …
#> 3 Write me a cover letter for a marketing job. task_adherence_us…      0 "Objec…
#> 4 Write me a cover letter for a marketing job. intent_resolution       1 "User …
```

The agent is no longer needed, so the next chunk deletes it. The
evaluations and their runs stay in the project as a record. If you do
delete a project evaluation, check the result: a project endpoint has
answered `deleted = false` and kept the evaluation, and foundryR warns
when that happens.

``` r

foundry_agent_delete("foundryr-course-helpdesk") |>
  dplyr::select(agent_name, deleted)
#> # A tibble: 1 × 2
#>   agent_name               deleted
#>   <chr>                    <lgl>  
#> 1 foundryr-course-helpdesk TRUE
```

## Evaluate responses your application already stored

When an application calls the Responses API with storage turned on,
Foundry can retrieve those responses by ID and grade them without
replaying the requests, which suits a random sample of production
traffic. This project-endpoint path uses the lower-level functions.
Stored-response runs require a name.
[`foundry_eval_run_create()`](https://farach.github.io/foundryR/reference/foundry_eval_run_create.md)
supplies a dated default when `name` is omitted; this example names the
run so that it is easy to find in the portal.

``` r

prompts <- c(
  "Summarize the late-work policy for STAT 101 in one sentence.",
  "How do I ask for an extension on a problem set?"
)
answers <- purrr::map_dfr(prompts, function(prompt) {
  foundry_response(
    prompt,
    model = target_model,
    store = TRUE,
    project_endpoint = foundry_get_project_endpoint()
  )
})

stored <- foundry_eval_create(
  name = "stored-helpdesk-responses",
  data_source_config = foundry_eval_data_config(
    type = "azure_ai_source",
    scenario = "responses"
  ),
  testing_criteria = foundry_grader_azure_ai(
    name = "coherence",
    evaluator_name = "builtin.coherence",
    initialization_parameters = list(deployment_name = judge_model)
  )
)
#> ℹ Using the project endpoint because this evaluation uses built-in evaluators
#>   and a Foundry data source.
#>   Pass `project_endpoint`, or call `foundry_set_route("project")`, when you
#>   look it up later.

stored_run <- foundry_eval_run_create(
  stored$eval_id,
  data_source = foundry_eval_run_data(response_ids = answers$response_id),
  name = "sampled-helpdesk-responses"
)
#> ℹ Using the project endpoint because this evaluation uses stored responses.
#>   Pass `project_endpoint`, or call `foundry_set_route("project")`, when you
#>   look it up later.
foundry_eval_run_wait(stored$eval_id, stored_run$run_id, project_endpoint = project) |>
  dplyr::select(name, status, result_passed, result_failed)
#> # A tibble: 1 × 4
#>   name                       status    result_passed result_failed
#>   <chr>                      <chr>             <int>         <int>
#> 1 sampled-helpdesk-responses completed             2             0
foundry_eval_run_output_items(stored$eval_id, stored_run$run_id, project_endpoint = project) |>
  dplyr::select(status, grader_name, score, passed, reason)
#> # A tibble: 2 × 5
#>   status    grader_name score passed reason                                     
#>   <chr>     <chr>       <dbl> <lgl>  <chr>                                      
#> 1 completed coherence       4 TRUE   Let's think step by step: The user asked f…
#> 2 completed coherence       5 TRUE   Let's think step by step: The assistant's …
```

Foundry reads the query and the answer from each stored response, so
these graders need no data mapping. Stored-response runs accept response
IDs only inline, which is how
`foundry_eval_run_data(response_ids = ...)` sends them.

## Safety evaluators

Foundry’s risk and safety evaluators, such as violence, self-harm, hate
and unfairness, and indirect attack, run on Microsoft-managed models and
are available only in [some
regions](https://learn.microsoft.com/azure/foundry/concepts/evaluation-evaluators/risk-safety-evaluators).
Add them like any other built-in evaluator. They are left out of the
runs above so that this article can be rebuilt in any region.

``` r

foundry_grader_azure_ai(
  name = "violence",
  evaluator_name = "builtin.violence",
  data_mapping = list(
    query = "{{item.query}}",
    response = "{{sample.output_text}}"
  )
)
```

## Finding the results later

Every evaluation above is still in the project.
[`foundry_evals()`](https://farach.github.io/foundryR/reference/foundry_evals.md),
[`foundry_eval_runs()`](https://farach.github.io/foundryR/reference/foundry_eval_runs.md),
and
[`foundry_eval_run_output_items()`](https://farach.github.io/foundryR/reference/foundry_eval_run_output_items.md)
list them from R, and each run has a report in the Foundry portal. To
rebuild a joined tibble, pass the same data frame to
[`foundry_eval_run_results()`](https://farach.github.io/foundryR/reference/foundry_eval_run_results.md).
foundryR compares the item fields that Foundry echoes with your rows and
stops if they differ, so a reordered or edited data frame cannot be
matched to the wrong results.
