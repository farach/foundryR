test_that("foundry speech configuration helpers set values", {
  withr::local_envvar(
    AZURE_FOUNDRY_SPEECH_ENDPOINT = "",
    AZURE_FOUNDRY_SPEECH_KEY = ""
  )

  suppressMessages(foundry_set_speech_endpoint("https://speech.example.com/"))
  suppressMessages(foundry_set_speech_key("speech-key"))

  expect_equal(
    Sys.getenv("AZURE_FOUNDRY_SPEECH_ENDPOINT"),
    "https://speech.example.com"
  )
  expect_equal(Sys.getenv("AZURE_FOUNDRY_SPEECH_KEY"), "speech-key")
})

audio_definition <- function(req) {
  jsonlite::fromJSON(req$body$data$definition, simplifyVector = FALSE)
}

test_that("foundry_transcribe defaults to Speech fast transcription", {
  setup_mock_env()
  withr::local_envvar(
    AZURE_FOUNDRY_SPEECH_ENDPOINT = "https://speech.example.com",
    AZURE_FOUNDRY_SPEECH_KEY = "speech-key",
    AZURE_FOUNDRY_SPEECH_TOKEN = ""
  )
  audio <- withr::local_tempfile(fileext = ".wav")
  writeBin(charToRaw("fake audio"), audio)
  captured <- NULL
  mock_resp <- mock_httr2_response(list(
    durationMilliseconds = 1200,
    combinedPhrases = list(list(text = "Hello world.")),
    phrases = list(
      list(
        offsetMilliseconds = 0,
        durationMilliseconds = 1200,
        text = "Hello world.",
        locale = "en-us",
        confidence = 0
      )
    )
  ))

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      mock_resp
    },
    .package = "httr2"
  )

  result <- foundry_transcribe(audio)

  expect_match(captured$url, "/speechtotext/transcriptions:transcribe")
  expect_equal(captured$method, "POST")
  expect_valid_multipart_request(captured)
  definition <- audio_definition(captured)
  expect_null(definition$enhancedMode)
  expect_length(definition, 0L)
  expect_true(is.na(result$model))
  expect_equal(result$text, "Hello world.")
  expect_equal(nrow(result$phrases[[1]]), 1L)
})

test_that("foundry_transcribe sends MAI model in enhanced mode", {
  setup_mock_env()
  withr::local_envvar(
    AZURE_FOUNDRY_SPEECH_ENDPOINT = "https://speech.example.com",
    AZURE_FOUNDRY_SPEECH_KEY = "speech-key",
    AZURE_FOUNDRY_SPEECH_TOKEN = ""
  )
  audio <- withr::local_tempfile(fileext = ".wav")
  writeBin(charToRaw("fake audio"), audio)
  captured <- NULL
  mock_resp <- mock_httr2_response(list(
    combinedPhrases = list(list(text = "Hello world."))
  ))

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      mock_resp
    },
    .package = "httr2"
  )

  result <- foundry_transcribe(audio, model = "mai-transcribe-2")

  definition <- audio_definition(captured)
  expect_true(definition$enhancedMode$enabled)
  expect_equal(definition$enhancedMode$task, "transcribe")
  expect_equal(definition$enhancedMode$model, "mai-transcribe-2")
  expect_equal(result$model, "mai-transcribe-2")
})

test_that("foundry_transcribe can force enhanced mode without a model", {
  setup_mock_env()
  withr::local_envvar(
    AZURE_FOUNDRY_SPEECH_ENDPOINT = "https://speech.example.com",
    AZURE_FOUNDRY_SPEECH_KEY = "speech-key",
    AZURE_FOUNDRY_SPEECH_TOKEN = ""
  )
  audio <- withr::local_tempfile(fileext = ".wav")
  writeBin(charToRaw("fake audio"), audio)
  captured <- NULL
  mock_resp <- mock_httr2_response(list(
    combinedPhrases = list(list(text = "Hello world."))
  ))

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      mock_resp
    },
    .package = "httr2"
  )

  foundry_transcribe(audio, enhanced = TRUE)

  definition <- audio_definition(captured)
  expect_true(definition$enhancedMode$enabled)
  expect_equal(definition$enhancedMode$task, "transcribe")
  expect_null(definition$enhancedMode$model)
})

test_that("foundry_transcribe rejects enhanced false with enhanced-only options", {
  setup_mock_env()
  audio <- withr::local_tempfile(fileext = ".wav")
  writeBin(charToRaw("fake audio"), audio)

  expect_error(
    foundry_transcribe(audio, model = "mai-transcribe-2", enhanced = FALSE),
    "enhanced-mode options"
  )
})

test_that("foundry_transcribe places prompt and transcribe style for Speech", {
  setup_mock_env()
  withr::local_envvar(
    AZURE_FOUNDRY_SPEECH_ENDPOINT = "https://speech.example.com",
    AZURE_FOUNDRY_SPEECH_KEY = "speech-key",
    AZURE_FOUNDRY_SPEECH_TOKEN = ""
  )
  audio <- withr::local_tempfile(fileext = ".wav")
  writeBin(charToRaw("fake audio"), audio)
  captured <- NULL
  mock_resp <- mock_httr2_response(list(
    combinedPhrases = list(list(text = "Hello world."))
  ))

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      mock_resp
    },
    .package = "httr2"
  )

  foundry_transcribe(
    audio,
    model = "mai-transcribe-2",
    prompt = "Use lexical format.",
    transcribe_style = "clean"
  )

  definition <- audio_definition(captured)
  expect_equal(definition$enhancedMode$prompt, list("Use lexical format."))
  expect_null(definition$enhancedMode$transcribeStyle)
  expect_equal(definition$enhancedMode$modelOptions$transcribeStyle, "clean")
})

