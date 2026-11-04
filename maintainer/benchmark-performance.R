# Run from the package root:
# Rscript --vanilla maintainer/benchmark-performance.R a771a0b <output-directory>
# All requests are mocked. No credentials or Azure resource are needed.
args <- commandArgs(trailingOnly = TRUE)
baseline_ref <- if (length(args)) args[[1]] else "a771a0b"
output_dir <- if (length(args) > 1L) args[[2]] else tempdir()
stopifnot(dir.exists(output_dir))
options(cli.progress_show_after = Inf)
suppressPackageStartupMessages(pkgload::load_all(quiet = TRUE))
withr::local_envvar(c(
  AZURE_FOUNDRY_ENDPOINT = "https://benchmark.openai.azure.com",
  AZURE_FOUNDRY_TOKEN = "",
  AZURE_OPENAI_TOKEN = "",
  FOUNDRYR_RUN_LIVE_TESTS = "false"
))
withr::local_options(list(foundryR.config_file = tempfile()))

baseline <- new.env(parent = asNamespace("foundryR"))
for (file in c("embed-batch.R", "embed.R")) {
  code <- system2(
    "git", c("show", paste0(baseline_ref, ":R/", file)),
    stdout = TRUE
  )
  if (!is.null(attr(code, "status"))) stop("Cannot load baseline ", baseline_ref)
  eval(parse(text = code), envir = baseline)
}

measure <- function(label, fun, iterations = 5L) {
  fun()
  times <- replicate(iterations, {
    gc()
    unname(system.time(fun())[["elapsed"]])
  })
  allocation_file <- tempfile()
  Rprofmem(allocation_file)
  fun()
  Rprofmem(NULL)
  allocation <- readLines(allocation_file, warn = FALSE)
  unlink(allocation_file)
  bytes <- suppressWarnings(as.numeric(sub(" .*", "", allocation)))
  data.frame(
    workload = label,
    median_seconds = median(times),
    allocated_bytes = sum(bytes, na.rm = TRUE),
    iterations = iterations
  )
}

rows <- list()
for (n in c(100L, 1000L)) {
  cat("Embedding workload:", n, "texts x 256 dimensions\n")
  payload <- list(
    object = "list", model = "benchmark-embedding",
    data = lapply(rev(seq_len(n)), function(i) {
      list(index = i - 1L, object = "embedding", embedding = as.list(rep(i / n, 256L)))
    }),
    usage = list(prompt_tokens = n, total_tokens = n)
  )
  response <- httr2::response(
    200L, url = "https://benchmark.openai.azure.com",
    headers = list(`content-type` = "application/json"),
    body = charToRaw(as.character(jsonlite::toJSON(payload, auto_unbox = TRUE)))
  )
  # Cache JSON parsing, isolating request setup and result assembly from the
  # common JSON parser. Both implementations receive exactly the same response.
  invisible(httr2::resp_body_json(response))
  testthat::local_mocked_bindings(
    foundry_req_perform_many = function(...) list(response),
    .package = "foundryR"
  )
  texts <- paste("text", seq_len(n))
  old <- function() baseline$foundry_embed_batch(
    texts, model = "benchmark-embedding", batch_size = n,
    api_key = "benchmark-not-a-key", progress = FALSE
  )
  new <- function() foundry_embed_batch(
    texts, model = "benchmark-embedding", batch_size = n,
    api_key = "benchmark-not-a-key", progress = FALSE
  )
  stopifnot(identical(old(), new()))
  if (n == 100L) {
    Rprof(file.path(output_dir, "embedding-profile.out"), interval = 0.02)
    old()
    Rprof(NULL)
    print(utils::head(summaryRprof(file.path(output_dir, "embedding-profile.out"))$by.total, 12))
  }
  rows[[length(rows) + 1L]] <- measure(paste("embedding baseline", n), old)
  rows[[length(rows) + 1L]] <- measure(paste("embedding current", n), new)
  if (n == 1000L) {
    cat("Embedding workload: fresh JSON decoding plus request/result processing\n")
    bytes <- httr2::resp_body_raw(response)
    testthat::local_mocked_bindings(
      foundry_req_perform_many = function(...) {
        list(httr2::response(
          200L, url = "https://benchmark.openai.azure.com",
          headers = list(`content-type` = "application/json"), body = bytes
        ))
      },
      .package = "foundryR"
    )
    stopifnot(identical(old(), new()))
    rows[[length(rows) + 1L]] <- measure("embedding baseline 1000 fresh JSON", old)
    rows[[length(rows) + 1L]] <- measure("embedding current 1000 fresh JSON", new)
  }
}

set.seed(420)
data <- tibble::tibble(
  text = paste("text", seq_len(1000L)),
  embedding = replicate(1000L, rnorm(256L), simplify = FALSE)
)
for (matrix_output in c(FALSE, TRUE)) {
  cat("Similarity workload: 1000 x 256; matrix =", matrix_output, "\n")
  old <- function() baseline$foundry_similarity(data, top_k = 20L, as_matrix = matrix_output)
  new <- function() foundry_similarity(data, top_k = 20L, as_matrix = matrix_output)
  stopifnot(identical(old(), new()))
  rows[[length(rows) + 1L]] <- measure(paste("similarity baseline matrix", matrix_output), old)
  rows[[length(rows) + 1L]] <- measure(paste("similarity current matrix", matrix_output), new)
}

build_dir <- tempfile("foundryr-c-reference-")
dir.create(build_dir)
source_file <- normalizePath(file.path("maintainer", "similarity-reference.c"))
file.copy(source_file, file.path(build_dir, "similarity_reference.c"))
withr::with_dir(build_dir, {
  status <- system2(
    file.path(R.home("bin"), "R"), c("CMD", "SHLIB", "similarity_reference.c")
  )
  if (status != 0L) stop("The optional C benchmark needs R build tools.")
})
library_file <- file.path(build_dir, paste0("similarity_reference", .Platform$dynlib.ext))
dll <- dyn.load(library_file)
reference <- getNativeSymbolInfo("similarity_reference", PACKAGE = dll)
c_kernel <- function() {
  out <- .Call(reference, data$embedding)
  dimnames(out) <- list(data$text, data$text)
  out
}
stopifnot(isTRUE(all.equal(
  foundry_similarity(data, as_matrix = TRUE), c_kernel(), tolerance = 1e-12
)))
rows[[length(rows) + 1L]] <- measure("similarity C reference matrix TRUE", c_kernel)
dyn.unload(library_file)
unlink(build_dir, recursive = TRUE)

results <- do.call(rbind, rows)
print(results, row.names = FALSE)
write.csv(results, file.path(output_dir, "performance.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(output_dir, "performance-session.txt"))
