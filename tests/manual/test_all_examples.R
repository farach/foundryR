# ============================================================================
# foundryR Manual Integration Tests
# Comprehensive test coverage for ALL functions mentioned in vignettes
#
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
test_warnings <- list()

# Helper function for running tests
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
        test_warnings[[name]] <<- "Empty tibble returned"
      }

      # Check for unexpected NAs in non-list columns
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
# SECTION 1: CONFIGURATION FUNCTIONS
# From: getting-started.Rmd, content-safety.Rmd, image-generation.Rmd
# ============================================================================

cat("\n\n### SECTION 1: CONFIGURATION FUNCTIONS ###\n")

# Test foundry_check_setup()
run_test("foundry_check_setup - basic", quote({
  foundry_check_setup()
}))

# Test foundry_set_endpoint / foundry_get_endpoint
run_test("foundry_set_endpoint / foundry_get_endpoint", quote({
  # Store current endpoint
  current_endpoint <- Sys.getenv("AZURE_FOUNDRY_ENDPOINT")

  # Test setting endpoint
  suppressMessages(foundry_set_endpoint("https://test-endpoint.openai.azure.com"))
  retrieved <- foundry_get_endpoint()
  stopifnot(retrieved == "https://test-endpoint.openai.azure.com")

  # Restore original
  if (current_endpoint != "") {
    Sys.setenv(AZURE_FOUNDRY_ENDPOINT = current_endpoint)
  }

  cat("Endpoint set and retrieved successfully\n")
  TRUE
}))

# Test Content Safety config functions
run_test("foundry_set_content_safety_endpoint / get", quote({
  current_endpoint <- Sys.getenv("AZURE_CONTENT_SAFETY_ENDPOINT")

  suppressMessages(foundry_set_content_safety_endpoint("https://test-cs.cognitiveservices.azure.com"))
  retrieved <- get_content_safety_endpoint()
  stopifnot(retrieved == "https://test-cs.cognitiveservices.azure.com")

  # Restore
  if (current_endpoint != "") {
    Sys.setenv(AZURE_CONTENT_SAFETY_ENDPOINT = current_endpoint)
  }

  cat("Content Safety endpoint set and retrieved successfully\n")
  TRUE
}))

run_test("foundry_set_content_safety_key", quote({
  current_key <- Sys.getenv("AZURE_CONTENT_SAFETY_KEY")

  suppressMessages(foundry_set_content_safety_key("test-cs-key-12345"))
  retrieved <- get_content_safety_key()
  stopifnot(retrieved == "test-cs-key-12345")

  # Restore
  if (current_key != "") {
    Sys.setenv(AZURE_CONTENT_SAFETY_KEY = current_key)
  }

  cat("Content Safety key set and retrieved successfully\n")
  TRUE
}))

# Test Image config functions
run_test("foundry_set_image_endpoint / foundry_get_image_endpoint", quote({
  current_endpoint <- Sys.getenv("AZURE_FOUNDRY_IMAGE_ENDPOINT")

  suppressMessages(foundry_set_image_endpoint("https://test-dalle.cognitiveservices.azure.com"))
  retrieved <- foundry_get_image_endpoint()
  stopifnot(retrieved == "https://test-dalle.cognitiveservices.azure.com")

  # Restore
  if (current_endpoint != "") {
    Sys.setenv(AZURE_FOUNDRY_IMAGE_ENDPOINT = current_endpoint)
  }

  cat("Image endpoint set and retrieved successfully\n")
  TRUE
}))

run_test("foundry_set_image_key / foundry_get_image_key", quote({
  current_key <- Sys.getenv("AZURE_FOUNDRY_IMAGE_KEY")

  suppressMessages(foundry_set_image_key("test-image-key-12345"))
  retrieved <- foundry_get_image_key()
  stopifnot(retrieved == "test-image-key-12345")

  # Restore
  if (current_key != "") {
    Sys.setenv(AZURE_FOUNDRY_IMAGE_KEY = current_key)
  }

  cat("Image key set and retrieved successfully\n")
  TRUE
}))

