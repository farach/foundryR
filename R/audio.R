#' Set Microsoft Foundry Speech endpoint
#'
#' Set the endpoint for Speech in Foundry Tools. This endpoint is used by
#' `foundry_transcribe()` and `foundry_translate_audio()` when
#' `service = "speech"`.
#'
#' @param endpoint Character. Speech endpoint URL.
#'
#' @return Invisibly returns the endpoint that was set.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_set_speech_endpoint(Sys.getenv("AZURE_FOUNDRY_SPEECH_ENDPOINT"))
#' }
foundry_set_speech_endpoint <- function(endpoint) {
  foundry_check_character_scalar(endpoint, "endpoint")
  endpoint <- sub("/$", "", endpoint)
  Sys.setenv(AZURE_FOUNDRY_SPEECH_ENDPOINT = endpoint)
  cli::cli_alert_success("Speech endpoint set to {.url {endpoint}}")
  invisible(endpoint)
}


#' Set Microsoft Foundry Speech API key
#'
#' @param key Character. Speech resource API key.
#'
#' @return Invisibly returns `TRUE` if the key was set successfully.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_set_speech_key("your-speech-key")
#' }
foundry_set_speech_key <- function(key) {
  foundry_check_character_scalar(key, "key")
  Sys.setenv(AZURE_FOUNDRY_SPEECH_KEY = key)
  cli::cli_alert_success("Speech API key set successfully.")
  invisible(TRUE)
}


#' Transcribe an audio file with Microsoft Foundry
#'
#' Transcribe audio through the Speech in Foundry Tools LLM Speech API, including
#' MAI-Transcribe models, or through the Azure OpenAI v1 preview audio endpoint.
#'
#' @param file Character. Local audio file path.
#' @param model Character. Model or deployment name. Defaults to
#'   `"mai-transcribe-1.5"` for `service = "speech"` and to
#'   `AZURE_FOUNDRY_MODEL` for `service = "openai"`.
#' @param service Character. `"speech"` for LLM Speech/MAI-Transcribe or
#'   `"openai"` for `/openai/v1/audio/transcriptions`.
#' @param api Character. Used when `service = "openai"`. `"v1"` calls the
#'   `/openai/v1/...` data-plane path; `"deployment"` calls
#'   `/openai/deployments/{model}/...`. Classic `whisper` deployments require
#'   `"deployment"`; `gpt-4o-transcribe`-family models use `"v1"`.
#' @param locales Character vector. Optional Speech locale hints such as
#'   `"en-US"` or `"es-ES"`.
#' @param language Character. Optional OpenAI transcription language hint such as
#'   `"en"` or `"es"`.
#' @param prompt Character vector. Optional prompt instructions.
#' @param transcribe_style Character. Optional MAI-Transcribe 1.5 style, such as
#'   `"verbatim"`.
#' @param phrase_list Character vector. Optional phrases for MAI-Transcribe 1.5.
#' @param response_format Character. Optional OpenAI response format.
#' @param timestamp_granularities Character vector. Optional OpenAI timestamp
#'   granularities, such as `"segment"` or `"word"`.
#' @param include Character vector. Optional OpenAI include values.
#' @param temperature Numeric. Optional OpenAI sampling temperature.
#' @param api_key Character. Optional API key override.
#' @param token Character. Optional bearer token override.
#' @param endpoint Character. Optional endpoint override.
#' @param api_version Character. Optional API version. Defaults to
#'   `"2025-10-15"` for Speech and `"preview"` for OpenAI audio.
#'
#' @return A one-row tibble with transcript text, phrase-level detail, and the
#'   raw response in list-columns.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_transcribe("interview.mp3", model = "mai-transcribe-1.5")
#' foundry_transcribe("interview.mp3", service = "openai", model = "gpt-4o-transcribe")
#' foundry_transcribe("speech.wav", service = "openai", model = "whisper", api = "deployment")
#' }
foundry_transcribe <- function(file,
                               model = NULL,
                               service = c("speech", "openai"),
                               api = c("v1", "deployment"),
                               locales = NULL,
                               language = NULL,
                               prompt = NULL,
                               transcribe_style = NULL,
                               phrase_list = NULL,
                               response_format = NULL,
                               timestamp_granularities = NULL,
                               include = NULL,
                               temperature = NULL,
                               api_key = NULL,
                               token = NULL,
                               endpoint = NULL,
                               api_version = NULL) {
  service <- match.arg(service)
  api <- match.arg(api)
  foundry_check_file(file)

  if (identical(service, "speech")) {
    model <- model %||% "mai-transcribe-1.5"
    return(foundry_speech_transcribe(
      file = file,
      task = "transcribe",
      model = model,
      locales = locales,
      prompt = prompt,
      transcribe_style = transcribe_style,
      phrase_list = phrase_list,
      api_key = api_key,
      token = token,
      endpoint = endpoint,
      api_version = api_version
    ))
  }

  model <- foundry_resolve_model(model)
  foundry_openai_audio(
    file = file,
    path = "audio/transcriptions",
    model = model,
    language = language,
    prompt = prompt,
    response_format = response_format,
    timestamp_granularities = timestamp_granularities,
    include = include,
    temperature = temperature,
    api = api,
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version,
    task = "transcribe"
  )
}


