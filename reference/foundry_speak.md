# Generate speech audio from text

**\[experimental\]**

Use a Microsoft Foundry speech deployment to synthesize audio and save
it to a local file. The v1 data-plane path is used by default; set
`api = "deployment"` for a deployment exposed only on the classic
`/openai/deployments/{model}/audio/speech` path.

## Usage

``` r
foundry_speak(
  text,
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
  api_version = NULL
)
```

## Arguments

- text:

  Character. Text to synthesize.

- model:

  Character. Speech model deployment name.

- voice:

  Character. Voice name supported by the deployed model.

- path:

  Character. Output file path. Defaults to a temporary file.

- response_format:

  Character. Audio format such as `"mp3"`, `"wav"`, `"opus"`, `"aac"`,
  `"flac"`, or `"pcm"`.

- instructions:

  Character. Optional style or pronunciation instructions.

- speed:

  Numeric. Optional speech speed.

- overwrite:

  Logical. Whether to overwrite an existing file.

- api:

  Character. `"v1"` uses `/openai/v1/audio/speech`; `"deployment"` uses
  `/openai/deployments/{model}/audio/speech`. Use `"deployment"` when
  your text-to-speech deployment is not exposed on the v1 data-plane
  path.

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

A tibble with the output path, byte count, model, voice, and format.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_speak("Hello from R.", model = "gpt-4o-mini-tts", voice = "alloy")
} # }
```
