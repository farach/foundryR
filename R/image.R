#' Set Image Generation Endpoint
#'
#' Set the Azure endpoint for image generation (DALL-E). Use this when your
#' DALL-E model is deployed on a different Azure resource than your chat/embedding models.
#'
#' @param endpoint Character. The full Azure endpoint URL for image generation.
#'
#' @return Invisibly returns the endpoint that was set.
#'
#' @details
#' If not set, `foundry_image()` will fall back to `AZURE_FOUNDRY_ENDPOINT`.
#' Use this function when DALL-E is deployed on a separate Azure resource.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_set_image_endpoint("https://my-dalle-resource.cognitiveservices.azure.com")
#' }
foundry_set_image_endpoint <- function(endpoint) {
 if (is.null(endpoint) || endpoint == "") {
    cli::cli_abort("Image endpoint is required and cannot be empty.")
  }

  # Remove trailing slash if present
 endpoint <- sub("/$", "", endpoint)

  Sys.setenv(AZURE_FOUNDRY_IMAGE_ENDPOINT = endpoint)
  cli::cli_alert_success("Image endpoint set to {.url {endpoint}}")
  invisible(endpoint)
}


#' Get Image Generation Endpoint
#'
#' Retrieve the Azure endpoint for image generation.
#'
#' @param required Logical. If TRUE and no endpoint is set, throws an error.
#'
#' @return Character string with the endpoint, or NULL if not set and not required.
#'
#' @details
#' Checks `AZURE_FOUNDRY_IMAGE_ENDPOINT` first, then falls back to `AZURE_FOUNDRY_ENDPOINT`.
#'
#' @keywords internal
foundry_get_image_endpoint <- function(required = FALSE) {
  # First check image-specific endpoint
  endpoint <- Sys.getenv("AZURE_FOUNDRY_IMAGE_ENDPOINT")

  # Fall back to main endpoint
  if (endpoint == "") {
    endpoint <- Sys.getenv("AZURE_FOUNDRY_ENDPOINT")
  }

  if (endpoint == "") {
    if (required) {
      cli::cli_abort(c(
        "Image endpoint is required but not set.",
        "i" = "Set {.envvar AZURE_FOUNDRY_IMAGE_ENDPOINT} or use {.fun foundry_set_image_endpoint}.",
        "i" = "Alternatively, set {.envvar AZURE_FOUNDRY_ENDPOINT} if DALL-E is on your main resource."
      ))
    }
    return(NULL)
  }

  endpoint
}


#' Set Image Generation API Key
#'
#' Set the API key for image generation. Use this when your DALL-E model
#' uses a different API key than your chat/embedding models.
#'
#' @param key Character. The API key for image generation.
#'
#' @return Invisibly returns TRUE on success.
#'
#' @details
#' If not set, `foundry_image()` will fall back to `AZURE_FOUNDRY_KEY`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_set_image_key("your-dalle-api-key")
#' }
foundry_set_image_key <- function(key) {
  if (is.null(key) || is.na(key) || key == "") {
    cli::cli_abort("Image API key cannot be empty.")
  }

  Sys.setenv(AZURE_FOUNDRY_IMAGE_KEY = key)
  cli::cli_alert_success("Image API key set successfully.")
  invisible(TRUE)
}


#' Get Image Generation API Key
#'
#' Retrieve the API key for image generation.
#'
#' @param key Character. Optional key to use directly instead of environment variable.
#' @param required Logical. If TRUE and no key is found, throws an error.
#'
#' @return Character string with the API key, or NULL if not found and not required.
#'
#' @details
#' Checks in order: provided key, `AZURE_FOUNDRY_IMAGE_KEY`, `AZURE_FOUNDRY_KEY`.
#'
#' @keywords internal
foundry_get_image_key <- function(key = NULL, required = FALSE) {
  # Use provided key first
  if (!is.null(key) && key != "") {
    return(key)
  }

  # Check image-specific key
  env_key <- Sys.getenv("AZURE_FOUNDRY_IMAGE_KEY")

  # Fall back to main key
  if (env_key == "") {
    env_key <- Sys.getenv("AZURE_FOUNDRY_KEY")
  }

  if (env_key == "") {
    if (required) {
      cli::cli_abort(c(
        "Image API key is required but not set.",
        "i" = "Set {.envvar AZURE_FOUNDRY_IMAGE_KEY} or use {.fun foundry_set_image_key}.",
        "i" = "Alternatively, set {.envvar AZURE_FOUNDRY_KEY} if using the same key as your main resource."
      ))
    }
    return(NULL)
  }

  env_key
}


