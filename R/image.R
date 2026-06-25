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
#' foundry_set_image_endpoint("AZURE_FOUNDRY_IMAGE_ENDPOINT")
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
#'   Modern v1 image models support `"auto"`, `"1024x1024"`, `"1536x1024"`,
#'   and `"1024x1536"`. DALL-E deployments also support older sizes such as
#'   `"1792x1024"`, `"1024x1792"`, `"512x512"`, and `"256x256"`.
#' @param quality Character. The quality of the image. Modern v1 models support
#'   `"auto"`, `"low"`, `"medium"`, and `"high"`. DALL-E 3 supports
#'   `"standard"` and `"hd"`.
#' @param style Character. Optional DALL-E 3 style, `"vivid"` or `"natural"`.
#' @param response_format Character. Optional DALL-E response format, `"url"`
#'   or `"b64_json"`. This is not supported by `gpt-image-1`-series models,
#'   which return base64 image data.
#' @param output_format Character. Optional v1 image output format, `"png"`,
#'   `"jpeg"`, or `"webp"`.
#' @param output_compression Integer. Optional v1 compression level from 0 to
#'   100 for `"jpeg"` or `"webp"` output.
#' @param background Character. Optional v1 background mode: `"transparent"`,
#'   `"opaque"`, or `"auto"`.
#' @param moderation Character. Optional v1 moderation level: `"low"` or
#'   `"auto"`.
#' @param api Character. API shape to use. `"v1"` uses
#'   `/openai/v1/images/generations`; `"deployment"` uses the legacy
#'   `/openai/deployments/{deployment}/images/generations` endpoint.
#' @param api_key Character. Optional API key override.
#' @param token Character. Optional bearer token override.
#' @param api_version Character. Optional API version override.
#'
#' @return A tibble with columns:
#'   \describe{
#'     \item{prompt}{Character. The original prompt provided.}
#'     \item{revised_prompt}{Character. DALL-E's interpretation/revision of the prompt (DALL-E 3 only).}
#'     \item{url}{Character. URL to the generated image (NA if response_format is "b64_json").}
#'     \item{b64_json}{Character. Base64-encoded image data (NA if response_format is "url").}
#'     \item{output_format}{Character. Requested or returned output format.}
#'     \item{created}{POSIXct. Timestamp when the image was created.}
#'     \item{raw_image}{List. Raw image object returned by the service.}
#'   }
#'
#' @details
#' **Model Requirements**: The `model` parameter must be an image-capable
#' deployment such as a DALL-E or `gpt-image-1`-series deployment. Chat models
#' cannot generate images.
#'
#' **Size Availability**:
#' - gpt-image-1 series: auto, 1024x1024, 1536x1024, 1024x1536
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
                          size = "1024x1024",
                          quality = NULL,
                          style = NULL,
                          response_format = NULL,
                          output_format = NULL,
                          output_compression = NULL,
                          background = NULL,
                          moderation = NULL,
                          api = c("v1", "deployment"),
                          api_key = NULL,
                          token = NULL,
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

  api <- match.arg(api)
  foundry_validate_image_options(
    size = size,
    quality = quality,
    style = style,
    response_format = response_format,
    output_format = output_format,
    background = background,
    moderation = moderation
  )

  # Build request body
  body <- list(
    model = model,
    prompt = prompt,
    n = n,
    size = size
  )
  if (!is.null(quality)) body$quality <- quality
  if (!is.null(style)) body$style <- style
  if (!is.null(response_format)) body$response_format <- response_format
  if (!is.null(output_format)) body$output_format <- output_format
  if (!is.null(output_compression)) {
    output_compression <- as.integer(output_compression)
    if (is.na(output_compression) || output_compression < 0L ||
        output_compression > 100L) {
      cli::cli_abort("{.arg output_compression} must be between 0 and 100.")
    }
    body$output_compression <- output_compression
  }
  if (!is.null(background)) body$background <- background
  if (!is.null(moderation)) body$moderation <- moderation

  # Get image-specific endpoint and use image credentials without overriding
  # shared token/key precedence.
  base_url <- foundry_get_image_endpoint(required = TRUE)

  if (identical(api, "v1")) {
    req <- foundry_build_v1_request(
      path = "images/generations",
      body = body,
      method = "POST",
      api_key = api_key,
      token = token,
      endpoint = base_url,
      api_version = api_version %||% "preview",
      key_getter = foundry_get_image_key
    )
  } else {
    body$model <- NULL
    api_version <- api_version %||% foundry_get_api_version()
    url <- paste0(
      base_url,
      "/openai/deployments/",
      model,
      "/images/generations"
    )

    req <- httr2::request(url) %>%
      httr2::req_url_query(`api-version` = api_version) %>%
      foundry_authenticate_request(
        api_key = api_key,
        token = token,
        key_getter = foundry_get_image_key
      ) %>%
      httr2::req_body_json(body) %>%
      httr2::req_retry(max_tries = 3, backoff = ~ 2) %>%
      httr2::req_error(body = foundry_error_body)
  }

  result <- foundry_perform(req)

  # Parse response into tibble
  foundry_parse_image_response(result, prompt, response_format, output_format)
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
foundry_parse_image_response <- function(result,
                                         original_prompt,
                                         response_format = NULL,
                                         output_format = NULL) {
  # Convert Unix timestamp to POSIXct
  created_time <- as.POSIXct(result$created, origin = "1970-01-01", tz = "UTC")

  # Process each image in the data array
  images <- purrr::map_dfr(result$data, function(img) {
    tibble::tibble(
      prompt = original_prompt,
      revised_prompt = img$revised_prompt %||% NA_character_,
      url = img$url %||% NA_character_,
      b64_json = img$b64_json %||% NA_character_,
      output_format = output_format %||% img$output_format %||% NA_character_,
      created = created_time,
      raw_image = list(img)
    )
  })

  images
}


