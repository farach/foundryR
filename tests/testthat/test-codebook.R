test_that("foundry_codebook builds the specified object contract", {
  schema <- foundry_schema(
    ai_applicable = type_boolean("AI could materially assist the task"),
    confidence = type_number("Coder confidence")
  )

  codebook <- foundry_codebook(
    name = "ai-applicability",
    version = "1.0.0",
    instructions = "Label whether the task could use AI assistance.",
    schema = schema,
    examples = list(list(text = "Draft a memo", ai_applicable = TRUE))
  )

  expect_s3_class(codebook, "foundry_codebook")
  expect_named(
    codebook,
    c("name", "version", "instructions", "schema", "examples", "created", "hash")
  )
  expect_equal(codebook$name, "ai-applicability")
  expect_equal(codebook$version, "1.0.0")
  expect_equal(codebook$schema, schema)
  expect_s3_class(codebook$created, "POSIXct")
  expect_equal(attr(codebook$created, "tzone"), "UTC")
  expect_match(codebook$hash, "^[0-9a-f]{64}$")
})

test_that("codebook hashes are stable and content addressed", {
  schema <- foundry_schema(label = type_enum("Task label", c("yes", "no")))
  single_enum_schema <- foundry_schema(label = type_enum("Only label", "yes"))
  first <- foundry_codebook(
    name = "task-label",
    version = "1.0.0",
    instructions = "Label each task.",
    schema = schema,
    examples = list(list(text = "Write code", label = "yes"))
  )
  second <- foundry_codebook(
    name = "renamed-task-label",
    version = "1.0.0",
    instructions = "Label each task.",
    schema = schema,
    examples = list(list(text = "Write code", label = "yes"))
  )
  changed <- foundry_codebook(
    name = "task-label",
    version = "1.0.1",
    instructions = "Label each task.",
    schema = schema,
    examples = list(list(text = "Write code", label = "yes"))
  )
  single_enum <- foundry_codebook(
    name = "single-label",
    version = "1.0.0",
    instructions = "Label each task.",
    schema = single_enum_schema,
    examples = NULL
  )

  canonical <- jsonlite::toJSON(
    list(
      instructions = "Label each task.",
      schema = foundry_preserve_schema_arrays(schema),
      examples = list(list(text = "Write code", label = "yes")),
      version = "1.0.0"
    ),
    auto_unbox = TRUE,
    digits = NA,
    null = "null"
  )
  single_enum_canonical <- jsonlite::toJSON(
    list(
      instructions = "Label each task.",
      schema = foundry_preserve_schema_arrays(single_enum_schema),
      examples = NULL,
      version = "1.0.0"
    ),
    auto_unbox = TRUE,
    digits = NA,
    null = "null"
  )

  expect_equal(first$hash, second$hash)
  expect_equal(
    first$hash,
    digest::digest(enc2utf8(as.character(canonical)), algo = "sha256", serialize = FALSE)
  )
  expect_equal(
    single_enum$hash,
    digest::digest(
      enc2utf8(as.character(single_enum_canonical)),
      algo = "sha256",
      serialize = FALSE
    )
  )
  expect_match(changed$hash, "^[0-9a-f]{64}$")
  expect_failure(expect_equal(first$hash, changed$hash))
})

test_that("codebook schema helpers reuse existing schema constructors", {
  expect_equal(type_boolean("Flag"), schema_boolean("Flag"))
  expect_equal(type_number("Score"), schema_number("Score"))
  expect_equal(type_string("Text"), schema_string("Text"))
  expect_equal(
    type_enum("Choice", c("yes", "no")),
    schema_enum(c("yes", "no"), description = "Choice")
  )
})

test_that("foundry_codebook validates name, version, schema, and examples", {
  expect_snapshot(
    error = TRUE,
    foundry_codebook(
      name = "Bad Name",
      version = "1.0.0",
      instructions = "Label.",
      schema = foundry_schema(label = type_string())
    )
  )
  expect_snapshot(
    error = TRUE,
    foundry_codebook(
      name = "good-name",
      version = "1",
      instructions = "Label.",
      schema = foundry_schema(label = type_string())
    )
  )
  expect_snapshot(
    error = TRUE,
    foundry_codebook(
      name = "good-name",
      version = "1.0.0",
      instructions = "Label.",
      schema = list(type = "string")
    )
  )
  expect_snapshot(
    error = TRUE,
    foundry_codebook(
      name = "good-name",
      version = "1.0.0",
      instructions = "Label.",
      schema = foundry_schema(label = type_string()),
      examples = "not-list"
    )
  )
})

test_that("codebook print and diff output are stable", {
  old <- foundry_codebook(
    name = "task-label",
    version = "1.0.0",
    instructions = "Label each task.\nUse yes or no.",
    schema = foundry_schema(label = type_enum("Task label", c("yes", "no"))),
    examples = list(list(text = "Write code", label = "yes"))
  )
  new <- foundry_codebook(
    name = "task-label",
    version = "1.1.0",
    instructions = "Label each task.\nUse yes, no, or maybe.",
    schema = foundry_schema(
      label = type_enum("Task label", c("yes", "no", "maybe")),
      rationale = type_string("Short reason")
    ),
    examples = list(
      list(text = "Write code", label = "yes"),
      list(text = "Carry a box", label = "no")
    )
  )

  expect_snapshot(print(old))
  expect_snapshot(codebook_diff(old, new))
})
