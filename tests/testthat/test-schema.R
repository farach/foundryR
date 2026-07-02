test_that("schema constructors build strict object schemas", {
  schema <- foundry_schema(
    sentiment = schema_enum(c("positive", "negative")),
    score = schema_number(),
    tags = schema_array(schema_string())
  )

  expect_equal(schema$type, "object")
  expect_equal(names(schema$properties), c("sentiment", "score", "tags"))
  expect_equal(schema$additionalProperties, FALSE)
  expect_equal(unclass(schema$required), c("sentiment", "score", "tags"))
  expect_equal(unclass(schema$properties$sentiment$enum), c("positive", "negative"))
})

test_that("as_foundry_schema returns raw object schemas", {
  raw <- list(type = "object", properties = list(x = list(type = "string")))

  expect_equal(as_foundry_schema(raw)$type, "object")
})

test_that("as_foundry_schema converts ellmer type_object specs", {
  skip_if_not_installed("ellmer")

  spec <- ellmer::type_object(
    .description = "A record",
    name = ellmer::type_string("the name"),
    score = ellmer::type_number(),
    tags = ellmer::type_array(items = ellmer::type_string()),
    mood = ellmer::type_enum(values = c("good", "bad"))
  )

  schema <- as_foundry_schema(spec)

  expect_equal(schema$type, "object")
  expect_equal(schema$additionalProperties, FALSE)
  expect_equal(schema$description, "A record")
  expect_setequal(names(schema$properties), c("name", "score", "tags", "mood"))
  expect_equal(schema$properties$name$type, "string")
  expect_equal(schema$properties$name$description, "the name")
  expect_equal(schema$properties$score$type, "number")
  expect_equal(schema$properties$tags$type, "array")
  expect_equal(schema$properties$tags$items$type, "string")
  expect_equal(as.character(schema$properties$mood$enum), c("good", "bad"))
  expect_setequal(as.character(schema$required), c("name", "score", "tags", "mood"))
})

test_that("as_foundry_schema rejects non-object ellmer types", {
  skip_if_not_installed("ellmer")

  expect_error(as_foundry_schema(ellmer::type_string()), "type_object")
})
