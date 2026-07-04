# foundry_codebook validates name, version, schema, and examples

    Code
      foundry_codebook(name = "Bad Name", version = "1.0.0", instructions = "Label.",
        schema = foundry_schema(label = type_string()))
    Condition
      Error in `foundry_check_codebook_name()`:
      ! `name` must be a lowercase slug with optional hyphens.

---

    Code
      foundry_codebook(name = "good-name", version = "1", instructions = "Label.",
        schema = foundry_schema(label = type_string()))
    Condition
      Error in `foundry_check_semver()`:
      ! `version` must be a semantic version string.

---

    Code
      foundry_codebook(name = "good-name", version = "1.0.0", instructions = "Label.",
        schema = list(type = "string"))
    Condition
      Error in `as_foundry_schema()`:
      ! `x` is not a supported schema object.

---

    Code
      foundry_codebook(name = "good-name", version = "1.0.0", instructions = "Label.",
        schema = foundry_schema(label = type_string()), examples = "not-list")
    Condition
      Error in `foundry_codebook()`:
      ! `examples` must be a list or NULL.

# codebook print and diff output are stable

    Code
      print(old)
    Output
      foundry codebook: task-label
      version: 1.0.0
      hash: a74264284ddf
      variables:
        - label: string [yes, no] (Task label)
      examples: 1

---

    Code
      codebook_diff(old, new)
    Output
      Codebook diff
      old: task-label 1.0.0 a74264284ddf870634ed8924c5b5e11fba0c53829792b220195f70811929fb2a
      new: task-label 1.1.0 0a6994011e7b981609194e7fe0e6b681908faf0f76c7083212052ed8aa79afe2
      
      Instructions:
      --- old instructions
      +++ new instructions
      @@
       Label each task.
      -Use yes or no.
      +Use yes, no, or maybe.
      
      Schema:
      ~ label: {"type":"string","description":"Task label","enum":["yes","no"]} -> {"type":"string","description":"Task label","enum":["yes","no","maybe"]}
      + rationale: {"type":"string","description":"Short reason"}
      
      Examples:
        1: no change
      + 2: {"text":"Carry a box","label":"no"}

