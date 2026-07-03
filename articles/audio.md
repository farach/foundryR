# Audio Workflows with Microsoft Foundry

``` r

library(foundryR)
```

Audio is one of the most useful Foundry additions for researchers. You
can transcribe interviews, lectures, field recordings, meetings, and
focus groups, then keep the result in a tibble with segment-level timing
for downstream coding or analysis.

## Two ways to reach speech models

foundryR can use audio models in two places:

- **Azure OpenAI deployments on your main resource** – `whisper` for
  transcription and translation, and a text-to-speech model such as
  `gpt-4o-mini-tts` for synthesis. These reuse your main endpoint and
  key and are what the examples below use. Classic `whisper` is exposed
  only on the deployment path, so pass `api = "deployment"`.
- **A dedicated Speech (LLM Speech) resource** for MAI-Transcribe
  models. This chunk is illustrative and is not run:

``` r

# Only needed for MAI-Transcribe on a dedicated Speech resource:
foundry_set_speech_endpoint(Sys.getenv("AZURE_FOUNDRY_SPEECH_ENDPOINT"))
foundry_set_speech_key("your-speech-key")
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
#> [1] "jfk.wav"
```

## Transcribe an audio file

[`foundry_transcribe()`](https://farach.github.io/foundryR/reference/foundry_transcribe.md)
returns one row per file. The `text` column holds the transcript and the
`phrases` list-column holds segment-level timing. We use the `whisper`
deployment on the main resource; because classic whisper lives on the
deployment path we pass `api = "deployment"`, and
`response_format = "verbose_json"` asks the service for per-segment
timing.

``` r

transcript <- foundry_transcribe(
  sample_audio,
  service = "openai",
  model = "whisper",
  api = "deployment",
  response_format = "verbose_json"
)

transcript$text
#> [1] "And so my fellow Americans, ask not what your country can do for you, ask what you can do for your country."
```

The segment timing lives in the `phrases` list-column, one row per
recognized segment. A short clip like this one is a single segment;
longer recordings return many:

``` r

head(transcript$phrases[[1]])
#> # A tibble: 1 × 7
#>   text                    locale offset_ms duration_ms confidence speaker words 
#>   <chr>                   <chr>      <int>       <int>      <dbl> <chr>   <list>
#> 1 " And so my fellow Ame… NA             0       11000         NA NA      <list>
```

## Synthesize speech

[`foundry_speak()`](https://farach.github.io/foundryR/reference/foundry_speak.md)
writes binary audio to disk and returns the file path and byte count –
handy for experiment stimuli, accessibility assets, and demos. Use your
text-to-speech deployment name for `model`.

``` r

speech <- foundry_speak(
  "Hello, world.",
  model = "gpt-4o-mini-tts",
  voice = "alloy",
  path = tempfile(fileext = ".mp3")
)

speech[, c("bytes", "model", "voice", "format")]
#> # A tibble: 1 × 4
#>   bytes model           voice format
#>   <int> <chr>           <chr> <chr> 
#> 1 25728 gpt-4o-mini-tts alloy mp3
```

Those bytes are the real audio the model returned. Play them here:

Your browser does not support audio playback.

## Translate multilingual recordings

Use
[`foundry_translate_audio()`](https://farach.github.io/foundryR/reference/foundry_translate_audio.md)
when you want an analysis corpus in a common language. To keep the
example fully reproducible we first synthesize a short Spanish clip,
then translate it to English with whisper – both are real API calls.

``` r

spanish_clip <- foundry_speak(
  "La reunion fue muy util.",
  model = "gpt-4o-mini-tts",
  voice = "alloy",
  path = tempfile(fileext = ".mp3")
)
```

Listen to the synthesized Spanish input:

Your browser does not support audio playback.

Now translate it to English with the whisper deployment:

``` r

translation <- foundry_translate_audio(
  spanish_clip$path,
  service = "openai",
  model = "whisper",
  api = "deployment"
)

translation$text
#> [1] "The meeting was very useful."
```

## Notes for researchers

- Inspect `head(transcript$phrases[[1]])` before processing long
  recordings so you know the segment structure your coding scheme has to
  handle.
- Keep raw audio out of your project repository; store transcripts and
  IDs.
- Request `response_format = "verbose_json"` to get segment-level timing
  from whisper; the default format returns the transcript text only.
