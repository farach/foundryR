#' Create a measurement codebook
#'
#' A codebook records the instructions, JSON Schema, examples, semantic
#' version, creation time, and deterministic SHA-256 hash for an LLM annotation
#' instrument. The hash is computed from a canonical JSON serialization of
#' `instructions`, `schema`, `examples`, and `version`, in that order. Before
#' serialization, schema arrays are preserved with the same internal helper used
#' by structured outputs so single-value `enum` and `required` arrays do not
#' collapse to scalars. The payload is serialized with
#' `jsonlite::toJSON(auto_unbox = TRUE, digits = NA, null = "null")`,
#' normalized with `enc2utf8()`, and hashed with SHA-256.
#'
#' @param name Character. Lowercase slug for the codebook; hyphens are allowed.
#' @param version Character. Semantic version string.
#' @param instructions Character. System or instruction prompt for annotation.
#' @param schema List. JSON Schema object, typically from [foundry_schema()].
#' @param examples List or `NULL`. Few-shot examples included in the codebook
#'   hash.
#'
#' @return A `foundry_codebook` object.
#' @export
#'
#' @examples
#' \dontrun{
#' codebook <- foundry_codebook(
#'   name = "ai-applicability",
#'   version = "1.0.0",
#'   instructions = "Label whether the task could use AI assistance.",
#'   schema = foundry_schema(
#'     ai_applicable = type_boolean("AI could materially assist the task")
#'   ),
#'   examples = list(
#'     list(text = "Draft a memo", ai_applicable = TRUE),
#'     list(text = "Lift a heavy box", ai_applicable = FALSE)
#'   )
#' )
#' }
foundry_codebook <- function(name,
                             version,
                             instructions,
                             schema,
                             examples = NULL) {
  foundry_check_codebook_name(name)
  foundry_check_semver(version)
  foundry_check_character_scalar(instructions, "instructions")
  schema <- as_foundry_schema(schema)
  if (!is.null(examples) && !is.list(examples)) {
    cli::cli_abort("{.arg examples} must be a list or NULL.")
  }

  out <- list(
    name = name,
    version = version,
    instructions = instructions,
    schema = schema,
    examples = examples,
    created = foundry_utc_now()
  )
  out$hash <- foundry_codebook_hash(
    instructions = instructions,
    schema = schema,
    examples = examples,
    version = version
  )
  structure(out, class = "foundry_codebook")
}


#' Codebook schema helpers
#'
#' These light wrappers reuse foundryR's existing strict JSON Schema
#' constructors while following the measurement-layer codebook vocabulary.
#'
#' @param desc Character. Optional field description.
#' @param values Character vector of allowed values for `type_enum()`.
#'
#' @return A JSON Schema fragment represented as an R list.
#' @name codebook_schema_helpers
NULL


#' @rdname codebook_schema_helpers
#' @export
type_boolean <- function(desc = NULL) {
  schema_boolean(description = desc)
}


#' @rdname codebook_schema_helpers
#' @export
type_enum <- function(desc = NULL, values) {
  schema_enum(values = values, description = desc)
}


#' @rdname codebook_schema_helpers
#' @export
type_number <- function(desc = NULL) {
  schema_number(description = desc)
}


#' @rdname codebook_schema_helpers
#' @export
type_string <- function(desc = NULL) {
  schema_string(description = desc)
}


#' Compare two codebooks
#'
#' Print a compact diff of two `foundry_codebook` objects, including both
#' hashes, a unified diff of instructions, and field-level changes for schema
#' properties and examples.
#'
#' @param old,new `foundry_codebook` objects to compare.
#'
#' @return Invisibly returns the printed diff lines.
#' @export
#'
#' @examples
#' \dontrun{
#' codebook_diff(old_codebook, new_codebook)
#' }
codebook_diff <- function(old, new) {
  foundry_check_codebook(old, "old")
  foundry_check_codebook(new, "new")

  lines <- c(
    "Codebook diff",
    paste0("old: ", old$name, " ", old$version, " ", old$hash),
    paste0("new: ", new$name, " ", new$version, " ", new$hash),
    "",
    "Instructions:",
    foundry_unified_diff(old$instructions, new$instructions),
    "",
    "Schema:",
    foundry_named_list_diff(old$schema$properties, new$schema$properties),
    "",
    "Examples:",
    foundry_named_list_diff(
      foundry_examples_as_fields(old$examples),
      foundry_examples_as_fields(new$examples)
    )
  )

  cat(lines, sep = "\n")
  invisible(lines)
}


#' @export
format.foundry_codebook <- function(x, ...) {
  foundry_check_codebook(x, "x")

  properties <- x$schema$properties %||% list()
  variables <- if (length(properties) == 0L) {
    "  (none)"
  } else {
    vapply(names(properties), function(field) {
      paste0("  - ", field, ": ", foundry_schema_field_summary(properties[[field]]))
    }, character(1))
  }

  c(
    paste0("foundry codebook: ", x$name),
    paste0("version: ", x$version),
    paste0("hash: ", substr(x$hash, 1L, 12L)),
    "variables:",
    variables,
    paste0("examples: ", length(x$examples %||% list()))
  )
}


#' @export
print.foundry_codebook <- function(x, ...) {
  cat(format(x), sep = "\n")
  invisible(x)
}


