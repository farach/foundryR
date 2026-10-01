# Changelog

## foundryR (development version)

## foundryR 1.0.0

foundryR’s lifecycle stage is now stable instead of experimental. After
this release, breaking changes to exported functions will go through a
deprecation cycle. Functions marked experimental in their documentation,
and operations that use preview APIs, can still change without one; see
[`vignette("api-support")`](https://farach.github.io/foundryR/articles/api-support.md).

### Breaking changes

These changes can alter the output of code written for 0.1.0. Most fix
behavior that was wrong or that the service rejected.

- [`foundry_transcribe()`](https://farach.github.io/foundryR/reference/foundry_transcribe.md)
  now uses standard Speech fast transcription by default, with no
  enhanced mode and no model. The old default, enhanced mode with
  `mai-transcribe-1.5`, is rejected in many regions, including East
  US 2. Pass `model = "mai-transcribe-2"` or the new `enhanced = TRUE`
  to use MAI-Transcribe or LLM Speech where they are available.
- [`foundry_translate_audio()`](https://farach.github.io/foundryR/reference/foundry_translate_audio.md)
  no longer defaults to a MAI-Transcribe model for Speech translation,
  because MAI-Transcribe does not translate. Speech translation still
  needs LLM Speech enhanced mode.
- OpenAI-route audio calls
  ([`foundry_transcribe()`](https://farach.github.io/foundryR/reference/foundry_transcribe.md)
  and
  [`foundry_translate_audio()`](https://farach.github.io/foundryR/reference/foundry_translate_audio.md)
  with `service = "openai"`, and
  [`foundry_speak()`](https://farach.github.io/foundryR/reference/foundry_speak.md))
  now require an explicit `model` deployment name instead of falling
  back to `AZURE_FOUNDRY_MODEL`, which usually names a chat deployment.
- [`foundry_file_upload()`](https://farach.github.io/foundryR/reference/foundry_file_upload.md)
  no longer sends a 30-day expiry by default
  (`expires_after_seconds = NULL`). The service rejects an expiry for
  `purpose = "assistants"`, which is the default purpose, so default
  uploads failed. Pass `expires_after_seconds` to set an expiry on batch
  files.
- [`foundry_moderate()`](https://farach.github.io/foundryR/reference/foundry_moderate.md)
  now labels severities on Microsoft’s scale: 0-1 safe, 2-3 low, 4-5
  medium, 6-7 high. The old labels were wrong on the eight-level scale;
  severity 1, for example, was labeled “low”.
- [`foundry_moderate()`](https://farach.github.io/foundryR/reference/foundry_moderate.md)
  and
  [`foundry_shield()`](https://farach.github.io/foundryR/reference/foundry_shield.md)
  keep the full input text instead of truncating it, and gain an
  `.input_idx` column for joining results back to your data.
  [`foundry_shield()`](https://farach.github.io/foundryR/reference/foundry_shield.md)
  names documents by their original position, so skipping an empty
  document no longer renumbers the rest.
  [`foundry_moderate()`](https://farach.github.io/foundryR/reference/foundry_moderate.md)
  gains a `blocklist_hit` column.
- [`foundry_moderate()`](https://farach.github.io/foundryR/reference/foundry_moderate.md),
  [`foundry_shield()`](https://farach.github.io/foundryR/reference/foundry_shield.md),
  and
  [`foundry_groundedness()`](https://farach.github.io/foundryR/reference/foundry_groundedness.md)
  return `NA` when the service omits a safety field, instead of
  reporting the input as safe or clean.
- [`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
  returns your columns first, then the extracted fields, then the
  dot-prefixed metadata. Field types now follow the schema: a JSON
  `null` becomes a typed `NA`, and array and object fields are always
  list-columns. It stops before sending any request when a schema field
  has the same name as one of your columns.
- [`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
  and
  [`foundry_embed_batch()`](https://farach.github.io/foundryR/reference/foundry_embed_batch.md)
  show progress bars only in interactive sessions. Set
  `options(foundryR.progress = TRUE)` to see them in scripts.
- [`foundry_embed_batch()`](https://farach.github.io/foundryR/reference/foundry_embed_batch.md)
  stores only each row’s own metadata in `raw_response`. It used to copy
  the whole batch response, every embedding included, into every row: 22
  MB instead of 2.5 MB in memory for 200 texts.
- [`foundry_usage()`](https://farach.github.io/foundryR/reference/foundry_usage.md)
  no longer counts cached input tokens twice. The input token count the
  service reports includes cached tokens, so the cost is now
  `(input - cached) * input + cached * cached_input + output * output`,
  and cached tokens are billed at the `input` rate when no
  `cached_input` rate is given.
- [`foundry_agreement()`](https://farach.github.io/foundryR/reference/foundry_agreement.md)
  no longer switches to irr when it is installed. It always uses its own
  two-coder Krippendorff’s alpha, so results no longer depend on which
  packages are installed. Kappa and alpha are `NA`, with a warning, when
  only one category occurs. Macro precision, recall, and F1 use one
  label set and drop classes whose value is undefined, with a warning,
  as yardstick does. It also warns when the two label sets differ and
  reports how many incomplete pairs it dropped.
- [`foundry_consistency()`](https://farach.github.io/foundryR/reference/foundry_consistency.md)
  compares records after sorting their keys, at full numeric precision.
  Key order no longer counts as a disagreement, and values are no longer
  rounded to four decimals before comparison.
- [`foundry_provenance()`](https://farach.github.io/foundryR/reference/foundry_provenance.md)
  records a 64-character SHA-256 schema hash, the same one
  [`foundry_codebook()`](https://farach.github.io/foundryR/reference/foundry_codebook.md)
  uses, and a UTC timestamp. Hashes recorded by 0.1.0 will not match.
- [`step_foundry_embed()`](https://farach.github.io/foundryR/reference/step_foundry_embed.md)
  resolves the embedding model at `prep()` and keeps it, so changing
  `AZURE_FOUNDRY_EMBED_MODEL` later no longer changes the model `bake()`
  uses. The disk cache key now includes the model and the endpoint.

### New features

- [`foundry_evaluate()`](https://farach.github.io/foundryR/reference/foundry_evaluate.md)
  runs a Microsoft Foundry cloud evaluation from a data frame. It
  creates the evaluation and run, waits for the run, and returns one row
  per input row and grader with the input columns kept. It grades
  existing columns, or has Foundry generate responses with a model
  deployment or agent first (`target`), and `eval_id` adds a run to an
  existing evaluation so runs can be compared. Rows are matched to
  results through a reserved `foundryr_row_id` field (`"row-1"`,
  `"row-2"`, …) that the service echoes back, never by position. This
  function and the two below are experimental.
- [`foundry_eval_run_wait()`](https://farach.github.io/foundryR/reference/foundry_eval_run_wait.md)
  polls an evaluation run until it finishes, and
  [`foundry_eval_run_results()`](https://farach.github.io/foundryR/reference/foundry_eval_run_results.md)
  joins a completed run’s grader results to the evaluated data frame.
- [`foundry_eval_run_data()`](https://farach.github.io/foundryR/reference/foundry_eval_run_data.md)
  builds target runs for model deployments and agents (`target`,
  `input_messages`) and stored-response runs (`response_ids`).
  [`foundry_eval_data_config()`](https://farach.github.io/foundryR/reference/foundry_eval_data_config.md)
  gains `type = "azure_ai_source"` with a `scenario` argument.
- Evaluation functions gain a `project_endpoint` argument. They use the
  resource endpoint, as in 0.1.0, unless you pass `project_endpoint`,
  call `foundry_set_route("project")`, or the evaluation uses a feature
  that exists only on a project endpoint: built-in evaluators, a model
  or agent target, or stored responses. Those calls use the configured
  project endpoint and print a message saying so. Target and
  stored-response runs get a default name, which the service requires.
- Evaluation run tibbles now include `per_testing_criteria_results`,
  target latency (`target_latency_p50_ms`, `target_latency_p95_ms`,
  `target_latency_samples`), and estimated target cost (`target_cost`,
  `target_cost_currency`, `target_cost_completeness`). Output-item
  tibbles include the echoed `datasource_item` and the generated
  `sample_output_text` and `sample_output_items`.
- [`foundry_set_route()`](https://farach.github.io/foundryR/reference/foundry_set_route.md)
  chooses the default endpoint for the APIs that run on both a resource
  and a project endpoint: responses, files, vector stores, and
  evaluations. The default remains the resource endpoint.
- Conversations now work. The `foundry_conversation_*()` functions use
  the project endpoint, the only place conversations exist; in 0.1.0
  they called the resource endpoint and always failed with HTTP 404.
  They gain `token` and `project_endpoint` arguments.
- File and vector store functions gain `project_endpoint`, and vector
  store functions gain `token`, so the files and stores that a
  server-side agent searches can be created where the agent looks for
  them.
- [`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
  and
  [`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
  gain a `token` argument.
- [`foundry_extract_batch_results()`](https://farach.github.io/foundryR/reference/foundry_extract_batch_results.md)
  collects a finished extraction batch later, joins the results to the
  original rows through their `row-N` IDs, and flattens the fields the
  way
  [`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
  does. It warns about input rows that have no result.
  `foundry_extract_batch(wait = TRUE)` now uses it.
- [`foundry_moderate()`](https://farach.github.io/foundryR/reference/foundry_moderate.md)
  gains a `blocklist_hit` column, and
  [`foundry_transcribe()`](https://farach.github.io/foundryR/reference/foundry_transcribe.md)
  gains an `enhanced` argument.
- [`foundry_check_setup()`](https://farach.github.io/foundryR/reference/foundry_check_setup.md)
  reports project-endpoint authentication and the session route, and
  shows only the last four characters of an API key.
- The articles are rewritten around research tasks, and each shows
  output recorded from live Microsoft Foundry resources. New articles
  cover evaluations
  ([`vignette("evaluations")`](https://farach.github.io/foundryR/articles/evaluations.md))
  and the analysis of evaluation results
  ([`vignette("evaluation-analysis")`](https://farach.github.io/foundryR/articles/evaluation-analysis.md)).
  The comparison with ellmer now lives in the README and
  [`vignette("responses-api")`](https://farach.github.io/foundryR/articles/responses-api.md).
  The O*NET article is rewritten as a worked example of matching
  free-text job descriptions to O*NET-SOC occupations, with its output
  recorded live.

### Deprecated and defunct

- The video functions
  [`foundry_video_job_create()`](https://farach.github.io/foundryR/reference/foundry_video_defunct.md),
  [`foundry_video_jobs()`](https://farach.github.io/foundryR/reference/foundry_video_defunct.md),
  [`foundry_video_job_get()`](https://farach.github.io/foundryR/reference/foundry_video_defunct.md),
  [`foundry_video_job_delete()`](https://farach.github.io/foundryR/reference/foundry_video_defunct.md),
  [`foundry_video_get()`](https://farach.github.io/foundryR/reference/foundry_video_defunct.md),
  and
  [`foundry_video_download()`](https://farach.github.io/foundryR/reference/foundry_video_defunct.md)
  are defunct and raise an error. Azure OpenAI retires its last Sora
  model (`sora-2`, version 2025-12-08) on 2026-10-15 and has announced
  no replacement.
- [`type_boolean()`](https://farach.github.io/foundryR/reference/codebook_schema_helpers.md),
  [`type_enum()`](https://farach.github.io/foundryR/reference/codebook_schema_helpers.md),
  [`type_number()`](https://farach.github.io/foundryR/reference/codebook_schema_helpers.md),
  and
  [`type_string()`](https://farach.github.io/foundryR/reference/codebook_schema_helpers.md)
  are deprecated in favor of
  [`schema_boolean()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
  [`schema_enum()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
  [`schema_number()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
  and
  [`schema_string()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
  because they mask ellmer’s functions of the same names. To reuse
  ellmer types, pass them to
  [`as_foundry_schema()`](https://farach.github.io/foundryR/reference/as_foundry_schema.md).
- The bring-your-own-LLM options of
  [`foundry_groundedness()`](https://farach.github.io/foundryR/reference/foundry_groundedness.md)
  (`reasoning`, `correction`, and `llm_resource`) and
  [`foundry_llm_resource()`](https://farach.github.io/foundryR/reference/foundry_llm_resource.md)
  are deprecated. They require an Azure OpenAI GPT-4o deployment, and
  the core groundedness check does not need them.

### Bug fixes

- API errors now keep the service’s own message. The old handler
  replaced any message containing “key” with “Invalid API key” and
  labeled any 404 “Deployment not found”. The hint now depends on the
  HTTP status and on the endpoint called; for example, a 404 on the
  resource endpoint mentions that objects created on a project endpoint
  are not visible there. Empty error bodies and string-valued `error`
  fields no longer break error handling.
- [`foundry_blocklist_delete()`](https://farach.github.io/foundryR/reference/foundry_blocklists.md)
  and
  [`foundry_blocklist_remove_items()`](https://farach.github.io/foundryR/reference/foundry_blocklists.md)
  no longer fail after a successful call; the service answers 204 with
  no body.
- [`foundry_blocklist_create()`](https://farach.github.io/foundryR/reference/foundry_blocklists.md)
  without a description sends [`{}`](https://rdrr.io/r/base/Paren.html),
  not `[]`, which the service rejected. Conversation and vector store
  updates with no fields send [`{}`](https://rdrr.io/r/base/Paren.html)
  as well.
- [`foundry_moderate()`](https://farach.github.io/foundryR/reference/foundry_moderate.md)
  keeps blocklist matches when a blocklist hit halts analysis and labels
  those rows “blocked”. It used to drop them.
- `foundry_groundedness(correction = TRUE)` sends `correction`, the
  field the service reads; Microsoft Learn documents `mitigating`, which
  the live service ignores. `ungrounded_pct` is always numeric.
- [`foundry_protected_code()`](https://farach.github.io/foundryR/reference/foundry_protected_code.md)
  checks the service’s length requirement, more than 110 characters per
  snippet, before sending a request.
- [`foundry_batch_results()`](https://farach.github.io/foundryR/reference/foundry_batch_results.md)
  leaves plain-text output as text instead of reporting a JSON parse
  error, and reads downloaded output as UTF-8.
  [`foundry_batch_requests()`](https://farach.github.io/foundryR/reference/foundry_batch_requests.md)
  writes numbers at full precision and missing values as `null`, and
  separates lines with `\n` on every platform; on Windows it used to
  write `\r\n`.
- [`foundry_embed()`](https://farach.github.io/foundryR/reference/foundry_embed.md)
  and
  [`foundry_embed_batch()`](https://farach.github.io/foundryR/reference/foundry_embed_batch.md)
  treat empty strings like missing input: the row gets an error and
  nothing is sent.
- [`foundry_usage()`](https://farach.github.io/foundryR/reference/foundry_usage.md)
  accepts rates as a named list.
- [`foundry_transcribe()`](https://farach.github.io/foundryR/reference/foundry_transcribe.md)
  places `transcribe_style` under `enhancedMode.modelOptions`, as
  Microsoft Learn documents, reports enhanced-mode region failures with
  guidance, and fills `duration_ms` from Whisper `verbose_json`
  responses.
- [`foundry_vector_search()`](https://farach.github.io/foundryR/reference/foundry_vector_stores.md)
  returns the text of each content part rather than the parts’ type
  labels.
- [`foundry_eval_delete()`](https://farach.github.io/foundryR/reference/foundry_eval_delete.md)
  warns when the service does not confirm the deletion. A project
  endpoint has been observed to answer `deleted = false` and keep the
  evaluation.
- Evaluation calls to a project endpoint need a Microsoft Entra ID
  token. With only an API key they now stop before the request with an
  explanation, instead of the service’s HTTP 403. The other project APIs
  (responses, agents, conversations, files, and vector stores) accept
  the resource’s API key, as in 0.1.0.
- [`foundry_eval_run_results()`](https://farach.github.io/foundryR/reference/foundry_eval_run_results.md)
  reports each grader under the name you gave it; the resource endpoint
  appends an ID to grader names, which is now removed from `.grader`.
  For `label_model` and `score_model` graders, `.label` and `.reason`
  (and `label` and `reason` in
  [`foundry_eval_run_output_items()`](https://farach.github.io/foundryR/reference/foundry_eval_run_output_items.md))
  now hold the judge’s chosen label and the conclusions of its
  reasoning, which were empty.
- [`foundry_translate_audio()`](https://farach.github.io/foundryR/reference/foundry_translate_audio.md)
  gives region guidance when the Speech resource cannot translate,
  including the “specified model is not supported” answer seen in
  regions without LLM Speech translation.
- [`foundry_eval_run_output_items()`](https://farach.github.io/foundryR/reference/foundry_eval_run_output_items.md)
  follows the service’s pagination and returns every output item. It
  previously returned only the first page, which silently truncated
  larger runs. `limit` still caps the number of output items returned.
- [`codebook_diff()`](https://farach.github.io/foundryR/reference/codebook_diff.md)
  shows key-level changes inside a changed field, such as
  `enum: +workload`, instead of cutting values off at 77 characters.
- [`foundry_models()`](https://farach.github.io/foundryR/reference/foundry_models.md)
  is documented correctly: it lists the models available to your
  resource, not your deployments.
- [`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
  and
  [`foundry_extract_batch_results()`](https://farach.github.io/foundryR/reference/foundry_extract_batch_results.md)
  mark a row as an error when the response carries no structured data,
  and `.error_msg` names the reason, such as a refusal, a content-filter
  stop, a token-limit stop, or JSON that did not parse. These rows used
  to have empty fields and `.error = FALSE`, so they looked like valid
  missing answers.
- [`foundry_image()`](https://farach.github.io/foundryR/reference/foundry_image.md)
  fills `output_format` for gpt-image models, which report the format
  once for the whole response instead of once per image.
- `foundry_evaluate(eval_id = ...)` reads the item schema of an
  evaluation stored on a project endpoint, which reports it in a
  different place from the resource endpoint. It used to warn that it
  could not read the schema and skip the check that the evaluation can
  carry your columns.
- [`foundry_transcribe()`](https://farach.github.io/foundryR/reference/foundry_transcribe.md)
  fills `language` for Speech fast transcription from the locales the
  service reports on each phrase. It was always `NA`.
- [`foundry_set_token_provider()`](https://farach.github.io/foundryR/reference/foundry_set_token_provider.md)
  warns when an Azure CLI provider requests tokens for the wrong kind of
  endpoint. Project endpoints need `https://ai.azure.com` tokens and
  resource endpoints need Cognitive Services tokens. Setup and error
  messages now suggest `foundry_token_azure_cli("https://ai.azure.com")`
  for project endpoints.
- The 0.1.0 entry below said
  [`foundry_agreement()`](https://farach.github.io/foundryR/reference/foundry_agreement.md)
  reports Fleiss’ kappa. It reports Cohen’s kappa and Krippendorff’s
  alpha; the entry has been corrected.
- foundryR now requires httr2 1.1.1 or later, the version whose features
  it uses. irr is no longer a suggested package.

## foundryR 0.1.0

CRAN release: 2026-09-24

Initial CRAN release of foundryR, a tidy interface to Microsoft Foundry
(formerly Azure AI Foundry).

### New features

- Added Agent Service support for named, versioned prompt agents with
  [`foundry_agent_create()`](https://farach.github.io/foundryR/reference/foundry_agent_create.md),
  [`foundry_agents()`](https://farach.github.io/foundryR/reference/foundry_agents.md),
  [`foundry_agent_get()`](https://farach.github.io/foundryR/reference/foundry_agent_get.md),
  [`foundry_agent_delete()`](https://farach.github.io/foundryR/reference/foundry_agent_delete.md),
  and
  [`foundry_agent_versions()`](https://farach.github.io/foundryR/reference/foundry_agent_versions.md),
  plus a new `agent` argument on
  [`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
  (backed by
  [`foundry_agent_reference()`](https://farach.github.io/foundryR/reference/foundry_agent_reference.md))
  that runs a stored agent by name through the project-scoped Responses
  endpoint.
- Added Content Safety image moderation, protected-material detection,
  and text blocklist helpers with
  [`foundry_moderate_image()`](https://farach.github.io/foundryR/reference/foundry_moderate_image.md),
  [`foundry_protected_material()`](https://farach.github.io/foundryR/reference/foundry_protected_material.md),
  [`foundry_blocklists()`](https://farach.github.io/foundryR/reference/foundry_blocklists.md),
  and related blocklist item functions.
- Added cloud evaluation workflows with grader constructors
  ([`foundry_grader_string_check()`](https://farach.github.io/foundryR/reference/foundry_grader_string_check.md),
  [`foundry_grader_text_similarity()`](https://farach.github.io/foundryR/reference/foundry_grader_text_similarity.md),
  [`foundry_grader_label_model()`](https://farach.github.io/foundryR/reference/foundry_grader_label_model.md),
  [`foundry_grader_score_model()`](https://farach.github.io/foundryR/reference/foundry_grader_score_model.md),
  and
  [`foundry_grader_azure_ai()`](https://farach.github.io/foundryR/reference/foundry_grader_azure_ai.md)
  for `builtin.*` evaluators), evaluation and run lifecycle functions
  ([`foundry_eval_create()`](https://farach.github.io/foundryR/reference/foundry_eval_create.md),
  [`foundry_evals()`](https://farach.github.io/foundryR/reference/foundry_evals.md),
  [`foundry_eval_get()`](https://farach.github.io/foundryR/reference/foundry_eval_get.md),
  [`foundry_eval_delete()`](https://farach.github.io/foundryR/reference/foundry_eval_delete.md),
  [`foundry_eval_run_create()`](https://farach.github.io/foundryR/reference/foundry_eval_run_create.md),
  [`foundry_eval_runs()`](https://farach.github.io/foundryR/reference/foundry_eval_runs.md),
  [`foundry_eval_run_get()`](https://farach.github.io/foundryR/reference/foundry_eval_run_get.md),
  [`foundry_eval_run_cancel()`](https://farach.github.io/foundryR/reference/foundry_eval_run_cancel.md)),
  and
  [`foundry_eval_run_output_items()`](https://farach.github.io/foundryR/reference/foundry_eval_run_output_items.md),
  which returns per-row grader scores as a tibble.
- Added preview Content Safety operations:
  [`foundry_protected_code()`](https://farach.github.io/foundryR/reference/foundry_protected_code.md)
  for protected-material-in-code detection,
  [`foundry_moderate_multimodal()`](https://farach.github.io/foundryR/reference/foundry_moderate_multimodal.md)
  for image-with-text moderation, and
  [`foundry_task_adherence()`](https://farach.github.io/foundryR/reference/foundry_task_adherence.md)
  (with
  [`foundry_agent_tool()`](https://farach.github.io/foundryR/reference/foundry_agent_tool.md),
  [`foundry_agent_tool_call()`](https://farach.github.io/foundryR/reference/foundry_agent_tool_call.md),
  and
  [`foundry_agent_message()`](https://farach.github.io/foundryR/reference/foundry_agent_message.md)
  builders) for agent task-adherence checks.
- Added Responses API conversation and vector store helpers, including
  [`foundry_conversation_create()`](https://farach.github.io/foundryR/reference/foundry_conversations.md),
  [`foundry_conversations()`](https://farach.github.io/foundryR/reference/foundry_conversations.md),
  [`foundry_vector_store_create()`](https://farach.github.io/foundryR/reference/foundry_vector_stores.md),
  [`foundry_vector_search()`](https://farach.github.io/foundryR/reference/foundry_vector_stores.md),
  and
  [`foundry_tool_file_search()`](https://farach.github.io/foundryR/reference/foundry_tool_file_search.md).
- Added
  [`foundry_codebook()`](https://farach.github.io/foundryR/reference/foundry_codebook.md)
  and
  [`codebook_diff()`](https://farach.github.io/foundryR/reference/codebook_diff.md)
  for versioned measurement-layer codebooks with deterministic SHA-256
  hashes, schema helper wrappers, print output, and codebook diffs.
- Added schema constructors with
  [`foundry_schema()`](https://farach.github.io/foundryR/reference/foundry_schema.md),
  [`schema_string()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
  [`schema_enum()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
  [`schema_number()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
  [`schema_integer()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
  [`schema_boolean()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
  [`schema_array()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
  [`schema_object()`](https://farach.github.io/foundryR/reference/schema_constructors.md),
  and
  [`as_foundry_schema()`](https://farach.github.io/foundryR/reference/as_foundry_schema.md)
  for strict structured-output schemas.
- Added validation helpers
  [`foundry_agreement()`](https://farach.github.io/foundryR/reference/foundry_agreement.md),
  [`foundry_consistency()`](https://farach.github.io/foundryR/reference/foundry_consistency.md),
  and
  [`foundry_provenance()`](https://farach.github.io/foundryR/reference/foundry_provenance.md)
  for publication-oriented annotation checks and reproducibility
  metadata.
- Added v1 Batch API workflows with
  [`foundry_batch_create()`](https://farach.github.io/foundryR/reference/foundry_batch_create.md),
  [`foundry_batches()`](https://farach.github.io/foundryR/reference/foundry_batches.md),
  [`foundry_batch_get()`](https://farach.github.io/foundryR/reference/foundry_batch_get.md),
  [`foundry_batch_cancel()`](https://farach.github.io/foundryR/reference/foundry_batch_cancel.md),
  and
  [`foundry_batch_requests()`](https://farach.github.io/foundryR/reference/foundry_batch_requests.md)
  for large-scale prompt, annotation, extraction, and classification
  jobs.
- Added v1 Files API support with
  [`foundry_file_upload()`](https://farach.github.io/foundryR/reference/foundry_file_upload.md),
  [`foundry_files()`](https://farach.github.io/foundryR/reference/foundry_files.md),
  [`foundry_file_get()`](https://farach.github.io/foundryR/reference/foundry_file_get.md),
  [`foundry_file_delete()`](https://farach.github.io/foundryR/reference/foundry_file_delete.md),
  and
  [`foundry_file_download()`](https://farach.github.io/foundryR/reference/foundry_file_download.md)
  for Batch, eval, fine-tuning, and file-search workflows.
- Added
  [`foundry_agent()`](https://farach.github.io/foundryR/reference/foundry_agent.md)
  and
  [`foundry_tool()`](https://farach.github.io/foundryR/reference/foundry_tool.md)
  for a bounded Responses API function-calling loop with user-defined R
  tools.
- Added
  [`foundry_batch_results()`](https://farach.github.io/foundryR/reference/foundry_batch_results.md),
  [`foundry_batch_wait()`](https://farach.github.io/foundryR/reference/foundry_batch_wait.md),
  [`foundry_extract_batch()`](https://farach.github.io/foundryR/reference/foundry_extract_batch.md),
  and
  [`foundry_usage()`](https://farach.github.io/foundryR/reference/foundry_usage.md)
  to complete the batch annotation loop from JSONL requests through
  parsed tibble results and user-supplied cost summaries.
- Added
  [`foundry_image_edit()`](https://farach.github.io/foundryR/reference/foundry_image_edit.md)
  for v1 preview image editing with local image and optional mask
  uploads.
- Added
  [`foundry_response_cancel()`](https://farach.github.io/foundryR/reference/foundry_response_cancel.md)
  and
  [`foundry_response_input_items()`](https://farach.github.io/foundryR/reference/foundry_response_input_items.md)
  for background Responses API workflows and response introspection.
- Added
  [`foundry_set_project_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_project_endpoint.md),
  [`foundry_get_project_endpoint()`](https://farach.github.io/foundryR/reference/foundry_get_project_endpoint.md),
  [`foundry_set_token_provider()`](https://farach.github.io/foundryR/reference/foundry_set_token_provider.md),
  and
  [`foundry_token_azure_cli()`](https://farach.github.io/foundryR/reference/foundry_token_azure_cli.md)
  for project-scoped APIs and refreshable Microsoft Entra
  authentication.
- Added
  [`foundry_token_azure_identity()`](https://farach.github.io/foundryR/reference/foundry_token_azure_identity.md),
  a refreshable Microsoft Entra ID token provider backed by AzureAuth
  that supports service principals, managed identity, and interactive or
  device-code flows.
- Added
  [`foundry_set_speech_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_speech_endpoint.md),
  [`foundry_set_speech_key()`](https://farach.github.io/foundryR/reference/foundry_set_speech_key.md),
  [`foundry_transcribe()`](https://farach.github.io/foundryR/reference/foundry_transcribe.md),
  and
  [`foundry_translate_audio()`](https://farach.github.io/foundryR/reference/foundry_translate_audio.md)
  for LLM Speech and MAI-Transcribe workflows.
- Added
  [`foundry_set_token()`](https://farach.github.io/foundryR/reference/foundry_set_token.md)
  for Microsoft Entra ID bearer-token authentication across Foundry
  requests.
- Added
  [`foundry_speak()`](https://farach.github.io/foundryR/reference/foundry_speak.md)
  for v1 preview text-to-speech output saved to local audio files.
- Added
  [`foundry_cache_clear()`](https://farach.github.io/foundryR/reference/foundry_cache_clear.md)
  to remove embeddings cached on disk by
  `step_foundry_embed(cache = "disk")`.
- Added
  [`foundry_video_job_create()`](https://farach.github.io/foundryR/reference/foundry_video_defunct.md),
  [`foundry_video_jobs()`](https://farach.github.io/foundryR/reference/foundry_video_defunct.md),
  [`foundry_video_job_get()`](https://farach.github.io/foundryR/reference/foundry_video_defunct.md),
  [`foundry_video_job_delete()`](https://farach.github.io/foundryR/reference/foundry_video_defunct.md),
  [`foundry_video_get()`](https://farach.github.io/foundryR/reference/foundry_video_defunct.md),
  and
  [`foundry_video_download()`](https://farach.github.io/foundryR/reference/foundry_video_defunct.md)
  for preview video job management and content downloads.

### Improvements

- Configuration setters with `store = TRUE` now persist under
  `tools::R_user_dir("foundryR", "config")` instead of modifying
  `.Renviron`.
- [`foundry_moderate()`](https://farach.github.io/foundryR/reference/foundry_moderate.md),
  [`foundry_moderate_image()`](https://farach.github.io/foundryR/reference/foundry_moderate_image.md),
  and
  [`foundry_protected_material()`](https://farach.github.io/foundryR/reference/foundry_protected_material.md)
  now accept resource-scoped Microsoft Entra token providers in addition
  to Content Safety API keys.
- [`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
  and its retrieve, cancel, delete, and input-item helpers now accept an
  explicit `project_endpoint`, keeping agent-backed response lifecycles
  on one project endpoint.
- [`foundry_token_azure_cli()`](https://farach.github.io/foundryR/reference/foundry_token_azure_cli.md),
  [`foundry_token_azure_identity()`](https://farach.github.io/foundryR/reference/foundry_token_azure_identity.md),
  [`foundry_set_token()`](https://farach.github.io/foundryR/reference/foundry_set_token.md),
  and
  [`foundry_set_token_provider()`](https://farach.github.io/foundryR/reference/foundry_set_token_provider.md)
  now separate resource and project authentication, default resource
  tokens to the documented Cognitive Services audience, and use the AI
  audience only for project operations.
- Parallel HTTP helpers now default to at most two active requests, and
  the web-search compliance warning uses package-local state rather than
  changing global R options.
- [`step_foundry_embed()`](https://farach.github.io/foundryR/reference/step_foundry_embed.md)
  now checks for recipes before generating its default step identifier,
  and generics is declared for its exported `tidy()` method.
- [`foundry_groundedness()`](https://farach.github.io/foundryR/reference/foundry_groundedness.md)
  now supports the Content Safety correction feature via
  `correction = TRUE` with a bring-your-own Azure OpenAI deployment
  described by the new
  [`foundry_llm_resource()`](https://farach.github.io/foundryR/reference/foundry_llm_resource.md),
  returning a `correction_text` column, and surfaces per-segment
  `ungrounded_reasons` when `reasoning = TRUE`.
- [`codebook_diff()`](https://farach.github.io/foundryR/reference/codebook_diff.md)
  returns a printable character-vector object, so assigning the result
  produces no console output;
  [`format()`](https://rdrr.io/r/base/format.html) returns the plain
  diff lines.
- [`as_foundry_schema()`](https://farach.github.io/foundryR/reference/as_foundry_schema.md)
  now converts
  [`ellmer::type_object()`](https://ellmer.tidyverse.org/reference/type_boolean.html)
  specifications to strict JSON Schema, so ellmer users can reuse
  existing type definitions in
  [`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
  and
  [`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md).
- [`foundry_agreement()`](https://farach.github.io/foundryR/reference/foundry_agreement.md)
  now reports Krippendorff’s alpha alongside Cohen’s kappa, using irr
  when installed and a base-R nominal fallback otherwise.
- [`foundry_chat()`](https://farach.github.io/foundryR/reference/foundry_chat.md)
  now accepts `reasoning_effort` and returns `reasoning_tokens` and
  `cached_input_tokens` when chat-completions responses report those
  fields.
- [`foundry_chat()`](https://farach.github.io/foundryR/reference/foundry_chat.md)
  now defaults to the `/openai/v1/chat/completions` endpoint while
  keeping `api = "deployment"` as a legacy escape hatch.
- [`foundry_embed()`](https://farach.github.io/foundryR/reference/foundry_embed.md)
  now uses the `/openai/v1/embeddings` array endpoint by default,
  returns row-level `.error` and `.error_msg` fields, and keeps
  `api = "deployment"` as a legacy escape hatch.
- [`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
  now accepts data frames with `text_col`, preserves original columns,
  runs requests in parallel, and returns parse or HTTP failures as
  `.error` rows instead of aborting the whole job.
- [`foundry_image()`](https://farach.github.io/foundryR/reference/foundry_image.md)
  now uses the v1 preview image generation endpoint by default, supports
  newer image options such as `output_format`, `output_compression`,
  `background`, and `moderation`, and keeps the legacy deployment
  endpoint available with `api = "deployment"`.
- [`foundry_moderate()`](https://farach.github.io/foundryR/reference/foundry_moderate.md)
  now supports Content Safety blocklists and keeps raw response payloads
  in list-columns.
- [`foundry_models()`](https://farach.github.io/foundryR/reference/foundry_models.md)
  now calls the v1 model and deployment metadata endpoints instead of
  sending a dummy chat request.
- [`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
  now accepts background, conversation, prompt-cache,
  parallel-tool-call, max-tool-call, safety-identifier, and
  reasoning-summary controls from the v1 Responses API.
- [`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
  accepts
  [`foundry_tool()`](https://farach.github.io/foundryR/reference/foundry_tool.md)
  objects in `tools`, strips local R function references from request
  bodies, and returns `cached_input_tokens` when the Responses API
  reports cached input tokens.
- [`foundry_similarity()`](https://farach.github.io/foundryR/reference/foundry_similarity.md)
  now computes all pairwise cosine similarities with a single vectorized
  matrix product, supports `top_k`, and can return a similarity matrix
  with `as_matrix = TRUE`.
- [`step_foundry_embed()`](https://farach.github.io/foundryR/reference/step_foundry_embed.md)
  supports `cache = "disk"`, which stores embeddings in the R session’s
  temporary directory unless you supply `cache_dir` for a persistent
  cache, and builds all embedding columns in one pass.
- [`foundry_transcribe()`](https://farach.github.io/foundryR/reference/foundry_transcribe.md),
  [`foundry_translate_audio()`](https://farach.github.io/foundryR/reference/foundry_translate_audio.md),
  and
  [`foundry_speak()`](https://farach.github.io/foundryR/reference/foundry_speak.md)
  now accept `api = "deployment"` to reach OpenAI audio models through
  the `/openai/deployments/{model}/...` path, so a `whisper`
  transcription or translation deployment works alongside the default v1
  data-plane path.

### Documentation and package metadata

- Documentation now positions foundryR around Azure AI Content Safety,
  Responses API workflows, strict extraction, embeddings, batch jobs,
  and research annotation workflows, with chat completions kept as a
  maintained convenience layer.
- The README, vignettes, and website articles now show real Microsoft
  Foundry output. Each documentation page runs once against live
  resources with `data-raw/record-doc-outputs.R`, which captures every
  API response as a sanitized httptest2 fixture; all later builds (R CMD
  check, pkgdown, CRAN, CI) replay those fixtures and render the real
  tibbles, images, and audio with no credentials and no network calls.
  When fixtures are absent the API chunks simply do not evaluate, so
  nothing is fabricated. Replay restores the session’s environment
  variables and options when it finishes.
- Added an onet2r integration as a website-only pkgdown article that
  pulls real occupation data from O\*NET, embeds it with
  [`foundry_embed()`](https://farach.github.io/foundryR/reference/foundry_embed.md),
  ranks occupations by semantic similarity, and summarizes the top match
  with
  [`foundry_chat()`](https://farach.github.io/foundryR/reference/foundry_chat.md);
  the redactor now strips the O\*NET `X-API-Key` header so its fixtures
  carry no secrets.
- Examples that need no credentials run during package checks; examples
  that call Azure services state their prerequisites, and examples that
  write files use temporary paths.
- Media helpers are grouped as experimental media while the core
  research surface is documented separately.
- Media documentation now uses one image and video generation vignette
  instead of separate overlapping image and media articles.
- New vignettes compare foundryR with ellmer and show an end-to-end
  annotation workflow.
- License metadata now uses a single MIT license file so GitHub reports
  one license.