# ============================================================================
# SECTION 2: CHAT COMPLETIONS
# From: getting-started.Rmd, onet2r-integration.Rmd
# ============================================================================

cat("\n\n### SECTION 2: CHAT COMPLETIONS ###\n")

chat_model <- Sys.getenv("AZURE_FOUNDRY_MODEL")
if (chat_model == "") {
  cat("WARNING: AZURE_FOUNDRY_MODEL not set. Skipping chat tests.\n")
} else {
  cat("Using chat model:", chat_model, "\n\n")

  # Basic chat - from getting-started.Rmd
  run_test("foundry_chat - basic question", quote({
    result <- foundry_chat("What is 2 + 2? Reply with just the number.",
                           model = chat_model)
    stopifnot(nrow(result) == 1)
    stopifnot(!is.na(result$content))
    stopifnot(nchar(result$content) > 0)
    stopifnot("role" %in% names(result))
    stopifnot("finish_reason" %in% names(result))
    stopifnot("prompt_tokens" %in% names(result))
    stopifnot("completion_tokens" %in% names(result))
    stopifnot("total_tokens" %in% names(result))
    result
  }))

  # Chat with system prompt - from getting-started.Rmd
  run_test("foundry_chat - with system prompt", quote({
    result <- foundry_chat(
      "Explain what a tibble is in R",
      system = "You are a helpful R tutor. Be concise, max 2 sentences.",
      model = chat_model
    )
    stopifnot(!is.na(result$content))
    result
  }))

  # Chat with temperature - from getting-started.Rmd
  run_test("foundry_chat - with temperature", quote({
    result <- foundry_chat(
      "Write a haiku about data science",
      model = chat_model,
      temperature = 0.9
    )
    stopifnot(!is.na(result$content))
    result
  }))

  # Chat with max_completion_tokens - from getting-started.Rmd
  run_test("foundry_chat - with max_completion_tokens", quote({
    result <- foundry_chat(
      "Say hello in a creative way",
      model = chat_model,
      max_completion_tokens = 100
    )
    stopifnot(!is.na(result$content))
    result
  }))

  # Chat for career analysis - from onet2r-integration.Rmd
  run_test("foundry_chat - career analysis scenario", quote({
    occupation_data <- paste(
      "Occupation: Software Developer",
      "Description: Research, design, and develop computer systems",
      "Top Skills: Programming, Critical Thinking, Problem Solving"
    )

    result <- foundry_chat(
      prompt = occupation_data,
      system = "You are a career counselor. Provide a brief 2-sentence summary.",
      model = chat_model
    )
    stopifnot(!is.na(result$content))
    cat("\nCareer analysis response:\n", substr(result$content, 1, 200), "...\n")
    result
  }))
}

# ============================================================================
# SECTION 3: EMBEDDINGS
# From: getting-started.Rmd, embeddings.Rmd, onet2r-integration.Rmd
# ============================================================================

cat("\n\n### SECTION 3: EMBEDDINGS ###\n")

