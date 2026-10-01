# foundryR Evaluation and Experimentation Layer: Plan

Status: future plan, not scheduled. Nothing here is implemented.
Owner: Alex (farach)
Target: a release after 1.0.0
Related: `maintainer/SPEC-measurement-layer.md`, which shares the long
format, bootstrap intervals, the ipd handoff, and the provenance sidecar.

---

## 0. How to use this plan

1. This is a plan, not an implementation spec. Before implementing a
   milestone, turn it into a spec that follows the process rules in
   sections 0 and 11 of `SPEC-measurement-layer.md`: one milestone per pull
   request, a spec anchor for every export, the verification loop, and a
   fresh-context review.
2. Items marked [Verify] must be confirmed against current Microsoft Learn
   documentation and a live Foundry project before any code is written.
3. Items marked [Decide] and everything in section 9 are Alex's decisions.

## 1. Goal

Let R users compare models, prompts, and agents on the same test cases and
capture evaluation metrics they can defend, without leaving R.

Division of labor: Foundry runs and stores the evaluations; R compares them
with valid uncertainty and records how each result was produced.

## 2. What 1.0.0 already provides

- `foundry_evaluate()` (experimental) turns a data frame into an evaluation
  and run and returns one row per input row and grader. It grades existing
  columns, or generates responses first with `target`: a model deployment or
  a pinned agent version from `foundry_agent_reference(name, version)`.
  `eval_id` adds a run to an existing evaluation with the same graders, and
  `wait = FALSE` with `foundry_eval_run_wait()` and
  `foundry_eval_run_results()` collects runs later. Rows are matched through
  the reserved `foundryr_row_id` field, never by position.
- Graders: `foundry_grader_string_check()`,
  `foundry_grader_text_similarity()`, `foundry_grader_label_model()`,
  `foundry_grader_score_model()`, and `foundry_grader_azure_ai()` for
  built-in evaluators such as `builtin.coherence`,
  `builtin.task_adherence`, and `builtin.intent_resolution`.
- Lower-level lifecycle functions: `foundry_eval_create()`,
  `foundry_eval_run_create()`, `foundry_eval_runs()`,
  `foundry_eval_run_output_items()`, and `foundry_eval_run_data()`, whose
  `response_ids` argument grades responses an application already stored.
- Run tibbles carry per-criterion results, target latency (p50, p95), and
  estimated target cost with a completeness field.
- Local metrics: `foundry_agreement()` (accuracy, macro precision, recall
  and F1, Cohen's kappa, Krippendorff's alpha), `foundry_consistency()`
  (stability across repeated extractions), `foundry_provenance()`, and
  `foundry_codebook()` hashing.
- `vignette("evaluation-analysis")` shows Wilson intervals, an exact
  McNemar test, a bootstrap that resamples cases, a sample-size calculation
  (Connor, 1987), judge validation against human labels, and cost and
  latency trade-offs. All of it is example code, not package functions.

## 3. Gaps

1. Comparing several candidates is manual: one call per candidate, passing
   `eval_id`, waiting on each run, and stacking results with `bind_rows()`.
2. The comparison statistics exist only as vignette code that users copy.
   The Foundry portal's run comparison uses a t-test, not a paired test.
3. Nothing records which dataset, graders, candidates, and versions
   produced a result.
4. Each candidate runs once, so run-to-run variation from nondeterministic
   generation and judging is not measured.
5. `vignette("api-support")` lists Foundry project surfaces that foundryR
   does not wrap: datasets, evaluator catalogs, evaluation taxonomies and
   rules, insights, red-team schedules and runs, and schedules.

## 4. Principles

1. Foundry is the system of record. Every run stays in the Foundry project
   and portal. foundryR adds no local experiment database and no MLflow or
   Weights & Biases integration.
2. Long format is canonical: one row per test case, candidate, grader, and
   replicate. Summaries are derived views, as in section 3 of the
   measurement spec.
3. Statistics functions are independent of the backend. They take any data
   frame with a case ID, a candidate column, and an outcome column, so they
   also work on results graded locally.
4. Comparisons are paired by construction: every candidate runs on the same
   rows under one evaluation, and results are matched by ID.
5. Statistics are implemented in base R. No new hard dependencies; ipd stays
   in Suggests.
6. Every new export starts experimental. The 1.0.0 stability promise does
   not cover experimental functions.
7. Cost is shown before spending: print the number of runs, generated
   responses, and judge calls before anything is launched.

## 5. Proposed components

### 5.1 Comparison statistics (no network calls)

Promote the `evaluation-analysis` vignette code into tested functions.
Names and arguments are provisional [Decide].

```r
foundry_eval_summary(results, by = NULL, outcome = ".passed", level = 0.95)
foundry_eval_contrast(results, candidate = ".candidate", case = NULL,
                      baseline = NULL, outcome = ".passed",
                      boot = 2000, level = 0.95, seed = NULL)
foundry_eval_sample_size(difference, discordance,
                         alpha = 0.05, power = 0.8)
foundry_judge_check(data, judge, human, positive = "pass")
```

- `foundry_eval_summary()`: cases, passes, missing and errored counts, pass
  rate with a Wilson interval, and the mean score with an interval for
  score graders.
- `foundry_eval_contrast()`: discordant counts, the paired difference, an
  interval from a bootstrap that resamples cases (or a paired Wald
  interval), and an exact or mid-p McNemar test for pass/fail outcomes.
  Score outcomes use a paired bootstrap of the mean difference [Decide on
  other tests]. With more than two candidates, compare each with the
  baseline and flag multiplicity [Decide].