test_that("foundry_translate_audio uses speech translate task", {
  setup_mock_env()
  withr::local_envvar(
    AZURE_FOUNDRY_SPEECH_ENDPOINT = "https://speech.example.com",
    AZURE_FOUNDRY_SPEECH_KEY = "speech-key",
    AZURE_FOUNDRY_SPEECH_TOKEN = ""
  )
  audio <- withr::local_tempfile(fileext = ".mp3")
  writeBin(charToRaw("fake audio"), audio)
  captured <- NULL
  mock_resp <- mock_httr2_response(list(
    combinedPhrases = list(list(text = "Translated text."))
  ))

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      mock_resp
    },
    .package = "httr2"
  )

  result <- foundry_translate_audio(audio, target_language = "en")

  definition <- audio_definition(captured)
  expect_true(definition$enhancedMode$enabled)
  expect_equal(definition$enhancedMode$task, "translate")
  expect_equal(definition$enhancedMode$targetLanguage, "en")
  expect_null(definition$enhancedMode$model)
  expect_equal(result$task, "translate")
  expect_equal(result$text, "Translated text.")
})

test_that("foundry_transcribe can use OpenAI audio preview endpoint", {
  setup_mock_env()
  audio <- withr::local_tempfile(fileext = ".wav")
  writeBin(charToRaw("fake audio"), audio)
  captured <- NULL
  mock_resp <- mock_httr2_response(list(
    text = "OpenAI-compatible transcript.",
    segments = list(list(text = "OpenAI-compatible transcript.", start = 0))
  ))

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      captured <<- req
      mock_resp
    },
    .package = "httr2"
  )

  result <- foundry_transcribe(
    audio,
    service = "openai",
    model = "gpt-4o-transcribe",
    response_format = "verbose_json",
    timestamp_granularities = c("word", "segment"),
    include = "logprobs",
    temperature = 0
  )

  expect_match(captured$url, "/openai/v1/audio/transcriptions")
  expect_match(captured$url, "api-version=preview")
  expect_valid_multipart_request(captured)
  expect_equal(
    sum(names(captured$body$data) == "timestamp_granularities[]"),
    2L
  )
  expect_equal(sum(names(captured$body$data) == "include[]"), 1L)
  expect_equal(captured$body$data$temperature, "0")
  expect_equal(result$text, "OpenAI-compatible transcript.")
})

test_that("foundry_parse_audio_result uses OpenAI verbose_json duration seconds", {
  setup_mock_env()
  audio <- withr::local_tempfile(fileext = ".wav")
  writeBin(charToRaw("fake audio"), audio)
  mock_request(list(
    text = "OpenAI-compatible transcript.",
    duration = 11
  ))

  result <- foundry_transcribe(
    audio,
    service = "openai",
    model = "gpt-4o-transcribe",
    response_format = "verbose_json"
  )

  expect_equal(result$duration_ms, 11000L)
})

test_that("Speech enhanced mode region errors are actionable", {
  setup_mock_env()
  withr::local_envvar(
    AZURE_FOUNDRY_SPEECH_ENDPOINT = "https://speech.example.com",
    AZURE_FOUNDRY_SPEECH_KEY = "speech-key",
    AZURE_FOUNDRY_SPEECH_TOKEN = ""
  )
  audio <- withr::local_tempfile(fileext = ".wav")
  writeBin(charToRaw("fake audio"), audio)
  mock_resp <- mock_httr2_response(
    list(error = list(message = "Enhanced mode with model is currently not supported yet.")),
    status_code = 400L
  )

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) mock_resp,
    .package = "httr2"
  )

  expect_error(
    foundry_transcribe(audio, model = "mai-transcribe-2"),
    regexp = "not available for this Speech resource's region.*Enhanced mode with model",
    class = "rlang_error"
  )
})

test_that("OpenAI audio routes require explicit models", {
  setup_mock_env()
  audio <- withr::local_tempfile(fileext = ".wav")
  writeBin(charToRaw("fake audio"), audio)
  out <- withr::local_tempfile(fileext = ".mp3")

  expect_error(
    foundry_transcribe(audio, service = "openai"),
    "explicit model/deployment"
  )
  expect_error(
    foundry_translate_audio(audio, service = "openai"),
    "explicit model/deployment"
  )
  expect_error(
    foundry_speak("Hello", path = out),
    "explicit model/deployment"
  )
})

test_that("foundry_speak writes binary audio", {
  setup_mock_env()
  path <- withr::local_tempfile(fileext = ".mp3")
  mock_resp <- mock_httr2_raw_response(charToRaw("audio bytes"))

  testthat::local_mocked_bindings(
    req_perform = function(req, ...) mock_resp,
    .package = "httr2"
  )

  result <- foundry_speak(
    "Hello",
    model = "tts-1",
    voice = "alloy",
    path = path
  )

  expect_equal(result$bytes, length(charToRaw("audio bytes")))
  expect_equal(result$model, "tts-1")
  expect_true(file.exists(path))
})
