# ============================================================================
# foundryR Manual Integration Tests
# Run this script in RStudio after configuring your Azure credentials
#
# BEFORE RUNNING:
# 1. Set your main endpoint and key:
#    foundry_set_endpoint("https://your-resource.openai.azure.com")
#    foundry_set_key("your-api-key")
#
# 2. Set your default models:
#    Sys.setenv(AZURE_FOUNDRY_MODEL = "your-chat-deployment")
#    Sys.setenv(AZURE_FOUNDRY_EMBED_MODEL = "your-embed-deployment")
#
# 3. For Content Safety tests, also set:
#    foundry_set_content_safety_endpoint("https://your-cs-resource.cognitiveservices.azure.com")
#    foundry_set_content_safety_key("your-cs-key")
#
# 4. For Image tests, also set:
#    foundry_set_image_endpoint("https://your-dalle-resource.cognitiveservices.azure.com")
#    Sys.setenv(AZURE_FOUNDRY_IMAGE_MODEL = "your-dalle-deployment")
#
# ============================================================================

library(foundryR)
library(dplyr)
library(tibble)

# Track results
test_results <- list()
test_errors <- list()

# Helper function
run_test <- function(name, expr) {
  cat("\n", strrep("=", 60), "\n", sep = "")
  cat("TEST:", name, "\n")
  cat(strrep("=", 60), "\n")

  result <- tryCatch({
    val <- eval(expr)
    cat("SUCCESS\n")

    if (is.data.frame(val)) {
      cat("Dimensions:", nrow(val), "x", ncol(val), "\n")

      if (nrow(val) == 0) {
        cat("WARNING: Empty tibble!\n")
        test_errors[[name]] <<- "Empty tibble returned"
      }

      # Check for NAs in non-list columns
      for (col_name in names(val)) {
        if (!is.list(val[[col_name]])) {
          na_count <- sum(is.na(val[[col_name]]))
          if (na_count > 0) {
            cat("  Column '", col_name, "' has ", na_count, " NA values\n", sep = "")
          }
        }
      }

      print(val)
    } else {
      print(val)
    }

    test_results[[name]] <<- "PASS"
    invisible(val)
  }, error = function(e) {
    cat("FAILED:", conditionMessage(e), "\n")
    test_results[[name]] <<- "FAIL"
    test_errors[[name]] <<- conditionMessage(e)
    invisible(NULL)
  })

  result
}

# ============================================================================
# SECTION 1: CONFIGURATION
# ============================================================================

cat("\n\n### SECTION 1: CONFIGURATION ###\n")

run_test("foundry_check_setup", quote({
  foundry_check_setup()
}))

# ============================================================================
# SECTION 2: CHAT COMPLETIONS
# ============================================================================

cat("\n\n### SECTION 2: CHAT COMPLETIONS ###\n")

chat_model <- Sys.getenv("AZURE_FOUNDRY_MODEL")
if (chat_model == "") {
  cat("WARNING: AZURE_FOUNDRY_MODEL not set. Skipping chat tests.\n")
} else {
  cat("Using chat model:", chat_model, "\n\n")

  run_test("foundry_chat - basic question", quote({
    result <- foundry_chat("What is 2 + 2? Reply with just the number.",
                           model = chat_model)
    stopifnot(nrow(result) == 1)
    stopifnot(!is.na(result$content))
    stopifnot(nchar(result$content) > 0)
    result
  }))

  run_test("foundry_chat - with system prompt", quote({
    result <- foundry_chat(
      "Explain what a tibble is in R",
      system = "You are a helpful R tutor. Be concise, max 2 sentences.",
      model = chat_model
    )
    stopifnot(!is.na(result$content))
    result
  }))

  run_test("foundry_chat - with parameters", quote({
    result <- foundry_chat(
      "Say hello in a creative way",
      model = chat_model,
      temperature = 0.9,
      max_completion_tokens = 100
    )
    stopifnot(!is.na(result$content))
    result
  }))
}

# ============================================================================
# SECTION 3: EMBEDDINGS
# ============================================================================