#' Translate an audio file with Microsoft Foundry
#'
#' Translate audio through LLM Speech enhanced mode or the OpenAI-compatible v1
#' audio translations endpoint. LLM Speech supports multiple target languages;
#' the OpenAI-compatible translations endpoint translates to English.
#'
#' @param file Character. Local audio file path.
#' @param target_language Character. Target language code for
#'   `service = "speech"`, such as `"en"`, `"es"`, `"fr"`, `"de"`, `"ko"`,
#'   `"ja"`, `"pt"`, or `"zh"`.
#' @param model Character. Optional model or deployment name. For Speech
#'   translation this is omitted by default because MAI-Transcribe models do not
#'   translate. For `service = "openai"`, defaults to `AZURE_FOUNDRY_MODEL`.
#' @inheritParams foundry_transcribe
#'
#' @return A one-row tibble with translated text, phrase-level detail, and the
#'   raw response in list-columns.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_translate_audio("interview-es.mp3", target_language = "en")
#' }
foundry_translate_audio <- function(file,
                                    target_language = "en",
                                    model = NULL,
                                    service = c("speech", "openai"),
                                    api = c("v1", "deployment"),
                                    locales = NULL,
                                    language = NULL,
                                    prompt = NULL,
                                    response_format = NULL,
                                    temperature = NULL,
                                    api_key = NULL,
                                    token = NULL,
                                    endpoint = NULL,
                                    api_version = NULL) {
  service <- match.arg(service)
  api <- match.arg(api)
  foundry_check_file(file)

  if (identical(service, "speech")) {
    foundry_check_character_scalar(target_language, "target_language")
    return(foundry_speech_transcribe(
      file = file,
      task = "translate",
      model = model,
      locales = locales,
      target_language = target_language,
      prompt = prompt,
      api_key = api_key,
      token = token,
      endpoint = endpoint,
      api_version = api_version
    ))
  }

  model <- foundry_resolve_model(model)
  foundry_openai_audio(
    file = file,
    path = "audio/translations",
    model = model,
    language = language,
    prompt = prompt,
    response_format = response_format,
    temperature = temperature,
    api = api,
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version,
    task = "translate"
  )
}


