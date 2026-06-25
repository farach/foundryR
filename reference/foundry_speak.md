# Generate speech audio from text

Use the Microsoft Foundry v1 preview speech endpoint to synthesize audio
and save it to a local file.

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
  api_key = NULL,
  token = NULL,
  endpoint = NULL,
  api_version = "preview"
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
foundry_speak("Hello from R.", model = "tts-1", voice = "alloy")
} # }
```
