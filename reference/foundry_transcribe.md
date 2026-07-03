# Transcribe an audio file with Microsoft Foundry

Transcribe audio through the Speech in Foundry Tools LLM Speech API,
including MAI-Transcribe models, or through the Azure OpenAI v1 preview
audio endpoint.

## Usage

``` r
foundry_transcribe(
  file,
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
  api_version = NULL
)
```

## Arguments

- file:

  Character. Local audio file path.

- model:

  Character. Model or deployment name. Defaults to
  `"mai-transcribe-1.5"` for `service = "speech"` and to
  `AZURE_FOUNDRY_MODEL` for `service = "openai"`.

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

- transcribe_style:

  Character. Optional MAI-Transcribe 1.5 style, such as `"verbatim"`.

- phrase_list:

  Character vector. Optional phrases for MAI-Transcribe 1.5.

- response_format:

  Character. Optional OpenAI response format.

- timestamp_granularities:

  Character vector. Optional OpenAI timestamp granularities, such as
  `"segment"` or `"word"`.

- include:

  Character vector. Optional OpenAI include values.

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

A one-row tibble with transcript text, phrase-level detail, and the raw
response in list-columns.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_transcribe("interview.mp3", model = "mai-transcribe-1.5")
foundry_transcribe("interview.mp3", service = "openai", model = "gpt-4o-transcribe")
foundry_transcribe("speech.wav", service = "openai", model = "whisper", api = "deployment")
} # }
```
