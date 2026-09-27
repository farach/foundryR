# Choose the endpoint for APIs that run on a resource or a project

Microsoft Foundry serves some OpenAI-compatible APIs from two places:
the resource endpoint (for example
`https://<resource>.openai.azure.com`) and a project endpoint
(`https://<resource>.services.ai.azure.com/api/projects/<project>`).
Responses, files, vector stores, and evaluations work on both. foundryR
sends them to the resource endpoint unless you ask for the project, so
code written for foundryR 0.1.0 keeps working.

`foundry_set_route("project")` sends those calls to the project endpoint
set with
[`foundry_set_project_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_project_endpoint.md)
for the rest of the R session. A call's own `endpoint` or
`project_endpoint` argument always wins over the session route.

## Usage

``` r
foundry_set_route(route = c("resource", "project"))
```

## Arguments

- route:

  Character. `"resource"` (the default) or `"project"`.

## Value

The previous route, invisibly, so you can restore it.

## Details

Some calls use the project endpoint whatever the session route is,
because the feature exists only there: conversations and server-side
agents always do, and
[`foundry_evaluate()`](https://farach.github.io/foundryR/reference/foundry_evaluate.md)
does when a run uses built-in evaluators, an agent target, or stored
responses. It prints a message when it switches.

Objects created on one endpoint are not always visible from the other.
Look a file, vector store, or evaluation up on the endpoint where you
created it.

Project endpoints accept the resource's API key for responses, agents,
conversations, files, and vector stores. Evaluations on a project
endpoint need a Microsoft Entra ID token; see
[`foundry_token_azure_cli()`](https://farach.github.io/foundryR/reference/foundry_token_azure_cli.md),
[`foundry_token_azure_identity()`](https://farach.github.io/foundryR/reference/foundry_token_azure_identity.md),
and
[`foundry_set_token()`](https://farach.github.io/foundryR/reference/foundry_set_token.md)
with `scope = "project"`.

## Examples

``` r
old <- foundry_set_route("project")
#> Warning: The session route is now "project", but no project endpoint is set.
#> ℹ Set one with `foundry_set_project_endpoint()`.
#> Responses, files, vector stores, and evaluations now use the project endpoint.
foundry_set_route(old)
#> Responses, files, vector stores, and evaluations now use the resource endpoint.
```