#' Generate speech audio from text
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Use a Microsoft Foundry speech deployment to synthesize audio and save it to
#' a local file. The v1 data-plane path is used by default; set
#' `api = "deployment"` for a deployment exposed only on the classic
#' `/openai/deployments/{model}/audio/speech` path.
#'
#' @param text Character. Text to synthesize.
#' @param model Character. Speech model deployment name.
#' @param voice Character. Voice name supported by the deployed model.
#' @param path Character. Output file path. Defaults to a temporary file.
#' @param response_format Character. Audio format such as `"mp3"`, `"wav"`,
#'   `"opus"`, `"aac"`, `"flac"`, or `"pcm"`.
#' @param instructions Character. Optional style or pronunciation instructions.
#' @param speed Numeric. Optional speech speed.
#' @param overwrite Logical. Whether to overwrite an existing file.
#' @param api Character. `"v1"` uses `/openai/v1/audio/speech`; `"deployment"`
#'   uses `/openai/deployments/{model}/audio/speech`. Use `"deployment"` when
#'   your text-to-speech deployment is not exposed on the v1 data-plane path.
#' @inheritParams foundry_transcribe
#'
#' @return A tibble with the output path, byte count, model, voice, and format.
#' @export
#'
#' @examples
#' \dontrun{
#' foundry_speak("Hello from R.", model = "gpt-4o-mini-tts", voice = "alloy")
#' }
foundry_speak <- function(text,
                          model = NULL,
                          voice = "alloy",
                          path = NULL,
                          response_format = "mp3",
                          instructions = NULL,
                          speed = NULL,
                          overwrite = FALSE,
                          api = c("v1", "deployment"),
                          api_key = NULL,
                          token = NULL,
                          endpoint = NULL,
                          api_version = NULL) {
  foundry_check_character_scalar(text, "text")
  model <- foundry_resolve_model(model)
  foundry_check_character_scalar(voice, "voice")
  foundry_check_character_scalar(response_format, "response_format")
  api <- match.arg(api)
  if (is.null(path)) {
    path <- tempfile(fileext = paste0(".", response_format))
  }
  foundry_check_character_scalar(path, "path")

  body <- list(
    input = text,
    voice = voice,
    response_format = response_format
  )
  if (!is.null(instructions)) body$instructions <- instructions
  if (!is.null(speed)) body$speed <- speed

  if (identical(api, "deployment")) {
    base_url <- foundry_get_endpoint(endpoint = endpoint, required = TRUE)
    url <- paste0(base_url, "/openai/deployments/", model, "/audio/speech")
    req <- httr2::request(url) |>
      httr2::req_method("POST") |>
      foundry_authenticate_request(api_key = api_key, token = token) |>
      httr2::req_url_query(`api-version` = api_version %||% foundry_get_api_version()) |>
      httr2::req_body_json(body) |>
      httr2::req_retry(max_tries = 3, backoff = ~ 2) |>
      httr2::req_error(body = foundry_error_body)
  } else {
    body$model <- model
    req <- foundry_build_v1_request(
      path = "audio/speech",
      body = body,
      method = "POST",
      api_key = api_key,
      token = token,
      endpoint = endpoint,
      api_version = api_version %||% "preview"
    )
  }

  result <- foundry_write_raw_response(req, path, overwrite = overwrite)
  result$model <- model
  result$voice <- voice
  result$format <- response_format
  result
}


foundry_speech_transcribe <- function(file,
                                      task,
                                      model = NULL,
                                      locales = NULL,
                                      target_language = NULL,
                                      prompt = NULL,
                                      transcribe_style = NULL,
                                      phrase_list = NULL,
                                      api_key = NULL,
                                      token = NULL,
                                      endpoint = NULL,
                                      api_version = NULL) {
  enhanced <- list(enabled = TRUE, task = task)
  if (!is.null(model)) enhanced$model <- model
  if (!is.null(target_language)) enhanced$targetLanguage <- target_language
  if (!is.null(prompt)) enhanced$prompt <- as.list(prompt)
  if (!is.null(transcribe_style)) enhanced$transcribeStyle <- transcribe_style

  definition <- list(enhancedMode = enhanced)
  if (!is.null(locales)) definition$locales <- as.list(locales)
  if (!is.null(phrase_list)) {
    definition$phraseList <- list(phrases = as.list(phrase_list))
  }

  req <- foundry_build_speech_request(
    path = "speechtotext/transcriptions:transcribe",
    method = "POST",
    api_key = api_key,
    token = token,
    endpoint = endpoint,
    api_version = api_version %||% "2025-10-15"
  )

  req <- req |>
    httr2::req_body_multipart(
      audio = curl::form_file(file),
      definition = jsonlite::toJSON(definition, auto_unbox = TRUE)
    )

  result <- foundry_perform(req)
  foundry_parse_audio_result(result, file = file, model = model, task = task)
}