#' Generate Images with DALL-E
#'
#' Generate images using an Azure AI Foundry deployed DALL-E model. Returns a
#' tibble with the generated image URLs or base64-encoded data, along with
#' metadata about the generation.
#'
#' @param prompt Character. A text description of the desired image(s).
#' @param model Character. The deployment name of a DALL-E model.
#'   Defaults to the environment variable `AZURE_FOUNDRY_IMAGE_MODEL`.
#' @param n Integer. Number of images to generate (1-10). Default: 1.
#' @param size Character. The size of the generated image(s).
#'   One of: "1024x1024" (default), "1792x1024", "1024x1792", "512x512", "256x256".
#'   Note: Not all sizes are supported by all DALL-E versions.
#' @param quality Character. The quality of the image. One of: "standard" (default), "hd".
#'   HD quality provides finer details and greater consistency. Only supported by DALL-E 3.
#' @param style Character. The style of the generated image. One of: "vivid" (default), "natural".
#'   Vivid creates hyper-real and dramatic images. Natural produces more realistic,
#'   less hyper-real images. Only supported by DALL-E 3.
#' @param response_format Character. The format of the generated images.
#'   One of: "url" (default) or "b64_json" (base64-encoded).
#' @param api_key Character. Optional API key override.
#' @param api_version Character. Optional API version override.
#'
#' @return A tibble with columns:
#'   \describe{
#'     \item{prompt}{Character. The original prompt provided.}
#'     \item{revised_prompt}{Character. DALL-E's interpretation/revision of the prompt (DALL-E 3 only).}
#'     \item{url}{Character. URL to the generated image (NA if response_format is "b64_json").}
#'     \item{b64_json}{Character. Base64-encoded image data (NA if response_format is "url").}
#'     \item{created}{POSIXct. Timestamp when the image was created.}
#'   }
#'
#' @details
#' **Model Requirements**: The `model` parameter must be a deployment of a DALL-E model
#' (e.g., dall-e-2, dall-e-3). Chat models cannot generate images.
#'
#' **Size Availability**:
#' - DALL-E 3: 1024x1024, 1792x1024, 1024x1792
#' - DALL-E 2: 256x256, 512x512, 1024x1024
#'
#' **URL Expiration**: Image URLs returned by the API are temporary and will expire.
#' Use `foundry_save_image()` to download and save images locally.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Generate a single image
#' result <- foundry_image("A sunset over mountains", model = "dall-e-3")
#'
#' # View the image URL
#' result$url
#'
#' # Generate multiple images with HD quality
#' result <- foundry_image(
#'   "A futuristic cityscape",
#'   model = "dall-e-3",
#'   n = 2,
#'   quality = "hd",
#'   style = "vivid"
#' )
#'
#' # Get base64-encoded images instead of URLs
#' result <- foundry_image(
#'   "An abstract painting",
#'   model = "dall-e-3",
#'   response_format = "b64_json"
#' )
#'
#' # Save an image to disk
#' result <- foundry_image("A cat wearing a hat", model = "dall-e-3")
#' foundry_save_image(result, "cat_hat.png")
#' }
foundry_image <- function(prompt,
                          model = NULL,
                          n = 1L,
                          size = c("1024x1024", "1792x1024", "1024x1792", "512x512", "256x256"),
                          quality = c("standard", "hd"),
                          style = c("vivid", "natural"),
                          response_format = c("url", "b64_json"),
                          api_key = NULL,
                          api_version = NULL) {

  # Get model/deployment
  if (is.null(model)) {
    model <- Sys.getenv("AZURE_FOUNDRY_IMAGE_MODEL")
    if (model == "") {
      cli::cli_abort(c(
        "Image model/deployment name is required.",
        "i" = "Specify {.arg model} or set the {.envvar AZURE_FOUNDRY_IMAGE_MODEL} environment variable."
      ))
    }
  }

  # Validate prompt
  if (missing(prompt) || is.null(prompt) || !is.character(prompt) || length(prompt) != 1) {
    cli::cli_abort("{.arg prompt} must be a single non-empty character string.")
  }

  if (nchar(prompt) == 0) {
    cli::cli_abort("{.arg prompt} cannot be empty.")
  }

  # Validate n
  n <- as.integer(n)
  if (is.na(n) || n < 1 || n > 10) {
    cli::cli_abort("{.arg n} must be an integer between 1 and 10.")
  }

  # Match arguments
  size <- match.arg(size)
  quality <- match.arg(quality)
  style <- match.arg(style)
  response_format <- match.arg(response_format)

  # Build request body
  body <- list(
    prompt = prompt,
    n = n,
    size = size,
    quality = quality,
    style = style,
    response_format = response_format
  )

  # Get image-specific endpoint and key (with fallback to main credentials)
  base_url <- foundry_get_image_endpoint(required = TRUE)
  api_key <- foundry_get_image_key(key = api_key, required = TRUE)
  api_version <- api_version %||% foundry_get_api_version()

  # Construct URL for image generation
  url <- paste0(
    base_url,
    "/openai/deployments/",
    model,
    "/images/generations"
  )

  # Build request
  req <- httr2::request(url) %>%
    httr2::req_url_query(`api-version` = api_version) %>%
    httr2::req_headers(`api-key` = api_key) %>%
    httr2::req_body_json(body) %>%
    httr2::req_retry(max_tries = 3, backoff = ~ 2) %>%
    httr2::req_error(body = foundry_error_body)

  result <- foundry_perform(req)

  # Parse response into tibble
  foundry_parse_image_response(result, prompt, response_format)
}


