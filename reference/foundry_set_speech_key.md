# Set Microsoft Foundry Speech API key

Set Microsoft Foundry Speech API key

## Usage

``` r
foundry_set_speech_key(key)
```

## Arguments

- key:

  Character. Speech resource API key.

## Value

Invisibly returns `TRUE` if the key was set successfully.

## Examples

``` r
local({
  old <- Sys.getenv("AZURE_FOUNDRY_SPEECH_KEY", unset = NA_character_)
  on.exit({
    if (is.na(old)) {
      Sys.unsetenv("AZURE_FOUNDRY_SPEECH_KEY")
    } else {
      Sys.setenv(AZURE_FOUNDRY_SPEECH_KEY = old)
    }
  })
  foundry_set_speech_key("example-speech-key-not-a-secret")
})
#> ✔ Speech API key set successfully.
```
