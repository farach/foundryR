test_that("foundry_req_perform_many returns an empty list without performing anything", {
  called <- FALSE
  testthat::local_mocked_bindings(
    req_perform = function(...) {
      called <<- TRUE
      NULL
    },
    req_perform_parallel = function(...) {
      called <<- TRUE
      NULL
    },
    .package = "httr2"
  )

  expect_identical(foundry_req_perform_many(list()), list())
  expect_false(called)
})

test_that("foundry_req_perform_many performs requests in parallel by default", {
  reqs <- list(
    httr2::request("https://example.com/a"),
    httr2::request("https://example.com/b")
  )
  testthat::local_mocked_bindings(
    req_perform = function(...) stop("sequential path must not be used by default"),
    req_perform_parallel = function(reqs, ...) {
      lapply(seq_along(reqs), function(i) paste0("parallel-", i))
    },
    .package = "httr2"
  )

  expect_identical(
    foundry_req_perform_many(reqs),
    list("parallel-1", "parallel-2")
  )
})

test_that("foundry_req_perform_many performs requests sequentially when the option is set", {
  withr::local_options(foundryR.sequential_requests = TRUE)
  reqs <- list(
    httr2::request("https://example.com/a"),
    httr2::request("https://example.com/b")
  )
  seen <- character()
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      seen <<- c(seen, req$url)
      paste0("seq-", req$url)
    },
    req_perform_parallel = function(...) {
      stop("parallel path must not be used when sequential requests are enabled")
    },
    .package = "httr2"
  )

  out <- foundry_req_perform_many(reqs)

  expect_identical(seen, c("https://example.com/a", "https://example.com/b"))
  expect_identical(
    out,
    list("seq-https://example.com/a", "seq-https://example.com/b")
  )
})

test_that("foundry_req_perform_many captures per-request errors on the sequential path", {
  withr::local_options(foundryR.sequential_requests = TRUE)
  reqs <- list(
    httr2::request("https://example.com/ok"),
    httr2::request("https://example.com/boom")
  )
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      if (grepl("boom", req$url)) {
        stop("network exploded")
      }
      "ok"
    },
    .package = "httr2"
  )

  out <- foundry_req_perform_many(reqs)

  expect_identical(out[[1]], "ok")
  expect_s3_class(out[[2]], "error")
  expect_match(conditionMessage(out[[2]]), "network exploded")
})