foundry_openai_audio <- function(file,
                                 path,
                                 model,
                                 language = NULL,
                                 prompt = NULL,
                                 response_format = NULL,
                                 timestamp_granularities = NULL,
                                 include = NULL,
                                 temperature = NULL,
                                 api = c("v1", "deployment"),
                                 api_key = NULL,
                                 token = NULL,
                                 endpoint = NULL,
                                 api_version = NULL,
                                 task = "transcribe") {
  api <- match.arg(api)

  if (identical(api, "deployment")) {
    base_url <- foundry_get_endpoint(endpoint = endpoint, required = TRUE)
    url <- paste0(base_url, "/openai/deployments/", model, "/", path)
    req <- httr2::request(url) |>
      httr2::req_method("POST") |>
      foundry_authenticate_request(api_key = api_key, token = token) |>
      httr2::req_url_query(`api-version` = api_version %||% foundry_get_api_version()) |>
      httr2::req_retry(max_tries = 3, backoff = ~ 2) |>
      httr2::req_error(body = foundry_error_body)
  } else {
    req <- foundry_build_v1_request(
      path = path,
      method = "POST",
      api_key = api_key,
      token = token,
      endpoint = endpoint,
      api_version = api_version %||% "preview"
    )
  }

  # The v1 endpoint takes the model in the request body; the deployment endpoint
  # encodes it in the URL and does not accept a body model field.
  multipart <- list(file = curl::form_file(file))
  if (identical(api, "v1")) multipart$model <- model
  if (!is.null(language)) multipart$language <- language
  if (!is.null(prompt)) multipart$prompt <- paste(prompt, collapse = "\n")
  if (!is.null(response_format)) multipart$response_format <- response_format
  if (!is.null(temperature)) multipart$temperature <- as.character(temperature)

  if (!is.null(timestamp_granularities)) {
    multipart <- foundry_multipart_add(
      multipart,
      "timestamp_granularities[]",
      timestamp_granularities
    )
  }
  if (!is.null(include)) {
    multipart <- foundry_multipart_add(multipart, "include[]", include)
  }

  req <- do.call(httr2::req_body_multipart, c(list(req), multipart))
  result <- foundry_perform(req)
  foundry_parse_audio_result(result, file = file, model = model, task = task)
}


foundry_build_speech_request <- function(path,
                                         method = "POST",
                                         api_key = NULL,
                                         token = NULL,
                                         endpoint = NULL,
                                         api_version = "2025-10-15") {
  base_url <- foundry_get_speech_endpoint(endpoint = endpoint, required = TRUE)
  path <- sub("^/+", "", path)
  url <- paste0(base_url, "/", path)

  req <- httr2::request(url) |>
    httr2::req_method(method) |>
    foundry_authenticate_request(
      api_key = api_key,
      token = token,
      key_header = "Ocp-Apim-Subscription-Key",
      key_getter = foundry_get_speech_key,
      token_getter = foundry_get_speech_token
    ) |>
    httr2::req_url_query(`api-version` = api_version) |>
    httr2::req_retry(max_tries = 3, backoff = ~ 2) |>
    httr2::req_error(body = foundry_error_body)

  req
}


foundry_get_speech_endpoint <- function(endpoint = NULL, required = FALSE) {
  if (is.null(endpoint)) {
    endpoint <- Sys.getenv("AZURE_FOUNDRY_SPEECH_ENDPOINT")
    if (endpoint == "") endpoint <- Sys.getenv("AZURE_SPEECH_ENDPOINT")
    if (endpoint == "") endpoint <- NULL
  }
  if (!is.null(endpoint)) endpoint <- sub("/$", "", endpoint)

  if (required && is.null(endpoint)) {
    cli::cli_abort(c(
      "Microsoft Foundry Speech endpoint is required.",
      "i" = "Set one with {.code foundry_set_speech_endpoint()} or the {.envvar AZURE_FOUNDRY_SPEECH_ENDPOINT} environment variable."
    ))
  }
  endpoint
}


