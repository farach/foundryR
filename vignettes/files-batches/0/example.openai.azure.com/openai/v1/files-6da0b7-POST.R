structure(list(method = "POST", url = "https://example.openai.azure.com/openai/v1/files", 
    status_code = 201L, headers = structure(list(`content-type` = "application/json; charset=utf-8", 
        date = "Sun, 27 Sep 2026 20:01:04 GMT", server = "uvicorn,istio-envoy", 
        location = "https://example.openai.azure.com/openai/files/file-7866cfdf0049457395b93099642c6036?api-version=1", 
        `x-ms-middleware-request-id` = "b4a79f5c-5244-4c69-8a8a-77be2fcbfecb", 
        `api-supported-versions` = "2022-12-01,2023-03-15-preview,2023-05-15,2023-06-01-preview,2023-07-01-preview,2023-08-01-preview,2023-09-01-preview,2023-10-01-preview,2023-12-01-preview,2024-02-01,2024-02-15-preview,2024-03-01-preview,2024-04-01-preview,2024-04-15-preview,2024-05-01-preview,2024-06-01,2024-07-01-preview,2024-08-01-preview,2024-09-01-preview,2024-10-01-preview,2024-10-21,2024-11-01-preview,2024-12-01-preview,2025-01-01-preview,2025-02-01-preview,2025-03-01-preview,2025-04-01-preview,2025-04-28,1", 
        `strict-transport-security` = "max-age=31536000; includeSubDomains; preload", 
        `apim-request-id` = "6d202a93-022c-4eb4-afa1-fdf0e9fda667", 
        `x-content-type-options` = "nosniff", `x-ms-region` = "East US 2"), class = "httr2_headers"), 
    body = charToRaw("{\n  \"status\": \"processed\",\n  \"bytes\": 4650,\n  \"purpose\": \"batch\",\n  \"filename\": \"file7260466446e2.jsonl\",\n  \"id\": \"file-7866cfdf0049457395b93099642c6036\",\n  \"created_at\": 1790539265,\n  \"object\": \"file\"\n}"), 
    timing = c(redirect = 0, namelookup = 0.03329, connect = 0.05577, 
    pretransfer = 0.08516, starttransfer = 0.263895, total = 0.263951
    ), cache = new.env(parent = emptyenv())), class = "httr2_response")