cat("\n\n### SECTION 3: EMBEDDINGS ###\n")

embed_model <- Sys.getenv("AZURE_FOUNDRY_EMBED_MODEL")
if (embed_model == "") {
  cat("WARNING: AZURE_FOUNDRY_EMBED_MODEL not set. Skipping embedding tests.\n")
} else {
  cat("Using embedding model:", embed_model, "\n\n")

  run_test("foundry_embed - single text", quote({
    result <- foundry_embed("Data science is fascinating", model = embed_model)
    stopifnot(nrow(result) == 1)
    stopifnot(!is.na(result$n_dims))
    stopifnot(result$n_dims > 0)
    stopifnot(length(result$embedding[[1]]) == result$n_dims)
    result
  }))

  run_test("foundry_embed - multiple texts", quote({
    texts <- c(
      "I love R programming",
      "R is great for statistics",
      "Python is also popular for data science"
    )
    result <- foundry_embed(texts, model = embed_model)
    stopifnot(nrow(result) == 3)
    stopifnot(all(!is.na(result$n_dims)))
    result
  }))

  run_test("foundry_embed_batch - parallel processing", quote({
    texts <- c(
      "Machine learning transforms industries",
      "Deep learning uses neural networks",
      "NLP analyzes text data",
      "Computer vision interprets images",
      "Reinforcement learning trains agents",
      "Transformers power modern LLMs"
    )
    result <- foundry_embed_batch(texts, model = embed_model, batch_size = 2)
    stopifnot(nrow(result) == 6)
    stopifnot(all(!is.na(result$n_dims)))
    result
  }))

  run_test("foundry_similarity - pairwise", quote({
    texts <- c(
      "I love programming in R",
      "R is my favorite language for data analysis",
      "The weather is nice today",
      "It's sunny and warm outside"
    )
    embeddings <- foundry_embed(texts, model = embed_model)
    similarities <- foundry_similarity(embeddings)

    stopifnot(nrow(similarities) > 0)
    stopifnot(all(!is.na(similarities$similarity)))
    stopifnot(all(similarities$similarity >= -1 & similarities$similarity <= 1))

    # R-related texts should be more similar to each other
    cat("\nSimilarity results (should show R texts more similar to each other):\n")
    similarities
  }))

  run_test("foundry_similarity - semantic search example", quote({
    documents <- c(
      "How to install R packages using install.packages()",
      "Data visualization with ggplot2 in R",
      "Introduction to machine learning with Python",
      "Building web applications with Shiny"
    )

    doc_embeddings <- foundry_embed(documents, model = embed_model)
    query <- "How do I create charts in R?"
    query_embedding <- foundry_embed(query, model = embed_model)

    # Compute similarity
    compute_similarity <- function(emb1, emb2) {
      sum(emb1 * emb2) / (sqrt(sum(emb1^2)) * sqrt(sum(emb2^2)))
    }

    query_vec <- query_embedding$embedding[[1]]
    results <- doc_embeddings %>%
      mutate(similarity = sapply(embedding, function(e) compute_similarity(query_vec, e))) %>%
      arrange(desc(similarity)) %>%
      select(text, similarity)

    cat("\nTop results for query 'How do I create charts in R?':\n")
    stopifnot(nrow(results) == 4)
    # ggplot2 should rank highly
    results
  }))
}

# ============================================================================
# SECTION 4: CONTENT SAFETY
# ============================================================================

cat("\n\n### SECTION 4: CONTENT SAFETY ###\n")