foundry_get_speech_key <- function(key = NULL, required = FALSE) {
  if (is.null(key)) {
    key <- Sys.getenv("AZURE_FOUNDRY_SPEECH_KEY")
    if (key == "") key <- Sys.getenv("AZURE_SPEECH_API_KEY")
    if (key == "") key <- NULL
  }
  if (required && is.null(key)) {
    cli::cli_abort(c(
      "Microsoft Foundry Speech API key is required.",
      "i" = "Set one with {.code foundry_set_speech_key()} or the {.envvar AZURE_FOUNDRY_SPEECH_KEY} environment variable."
    ))
  }
  key
}


foundry_get_speech_token <- function(token = NULL, required = FALSE) {
  if (is.null(token)) {
    token <- Sys.getenv("AZURE_FOUNDRY_SPEECH_TOKEN")
    if (token == "") token <- Sys.getenv("AZURE_SPEECH_TOKEN")
    if (token == "") token <- Sys.getenv("AZURE_FOUNDRY_TOKEN")
    if (token == "") token <- NULL
  }
  if (!is.null(token)) token <- sub("^Bearer\\s+", "", token, ignore.case = TRUE)
  if (required && is.null(token)) {
    cli::cli_abort("Microsoft Foundry Speech bearer token is required.")
  }
  token
}


foundry_parse_audio_result <- function(result, file, model, task) {
  text <- foundry_audio_text(result)
  tibble::tibble(
    file = normalizePath(file, winslash = "/", mustWork = FALSE),
    task = task,
    model = model %||% NA_character_,
    text = text,
    duration_ms = as.integer(result$durationMilliseconds %||% NA_integer_),
    language = result$language %||% result$locale %||% NA_character_,
    phrases = list(foundry_audio_phrases(result)),
    raw_response = list(result)
  )
}


foundry_audio_text <- function(result) {
  combined <- result$combinedPhrases %||% list()
  text <- vapply(combined, function(x) x$text %||% NA_character_, character(1))
  text <- text[!is.na(text)]
  if (length(text) > 0L) return(paste(text, collapse = "\n"))
  result$text %||% NA_character_
}


foundry_audio_phrases <- function(result) {
  phrases <- result$phrases %||% result$segments %||% list()
  if (length(phrases) == 0L) {
    return(tibble::tibble(
      text = character(),
      locale = character(),
      offset_ms = integer(),
      duration_ms = integer(),
      confidence = numeric(),
      speaker = character(),
      words = list()
    ))
  }

  purrr::map_dfr(phrases, function(phrase) {
    # LLM Speech / MAI-Transcribe reports millisecond offsets directly; OpenAI
    # whisper verbose_json reports start/end in seconds. Normalize both to ms.
    if (!is.null(phrase$offsetMilliseconds)) {
      offset_ms <- as.integer(phrase$offsetMilliseconds)
      duration_ms <- as.integer(phrase$durationMilliseconds %||% NA_integer_)
    } else if (!is.null(phrase$start)) {
      offset_ms <- as.integer(round(phrase$start * 1000))
      duration_ms <- if (!is.null(phrase$end)) {
        as.integer(round((phrase$end - phrase$start) * 1000))
      } else {
        NA_integer_
      }
    } else {
      offset_ms <- NA_integer_
      duration_ms <- NA_integer_
    }

    tibble::tibble(
      text = phrase$text %||% NA_character_,
      locale = phrase$locale %||% NA_character_,
      offset_ms = offset_ms,
      duration_ms = duration_ms,
      confidence = as.numeric(phrase$confidence %||% NA_real_),
      speaker = phrase$speaker %||% NA_character_,
      words = list(phrase$words %||% list())
    )
  })
}


foundry_check_file <- function(file) {
  foundry_check_character_scalar(file, "file")
  if (!file.exists(file)) {
    cli::cli_abort("File does not exist: {.file {file}}.")
  }
  invisible(file)
}