#' Parse Image Generation Response
#'
#' Internal function to parse image generation API response into a tibble.
#'
#' @param result List. The parsed JSON response.
#' @param original_prompt Character. The original prompt provided.
#' @param response_format Character. The response format requested.
#'
#' @return A tibble with image response data.
#' @keywords internal
foundry_parse_image_response <- function(result, original_prompt, response_format) {
  # Convert Unix timestamp to POSIXct
  created_time <- as.POSIXct(result$created, origin = "1970-01-01", tz = "UTC")

  # Process each image in the data array
  images <- purrr::map_dfr(result$data, function(img) {
    tibble::tibble(
      prompt = original_prompt,
      revised_prompt = img$revised_prompt %||% NA_character_,
      url = if (response_format == "url") img$url %||% NA_character_ else NA_character_,
      b64_json = if (response_format == "b64_json") img$b64_json %||% NA_character_ else NA_character_,
      created = created_time
    )
  })

  images
}


#' Save Generated Image to File
#'
#' Download and save a generated image from `foundry_image()` to a local file.
#' Works with both URL and base64-encoded image results.
#'
#' @param image_result A tibble returned by `foundry_image()`.
#' @param path Character. The file path where the image should be saved.
#'   Should include the file extension (e.g., ".png").
#' @param index Integer. Which image to save if multiple were generated (1-based).
#'   Default: 1 (first image).
#'
#' @return Invisibly returns the path to the saved file.
#'
#' @details
#' This function handles both URL and base64-encoded images automatically.
#' For URL-based images, it downloads the image from the temporary Azure URL.
#' For base64-encoded images, it decodes the data and writes it to file.
#'
#' **Note**: Image URLs from Azure are temporary and expire after a short time.
#' Use this function to save images locally before the URLs expire.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Generate and save an image
#' result <- foundry_image("A beautiful landscape", model = "dall-e-3")
#' foundry_save_image(result, "landscape.png")
#'
#' # Save a specific image when multiple were generated
#' result <- foundry_image("Colorful abstract art", model = "dall-e-3", n = 3)
#' foundry_save_image(result, "art_1.png", index = 1)
#' foundry_save_image(result, "art_2.png", index = 2)
#' foundry_save_image(result, "art_3.png", index = 3)
#'
#' # Save base64-encoded image
#' result <- foundry_image("A cat", model = "dall-e-3", response_format = "b64_json")
#' foundry_save_image(result, "cat.png")
#' }
foundry_save_image <- function(image_result, path, index = 1) {
  # Validate input
  if (!inherits(image_result, "data.frame")) {
    cli::cli_abort("{.arg image_result} must be a tibble from {.fun foundry_image}.")
  }

  required_cols <- c("url", "b64_json")
  if (!all(required_cols %in% names(image_result))) {
    cli::cli_abort("{.arg image_result} must contain {.field url} and {.field b64_json} columns from {.fun foundry_image}.")
  }

  # Validate index
  index <- as.integer(index)
  if (is.na(index) || index < 1 || index > nrow(image_result)) {
    cli::cli_abort("{.arg index} must be between 1 and {nrow(image_result)} (number of images).")
  }

  # Validate path
  if (missing(path) || is.null(path) || !is.character(path) || length(path) != 1) {
    cli::cli_abort("{.arg path} must be a single file path string.")
  }

  # Get the specified image row
  img <- image_result[index, ]

  # Determine if we have URL or base64 data
  has_url <- !is.na(img$url) && nchar(img$url) > 0
  has_b64 <- !is.na(img$b64_json) && nchar(img$b64_json) > 0

  if (!has_url && !has_b64) {
    cli::cli_abort("No image data found at index {index}. Both URL and b64_json are NA.")
  }

  if (has_b64) {
    # Check if base64enc is available
    if (!requireNamespace("base64enc", quietly = TRUE)) {
      cli::cli_abort(c(
        "Package {.pkg base64enc} is required to save base64-encoded images.",
        "i" = "Install it with: {.code install.packages(\"base64enc\")}"
      ))
    }
    # Decode base64 and write to file
    img_data <- base64enc::base64decode(img$b64_json)
    writeBin(img_data, path)
    cli::cli_alert_success("Image saved to {.file {path}} (from base64)")
  } else {
    # Download from URL
    tryCatch({
      utils::download.file(img$url, path, mode = "wb", quiet = TRUE)
      cli::cli_alert_success("Image saved to {.file {path}} (from URL)")
    }, error = function(e) {
      cli::cli_abort(c(
        "Failed to download image from URL.",
        "i" = "The URL may have expired. Generate a new image and save it promptly.",
        "x" = conditionMessage(e)
      ))
    })
  }

  invisible(path)
}
