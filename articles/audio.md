# Transcribe and translate audio

``` r

library(foundryR)
```

Calls to Azure show output recorded from a live run; setup code is shown
but not run.

Audio workflows usually start with transcription and end with a coding
or analysis table. The examples use the bundled JFK sample and a short
Spanish clip that the article generates, and they keep each service
result in a tibble.

``` r

sample_audio <- system.file("extdata", "samples", "jfk.wav", package = "foundryR")
basename(sample_audio)
#> [1] "jfk.wav"
```

## Fast transcription

[`foundry_transcribe()`](https://farach.github.io/foundryR/reference/foundry_transcribe.md)
defaults to Speech fast transcription with `service = "speech"`. This
path does not need a model or deployment name, so the returned `model`
column is `NA`. The `language` column holds the locale the service
detected.

``` r

transcript <- foundry_transcribe(sample_audio)

transcript$text
#> [1] "And so, my fellow Americans, ask not what your country can do for you, ask what you can do for your country."
transcript[, c("model", "duration_ms", "language")]
#> # A tibble: 1 × 3
#>   model duration_ms language
#>   <chr>       <int> <chr>   
#> 1 NA          11000 en-US
```

The `phrases` list-column holds phrase-level timing when the service
returns it. Use those offsets to spot-check long recordings before
coding them.

``` r

head(transcript$phrases[[1]][, c("text", "offset_ms", "duration_ms")])
#> # A tibble: 1 × 3
#>   text                                                     offset_ms duration_ms
#>   <chr>                                                        <int>       <int>
#> 1 And so, my fellow Americans, ask not what your country …       320       10160
```

## MAI-Transcribe enhanced mode

MAI-Transcribe is opt-in. Supplying a MAI model selects Speech enhanced
mode, which is preview and region-limited. In live testing,
MAI-Transcribe worked on a Sweden Central resource, while East US 2
rejected enhanced mode. foundryR adds region guidance to that error.

``` r

foundry_set_speech_endpoint(Sys.getenv("AZURE_FOUNDRY_SPEECH_ENDPOINT"))
foundry_set_speech_key("your-speech-key")

foundry_transcribe(
  sample_audio,
  model = "mai-transcribe-2"
)
```

## Transcribe non-English audio

Interviews are often recorded in more than one language. This example
makes a Spanish clip with
[`foundry_speak()`](https://farach.github.io/foundryR/reference/foundry_speak.md),
so the article does not depend on real participant audio.

``` r

spanish_path <- tempfile(fileext = ".mp3")
spanish_clip <- foundry_speak(
  paste(
    "Buenos dias a todos. En la reunion de hoy revisamos la encuesta a los docentes.",
    "La mayoria pidio mas tiempo para preparar las clases y menos tareas administrativas.",
    "El equipo presentara un plan el proximo mes."
  ),
  model = "gpt-4o-mini-tts",
  voice = "verse",
  path = spanish_path
)
```

Your browser does not support audio playback.

Pass the locale to fast transcription, then translate the text with a
model if readers need English.

``` r

spanish <- foundry_transcribe(spanish_clip$path, locales = "es-ES")
spanish$text
#> [1] "Buenos días a todos. En la reunión de hoy revisamos la encuesta a los docentes. La mayoría pidió más tiempo para preparar las clases y menos tareas administrativas. El equipo presentará un plan el próximo mes."

english <- foundry_response(
  spanish$text,
  instructions = "Translate the text into English. Return only the translation."
)
english$output_text
#> [1] "Good morning everyone. In today's meeting we reviewed the teachers' survey. The majority asked for more time to prepare classes and fewer administrative tasks. The team will present a plan next month."
```

Keep the Spanish transcript as the record and treat the English text as
a reading aid. The translation is another model output, so have a
bilingual reader spot-check it before you quote it.

## Audio translation endpoints

[`foundry_translate_audio()`](https://farach.github.io/foundryR/reference/foundry_translate_audio.md)
sends the audio to a translation endpoint instead. Speech translation
needs LLM Speech enhanced mode, and it failed in both regions tested,
East US 2 and Sweden Central. A classic Azure `whisper` deployment
accepts translation requests through the legacy deployment route. Azure
`whisper` version 001 retires on 2026-12-15.

``` r

whisper <- foundry_translate_audio(
  spanish_clip$path,
  service = "openai",
  model = "whisper",
  api = "deployment"
)

whisper$text
#> [1] "Good morning, everyone. In today's meeting, we reviewed the teacher survey. The majority asked for more time to prepare classes and fewer administrative tasks. The team will present a plan next month."
```

Whisper returned English text for this clip. Check the language of every
output before you use this route in a pipeline, because Whisper can
return untranslated text.

## Code the transcript

The next step is to turn transcript text into variables you can inspect,
join, or model. Closed label sets work best here: a fixed list of topics
and tones gives you codes you can count. The model can code the Spanish
transcript directly with English labels, so the codes do not depend on
the translation.

``` r

transcript_schema <- foundry_schema(
  topic = schema_enum(
    c("workload", "curriculum", "facilities", "other"),
    "Main topic of the passage."
  ),
  tone = schema_enum(
    c("formal", "informal", "urgent", "reflective"),
    "Overall tone of the speaker."
  )
)

meeting_code <- foundry_extract(
  spanish$text,
  schema = transcript_schema,
  schema_name = "TranscriptCode"
)

meeting_code[, c("topic", "tone", ".status", ".error")]
#> # A tibble: 1 × 4
#>   topic    tone   .status   .error
#>   <chr>    <chr>  <chr>     <lgl> 
#> 1 workload formal completed FALSE
```

Check `.error` before you use the codes. When a response stops early,
for example because the deployment’s content filter blocked the output
or the token limit ran out, `.status` is `"incomplete"`, `.error` is
`TRUE`, and `.error_msg` names the reason. Rerun or drop those rows;
their missing fields are not answers. The same call on the JFK
transcript shows what a failed row looks like.

``` r

speech_code <- foundry_extract(
  transcript$text,
  schema = transcript_schema,
  schema_name = "TranscriptCode"
)

speech_code[, c(".status", ".error")]
#> # A tibble: 1 × 2
#>   .status    .error
#>   <chr>      <lgl> 
#> 1 incomplete TRUE
speech_code$.error_msg
#> [1] "The response is incomplete (content_filter). The Azure content filter stopped the output; check the content filter configuration on the deployment."
```

In this recording the content filter stopped the response, although the
request asks only for two labels. Widely quoted text, such as a famous
speech, can trip the filter. If you code texts like these, ask your
Azure administrator about the content filter configuration on the
deployment, and report how many rows failed next to any coded shares.

## Synthesize speech

[`foundry_speak()`](https://farach.github.io/foundryR/reference/foundry_speak.md)
writes generated audio to disk and returns metadata about the file. Use
an explicit path for audio you want to keep.

``` r

speech_path <- tempfile(fileext = ".mp3")
speech <- foundry_speak(
  "Please read each survey question before choosing an answer.",
  model = "gpt-4o-mini-tts",
  voice = "verse",
  path = speech_path
)

speech[, c("bytes", "model", "voice", "format")]
#> # A tibble: 1 × 4
#>    bytes model           voice format
#>    <int> <chr>           <chr> <chr> 
#> 1 100992 gpt-4o-mini-tts verse mp3
```

Your browser does not support audio playback.

## Notes for analysis

Inspect `transcript$phrases[[1]]` before processing long recordings,
because segment structure affects coding and quality checks. Keep raw
audio out of your repository; store transcript text, stable IDs, model
metadata, and links to controlled storage.
