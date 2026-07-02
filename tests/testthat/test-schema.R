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
