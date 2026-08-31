# web search warning state stays inside the package

    Code
      foundry_warn_web_search()
    Condition
      Warning:
      ! Web search sends query data to Grounding with Bing services.
      i Microsoft documents that this can leave compliance/geographic boundaries and incur additional costs.
      i Set `options(foundryR.web_search_warning = TRUE)` to suppress this warning.

