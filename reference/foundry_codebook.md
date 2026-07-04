# Create a measurement codebook

A codebook records the instructions, JSON Schema, examples, semantic
version, creation time, and deterministic SHA-256 hash for an LLM
annotation instrument. The hash is computed from a canonical JSON
serialization of `instructions`, `schema`, `examples`, and `version`, in
that order. Before serialization, schema arrays are preserved with the
same internal helper used by structured outputs so single-value `enum`
and `required` arrays do not collapse to scalars. The payload is
serialized with
`jsonlite::toJSON(auto_unbox = TRUE, digits = NA, null = "null")`,
normalized with [`enc2utf8()`](https://rdrr.io/r/base/Encoding.html),
and hashed with SHA-256.

## Usage

``` r
foundry_codebook(name, version, instructions, schema, examples = NULL)
```

## Arguments

- name:

  Character. Lowercase slug for the codebook; hyphens are allowed.

- version:

  Character. Semantic version string.

- instructions:

  Character. System or instruction prompt for annotation.

- schema:

  List. JSON Schema object, typically from
  [`foundry_schema()`](https://farach.github.io/foundryR/reference/foundry_schema.md).

- examples:

  List or `NULL`. Few-shot examples included in the codebook hash.

## Value

A `foundry_codebook` object.

## Examples

``` r
if (FALSE) { # \dontrun{
codebook <- foundry_codebook(
  name = "ai-applicability",
  version = "1.0.0",
  instructions = "Label whether the task could use AI assistance.",
  schema = foundry_schema(
    ai_applicable = type_boolean("AI could materially assist the task")
  ),
  examples = list(
    list(text = "Draft a memo", ai_applicable = TRUE),
    list(text = "Lift a heavy box", ai_applicable = FALSE)
  )
)
} # }
```
