# Translate an audio file with Microsoft Foundry

Translate audio through LLM Speech enhanced mode or the
OpenAI-compatible v1 audio translations endpoint. LLM Speech supports
multiple target languages; the OpenAI-compatible translations endpoint
translates to English.

## Usage

``` r
foundry_translate_audio(
  file,
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
  api_version = NULL
)
```

## Arguments

- file:

  Character. Local audio file path.

- target_language:

  Character. Target language code for `service = "speech"`, such as
  `"en"`, `"es"`, `"fr"`, `"de"`, `"ko"`, `"ja"`, `"pt"`, or `"zh"`.

- model:

  Character. Optional model or deployment name. For Speech translation
  this is omitted by default because MAI-Transcribe models do not
  translate. For `service = "openai"`, defaults to
  `AZURE_FOUNDRY_MODEL`.

- service:

  Character. `"speech"` for LLM Speech/MAI-Transcribe or `"openai"` for
  `/openai/v1/audio/transcriptions`.

- api:

  Character. Used when `service = "openai"`. `"v1"` calls the
  `/openai/v1/...` data-plane path; `"deployment"` calls
  `/openai/deployments/{model}/...`. Classic `whisper` deployments
  require `"deployment"`; `gpt-4o-transcribe`-family models use `"v1"`.

- locales:

  Character vector. Optional Speech locale hints such as `"en-US"` or
  `"es-ES"`.

- language:

  Character. Optional OpenAI transcription language hint such as `"en"`
  or `"es"`.

- prompt:

  Character vector. Optional prompt instructions.

- response_format:

  Character. Optional OpenAI response format.

- temperature:

  Numeric. Optional OpenAI sampling temperature.

- api_key:

  Character. Optional API key override.

- token:

  Character. Optional bearer token override.

- endpoint:

  Character. Optional endpoint override.

- api_version:

  Character. Optional API version. Defaults to `"2025-10-15"` for Speech
  and `"preview"` for OpenAI audio.

## Value

A one-row tibble with translated text, phrase-level detail, and the raw
response in list-columns.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_translate_audio("interview-es.mp3", target_language = "en")
} # }
```