#' Edit an image with Microsoft Foundry
#'
#' Use the v1 preview image edits endpoint to edit one or more input images with
#' a text prompt.
#'
#' @param image Character vector of local image paths.
#' @param prompt Character. Edit instruction.
#' @param model Character. Image model deployment name.
#' @param mask Character. Optional local mask image path.
#' @param n Integer. Number of images to generate.
#' @param size Character. Output image size.
#' @param quality Character. Optional quality value.
#' @param output_format Character. Optional output format, such as `"png"`,
#'   `"jpeg"`, or `"webp"`.
#' @param background Character. Optional background mode.
#' @param api_key Character. Optional API key override.
#' @param token Character. Optional bearer token override.
#' @param api_version Character. Optional API version. Defaults to `"preview"`.
#'
#' @return A tibble with edited image data and metadata.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_image_edit("input.png", "Make the sky more dramatic", model = "gpt-image-1")
#' }
foundry_image_edit <- function(image,
                               prompt,
                               model = NULL,
                               mask = NULL,
                               n = 1L,
                               size = "1024x1024",
                               quality = NULL,
                               output_format = NULL,
                               background = NULL,
                               api_key = NULL,
                               token = NULL,
                               api_version = "preview") {
  if (!is.character(image) || length(image) < 1L || anyNA(image)) {
    cli::cli_abort("{.arg image} must be one or more local image paths.")
  }
  missing_images <- image[!file.exists(image)]
  if (length(missing_images) > 0L) {
    cli::cli_abort("Image file does not exist: {.file {missing_images[[1]]}}.")
  }
  foundry_check_character_scalar(prompt, "prompt")
  model <- foundry_resolve_image_model(model)
  n <- as.integer(n)
  if (is.na(n) || n < 1L || n > 10L) {
    cli::cli_abort("{.arg n} must be an integer between 1 and 10.")
  }
  if (!is.null(mask) && !file.exists(mask)) {
    cli::cli_abort("Mask file does not exist: {.file {mask}}.")
  }

  base_url <- foundry_get_image_endpoint(required = TRUE)
  req <- foundry_build_v1_request(
    path = "images/edits",
    method = "POST",
    api_key = api_key,
    token = token,
    endpoint = base_url,
    api_version = api_version,
    key_getter = foundry_get_image_key
  )

  multipart <- list(
    prompt = prompt,
    model = model,
    n = as.character(n),
    size = size
  )
  if (length(image) == 1L) {
    multipart$image <- curl::form_file(image)
  } else {
    image_parts <- lapply(image, curl::form_file)
    names(image_parts) <- rep("image[]", length(image_parts))
    multipart <- c(multipart, image_parts)
  }
  if (!is.null(mask)) multipart$mask <- curl::form_file(mask)
  if (!is.null(quality)) multipart$quality <- quality
  if (!is.null(output_format)) multipart$output_format <- output_format
  if (!is.null(background)) multipart$background <- background

  req <- do.call(httr2::req_body_multipart, c(list(req), multipart))
  result <- foundry_perform(req)
  foundry_parse_image_response(result, prompt, NULL, output_format)
}


foundry_validate_image_options <- function(size,
                                           quality,
                                           style,
                                           response_format,
                                           output_format,
                                           background,
                                           moderation) {
  foundry_match_choice(size, c(
    "auto", "1024x1024", "1536x1024", "1024x1536", "256x256",
    "512x512", "1792x1024", "1024x1792"
  ), "size")
  if (!is.null(quality)) {
    foundry_match_choice(quality, c(
      "auto", "standard", "hd", "low", "medium", "high"
    ), "quality")
  }
  if (!is.null(style)) foundry_match_choice(style, c("vivid", "natural"), "style")
  if (!is.null(response_format)) {
    foundry_match_choice(response_format, c("url", "b64_json"), "response_format")
  }
  if (!is.null(output_format)) {
    foundry_match_choice(output_format, c("png", "jpeg", "webp"), "output_format")
  }
  if (!is.null(background)) {
    foundry_match_choice(background, c("transparent", "opaque", "auto"), "background")
  }
  if (!is.null(moderation)) {
    foundry_match_choice(moderation, c("low", "auto"), "moderation")
  }
  invisible(TRUE)
}


foundry_match_choice <- function(value, choices, arg) {
  if (!is.character(value) || length(value) != 1L || is.na(value) ||
      !value %in% choices) {
    cli::cli_abort("{.arg {arg}} must be one of {.val {choices}}.")
  }
  invisible(value)
}


foundry_resolve_image_model <- function(model) {
  if (is.null(model)) {
    model <- Sys.getenv("AZURE_FOUNDRY_IMAGE_MODEL")
    if (model == "") {
      cli::cli_abort(c(
        "Image model/deployment name is required.",
        "i" = "Specify {.arg model} or set the {.envvar AZURE_FOUNDRY_IMAGE_MODEL} environment variable."
      ))
    }
  }
  foundry_check_character_scalar(model, "model")
  model
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