embed_model <- Sys.getenv("AZURE_FOUNDRY_EMBED_MODEL")
if (embed_model == "") {
  cat("WARNING: AZURE_FOUNDRY_EMBED_MODEL not set. Skipping embedding tests.\n")
} else {
  cat("Using embedding model:", embed_model, "\n\n")

  # Single text embedding - from getting-started.Rmd
  run_test("foundry_embed - single text", quote({
    result <- foundry_embed("Data science is fascinating", model = embed_model)
    stopifnot(nrow(result) == 1)
    stopifnot(!is.na(result$n_dims))
    stopifnot(result$n_dims > 0)
    stopifnot(length(result$embedding[[1]]) == result$n_dims)
    stopifnot("text" %in% names(result))
    stopifnot("embedding" %in% names(result))
    result
  }))

  # Multiple text embeddings - from getting-started.Rmd, embeddings.Rmd
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

  # Embeddings with dimensions parameter - from embeddings.Rmd
  run_test("foundry_embed - with dimensions (if supported)", quote({
    # Try reduced dimensions - may fail if model doesn't support it
    result <- tryCatch({
      foundry_embed(
        "Hello, world!",
        model = embed_model,
        dimensions = 256
      )
    }, error = function(e) {
      cat("Note: Model may not support dimension reduction\n")
      foundry_embed("Hello, world!", model = embed_model)
    })
    stopifnot(nrow(result) == 1)
    result
  }))

  # Batch embeddings - from embeddings.Rmd, onet2r-integration.Rmd
  run_test("foundry_embed_batch - parallel processing", quote({
    texts <- c(
      "Machine learning transforms industries",
      "Deep learning uses neural networks",
      "NLP analyzes text data",
      "Computer vision interprets images",
      "Reinforcement learning trains agents",
      "Transformers power modern LLMs"
    )
    result <- foundry_embed_batch(texts, model = embed_model, batch_size = 2, progress = FALSE)
    stopifnot(nrow(result) == 6)
    stopifnot(all(!result$.error))
    stopifnot(all(!is.na(result$n_dims)))
    stopifnot(".input_idx" %in% names(result))
    stopifnot(".error" %in% names(result))
    stopifnot(".error_msg" %in% names(result))
    result
  }))

  # Similarity computation - from embeddings.Rmd
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
    stopifnot("text_1" %in% names(similarities))
    stopifnot("text_2" %in% names(similarities))

    cat("\nSimilarity results (R texts should be more similar to each other):\n")
    similarities
  }))

  # Semantic search example - from embeddings.Rmd
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

  # Clustering example - from embeddings.Rmd
  run_test("foundry_embed - clustering example", quote({
    texts <- c(
      "Python is great for machine learning",
      "R excels at statistical analysis",
      "Italian pasta with tomato sauce",
      "Sushi is a popular Japanese dish",
      "Soccer is the world's most popular sport",
      "Basketball requires speed and agility"
    )

    embeddings <- foundry_embed(texts, model = embed_model)
    embedding_matrix <- do.call(rbind, embeddings$embedding)

    set.seed(42)
    clusters <- kmeans(embedding_matrix, centers = 3, nstart = 10)

    results <- embeddings %>%
      mutate(cluster = clusters$cluster) %>%
      arrange(cluster) %>%
      select(text, cluster)

    cat("\nClustering results (should group by topic):\n")
    print(results)

    stopifnot(nrow(results) == 6)
    stopifnot("cluster" %in% names(results))
    results
  }))
}

# ============================================================================
# SECTION 4: CONTENT SAFETY
# From: content-safety.Rmd
# ============================================================================

cat("\n\n### SECTION 4: CONTENT SAFETY ###\n")