- `foundry_eval_sample_size()`: the normal approximation from Connor
  (1987), as in the vignette.
- `foundry_judge_check()`: judge sensitivity and specificity with Wilson
  intervals, kappa through the `foundry_agreement()` internals, and the
  attenuation factor (sensitivity + specificity - 1).
- Shares bootstrap code with measurement spec M4 (`foundry_reliability()`)
  and the ipd handoff with M5 (`foundry_to_ipd()`). Build that code once.
- Tests reproduce the vignette's numbers and published worked examples
  [Verify sources].

### 5.2 `foundry_eval_compare()`

```r
foundry_eval_compare(data, graders, candidates, input = NULL,
                     instructions = NULL, reps = 1, name = NULL,
                     wait = TRUE, ...)
```

- `candidates` is a named list. Each element is a model deployment, a
  `foundry_agent_reference()`, or a list with `target`, `instructions`, and
  `sampling_params` for prompt or sampling variants. Accepting a data frame
  of candidates is an option [Decide].
- Creates one evaluation and one run per candidate and replicate, using
  `eval_id` and `wait = FALSE`, then waits for all of them. Returns the long
  tibble with `.candidate`, `.rep`, and `.run_id` columns, plus the run
  tibbles as an attribute.
- Reuses `foundry_evaluate()` internals without changing its signature.
- Runs that fail or are canceled are reported. Whether that is an error or a
  warning with partial results is [Decide].
- Resumable: the returned object keeps the evaluation and run IDs, so a
  session that times out can collect the runs later.

### 5.3 Experiment record

- Extend `foundry_provenance()` or add a new function [Decide]. Record the
  evaluation and run IDs; each candidate's deployment, agent name and
  version, instructions hash, and sampling parameters; a hash of the grader
  definitions; a hash of the dataset (the canonical JSON hashing that
  `foundry_codebook()` uses); case, missing, and errored counts; latency and
  cost with completeness; R and foundryR versions; and a UTC timestamp.
  Store the endpoint as a hash, as section 5.2 of the measurement spec
  does.
- Write a JSON sidecar whose schema matches section 5.3 of the measurement
  spec, so one format serves both layers.
- `foundry_eval_history(eval_id)`: every run of an evaluation as one long
  tibble, for tracking regressions over time. It could rebuild rows from the
  echoed `datasource_item`, so the original data frame is not needed
  [Verify].

### 5.4 Foundry surfaces, in priority order [Verify all]

1. Versioned datasets: upload a test set once and reference its name and
   version from runs, so comparisons months apart use identical cases.
   Foundry can also generate synthetic evaluation datasets.
2. Evaluator catalog: list built-in and custom (preview) evaluators with
   their required fields and initialization parameters, so
   `foundry_grader_azure_ai()` calls can be validated before a run.
3. Insights (cluster analysis, preview): failure clusters as a tibble.
4. Continuous evaluation rules, red-team runs, schedules, and benchmark
   evaluations (preview). These serve production monitoring more than
   experimentation, so they come last.

### 5.5 Agents

- Compare pinned versions, listed with `foundry_agent_versions()` and
  targeted with `foundry_agent_reference(name, version)`.
- Grade with the built-in task-adherence and intent-resolution evaluators.
- Compute tool-call metrics in R from `.output_items`, such as the number of
  tool calls, the tools used, and failed calls [Decide which].
- [Verify] Whether `foundry_agent()` loops with R tools, stored on the
  project endpoint (`project_endpoint` passes through `...`), can be graded
  with `response_ids`, and how Foundry reads a chain of responses linked by
  `previous_response_id`.

## 6. Non-goals

- No local experiment database, tracking server, or MLflow or Weights &
  Biases integration.
- No local reimplementation of Foundry graders and no parallel local
  evaluation engine.
- No breaking changes to `foundry_evaluate()` or any other export.
- No new hard dependencies; yardstick and ipd stay optional.
- No Shiny dashboards.

## 7. Risks

- Cost multiplies: candidates x replicates x cases, plus judge calls.
- Project evaluations need a Microsoft Entra ID token; API keys get HTTP 403.
- Preview APIs change. Mark the wrappers experimental and record them in
  `vignette("api-support")`.
- A judge's errors can differ between candidates, for example by favoring
  its own model family. `foundry_judge_check()` measures error but cannot
  remove that bias.
- Multiplicity across candidates and segments.
- Vignettes replay recorded httptest2 fixtures, so new live calls need new
  recordings.

## 8. Milestones, in order

- E1: comparison statistics (5.1). No network calls; lowest risk. Rewrite
  `vignette("evaluation-analysis")` to call the new functions.
- E2: `foundry_eval_compare()` with replicates (5.2). Update
  `vignette("evaluations")`.
- E3: experiment record and history (5.3).
- E4: versioned datasets and evaluator catalog (5.4, items 1 and 2).
- E5: insights, then the monitoring surfaces if users ask for them.

## 9. Open questions for Alex

1. Naming: `foundry_eval_*` for everything, or a separate
   `foundry_judge_check()`?
2. Score graders: paired bootstrap only, or also paired t and Wilcoxon
   tests?
3. Multiple comparisons: adjust by default (for example, Holm), or report
   raw p-values and flag them?
4. Experiment record: extend `foundry_provenance()`, or add a new function?
5. Should `foundry_eval_compare()` accept a data frame of candidates, or
   only a named list?
6. Build E1 before or after measurement spec M4, which shares the bootstrap
   code?

## References

Connor, R. J. (1987). Sample size for testing differences in proportions
for the paired-sample design. *Biometrics*, 43(1), 207-211.
