# Translate an audio file with Microsoft Foundry

Translate audio through Speech enhanced LLM Speech mode or the
OpenAI-compatible v1 audio translations endpoint. Speech translation
requires enhanced mode and a region where LLM Speech is available. The
OpenAI-compatible translations endpoint translates to English.

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

  Character. Optional Speech enhanced-mode model, or required Azure
  OpenAI audio deployment name when `service = "openai"`. For Speech
  translation this is omitted by default because MAI-Transcribe models
  do not translate.

- service:

  Character. `"speech"` for standard Speech fast transcription or
  enhanced LLM Speech/MAI-Transcribe; `"openai"` for
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

## Details

Speech translation uses LLM Speech enhanced mode because standard Speech
fast transcription and MAI-Transcribe do not translate. For Azure OpenAI
audio, pass the deployment name explicitly in `model`. Azure `whisper`
version `001` retires on 2026-12-15. The `gpt-4o-mini-transcribe`
version `2025-12-15` is generally available until 2027-06-15.

In live testing, an Azure `whisper` version `001` deployment returned
Spanish speech as Spanish text through the translations route in two of
three attempts, so check the language of the output before you rely on
it. Transcribing in the source language with
[`foundry_transcribe()`](https://farach.github.io/foundryR/reference/foundry_transcribe.md)
and translating the text with
[`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
is an alternative.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a configured Azure Speech endpoint in an LLM Speech region,
# credentials, and your own local audio input file.
foundry_translate_audio("interview-es.mp3", target_language = "en")
foundry_translate_audio(
  "interview-es.mp3", service = "openai", model = "whisper", api = "deployment"
)
} # }
```