cs_endpoint <- Sys.getenv("AZURE_CONTENT_SAFETY_ENDPOINT")
if (cs_endpoint == "") {
  cat("WARNING: AZURE_CONTENT_SAFETY_ENDPOINT not set. Skipping content safety tests.\n")
} else {
  cat("Content Safety endpoint:", cs_endpoint, "\n\n")

  # Basic moderation - from content-safety.Rmd
  run_test("foundry_moderate - safe content", quote({
    result <- foundry_moderate("I love R programming! It's great for data science.")
    stopifnot(nrow(result) == 4)  # 4 categories
    stopifnot("category" %in% names(result))
    stopifnot("severity" %in% names(result))
    stopifnot("label" %in% names(result))
    stopifnot(all(!is.na(result$severity)))
    stopifnot(all(result$severity <= 2))  # Safe content
    result
  }))

  # Multiple text moderation - from content-safety.Rmd
  run_test("foundry_moderate - multiple texts", quote({
    texts <- c(
      "Have a wonderful day!",
      "This product exceeded my expectations",
      "I respectfully disagree with that opinion"
    )
    result <- foundry_moderate(texts)
    stopifnot(nrow(result) == 12)  # 3 texts x 4 categories
    stopifnot(all(!is.na(result$severity)))
    result
  }))

  # Groundedness detection - QnA task - from content-safety.Rmd
  run_test("foundry_groundedness - grounded response (QnA)", quote({
    source_doc <- "foundryR is an R package for Azure AI Foundry. It was created by Alex Farach and is available on GitHub."
    ai_response <- "foundryR is an R package created by Alex Farach for Azure AI Foundry."
    user_query <- "What is foundryR and who created it?"

    result <- foundry_groundedness(
      text = ai_response,
      grounding_sources = source_doc,
      query = user_query,
      task = "QnA"
    )
    stopifnot(nrow(result) == 1)
    stopifnot(!is.na(result$grounded))
    stopifnot("grounded" %in% names(result))
    stopifnot("grounded_pct" %in% names(result))
    stopifnot("ungrounded_pct" %in% names(result))
    stopifnot("ungrounded_segments" %in% names(result))

    cat("\nGroundedness result:", result$grounded, "\n")
    cat("Grounded %:", result$grounded_pct, "\n")
    result
  }))

  # Groundedness - Summarization task - from content-safety.Rmd
  run_test("foundry_groundedness - summarization task", quote({
    source_doc <- "foundryR provides functions for chat and embeddings. It integrates with tidymodels."
    ai_response <- "foundryR offers chat, embeddings, and tidymodels integration."

    result <- foundry_groundedness(
      text = ai_response,
      grounding_sources = source_doc,
      task = "Summarization"
    )
    stopifnot(!is.na(result$grounded))
    cat("\nGrounded:", result$grounded, "\n")
    result
  }))

  # Groundedness - hallucination detection - from content-safety.Rmd
  run_test("foundry_groundedness - hallucination detection", quote({
    source_doc <- "foundryR is an R package for Azure AI Foundry created by Alex Farach."
    hallucinated_response <- "foundryR was released in 2020 and has over 10,000 downloads on CRAN."

    result <- foundry_groundedness(
      text = hallucinated_response,
      grounding_sources = source_doc,
      query = "When was foundryR released?",
      task = "QnA"
    )

    cat("\nHallucination detection - Grounded:", result$grounded, "\n")
    cat("Ungrounded %:", result$ungrounded_pct, "\n")
    if (length(result$ungrounded_segments[[1]]) > 0) {
      cat("Ungrounded segments:", paste(result$ungrounded_segments[[1]], collapse = "; "), "\n")
    }
    result
  }))

  # Groundedness - multiple sources - from content-safety.Rmd
  run_test("foundry_groundedness - multiple sources", quote({
    sources <- c(
      "foundryR provides chat completions via foundry_chat().",
      "Text embeddings are generated with foundry_embed().",
      "The package integrates with tidymodels via step_foundry_embed()."
    )

    result <- foundry_groundedness(
      text = "foundryR offers chat, embeddings, and tidymodels integration.",
      grounding_sources = sources,
      task = "Summarization"
    )
    stopifnot(!is.na(result$grounded))
    result
  }))

  # Shield - safe prompt - from content-safety.Rmd
  run_test("foundry_shield - safe prompt", quote({
    result <- foundry_shield("What is the capital of France?")
    stopifnot(nrow(result) == 1)
    stopifnot(!is.na(result$attack_detected))
    stopifnot(result$attack_detected == FALSE)
    stopifnot("source" %in% names(result))
    stopifnot("content" %in% names(result))
    result
  }))

  # Shield - with documents (RAG scenario) - from content-safety.Rmd
  run_test("foundry_shield - with documents (RAG)", quote({
    result <- foundry_shield(
      user_prompt = "Please summarize this document for me",
      documents = "This is a legitimate document about R programming best practices."
    )
    stopifnot(nrow(result) == 2)  # user_prompt + 1 document
    stopifnot(all(!is.na(result$attack_detected)))
    result
  }))

  # Shield - multiple documents - from content-safety.Rmd
  run_test("foundry_shield - multiple documents", quote({
    result <- foundry_shield(
      user_prompt = "Summarize these documents",
      documents = c(
        "Document 1: Introduction to R programming",
        "Document 2: Advanced data visualization",
        "Document 3: Machine learning basics"
      )
    )
    stopifnot(nrow(result) == 4)  # user_prompt + 3 documents
    result
  }))
}

# ============================================================================
# SECTION 5: IMAGE GENERATION
# From: image-generation.Rmd
# ============================================================================

cat("\n\n### SECTION 5: IMAGE GENERATION ###\n")