cs_endpoint <- Sys.getenv("AZURE_CONTENT_SAFETY_ENDPOINT")
if (cs_endpoint == "") {
  cat("WARNING: AZURE_CONTENT_SAFETY_ENDPOINT not set. Skipping content safety tests.\n")
} else {
  cat("Content Safety endpoint:", cs_endpoint, "\n\n")

  run_test("foundry_moderate - safe content", quote({
    result <- foundry_moderate("I love R programming! It's great for data science.")
    stopifnot(nrow(result) == 1)
    stopifnot(!is.na(result$hate_severity))
    stopifnot(!is.na(result$violence_severity))
    # Safe content should have low scores
    stopifnot(result$hate_severity <= 2)
    result
  }))

  run_test("foundry_moderate - multiple texts", quote({
    texts <- c(
      "Have a wonderful day!",
      "This product exceeded my expectations",
      "I respectfully disagree with that opinion"
    )
    result <- foundry_moderate(texts)
    stopifnot(nrow(result) == 3)
    stopifnot(all(!is.na(result$hate_severity)))
    result
  }))

  run_test("foundry_groundedness - grounded response", quote({
    source_doc <- "foundryR is an R package for Azure AI Foundry. It was created by Alex Farach and is available on GitHub."
    ai_response <- "foundryR is an R package created by Alex Farach for Azure AI Foundry."

    result <- foundry_groundedness(
      text = ai_response,
      grounding_sources = source_doc
    )
    stopifnot(nrow(result) == 1)
    stopifnot(!is.na(result$grounded))
    cat("\nGroundedness result:", result$grounded, "\n")
    cat("Grounded %:", result$grounded_pct, "\n")
    result
  }))

  run_test("foundry_groundedness - with hallucination", quote({
    source_doc <- "foundryR provides functions for chat and embeddings."
    ai_response <- "foundryR was released in 2015 and has millions of downloads."

    result <- foundry_groundedness(
      text = ai_response,
      grounding_sources = source_doc
    )
    stopifnot(!is.na(result$grounded))
    cat("\nExpected: grounded = FALSE (contains hallucinated info)\n")
    cat("Actual grounded:", result$grounded, "\n")
    result
  }))

  run_test("foundry_shield - safe prompt", quote({
    result <- foundry_shield("What is the capital of France?")
    stopifnot(nrow(result) == 1)
    stopifnot(!is.na(result$attack_detected))
    stopifnot(result$attack_detected == FALSE)  # Should be safe
    result
  }))

  run_test("foundry_shield - with documents (RAG scenario)", quote({
    result <- foundry_shield(
      text = "Please summarize this document for me",
      documents = "This is a legitimate document about R programming best practices."
    )
    stopifnot(!is.na(result$attack_detected))
    result
  }))
}

# ============================================================================
# SECTION 5: IMAGE GENERATION
# ============================================================================

cat("\n\n### SECTION 5: IMAGE GENERATION ###\n")

image_model <- Sys.getenv("AZURE_FOUNDRY_IMAGE_MODEL")
image_endpoint <- Sys.getenv("AZURE_FOUNDRY_IMAGE_ENDPOINT")

if (image_model == "" || image_endpoint == "") {
  cat("WARNING: Image generation not configured. Skipping image tests.\n")
  cat("  AZURE_FOUNDRY_IMAGE_MODEL:", image_model, "\n")
  cat("  AZURE_FOUNDRY_IMAGE_ENDPOINT:", image_endpoint, "\n")
} else {
  cat("Image model:", image_model, "\n")
  cat("Image endpoint:", image_endpoint, "\n\n")

  run_test("foundry_image - basic generation", quote({
    result <- foundry_image(
      "A simple blue circle on a white background, minimalist style",
      model = image_model,
      quality = "standard"
    )
    stopifnot(nrow(result) == 1)
    stopifnot(!is.na(result$url) || !is.na(result$b64_json))
    stopifnot(!is.na(result$created))

    cat("\nImage URL (temporary):", substr(result$url, 1, 80), "...\n")
    cat("Revised prompt:", substr(result$revised_prompt, 1, 100), "...\n")
    result
  }))

  run_test("foundry_save_image - save to file", quote({
    result <- foundry_image(
      "A red square",
      model = image_model,
      quality = "standard"
    )

    temp_file <- tempfile(fileext = ".png")
    foundry_save_image(result, temp_file)

    stopifnot(file.exists(temp_file))
    stopifnot(file.size(temp_file) > 1000)  # Should be at least 1KB

    cat("Image saved successfully!\n")
    cat("File:", temp_file, "\n")
    cat("Size:", file.size(temp_file), "bytes\n")

    # Cleanup
    unlink(temp_file)
    result
  }))
}