foundry_codebook_hash <- function(instructions, schema, examples, version) {
  payload <- list(
    instructions = instructions,
    schema = foundry_preserve_schema_arrays(schema),
    examples = examples,
    version = version
  )
  json <- jsonlite::toJSON(
    payload,
    auto_unbox = TRUE,
    digits = NA,
    null = "null"
  )
  digest::digest(enc2utf8(as.character(json)), algo = "sha256", serialize = FALSE)
}


foundry_check_codebook <- function(x, arg) {
  if (!inherits(x, "foundry_codebook")) {
    cli::cli_abort("{.arg {arg}} must be a {.cls foundry_codebook} object.")
  }
  invisible(x)
}


foundry_check_codebook_name <- function(name) {
  foundry_check_character_scalar(name, "name")
  if (!grepl("^[a-z0-9]+(-[a-z0-9]+)*$", name)) {
    cli::cli_abort(
      "{.arg name} must be a lowercase slug with optional hyphens."
    )
  }
  invisible(name)
}


foundry_check_semver <- function(version) {
  foundry_check_character_scalar(version, "version")
  semver <- paste0(
    "^(0|[1-9][0-9]*)\\.",
    "(0|[1-9][0-9]*)\\.",
    "(0|[1-9][0-9]*)",
    "(-[0-9A-Za-z.-]+)?",
    "(\\+[0-9A-Za-z.-]+)?$"
  )
  if (!grepl(semver, version)) {
    cli::cli_abort("{.arg version} must be a semantic version string.")
  }
  invisible(version)
}


foundry_utc_now <- function() {
  as.POSIXct(as.numeric(Sys.time()), origin = "1970-01-01", tz = "UTC")
}


foundry_unified_diff <- function(old, new) {
  old_lines <- foundry_split_lines(old)
  new_lines <- foundry_split_lines(new)
  if (identical(old_lines, new_lines)) {
    return("  (no changes)")
  }

  c(
    "--- old instructions",
    "+++ new instructions",
    "@@",
    foundry_lcs_diff(old_lines, new_lines)
  )
}


foundry_split_lines <- function(x) {
  if (identical(x, "")) {
    return("")
  }
  strsplit(x, "\n", fixed = TRUE)[[1]]
}


foundry_lcs_diff <- function(old, new) {
  n_old <- length(old)
  n_new <- length(new)
  lcs <- matrix(0L, nrow = n_old + 1L, ncol = n_new + 1L)

  if (n_old > 0L && n_new > 0L) {
    for (i in seq_len(n_old)) {
      for (j in seq_len(n_new)) {
        if (identical(old[[i]], new[[j]])) {
          lcs[i + 1L, j + 1L] <- lcs[i, j] + 1L
        } else {
          lcs[i + 1L, j + 1L] <- max(lcs[i, j + 1L], lcs[i + 1L, j])
        }
      }
    }
  }

  foundry_lcs_backtrack(old, new, lcs, n_old, n_new)
}


foundry_lcs_backtrack <- function(old, new, lcs, i, j) {
  out <- character()
  while (i > 0L || j > 0L) {
    if (i > 0L && j > 0L && identical(old[[i]], new[[j]])) {
      out <- c(paste0(" ", old[[i]]), out)
      i <- i - 1L
      j <- j - 1L
    } else if (j > 0L && (i == 0L || lcs[i + 1L, j] >= lcs[i, j + 1L])) {
      out <- c(paste0("+", new[[j]]), out)
      j <- j - 1L
    } else {
      out <- c(paste0("-", old[[i]]), out)
      i <- i - 1L
    }
  }
  out
}


foundry_named_list_diff <- function(old, new) {
  old <- old %||% list()
  new <- new %||% list()

  all_names <- union(names(old), names(new))
  if (length(all_names) == 0L) {
    return("  (none)")
  }

  lines <- vapply(all_names, function(field) {
    old_has <- field %in% names(old)
    new_has <- field %in% names(new)
    if (!old_has) {
      return(paste0("+ ", field, ": ", foundry_json_summary(new[[field]])))
    }
    if (!new_has) {
      return(paste0("- ", field, ": ", foundry_json_summary(old[[field]])))
    }
    if (identical(foundry_canonical_json(old[[field]]), foundry_canonical_json(new[[field]]))) {
      return(paste0("  ", field, ": no change"))
    }
    paste0(
      "~ ",
      field,
      ": ",
      foundry_json_summary(old[[field]]),
      " -> ",
      foundry_json_summary(new[[field]])
    )
  }, character(1))

  if (all(grepl(": no change$", lines))) {
    return("  (no changes)")
  }
  lines
}


foundry_examples_as_fields <- function(examples) {
  if (is.null(examples)) {
    return(list())
  }
  if (is.null(names(examples)) || any(names(examples) == "")) {
    names(examples) <- as.character(seq_along(examples))
  }
  examples
}


foundry_json_summary <- function(x) {
  json <- foundry_canonical_json(x)
  if (nchar(json) > 80L) {
    return(paste0(substr(json, 1L, 77L), "..."))
  }
  json
}


foundry_canonical_json <- function(x) {
  as.character(jsonlite::toJSON(
    foundry_preserve_schema_arrays(x),
    auto_unbox = TRUE,
    digits = NA,
    null = "null"
  ))
}


foundry_schema_field_summary <- function(field) {
  type <- field$type %||% "unknown"
  enum <- unclass(field$enum %||% NULL)
  allowed <- if (is.null(enum)) {
    ""
  } else {
    paste0(" [", paste(enum, collapse = ", "), "]")
  }
  description <- field$description %||% NULL
  detail <- if (is.null(description)) "" else paste0(" (", description, ")")
  paste0(type, allowed, detail)
}
