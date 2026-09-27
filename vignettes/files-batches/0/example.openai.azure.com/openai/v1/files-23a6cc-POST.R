structure(list(method = "POST", url = "https://example.openai.azure.com/openai/v1/files", 
    status_code = 201L, headers = structure(list(`content-type` = "application/json; charset=utf-8", 
        date = "Sun, 27 Sep 2026 22:31:09 GMT", server = "uvicorn,istio-envoy", 
        location = "https://example.openai.azure.com/openai/files/file-f2656a86733b4d059fe8727280d62316?api-version=1", 
        `x-ms-middleware-request-id` = "e3a6ca4f-9b1d-4c31-9fbd-9dbce76d0b68", 
        `api-supported-versions` = "2022-12-01,2023-03-15-preview,2023-05-15,2023-06-01-preview,2023-07-01-preview,2023-08-01-preview,2023-09-01-preview,2023-10-01-preview,2023-12-01-preview,2024-02-01,2024-02-15-preview,2024-03-01-preview,2024-04-01-preview,2024-04-15-preview,2024-05-01-preview,2024-06-01,2024-07-01-preview,2024-08-01-preview,2024-09-01-preview,2024-10-01-preview,2024-10-21,2024-11-01-preview,2024-12-01-preview,2025-01-01-preview,2025-02-01-preview,2025-03-01-preview,2025-04-01-preview,2025-04-28,1", 
        `strict-transport-security` = "max-age=31536000; includeSubDomains; preload", 
        `apim-request-id` = "ff74bd0f-9f13-4aee-803e-d5c46d1bb82a", 
        `x-content-type-options` = "nosniff", `x-ms-region` = "East US 2"), class = "httr2_headers"), 
    body = charToRaw("{\n  \"status\": \"processed\",\n  \"bytes\": 4644,\n  \"purpose\": \"batch\",\n  \"filename\": \"file3604c396822.jsonl\",\n  \"id\": \"file-f2656a86733b4d059fe8727280d62316\",\n  \"created_at\": 1790548270,\n  \"object\": \"file\"\n}"), 
    timing = c(redirect = 0, namelookup = 0.034119, connect = 0.056041, 
    pretransfer = 0.085356, starttransfer = 0.389238, total = 0.389293
    ), cache = new.env(parent = emptyenv())), class = "httr2_response")
