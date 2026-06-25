# Audio Workflows with Microsoft Foundry

``` r

library(foundryR)
#> 
#> foundryR - Tidy Azure AI Foundry workflows
#> ==========================================
#> * Check your setup:
#>   foundry_check_setup()
#> * Set your API key: foundry_set_key()
#> * Set your endpoint: foundry_set_endpoint()
#> * Get started: ?foundry_response, ?foundry_groundedness
#> 
#> New to Azure? See the README for setup instructions.
```

Audio is one of the most useful Foundry additions for researchers. You
can transcribe interviews, lectures, field recordings, meetings, and
focus groups, then keep the result in a tibble with segment-level timing
for downstream coding or analysis.

## Configure Speech in Foundry Tools

MAI-Transcribe models are exposed through the LLM Speech API. Configure
the Speech resource once per session:

``` r

foundry_set_speech_endpoint(Sys.getenv("AZURE_FOUNDRY_SPEECH_ENDPOINT"))
foundry_set_speech_key("your-speech-key")
```

For keyless authentication, set a bearer token instead of a key:

``` r

foundry_set_token("your-entra-id-access-token")
```

## Transcribe an audio file

``` r

transcript <- foundry_transcribe(
  "interview.mp3",
  model = "mai-transcribe-1.5",
  locales = "en-US",
  phrase_list = c("foundryR", "tidymodels")
)
```

A successful transcription returns one row per file. The `phrases`
column is a list-column with segment timing.

``` r

phrases <- tibble::tibble(
  text = c(
    "We used foundryR to transcribe the interview.",
    "Then we coded the responses in R."
  ),
  locale = c("en-us", "en-us"),
  offset_ms = c(0L, 3280L),
  duration_ms = c(3120L, 2600L),
  confidence = c(0, 0),
  speaker = c(NA_character_, NA_character_),
  words = list(list(), list())
)

transcript <- tibble::tibble(
  file = "interview.mp3",
  task = "transcribe",
  model = "mai-transcribe-1.5",
  text = paste(phrases$text, collapse = " "),
  duration_ms = 5880L,
  language = "en-us",
  phrases = list(phrases)
)

transcript[, c("file", "task", "model", "text", "duration_ms")]
#> # A tibble: 1 × 5
#>   file          task       model              text                   duration_ms
#>   <chr>         <chr>      <chr>              <chr>                        <int>
#> 1 interview.mp3 transcribe mai-transcribe-1.5 We used foundryR to t…        5880
head(transcript$phrases[[1]])
#> # A tibble: 2 × 7
#>   text                    locale offset_ms duration_ms confidence speaker words 
#>   <chr>                   <chr>      <int>       <int>      <dbl> <chr>   <list>
#> 1 We used foundryR to tr… en-us          0        3120          0 NA      <list>
#> 2 Then we coded the resp… en-us       3280        2600          0 NA      <list>
```

## Translate multilingual recordings

Use
[`foundry_translate_audio()`](https://farach.github.io/foundryR/reference/foundry_translate_audio.md)
when you want an analysis corpus in a common language.

``` r

translation <- foundry_translate_audio(
  "interview-es.mp3",
  target_language = "en",
  prompt = "Use concise research-note style."
)
```

``` r

translation <- tibble::tibble(
  file = "interview-es.mp3",
  task = "translate",
  model = NA_character_,
  text = "The participant described the workflow as fast and easy to learn.",
  duration_ms = 4210L,
  language = "en",
  phrases = list(tibble::tibble(
    text = "The participant described the workflow as fast and easy to learn.",
    locale = "en",
    offset_ms = 0L,
    duration_ms = 4210L,
    confidence = 0,
    speaker = NA_character_,
    words = list(list())
  ))
)

translation[, c("file", "task", "text", "duration_ms")]
#> # A tibble: 1 × 4
#>   file             task      text                                    duration_ms
#>   <chr>            <chr>     <chr>                                         <int>
#> 1 interview-es.mp3 translate The participant described the workflow…        4210
```

## Synthesize speech

[`foundry_speak()`](https://farach.github.io/foundryR/reference/foundry_speak.md)
writes binary audio to disk and returns the file path and byte count.
This is useful for experiment stimuli, accessibility assets, and demos.

``` r

speech <- foundry_speak(
  "Welcome to the study.",
  model = "tts-1",
  voice = "alloy",
  path = "welcome.mp3"
)
```

``` r

speech <- tibble::tibble(
  path = "welcome.mp3",
  bytes = 18432L,
  model = "tts-1",
  voice = "alloy",
  format = "mp3"
)

speech
#> # A tibble: 1 × 5
#>   path        bytes model voice format
#>   <chr>       <int> <chr> <chr> <chr> 
#> 1 welcome.mp3 18432 tts-1 alloy mp3
```

## Notes for researchers

- Use `head(transcript$phrases[[1]])` before processing long recordings.
- Keep raw audio out of your project repository; store transcripts and
  IDs.
- MAI-Transcribe preview limitations include no diarization for
  MAI-Transcribe models and no prompt tuning for MAI-Transcribe 1.0.
