#' Build a strict JSON Schema object
#'
#' Create a strict object schema for structured outputs. All supplied fields are
#' required by default and additional properties are disabled by default, matching
#' the strict schema shape expected by Azure OpenAI structured outputs.
#'
#' @param ... Named schema fields, usually created with `schema_*()` helpers.
#' @param required Character vector of required field names. Defaults to all
#'   supplied fields.
#' @param additional_properties Logical. Whether properties outside `...` are
#'   allowed.
#' @param description Character. Optional schema description.
#'
#' @return A JSON Schema represented as an R list.
#' @export
#'
#' @examples
#' schema <- foundry_schema(
#'   sentiment = schema_enum(c("positive", "negative", "neutral")),
#'   score = schema_number()
#' )
foundry_schema <- function(...,
                           required = NULL,
                           additional_properties = FALSE,
                           description = NULL) {
  schema_object(
    ...,
    required = required,
    additional_properties = additional_properties,
    description = description
  )
}


#' Schema constructors for structured outputs
#'
#' Build JSON Schema field definitions for use with `foundry_schema()` or raw
#' schema lists passed to `foundry_extract()` and `foundry_response()`.
#'
#' @param description Character. Optional field description.
#' @param enum Character vector of allowed values.
#' @param values Character vector of allowed values for `schema_enum()`.
#' @param items List. Item schema for `schema_array()`.
#' @param min_items,max_items Integer. Optional array length bounds.
#' @param ... Named child fields for `schema_object()`.
#' @param required Character vector of required child fields. Defaults to all
#'   supplied fields.
#' @param additional_properties Logical. Whether undeclared object properties
#'   are allowed.
#'
#' @return A JSON Schema fragment represented as an R list.
#' @name schema_constructors
#'
#' @examples
#' schema_string("Free-text label")
#' schema_enum(c("positive", "negative", "neutral"))
#' schema_object(
#'   sentiment = schema_enum(c("positive", "negative", "neutral")),
#'   confidence = schema_number()
#' )
NULL


#' @rdname schema_constructors
#' @export
schema_string <- function(description = NULL, enum = NULL) {
  out <- list(type = "string")
  if (!is.null(description)) out$description <- description
  if (!is.null(enum)) out$enum <- I(as.character(enum))
  out
}


#' @rdname schema_constructors
#' @export
schema_enum <- function(values, description = NULL) {
  if (missing(values) || !is.character(values) || length(values) == 0L ||
      any(is.na(values))) {
    cli::cli_abort("{.arg values} must be a non-empty character vector.")
  }
  schema_string(description = description, enum = values)
}


#' @rdname schema_constructors
#' @export
schema_number <- function(description = NULL) {
  schema_scalar("number", description)
}


#' @rdname schema_constructors
#' @export
schema_integer <- function(description = NULL) {
  schema_scalar("integer", description)
}


#' @rdname schema_constructors
#' @export
schema_boolean <- function(description = NULL) {
  schema_scalar("boolean", description)
}


#' @rdname schema_constructors
#' @export
schema_array <- function(items,
                         description = NULL,
                         min_items = NULL,
                         max_items = NULL) {
  if (missing(items) || is.null(items) || !is.list(items)) {
    cli::cli_abort("{.arg items} must be a schema list.")
  }

  out <- list(type = "array", items = items)
  if (!is.null(description)) out$description <- description
  if (!is.null(min_items)) out$minItems <- foundry_check_positive_integer(min_items, "min_items")
  if (!is.null(max_items)) out$maxItems <- foundry_check_positive_integer(max_items, "max_items")
  out
}


#' @rdname schema_constructors
#' @export
schema_object <- function(...,
                          required = NULL,
                          additional_properties = FALSE,
                          description = NULL) {
  properties <- list(...)
  if (length(properties) == 1L && is.list(properties[[1]]) &&
      is.null(names(properties))) {
    properties <- properties[[1]]
  }
  if (length(properties) == 0L || is.null(names(properties)) ||
      any(names(properties) == "")) {
    cli::cli_abort("Object schemas require named fields.")
  }
  if (!all(vapply(properties, is.list, logical(1)))) {
    cli::cli_abort("Each object field must be a schema list.")
  }
  if (is.null(required)) {
    required <- names(properties)
  }
  if (!is.character(required) || any(is.na(required))) {
    cli::cli_abort("{.arg required} must be a character vector.")
  }
  if (!is.logical(additional_properties) ||
      length(additional_properties) != 1L ||
      is.na(additional_properties)) {
    cli::cli_abort("{.arg additional_properties} must be TRUE or FALSE.")
  }

  out <- list(
    type = "object",
    properties = properties,
    required = I(required),
    additionalProperties = additional_properties
  )
  if (!is.null(description)) out$description <- description
  out
}


#' Convert an object to a foundryR JSON Schema
#'
#' `as_foundry_schema()` is a small validation/conversion helper. It returns raw
#' JSON Schema lists unchanged, so code can accept either schemas built with
#' foundryR constructors or hand-written JSON Schema lists. If the \pkg{ellmer}
#' package is installed, `ellmer::type_object()` specifications are converted to
#' the equivalent strict JSON Schema, so ellmer users can pass their existing
#' type definitions to [foundry_extract()] and [foundry_response()].
#'
#' @param x Object to convert. Either a foundryR/JSON Schema list or an ellmer
#'   `type_object()` specification.
#'
#' @return A JSON Schema represented as an R list.
#' @export
#'
#' @examples
#' schema <- foundry_schema(label = schema_string())
#' as_foundry_schema(schema)
as_foundry_schema <- function(x) {
  if (inherits(x, "ellmer::Type")) {
    return(foundry_preserve_schema_arrays(ellmer_type_to_schema(x)))
  }

  if (is.list(x) && identical(x$type %||% NULL, "object")) {
    return(foundry_preserve_schema_arrays(x))
  }

  cli::cli_abort("{.arg x} is not a supported schema object.")
}


ellmer_type_to_schema <- function(x) {
  if (!inherits(x, "ellmer::TypeObject")) {
    cli::cli_abort(
      "Only {.code ellmer::type_object()} specifications convert to a foundryR schema."
    )
  }
  ellmer_convert_type(x)
}


ellmer_convert_type <- function(type) {
  description <- ellmer_prop(type, "description")

  if (inherits(type, "ellmer::TypeObject")) {
    properties <- ellmer_prop(type, "properties") %||% list()
    required <- names(properties)[vapply(
      properties,
      function(p) isTRUE(ellmer_prop(p, "required")),
      logical(1)
    )]
    out <- list(
      type = "object",
      properties = lapply(properties, ellmer_convert_type),
      required = I(as.character(required)),
      additionalProperties = isTRUE(ellmer_prop(type, "additional_properties"))
    )
  } else if (inherits(type, "ellmer::TypeEnum")) {
    out <- list(type = "string", enum = I(as.character(ellmer_prop(type, "values"))))
  } else if (inherits(type, "ellmer::TypeArray")) {
    out <- list(
      type = "array",
      items = ellmer_convert_type(ellmer_prop(type, "items"))
    )
  } else if (inherits(type, "ellmer::TypeBasic")) {
    out <- list(type = ellmer_prop(type, "type"))
  } else {
    cli::cli_abort("Unsupported ellmer type: {.cls {class(type)}}.")
  }

  if (!is.null(description)) out$description <- description
  out
}


ellmer_prop <- function(x, name) {
  # ellmer types are S7 objects, so S7 is always available alongside them.
  S7::prop(x, name)
}


schema_scalar <- function(type, description = NULL) {
  out <- list(type = type)
  if (!is.null(description)) out$description <- description
  out
}