# ============================================================================
# SECTION 6: TIDYMODELS INTEGRATION
# ============================================================================

cat("\n\n### SECTION 6: TIDYMODELS INTEGRATION ###\n")

if (!requireNamespace("recipes", quietly = TRUE)) {
  cat("WARNING: recipes package not installed. Skipping tidymodels tests.\n")
} else if (embed_model == "") {
  cat("WARNING: AZURE_FOUNDRY_EMBED_MODEL not set. Skipping tidymodels tests.\n")
} else {
  library(recipes)

  run_test("step_foundry_embed - create recipe", quote({
    reviews <- tibble(
      text = c("Great product!", "Terrible", "Average", "Loved it"),
      sentiment = factor(c("pos", "neg", "neu", "pos"))
    )

    recipe_spec <- recipe(sentiment ~ text, data = reviews) %>%
      step_foundry_embed(text, model = embed_model, keep_original = FALSE)

    cat("Recipe created successfully\n")
    print(recipe_spec)
    recipe_spec
  }))

  run_test("step_foundry_embed - prep and bake", quote({
    reviews <- tibble(
      text = c("Excellent!", "Poor quality", "Okay product"),
      sentiment = factor(c("pos", "neg", "neu"))
    )

    recipe_spec <- recipe(sentiment ~ text, data = reviews) %>%
      step_foundry_embed(text, model = embed_model, keep_original = FALSE)

    prepped <- prep(recipe_spec, training = reviews)
    baked <- bake(prepped, new_data = NULL)

    stopifnot(nrow(baked) == 3)
    stopifnot(ncol(baked) > 1)  # sentiment + embedding columns
    stopifnot("sentiment" %in% names(baked))
    stopifnot(!("text" %in% names(baked)))  # Original removed

    cat("Baked dimensions:", nrow(baked), "x", ncol(baked), "\n")
    cat("First few column names:", paste(head(names(baked), 5), collapse = ", "), "...\n")
    baked[, 1:min(5, ncol(baked))]
  }))

  run_test("step_foundry_embed - keep original", quote({
    reviews <- tibble(
      text = c("Test one", "Test two"),
      outcome = c(1, 0)
    )

    recipe_spec <- recipe(outcome ~ text, data = reviews) %>%
      step_foundry_embed(text, model = embed_model, keep_original = TRUE)

    prepped <- prep(recipe_spec, training = reviews)
    baked <- bake(prepped, new_data = NULL)

    stopifnot("text" %in% names(baked))  # Original kept
    cat("Original 'text' column preserved:", "text" %in% names(baked), "\n")
    baked[, 1:min(5, ncol(baked))]
  }))
}

# ============================================================================
# FINAL SUMMARY
# ============================================================================

cat("\n\n")
cat(strrep("=", 60), "\n")
cat("FINAL TEST SUMMARY\n")
cat(strrep("=", 60), "\n")

pass_count <- sum(test_results == "PASS")
fail_count <- sum(test_results == "FAIL")
total <- length(test_results)

cat("\nTotal tests run:", total, "\n")
cat("Passed:", pass_count, "\n")
cat("Failed:", fail_count, "\n")
cat("Success rate:", round(100 * pass_count / max(total, 1), 1), "%\n")

if (fail_count > 0) {
  cat("\n--- FAILED TESTS ---\n")
  for (name in names(test_errors)) {
    cat("\n", name, ":\n  ", test_errors[[name]], "\n", sep = "")
  }
}

cat("\n--- ALL RESULTS ---\n")
for (name in names(test_results)) {
  status_symbol <- if (test_results[[name]] == "PASS") "\u2714" else "\u2718"
  cat(sprintf("%s %-50s %s\n", status_symbol, name, test_results[[name]]))
}

cat("\n")
if (fail_count == 0) {
  cat("All tests passed! The package is working correctly.\n")
} else {
  cat("Some tests failed. Please review the errors above.\n")
}