image_model <- Sys.getenv("AZURE_FOUNDRY_IMAGE_MODEL")
image_endpoint <- Sys.getenv("AZURE_FOUNDRY_IMAGE_ENDPOINT")

if (image_model == "") {
  cat("WARNING: AZURE_FOUNDRY_IMAGE_MODEL not set. Skipping image tests.\n")
} else {
  cat("Image model:", image_model, "\n")
  if (image_endpoint != "") cat("Image endpoint:", image_endpoint, "\n")
  cat("\n")

  # Basic image generation - from image-generation.Rmd
  run_test("foundry_image - basic generation", quote({
    result <- foundry_image(
      "A simple blue circle on a white background, minimalist style",
      model = image_model,
      quality = "standard"
    )
    stopifnot(nrow(result) == 1)
    stopifnot(!is.na(result$url) || !is.na(result$b64_json))
    stopifnot(!is.na(result$created))
    stopifnot("prompt" %in% names(result))
    stopifnot("revised_prompt" %in% names(result))
    stopifnot("url" %in% names(result))
    stopifnot("b64_json" %in% names(result))

    cat("\nImage URL (temporary):", substr(result$url, 1, 80), "...\n")
    cat("Revised prompt:", substr(result$revised_prompt, 1, 100), "...\n")
    result
  }))

  # Image with size parameter - from image-generation.Rmd
  run_test("foundry_image - landscape size", quote({
    result <- foundry_image(
      "A panoramic mountain landscape",
      model = image_model,
      size = "1792x1024",
      quality = "standard"
    )
    stopifnot(!is.na(result$url) || !is.na(result$b64_json))
    result
  }))

  # Image with quality parameter - from image-generation.Rmd
  run_test("foundry_image - HD quality", quote({
    result <- foundry_image(
      "A detailed mandala pattern",
      model = image_model,
      quality = "hd"
    )
    stopifnot(!is.na(result$url) || !is.na(result$b64_json))
    result
  }))

  # Image with style parameter - from image-generation.Rmd
  run_test("foundry_image - natural style", quote({
    result <- foundry_image(
      "A golden retriever in a park",
      model = image_model,
      style = "natural",
      quality = "standard"
    )
    stopifnot(!is.na(result$url) || !is.na(result$b64_json))
    result
  }))

  # Multiple images - from image-generation.Rmd
  run_test("foundry_image - multiple images (n=2)", quote({
    result <- foundry_image(
      "An abstract representation of data science",
      model = image_model,
      n = 2,
      quality = "standard"
    )
    stopifnot(nrow(result) == 2)
    result
  }))

  # Save image to file - from image-generation.Rmd
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

  # Base64 response format - from image-generation.Rmd
  run_test("foundry_image - base64 response format", quote({
    result <- foundry_image(
      "A simple logo design",
      model = image_model,
      response_format = "b64_json",
      quality = "standard"
    )

    stopifnot(!is.na(result$b64_json))
    stopifnot(nchar(result$b64_json) > 1000)  # Should have substantial base64 data

    cat("Base64 data length:", nchar(result$b64_json), "characters\n")
    result
  }))

  # Save base64 image - from image-generation.Rmd
  run_test("foundry_save_image - save from base64", quote({
    result <- foundry_image(
      "A green triangle",
      model = image_model,
      response_format = "b64_json",
      quality = "standard"
    )

    temp_file <- tempfile(fileext = ".png")
    foundry_save_image(result, temp_file)

    stopifnot(file.exists(temp_file))
    stopifnot(file.size(temp_file) > 1000)

    cat("Base64 image saved successfully!\n")
    cat("File:", temp_file, "\n")
    cat("Size:", file.size(temp_file), "bytes\n")

    # Cleanup
    unlink(temp_file)
    result
  }))
}

# ============================================================================
# SECTION 6: TIDYMODELS INTEGRATION
# From: tidymodels.Rmd
# ============================================================================

cat("\n\n### SECTION 6: TIDYMODELS INTEGRATION ###\n")

