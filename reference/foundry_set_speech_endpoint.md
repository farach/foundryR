# Set Microsoft Foundry Speech endpoint

Set the endpoint for Speech in Foundry Tools. This endpoint is used by
[`foundry_transcribe()`](https://farach.github.io/foundryR/reference/foundry_transcribe.md)
and
[`foundry_translate_audio()`](https://farach.github.io/foundryR/reference/foundry_translate_audio.md)
when `service = "speech"`.

## Usage

``` r
foundry_set_speech_endpoint(endpoint)
```

## Arguments

- endpoint:

  Character. Speech endpoint URL.

## Value

Invisibly returns the endpoint that was set.

## Examples

``` r
if (FALSE) { # \dontrun{
foundry_set_speech_endpoint("AZURE_FOUNDRY_SPEECH_ENDPOINT")
} # }
```
