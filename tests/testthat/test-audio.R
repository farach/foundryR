test_that("foundry speech configuration helpers set values", {
  withr::local_envvar(
    AZURE_FOUNDRY_SPEECH_ENDPOINT = "",
    AZURE_FOUNDRY_SPEECH_KEY = ""
  )

  suppressMessages(foundry_set_speech_endpoint("https://speech.example.com/"))
  suppressMessages(foundry_set_speech_key("speech-key"))

  expect_equal(Sys.getenv("AZURE_FOUNDRY_SPEECH_ENDPOINT"), "https://speech.example.com")
  expect_equal(Sys.getenv("AZURE_FOUNDRY_SPEECH_KEY"), "speech-key")
})

test_that("foundry_transcribe builds LLM Speech multipart request", {
  setup_mock_env()
  withr::local_envvar(
    AZURE_FOUNDRY_SPEECH_ENDPOINT = "https://speech.example.com",
    AZURE_FOUNDRY_SPEECH_KEY = "speech-key",
    AZURE_FOUNDRY_SPEECH_TOKEN = ""
  )
  audio <- tempfile(fileext = ".wav")
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

  result <- foundry_transcribe(audio, locales = "en-US", phrase_list = "foundryR")

  expect_match(captured$url, "/speechtotext/transcriptions:transcribe")
  expect_equal(captured$method, "POST")
  expect_equal(result$text, "Hello world.")
  expect_equal(nrow(result$phrases[[1]]), 1L)
})

test_that("foundry_translate_audio uses speech translate task", {
  setup_mock_env()
  withr::local_envvar(
    AZURE_FOUNDRY_SPEECH_ENDPOINT = "https://speech.example.com",
    AZURE_FOUNDRY_SPEECH_KEY = "speech-key",
    AZURE_FOUNDRY_SPEECH_TOKEN = ""
  )
  audio <- tempfile(fileext = ".mp3")
  writeBin(charToRaw("fake audio"), audio)
  mock_request(list(combinedPhrases = list(list(text = "Translated text."))))

  result <- foundry_translate_audio(audio, target_language = "en")

  expect_equal(result$task, "translate")
  expect_equal(result$text, "Translated text.")
})

test_that("foundry_transcribe can use OpenAI audio preview endpoint", {
  setup_mock_env()
  audio <- tempfile(fileext = ".wav")
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
  expect_equal(sum(names(captured$body$data) == "timestamp_granularities[]"), 2L)
  expect_equal(sum(names(captured$body$data) == "include[]"), 1L)
  expect_equal(captured$body$data$temperature, "0")
  expect_equal(result$text, "OpenAI-compatible transcript.")
})

test_that("foundry_speak writes binary audio", {
  setup_mock_env()
  path <- tempfile(fileext = ".mp3")
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
