# Audio Workflows with Microsoft Foundry

``` r

library(foundryR)
```

Audio is one of the most useful Foundry additions for researchers. You
can transcribe interviews, lectures, field recordings, meetings, and
focus groups, then keep the result in a tibble with segment-level timing
for downstream coding or analysis.

## Configure Speech in Foundry Tools

MAI-Transcribe models are exposed through the LLM Speech API. Configure
the Speech resource once per session. This chunk is illustrative and is
not run when the vignette builds:

``` r

foundry_set_speech_endpoint(Sys.getenv("AZURE_FOUNDRY_SPEECH_ENDPOINT"))
foundry_set_speech_key("your-speech-key")

# For keyless authentication, set a bearer token instead of a key:
foundry_set_token("your-entra-id-access-token")
```

## A real, public-domain sample

The examples below use a short excerpt from John F. Kennedy’s 1961
inaugural address (“And so, my fellow Americans…”). This clip ships with
the package and is the de facto “hello, world” of open-source speech
recognition, so the transcript is easy to check against a recording
everyone knows.

``` r

sample_audio <- system.file("extdata/samples/jfk.wav", package = "foundryR")
basename(sample_audio)
```

## Transcribe an audio file

[`foundry_transcribe()`](https://farach.github.io/foundryR/reference/foundry_transcribe.md)
returns one row per file. The `text` column holds the transcript and the
`phrases` list-column holds segment-level timing.

``` r

transcript <- foundry_transcribe(
  sample_audio,
  model = "mai-transcribe-1.5",
  locales = "en-US"
)

transcript$text
```

The segment timing lives in the `phrases` list-column, one row per
recognized phrase:

``` r

head(transcript$phrases[[1]])
```

## Synthesize speech

[`foundry_speak()`](https://farach.github.io/foundryR/reference/foundry_speak.md)
writes binary audio to disk and returns the file path and byte count.
This is useful for experiment stimuli, accessibility assets, and demos.
Use your text-to-speech deployment name for `model`.

``` r

speech <- foundry_speak(
  "Welcome to the foundryR audio vignette.",
  model = "tts-1",
  voice = "alloy",
  path = tempfile(fileext = ".mp3")
)

speech[, c("bytes", "model", "voice", "format")]
```

## Translate multilingual recordings

Use
[`foundry_translate_audio()`](https://farach.github.io/foundryR/reference/foundry_translate_audio.md)
when you want an analysis corpus in a common language. To keep this
example fully reproducible we first synthesize a short Spanish clip,
then translate it back to English – both are real API calls.

``` r

spanish_clip <- foundry_speak(
  "La reunion de investigacion fue clara y muy util.",
  model = "tts-1",
  voice = "alloy",
  path = tempfile(fileext = ".mp3")
)

translation <- foundry_translate_audio(
  spanish_clip$path,
  target_language = "en"
)

translation$text
```

## Notes for researchers

- Inspect `head(transcript$phrases[[1]])` before processing long
  recordings so you know the segment structure your coding scheme has to
  handle.
- Keep raw audio out of your project repository; store transcripts and
  IDs.
- MAI-Transcribe preview limitations include no diarization for
  MAI-Transcribe models and no prompt tuning for MAI-Transcribe 1.0.
