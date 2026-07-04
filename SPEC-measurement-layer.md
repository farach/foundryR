# foundryR Measurement Layer: Implementation Specification

Status: draft for implementation Owner: Alex (farach) Audience: coding
agent (Claude Code, Codex, Copilot) plus human reviewer Repo:
github.com/farach/foundryR

------------------------------------------------------------------------

## 0. How to use this spec (instructions to the coding agent)

1.  Read this entire file before writing any code. 1a. Enumerate the
    skills available in your environment (repo-level `.claude/skills/`,
    user-level skills, or equivalent). If a skill router skill exists,
    consult it FIRST and follow its routing for this task before
    applying any other skill. Known relevant skill: `wti-dataviz`, which
    is REQUIRED for any figures produced for the vignette or pkgdown
    articles (M6). If no router or no skills are found, state that
    explicitly in your plan and proceed using this spec alone. 1b. Scope
    discipline: every function, file, and exported symbol you create
    must trace to a numbered section of this spec. If you believe code
    is needed that has no spec anchor, STOP and propose a spec
    amendment; do not write unanchored code. Unreferenced code found
    during review is deleted, not justified after the fact.
2.  Read the existing package source in `R/` to learn current
    conventions: httr2 request construction, error handling style,
    tibble-first return values, credential handling
    ([`foundry_set_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_endpoint.md),
    [`foundry_set_key()`](https://farach.github.io/foundryR/reference/foundry_set_key.md),
    [`foundry_set_token()`](https://farach.github.io/foundryR/reference/foundry_set_token.md)),
    and the existing testthat setup.
3.  Implement ONE milestone (Section 11) per pull request. Do not
    combine milestones. Each PR must pass `devtools::check()` with no
    new errors, warnings, or notes, and all new code must have tests.
4.  Do not modify existing transport functions
    ([`foundry_chat()`](https://farach.github.io/foundryR/reference/foundry_chat.md),
    [`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md),
    [`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md),
    [`foundry_embed()`](https://farach.github.io/foundryR/reference/foundry_embed.md),
    batch and file functions) except where a milestone explicitly says
    to add a parameter. Reuse them internally.
5.  If you encounter anything listed in Section 12 (Open questions
    reserved for Alex), STOP and ask. Do not choose silently.
6.  Before Milestone 5, fetch and read the current CRAN documentation
    for the `ipd` package to verify its exact function signature and
    expected data layout. Details of the ipd API in this spec are marked
    \[Verify\] and must be confirmed against current docs, not assumed.

------------------------------------------------------------------------

## 1. Context and goal

foundryR currently provides a tidy access layer to Microsoft Azure AI
Foundry. This spec adds a measurement layer that treats LLM annotation
as a research instrument: replicated annotation with full parameter
capture, reliability statistics, gold-set design and validation, a
handoff to inference-on-predicted-data estimators (the `ipd` package),
and executable provenance.

Target user: a researcher or analyst who uses an LLM to label text at
scale and needs the resulting estimates to be defensible in a paper,
report, or regulatory context.

Positioning sentence for docs and README: “Turn LLM output into
estimates you can defend.”

## 2. Non-goals

- No new estimators. Bias correction is delegated to `ipd` (Suggests).
- No changes to image, video, or speech-synthesis functions.
- No provider abstraction in this phase. Foundry is the only backend,
  but see Section 3 rule 4 for the seam that keeps extraction possible
  later.
- No Shiny or GUI components.
- No agent/MCP surface in this phase.
- No promotional, comms, or marketing content. pkgdown highlight
  articles are governed by a separate brief owned by Alex; the only
  narrative artifact in scope here is the flagship vignette (M6). Do not
  draft announcement posts, taglines, or promotional copy under this
  spec.
- No multi-agent orchestration frameworks, swarm infrastructure, or
  workflow engines. The only multi-agent structure permitted is the
  sequential role protocol in Section 11 (implementer, reviewer, CRAN
  skeptic), each run as an independent fresh-context session.

## 3. Design principles

1.  Long format is canonical: one row per unit per replication. All
    summaries (consensus, reliability) are derived views.
2.  Every output row carries its own provenance columns. A row separated
    from its tibble must still identify model, parameters, and codebook.
3.  Idempotency: identical (text, codebook, model, params, rep) never
    pays for tokens twice. Caching is content-addressed.
4.  Transport seam: measurement functions must not call httr2 directly.
    They call a single internal generic, `annotate_backend()`, whose
    default method wraps the existing Foundry transport. This is the
    extraction seam for a future provider-agnostic package. Keep it
    internal (not exported).
5.  CRAN hygiene: hard dependencies limited to what the package already
    imports plus `digest` and `jsonlite` (verify jsonlite is not already
    an import). `ipd` goes in Suggests. Reliability math is implemented
    natively, not via `irr` or similar.
6.  Every user-facing message uses the package’s existing messaging
    style (cli if already used; otherwise match existing conventions).

## 4. New files

    R/codebook.R      foundry_codebook(), foundry_schema(), codebook_diff(),
                      print/format methods, hashing
    R/annotate.R      foundry_annotate(), annotate_backend() internal generic,
                      realtime and batch drivers, budget guardrail
    R/cache.R         content-addressed cache: key construction, read/write,
                      foundry_cache_clear(), foundry_cache_status()
    R/consensus.R     foundry_consensus(), stability flags
    R/reliability.R   foundry_reliability(), native Cohen's kappa,
                      Krippendorff's alpha (nominal + ordinal), bootstrap CI,
                      confusion matrix, print and report methods
    R/gold.R          foundry_gold_design(), foundry_gold_join()
    R/ipd.R           foundry_to_ipd() adapter (+ optional thin wrapper)
    R/provenance.R    foundry_provenance(), methods_paragraph(),
                      write_provenance()

Tests mirror this layout under `tests/testthat/`.

## 5. Data contracts

### 5.1 Codebook object

Class `foundry_codebook`. A list with elements:

| element      | type    | notes                                       |
|--------------|---------|---------------------------------------------|
| name         | chr(1)  | slug, lowercase, hyphens allowed            |
| version      | chr(1)  | semver string, validated                    |
| instructions | chr(1)  | the system/instruction prompt               |
| schema       | list    | JSON Schema list, built by foundry_schema() |
| examples     | list    | NULL                                        |
| created      | POSIXct | UTC                                         |
| hash         | chr(1)  | sha256 over canonical serialization of      |
|              |         | (instructions, schema, examples, version)   |

Canonical serialization:
`jsonlite::toJSON(..., auto_unbox = TRUE, digits = NA, null = "null")`
of a list with elements in the fixed order above, then
`digest::digest(algo = "sha256")` on the resulting string. Document this
so hashes are reproducible across sessions.

`foundry_schema(...)` is a light constructor producing the JSON Schema
list in the same shape
[`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
already accepts. Provide helpers `type_boolean(desc)`,
`type_enum(desc, values)`, `type_string(desc)`, `type_number(desc)`. If
ellmer-style helpers already exist in the package, reuse them instead of
duplicating.

`codebook_diff(old, new)` prints a unified diff of instructions and a
field-level diff of schema and examples, plus both hashes.

Print method: renders like a content-analysis codebook (name, version,
hash prefix, variable list with types and allowed values, n examples).

### 5.2 Annotation tibble

Class `c("foundry_annotation", class(tibble::tibble()))`.

Columns, in order (dot-prefixed to avoid collisions with user data):

| column             | type     | notes                                  |
|--------------------|----------|----------------------------------------|
| {id_col}           | as input | user’s id column, name preserved       |
| .text_hash         | chr      | sha256 of the unit text                |
| .rep               | int      | 1..reps                                |
| {label columns}    | varies   | one column per schema property         |
| .model             | chr      | model id requested                     |
| .deployment        | chr      | Foundry deployment name                |
| .temperature       | dbl      |                                        |
| .codebook          | chr      | codebook name                          |
| .codebook_version  | chr      |                                        |
| .codebook_hash     | chr      | full sha256                            |
| .response_id       | chr      | provider response id, NA if from cache |
| .prompt_tokens     | int      |                                        |
| .completion_tokens | int      |                                        |
| .created           | POSIXct  | UTC                                    |
| .from_cache        | lgl      |                                        |

Attributes: `codebook` (the codebook object), `run_meta` (list: endpoint
hash, api flavor, mode realtime/batch, seed, started/finished
timestamps, package version). Store the endpoint as a sha256 hash, never
the raw URL, so sidecars can be shared without leaking resource
addresses.

Failed units: on per-unit failure after retries, emit the row with NA
labels and add attribute `failures` (tibble of id, rep, error message).
Never silently drop rows; row count must equal n_units x reps.

### 5.3 Provenance sidecar (JSON)

Top-level keys (all snake_case):

    provenance_version, created,
    codebook {name, version, sha256, n_examples, schema},
    model {id, deployment, endpoint_sha256, api},
    parameters {temperature, reps, seed, mode},
    data {n_units, id_col, text_col, unit_hash_algo},
    gold {n, design, strata, seed} (null if absent),
    usage {requests, cached, prompt_tokens, completion_tokens, est_cost_usd},
    reliability {alpha_reps, alpha_ci, kappa_vs_human, accuracy, per_class}
      (null if absent),
    estimate {method, formula, package_versions} (null if absent),
    session {r_version, foundryR_version, os, locale}

`est_cost_usd` requires a pricing table; see Section 12 item 4 before
implementing (ship NULL if undecided).

## 6. Function specifications

### 6.1 foundry_annotate()

``` r

foundry_annotate(
  data, text, codebook,
  model = NULL, id = NULL,
  reps = 1, temperature = 0.3, seed = NULL,
  mode = c("realtime", "batch"),
  budget_usd = NULL, max_requests = NULL,
  cache = TRUE, verbose = TRUE, ...
)
```

- `text`, `id` use tidy evaluation (unquoted column names). If `id` is
  NULL, create `.id` from row numbers and warn.
- Builds one request per (unit, rep) using the codebook instructions as
  system prompt and the schema for structured output, reusing the
  internals of
  [`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
  /
  [`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md).
- Before any network call: compute request count and estimated tokens,
  print a plan line (n units, reps, requests, cache hits expected,
  mode). If `budget_usd` or `max_requests` would be exceeded, abort with
  a clear error before spending anything. In interactive sessions with
  more than 1,000 non-cached requests and no explicit budget, ask for
  confirmation.
- Realtime mode: sequential or chunked requests through the existing
  transport with retry/backoff matching package conventions.
- Batch mode: reuse
  [`foundry_batch_requests()`](https://farach.github.io/foundryR/reference/foundry_batch_requests.md),
  [`foundry_file_upload()`](https://farach.github.io/foundryR/reference/foundry_file_upload.md),
  [`foundry_batch_create()`](https://farach.github.io/foundryR/reference/foundry_batch_create.md).
  Provide `foundry_annotate_status(job)` and
  `foundry_annotate_collect(job)` so long jobs are resumable across
  sessions; collect must merge results into the same annotation tibble
  contract and write them into the cache.
- Cache behavior in Section 7.

### 6.2 foundry_consensus()

``` r

foundry_consensus(ann, method = c("majority", "unanimous"), ties = "na")
```

Returns one row per unit: modal label per schema property, `.agreement`
(share of reps agreeing with mode), `.stable` (lgl, agreement \>=
threshold, default 0.8), plus provenance columns collapsed where
constant. Keeps class `foundry_annotation` with attribute
`collapsed = TRUE`.

### 6.3 foundry_reliability()

``` r

foundry_reliability(ann, human = NULL, by = NULL,
                    level = c("nominal", "ordinal"),
                    boot = 1000, conf = 0.95, seed = NULL)
```

Computes, per label column (or the one named in `by`):

1.  Intra-model across reps: Krippendorff’s alpha treating reps as
    coders; percent unanimous; count of unstable units.
2.  Model vs human (if `human` supplied, joined on the id column):
    Cohen’s kappa on consensus labels vs human, accuracy, sensitivity,
    specificity (binary) or per-class precision/recall (multiclass),
    confusion matrix.
3.  Model vs model: if `ann` contains multiple `.model` values, pairwise
    alpha between models on consensus labels.

Bootstrap CIs for alpha: resample units with replacement, `boot` draws.

Native implementations required, with unit tests against published
worked examples (Section 9). Return object class `foundry_reliability`:
list of tibbles plus metadata;
[`print()`](https://rdrr.io/r/base/print.html) renders the block format
shown in the package README example; `report(rel)` returns a character
methods-style paragraph fragment.

### 6.4 foundry_gold_design() and foundry_gold_join()

``` r

foundry_gold_design(data, n, strata = NULL, seed = NULL)
```

Stratified (proportional) or simple random sampling. Returns a list of
class `foundry_gold_design`: `sample` (the selected rows with
`.gold = TRUE`), `record` (tibble: method, n, strata variable, seed,
per-stratum counts, created). The record is what provenance consumes;
the seed is mandatory in the record (generate and report one if the user
passed NULL).

``` r

foundry_gold_join(ann, human, by = NULL, suffix = "_human")
```

Validates that human labels use the codebook’s allowed values; errors on
unknown labels listing offenders. Joins onto the annotation tibble.

### 6.5 foundry_to_ipd()

``` r

foundry_to_ipd(ann, human, outcome = NULL, collapse = "majority")
```

Produces the stacked data frame `ipd` expects: gold rows carry both the
human label (truth) and the model label (prediction); non-gold rows
carry the model label only; a `set_label` column distinguishes “labeled”
and “unlabeled”. \[Verify\] Confirm required column naming and the
`ipd::ipd()` signature against current CRAN docs before implementing;
adjust the adapter, not the annotation contract, if they differ. Include
a `skip_on_cran`-guarded integration test that runs a small end-to-end
example when `ipd` is installed.

### 6.6 foundry_provenance() and friends

``` r

foundry_provenance(ann, reliability = NULL, estimate = NULL)
methods_paragraph(prov, style = c("generic", "apa"))
write_provenance(prov, path)   # writes path.json and path.md
```

`methods_paragraph()` is template-based (glue), not model-generated:
deterministic output, no network calls. It must gracefully omit
sentences for absent components (no reliability object, no estimate).
`estimate` handling: accept an `ipd` fit object if available and extract
method name and formula defensively; otherwise accept a plain list the
user builds.

## 7. Caching

- Location: `tools::R_user_dir("foundryR", "cache")`, overridable via
  option `foundryR.cache_dir`.
- Key: sha256 of the canonical JSON of (text, codebook_hash, model,
  deployment, temperature, seed, rep_index, api_flavor).
- Value: the parsed label list plus usage metadata, stored as one JSON
  file per key (no rds; keep it inspectable).
- `foundry_annotate(cache = TRUE)` reads before requesting and writes
  after. `.from_cache` column records hits.
- `foundry_cache_status()` prints entry count and size;
  `foundry_cache_clear(codebook = NULL)` clears all or one codebook
  hash.
- Never cache failures.

## 8. Dependencies

- Imports (new): `digest`; `jsonlite` if not already imported.
- Suggests (new): `ipd`.
- Do not add: `irr`, `boot`, `caret`, or any tidymodels component beyond
  what the package already uses.

## 9. Testing plan

1.  Transport mocking: use the package’s existing HTTP mocking approach;
    if none exists, introduce `httptest2` (Suggests) with recorded
    fixtures. No test may hit the network on CRAN.
2.  Reliability math against published values (hard requirement):
    - Cohen’s kappa: reproduce the worked example in Cohen (1960), and
      cross-check one two-coder table against a hand-computed value in
      the test comment.
    - Krippendorff’s alpha: reproduce the nominal-data worked example
      from Krippendorff’s published reliability notes (the widely
      reprinted coder-pair example; document the exact source table in
      the test). Tolerance 1e-6.
    - Degenerate cases: single category (alpha undefined, return NA with
      warning), all-agree, all-disagree, missing values.
3.  Contract tests: column names, types, and row count invariants of the
    annotation tibble, including the failure path (NA rows plus failures
    attribute).
4.  Cache tests: hit/miss, invalidation on codebook edit, corrupted
    cache entry handled by re-request.
5.  Snapshot tests: codebook print, reliability print, methods_paragraph
    output, sidecar JSON (with volatile fields normalized).
6.  Batch mode: unit-test request-file construction and collect/merge
    using fixtures; do not test live batch jobs.

## 10. Documentation

- Roxygen for every exported function, with runnable `\dontrun{}`
  examples matching this spec’s usage.
- One flagship vignette: “From text to defensible estimates: LLM
  annotation as measurement” following the job-tasks example (2,400 task
  statements, binary ai_applicable, 5 reps, 250-unit stratified gold
  set, PPI++ via ipd). Structure: codebook, gold design, annotate,
  reliability, corrected estimate, provenance. Use a small bundled
  synthetic dataset so the vignette builds without credentials; show
  real-call code in non-evaluated chunks.
- README: add a “Measurement” section above the endpoint feature list
  and move the positioning sentence to the first paragraph.
- pkgdown: new reference section “Measurement” listing these functions
  first.

## 11. Milestones (one PR each, in order)

### 11.0 Verification loop (applies to EVERY milestone)

Run this loop before declaring any milestone done. Do not skip steps.

1.  Implement against the milestone’s spec sections only.
2.  Self-review: re-read the relevant spec sections, then read your own
    diff line by line and note every deviation.
3.  Mechanical checks: run lintr (add a `.lintr` config in M1 if
    absent), `devtools::check()` (zero new errors/warnings/notes), and
    the full test suite.
4.  Gap analysis: produce a table in the PR description listing every
    requirement of the milestone (by spec section) with status MET,
    PARTIAL, or NOT MET, with one line of evidence each (test name,
    file, or line reference). PARTIAL or NOT MET items block the
    milestone.
5.  Dead-code check: confirm no unexported, uncalled functions; no
    commented-out blocks; no TODO markers without a linked issue; no new
    exports beyond Sections 4 and 6. Delete anything unanchored per
    Section 0 rule 1b.
6.  Reviewer pass (fresh context): a NEW session/agent that did not
    write the code reads only this spec and the diff, and independently
    repeats steps 2, 4, and 5. The reviewer’s findings are resolved
    before merge. Implementer and reviewer must not share a context
    window.

### 11.1 Sequential role protocol

Three roles, always sequential, never concurrent, each a fresh
session: - Implementer: writes code for exactly one milestone. -
Reviewer: adversarial spec-conformance review (step 6 above). - CRAN
skeptic: runs once, at M7, per Section 11.9. No other agent roles are
authorized by this spec.

M1 Codebook. codebook.R with constructor, schema helpers, hashing,
print, diff. Acceptance: hashes stable across sessions; snapshot tests
pass; check() clean.

M2 Annotate (realtime) + cache. annotate.R, cache.R, the
annotate_backend() seam, budget guardrail, failure semantics.
Acceptance: contract tests pass against mocked transport; second
identical run performs zero network calls; exceeding budget aborts
before any request.

M3 Annotate (batch). Batch driver reusing existing batch functions;
status/collect; cache writes on collect. Acceptance: fixture-based round
trip produces a contract-conformant tibble flagged mode=batch.

M4 Consensus + reliability. consensus.R, reliability.R with native kappa
and alpha plus bootstrap CIs, print and report methods. Acceptance:
published-value tests pass at 1e-6; print snapshot matches spec format.

M5 Gold + ipd adapter. gold.R, ipd.R. Acceptance: design record is
complete and seeded; label validation errors are informative; ipd
integration test (skipped on CRAN) runs end to end; \[Verify\] items
resolved against current ipd docs and noted in the PR description.

M6 Provenance + vignette + README. provenance.R, sidecar writer,
methods_paragraph, flagship vignette, README and pkgdown updates.
Acceptance: sidecar validates against the schema in 5.3; vignette builds
without credentials; check() clean. All vignette and article figures
follow the wti-dataviz skill.

### 11.9 M7 Red-team pre-mortem (after M6, before CRAN submission)

Purpose: surface the strongest criticisms this package will face and
resolve each one BEFORE release. Run as three independent fresh-context
sessions, one per persona. Each persona reads the spec, the full package
source, the vignette, and pkgdown output, then writes its harshest
good-faith review.

Personas: - P1 rOpenSci-style package reviewer: API design, statistical
software standards, test coverage, documentation completeness,
dependency hygiene, CRAN policy compliance. - P2 Methods-focused
academic referee (quantitative social science / economics): validity of
the measurement claims, whether the vignette’s inferential workflow is
defensible, whether limitations are honestly stated. - P3
Tidyverse-fluent R programmer: ergonomics, naming, tidy-eval
correctness, print methods, error messages, “why not just use ellmer and
mall” skepticism.

Seed criticisms (each persona must address the relevant ones; finding
none of these applicable requires stated justification): 1. Reliability
math is wrong or untested against authoritative values. 2. “LLM labels
are not measurement”: the package legitimizes treating model output as
data without sufficient methodological guardrails. 3. Reproducibility:
results change across model versions and even identical calls; seeds and
caching give false comfort. 4. “This is just an API wrapper with extra
steps.” 5. Azure lock-in: the measurement layer is chained to one
vendor. 6. Dependency and check hygiene: bloat, fragile Suggests
behavior, network calls in tests or vignettes. 7. Cost opacity: users
cannot predict spend before committing.

Resolution rule: every criticism raised must map to exactly one of (a) a
new or existing test, (b) a documentation or API change, or (c) an
explicit paragraph in a “Limitations” section of the flagship vignette.
Dismissal is not an available resolution. Output: a `RED-TEAM.md` report
at repo root listing each criticism, its resolution type, and a link to
the commit or file that resolves it, plus GitHub issues for anything
deferred with justification. Acceptance: RED-TEAM.md complete; zero
criticisms without a mapped resolution; Alex signs off on every item
resolved as type (c).

## 12. Open questions reserved for Alex (agent must ask, not decide)

1.  Default temperature for replication (spec says 0.3; confirm) and
    whether to expose a `models = c(...)` multi-model replication mode
    in M2 or defer it.
2.  Whether unstable units (low rep agreement) should be excluded by
    default in foundry_to_ipd() or passed through with a flag.
3.  Naming: `foundry_annotate` vs `foundry_code` (content-analysis
    vocabulary). Spec assumes foundry_annotate.
4.  Cost estimation table (per-model pricing) for est_cost_usd: include
    a static table that can go stale, or ship NULL until a pricing
    endpoint exists?
5.  Whether methods_paragraph() should offer a citation string/BibTeX
    for the package itself (relates to a future CITATION file and any
    paper).
6.  Whether to submit for rOpenSci software review or JOSS after CRAN
    acceptance. This affects M7 emphasis (rOpenSci standards checklists)
    and the CITATION file. The agent prepares for it only if Alex says
    so.

## 13. Style conventions

- Match existing package style; tidyverse style guide otherwise.
- lintr must pass with the repo `.lintr` config; no per-line
  suppressions without a comment explaining why.
- No dead code: no unexported uncalled functions, no commented-out
  blocks, no TODOs without linked issues.
- Exported API surface is frozen to Sections 4 and 6 of this spec; any
  additional export requires a spec amendment first.
- Errors and warnings must name the offending argument and show the
  offending values (first 5, then a count).
- All timestamps UTC. All hashes sha256, lowercase hex.
- No new global state beyond the documented cache dir and options
  prefixed `foundryR.`.
- NEWS.md entry per milestone.