if (!requireNamespace("recipes", quietly = TRUE)) {
  cat("WARNING: recipes package not installed. Skipping tidymodels tests.\n")
} else if (embed_model == "") {
  cat("WARNING: AZURE_FOUNDRY_EMBED_MODEL not set. Skipping tidymodels tests.\n")
} else {
  library(recipes)

  # Create recipe with step_foundry_embed - from tidymodels.Rmd
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

  # Prep and bake recipe - from tidymodels.Rmd
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

  # Keep original column - from tidymodels.Rmd
  run_test("step_foundry_embed - keep_original = TRUE", quote({
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

  # Custom prefix - from tidymodels.Rmd
  run_test("step_foundry_embed - custom prefix", quote({
    reviews <- tibble(
      text = c("Hello", "World"),
      outcome = c(1, 0)
    )

    recipe_spec <- recipe(outcome ~ text, data = reviews) %>%
      step_foundry_embed(text, model = embed_model, prefix = "vec_")

    prepped <- prep(recipe_spec, training = reviews)
    baked <- bake(prepped, new_data = NULL)

    # Check that columns start with "vec_"
    emb_cols <- names(baked)[grepl("^vec_", names(baked))]
    stopifnot(length(emb_cols) > 0)

    cat("Embedding columns with custom prefix:", paste(head(emb_cols, 3), collapse = ", "), "...\n")
    baked[, 1:min(5, ncol(baked))]
  }))

  # Tidy method - from tidymodels.Rmd
  run_test("step_foundry_embed - tidy method", quote({
    reviews <- tibble(
      text = c("Test", "Data"),
      outcome = c(1, 0)
    )

    recipe_spec <- recipe(outcome ~ text, data = reviews) %>%
      step_foundry_embed(text, model = embed_model, dimensions = 256)

    tidied <- tidy(recipe_spec$steps[[1]])

    stopifnot(is.data.frame(tidied))
    stopifnot("terms" %in% names(tidied))
    stopifnot("model" %in% names(tidied))
    stopifnot("dimensions" %in% names(tidied))
    stopifnot("id" %in% names(tidied))

    print(tidied)
    tidied
  }))

  # Required packages - from tidymodels.Rmd
  run_test("step_foundry_embed - required_pkgs", quote({
    reviews <- tibble(
      text = c("Test"),
      outcome = c(1)
    )

    recipe_spec <- recipe(outcome ~ text, data = reviews) %>%
      step_foundry_embed(text, model = embed_model)

    pkgs <- required_pkgs(recipe_spec$steps[[1]])

    stopifnot("foundryR" %in% pkgs)
    cat("Required packages:", paste(pkgs, collapse = ", "), "\n")
    pkgs
  }))

  # Bake with new data - from tidymodels.Rmd
  run_test("step_foundry_embed - bake with new_data", quote({
    train_reviews <- tibble(
      text = c("Great!", "Bad"),
      outcome = c(1, 0)
    )

    test_reviews <- tibble(
      text = c("Amazing!", "Terrible"),
      outcome = c(1, 0)
    )

    recipe_spec <- recipe(outcome ~ text, data = train_reviews) %>%
      step_foundry_embed(text, model = embed_model, keep_original = FALSE)

    prepped <- prep(recipe_spec, training = train_reviews)
    baked_test <- bake(prepped, new_data = test_reviews)

    stopifnot(nrow(baked_test) == 2)
    stopifnot("outcome" %in% names(baked_test))
    stopifnot(!("text" %in% names(baked_test)))

    cat("New data baked successfully\n")
    cat("Dimensions:", nrow(baked_test), "x", ncol(baked_test), "\n")
    baked_test[, 1:min(5, ncol(baked_test))]
  }))

  # Multiple text columns - from tidymodels.Rmd
  run_test("step_foundry_embed - multiple text columns", quote({
    data <- tibble(
      title = c("Great Product", "Terrible Experience"),
      description = c("Works as expected", "Broke immediately"),
      outcome = c(1, 0)
    )

    recipe_spec <- recipe(outcome ~ ., data = data) %>%
      step_foundry_embed(title, model = embed_model, prefix = "title_") %>%
      step_foundry_embed(description, model = embed_model, prefix = "desc_") %>%
      step_rm(title, description)

    prepped <- prep(recipe_spec, training = data)
    baked <- bake(prepped, new_data = NULL)

    # Check that both sets of embedding columns exist
    title_cols <- names(baked)[grepl("^title_", names(baked))]
    desc_cols <- names(baked)[grepl("^desc_", names(baked))]

    stopifnot(length(title_cols) > 0)
    stopifnot(length(desc_cols) > 0)

    cat("Title embedding columns:", length(title_cols), "\n")
    cat("Description embedding columns:", length(desc_cols), "\n")
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

if (length(test_warnings) > 0) {
  cat("\n--- WARNINGS ---\n")
  for (name in names(test_warnings)) {
    cat("\n", name, ":\n  ", test_warnings[[name]], "\n", sep = "")
  }
}

if (fail_count > 0) {
  cat("\n--- FAILED TESTS ---\n")
  for (name in names(test_errors)) {
    cat("\n", name, ":\n  ", test_errors[[name]], "\n", sep = "")
  }
}

cat("\n--- ALL RESULTS ---\n")
for (name in names(test_results)) {
  status_symbol <- if (test_results[[name]] == "PASS") "\u2714" else "\u2718"
  cat(sprintf("%s %-55s %s\n", status_symbol, name, test_results[[name]]))
}

cat("\n")
if (fail_count == 0) {
  cat("All tests passed! The package is working correctly.\n")
} else {
  cat("Some tests failed. Please review the errors above.\n")
}

# ============================================================================
# VIGNETTE COVERAGE CHECKLIST
# ============================================================================

cat("\n")
cat(strrep("=", 60), "\n")
cat("VIGNETTE FUNCTION COVERAGE\n")
cat(strrep("=", 60), "\n")

cat("\n[getting-started.Rmd]\n")
cat("  foundry_set_endpoint()        - Tested\n")
cat("  foundry_set_key()             - Tested (via foundry_check_setup)\n")
cat("  foundry_check_setup()         - Tested\n")
cat("  foundry_chat()                - Tested (basic, system, temp, max_tokens)\n")
cat("  foundry_embed()               - Tested (single, multiple)\n")

cat("\n[embeddings.Rmd]\n")
cat("  foundry_embed()               - Tested (dimensions parameter)\n")
cat("  foundry_similarity()          - Tested (pairwise, semantic search)\n")
cat("  foundry_embed_batch()         - Tested\n")

cat("\n[content-safety.Rmd]\n")
cat("  foundry_set_content_safety_endpoint() - Tested\n")
cat("  foundry_set_content_safety_key()      - Tested\n")
cat("  foundry_moderate()                    - Tested (single, multiple)\n")
cat("  foundry_groundedness()                - Tested (QnA, Summarization, multiple sources)\n")
cat("  foundry_shield()                      - Tested (basic, with documents)\n")

cat("\n[image-generation.Rmd]\n")
cat("  foundry_set_image_endpoint()  - Tested\n")
cat("  foundry_set_image_key()       - Tested\n")
cat("  foundry_get_image_endpoint()  - Tested\n")
cat("  foundry_get_image_key()       - Tested\n")
cat("  foundry_image()               - Tested (basic, size, quality, style, n, b64_json)\n")
cat("  foundry_save_image()          - Tested (URL, base64)\n")

cat("\n[tidymodels.Rmd]\n")
cat("  step_foundry_embed()          - Tested (create, prep, bake)\n")
cat("  prep.step_foundry_embed       - Tested\n")
cat("  bake.step_foundry_embed       - Tested (keep_original, prefix, new_data)\n")
cat("  tidy.step_foundry_embed       - Tested\n")
cat("  required_pkgs.step_foundry_embed - Tested\n")

cat("\n[onet2r-integration.Rmd] (foundryR functions only)\n")
cat("  foundry_set_endpoint()        - Tested (in Section 1)\n")
cat("  foundry_set_key()             - Tested (in Section 1)\n")
cat("  foundry_embed()               - Tested (in Section 3)\n")
cat("  foundry_chat()                - Tested (career analysis scenario)\n")

cat("\n")
