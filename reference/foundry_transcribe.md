# Transcribe an audio file with Microsoft Foundry

Transcribe audio through standard Speech fast transcription, the Speech
in Foundry Tools enhanced LLM Speech/MAI-Transcribe API, or the Azure
OpenAI v1 preview audio endpoint.

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
  api_version = NULL,
  enhanced = NULL
)
```

## Arguments

- file:

  Character. Local audio file path.

- model:

  Character. Optional Speech enhanced-mode model, or required Azure
  OpenAI audio deployment name when `service = "openai"`. Leave `NULL`
  with `service = "speech"` to use standard fast transcription; the
  returned `model` column is `NA` for this path.

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

- enhanced:

  Logical or `NULL`. For `service = "speech"`, `NULL` uses standard fast
  transcription unless a model, prompt, or `transcribe_style` requires
  enhanced mode. `TRUE` forces LLM Speech enhanced mode. `FALSE` forbids
  enhanced mode and errors if enhanced-only options are supplied.

## Value

A one-row tibble with transcript text, phrase-level detail, the model
that ran (`NA` for standard Speech fast transcription), and the raw
response in list-columns.

## Details

Standard Speech fast transcription is the default for
`service = "speech"`; it works in regular Speech regions and does not
require a model deployment. Enhanced LLM Speech and MAI-Transcribe modes
are opt-in, preview or region-limited, and are used when
`enhanced = TRUE`, `model` is supplied, or enhanced-only options such as
`prompt` or `transcribe_style` are supplied.

For Azure OpenAI audio, pass the deployment name explicitly in `model`.
Azure `whisper` version `001` retires on 2026-12-15. The
`gpt-4o-mini-transcribe` version `2025-12-15` is generally available
until 2027-06-15.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires configured Azure Speech/OpenAI endpoints and credentials
# and your own local audio input files.
foundry_transcribe("interview.mp3")
foundry_transcribe("interview.mp3", model = "mai-transcribe-2")
foundry_transcribe("interview.mp3", enhanced = TRUE, prompt = "Use names exactly.")
foundry_transcribe(
  "interview.mp3", service = "openai", model = "gpt-4o-transcribe"
)
foundry_transcribe(
  "speech.wav", service = "openai", model = "whisper", api = "deployment"
)
} # }
```
