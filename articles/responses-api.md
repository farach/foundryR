# Responses API, structured extraction, and web search

Calls to Azure show output recorded from a live run; setup code is shown
but not run.

The Responses API is the foundryR route for stored response objects,
stateful turns, built-in tools, token accounting, and schema-constrained
output. The `model =` argument is a deployment name, and foundryR reads
`AZURE_FOUNDRY_MODEL` when you omit it.

By default, responses go to the resource endpoint. Pass
`project_endpoint =` to send one call to a Foundry project instead, or
call `foundry_set_route("project")` to send responses, files, vector
stores, and evaluations there for the rest of the R session.
Agent-backed responses always use the project endpoint because agents
live in a project.

``` r

foundry_set_project_endpoint(Sys.getenv("AZURE_FOUNDRY_PROJECT_ENDPOINT"))

foundry_response(
  "Summarize the project route in one sentence.",
  project_endpoint = Sys.getenv("AZURE_FOUNDRY_PROJECT_ENDPOINT")
)
```

## Response text and usage

[`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
returns a one-row tibble. Most analysis starts with the generated text
and the token columns, not with the raw response.

``` r

basic <- foundry_response(
  "Answer in one sentence: what is retrieval-augmented generation?"
)

basic$output_text
#> [1] "Retrieval-augmented generation (RAG) is a method that augments a text-generating model with a retrieval component that fetches relevant documents from an external corpus and conditions the generated output on those documents to improve factual accuracy and up-to-date knowledge."
basic[, c(
  "input_tokens", "output_tokens", "reasoning_tokens",
  "cached_input_tokens", "total_tokens"
)]
#> # A tibble: 1 × 5
#>   input_tokens output_tokens reasoning_tokens cached_input_tokens total_tokens
#>          <int>         <int>            <int>               <int>        <int>
#> 1           19           356              256                   0          375
```

Reasoning models can spend tokens that do not appear in `output_text`.
Keep the token columns in reports when cost or model behavior matters.

## Stateful turns

Responses are stored by the service by default. Chaining with
`previous_response_id` lets the service carry state from one turn to the
next.

``` r

first <- foundry_response(
  "Define catastrophic forgetting in one sentence."
)

second <- foundry_response(
  "Explain it for a college freshman in one sentence.",
  previous_response_id = first$response_id
)

second$output_text
#> [1] "Catastrophic forgetting is when a neural network forgets how to do an old task after learning a new one, because updating its internal parameters for the new task overwrites the adjustments it had made for the old task."
second[, c("response_id", "input_tokens", "output_tokens", "total_tokens")]
#> # A tibble: 1 × 4
#>   response_id                            input_tokens output_tokens total_tokens
#>   <chr>                                         <int>         <int>        <int>
#> 1 resp_083254d4c0c03253006ab97c3e29a081…           77           313          390
```

Set `store = FALSE` for stateless calls when you do not need server-side
state. Chaining requires a stored previous response.

## Structured extraction

Structured output is useful when model output becomes data. The example
below codes short comments into sentiment, topic entities, and a
summary. foundryR’s schema helpers build the JSON Schema that Azure
enforces.

``` r

comment_schema <- foundry_schema(
  sentiment = schema_enum(c("positive", "negative", "neutral")),
  entities = schema_array(schema_string()),
  summary = schema_string()
)

comments <- c(
  "The new data pipeline reduced manual coding time by half.",
  "Participants reported confusion about the consent form."
)

comment_codes <- foundry_extract(
  comments,
  schema = comment_schema,
  schema_name = "CommentCode"
)

comment_codes[, c("sentiment", "entities", "summary", ".status")]
#> # A tibble: 2 × 4
#>   sentiment entities  summary                                            .status
#>   <chr>     <list>    <chr>                                              <chr>  
#> 1 positive  <chr [2]> The new data pipeline reduced manual coding time … comple…
#> 2 negative  <chr [2]> Participants reported confusion about the consent… comple…
```

Top-level scalar fields become regular columns. Arrays and nested
objects become list-columns, so you can unnest them only when your next
analysis needs it.

If you already use ellmer type specifications, convert them locally with
[`as_foundry_schema()`](https://farach.github.io/foundryR/reference/as_foundry_schema.md),
which returns the JSON Schema that foundryR sends with an extraction
request. This keeps the extraction contract in one place.

``` r

sentiment_spec <- ellmer::type_object(
  sentiment = ellmer::type_enum(
    c("positive", "negative", "neutral"),
    description = "Overall sentiment of the response."
  ),
  theme = ellmer::type_string("A short theme label for the response.")
)

sentiment_schema <- as_foundry_schema(sentiment_spec)
jsonlite::toJSON(sentiment_schema, auto_unbox = TRUE, pretty = TRUE)
#> {
#>   "type": "object",
#>   "properties": {
#>     "sentiment": {
#>       "type": "string",
#>       "enum": ["positive", "negative", "neutral"],
#>       "description": "Overall sentiment of the response."
#>     },
#>     "theme": {
#>       "type": "string",
#>       "description": "A short theme label for the response."
#>     }
#>   },
#>   "required": ["sentiment", "theme"],
#>   "additionalProperties": false
#> }
```

## User-defined R tools

[`foundry_tool()`](https://farach.github.io/foundryR/reference/foundry_tool.md)
describes an R function to the model and keeps the local function for
execution.
[`foundry_agent()`](https://farach.github.io/foundryR/reference/foundry_agent.md)
runs a bounded loop: ask the model, execute requested function calls in
R, send the matching tool outputs back, and stop when the model returns
a final answer.

``` r

get_weather <- function(location) {
  list(location = location, temperature = "70 F")
}

weather_tool <- foundry_tool(
  get_weather,
  description = "Get weather for a location",
  parameters = foundry_schema(
    location = schema_string("City and state.")
  )
)

tool_turns <- foundry_agent(
  "What is the weather in San Francisco?",
  tools = list(weather_tool),
  max_iterations = 4
)

tool_turns[, c("iteration", "final", "output_text")]
#> # A tibble: 2 × 3
#>   iteration final output_text                                                   
#>       <int> <lgl> <chr>                                                         
#> 1         1 FALSE  NA                                                           
#> 2         2 TRUE  "Current weather in San Francisco, CA: 70°F (about 21°C).\n\n…
tool_turns$tool_calls[[1]][, c("type", "name", "call_id", "arguments")]
#> # A tibble: 1 × 4
#>   type          name        call_id                       arguments             
#>   <chr>         <chr>       <chr>                         <chr>                 
#> 1 function_call get_weather call_5b7vLutyQoRGmPdZTjSsHIRd "{\"location\":\"San …
tool_turns$tool_results[[1]]
#> # A tibble: 1 × 4
#>   call_id                       name        arguments        output             
#>   <chr>                         <chr>       <list>           <chr>              
#> 1 call_5b7vLutyQoRGmPdZTjSsHIRd get_weather <named list [1]> "{\"location\":\"S…
```

The maximum iteration count protects long jobs from unbounded tool
loops. Set it to match the number of tool calls you are willing to
review.

## Remote MCP tools

Microsoft documents remote Model Context Protocol tools for the
Responses API. foundryR does not add a separate MCP helper because
[`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
accepts raw Responses API tool objects.

``` r

mcp_tool <- list(
  type = "mcp",
  server_label = "approved_server",
  server_url = Sys.getenv("MY_MCP_SERVER_URL"),
  require_approval = "never"
)

foundry_response(
  "Use the MCP server if it helps answer the question.",
  tools = list(mcp_tool)
)
```

Only attach MCP servers you trust and whose data handling your
organization has approved. Treat the server as part of the same data
boundary as the model call.

## Web-grounded answers

Web search sends query data to Grounding with Bing services. Microsoft
documents that this can leave compliance or geographic boundaries and
can incur extra cost, so avoid secrets and sensitive research data in
web-search prompts. foundryR warns about this before the first web
search in a session, and the option at the top of the next chunk
acknowledges that warning.

[`foundry_web_search()`](https://farach.github.io/foundryR/reference/foundry_web_search.md)
requests the Responses API `web_search` tool and parses citations and
tool calls into list-columns. The printed fields show the answer,
sources, and search query separately.

``` r

options(foundryR.web_search_warning = TRUE)

web_answer <- foundry_web_search(
  "Which version of R does the R Project website list as the latest release, and when was it released?",
  search_context_size = "medium"
)

web_answer$output_text
#> [1] "- Latest release: R 4.6.1, nicknamed \"Happy Hop\".\n- Release date: June 24, 2026 (2026-06-24). ([r-project.org](https://www.r-project.org/?0003=))"
web_answer$citations[[1]][, c("title", "url")]
#> # A tibble: 1 × 2
#>   title                                   url                             
#>   <chr>                                   <chr>                           
#> 1 The R Project for Statistical Computing https://www.r-project.org/?0003=
web_answer$tool_calls[[1]][, c("type", "status", "action_type", "query")]
#> # A tibble: 3 × 4
#>   type            status    action_type query                   
#>   <chr>           <chr>     <chr>       <chr>                   
#> 1 web_search_call completed search      R latest release version
#> 2 web_search_call completed open_page   NA                      
#> 3 web_search_call completed open_page   NA
```

You can pass approximate location fields when the answer depends on
place. Keep location values coarse unless the task needs more detail.

``` r

foundry_web_search(
  "Find a recent AI research event near me.",
  country = "US",
  region = "Washington",
  city = "Seattle",
  timezone = "America/Los_Angeles"
)
```

## Reasoning token accounting

`reasoning_effort` is sent as the Responses API `reasoning` object. The
returned usage columns show whether hidden reasoning tokens contributed
to cost.

``` r

reasoned <- foundry_response(
  "Compare the two arguments and identify the weaker premise: A says the survey item is valid because it is short. B says it is valid because respondents interpret it consistently.",
  reasoning_effort = "medium"
)

reasoned$output_text
#> [1] "- Premise A: “The item is valid because it is short.”\n- Premise B: “The item is valid because respondents interpret it consistently.”\n\nWeaker premise: A.\n\nWhy:\n- Length alone does not determine validity. An item being short is a form/quality issue and may even reduce content validity if it omits important aspects. It does not logically establish that the item measures the intended construct.\n\nWhy B is stronger (though still not sufficient):\n- If respondents interpret the item consistently, that reduces measurement error and confusion, which supports reliability and, to some extent, construct validity. It is a more meaningful basis for validity than shortness.\n\nCaveats:\n- Even B does not guarantee validity. An item could be interpreted consistently but still measure the wrong construct. Validity evidence would require additional checks (content validity, convergent/divergent validity, test-retest reliability, etc.)."
reasoned[, c(
  "input_tokens", "output_tokens", "reasoning_tokens",
  "cached_input_tokens", "total_tokens"
)]
#> # A tibble: 1 × 5
#>   input_tokens output_tokens reasoning_tokens cached_input_tokens total_tokens
#>          <int>         <int>            <int>               <int>        <int>
#> 1           39          1822             1600                   0         1861
```

## Streaming and chat completions

The Azure OpenAI Responses API supports Server-Sent Events streaming,
but foundryR does not implement streaming. The package focuses on
reproducible, tibble-returning analytical workflows. Use ellmer when you
need interactive streaming chat in R.

Use
[`foundry_chat()`](https://farach.github.io/foundryR/reference/foundry_chat.md)
for the established chat-completions interface and simple assistant
replies. Use
[`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
for response IDs, built-in tools, structured output formats, richer
output items, and token accounting.
