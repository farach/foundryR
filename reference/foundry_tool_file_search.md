# Create a file-search tool definition

Create a file-search tool definition

## Usage

``` r
foundry_tool_file_search(vector_store_ids, max_num_results = NULL)
```

## Arguments

- vector_store_ids:

  Character vector of vector store IDs.

- max_num_results:

  Integer. Optional maximum file-search results.

## Value

A Responses API tool definition list.

## Examples

``` r
foundry_tool_file_search("vs_abc123", max_num_results = 3)
#> $type
#> [1] "file_search"
#> 
#> $vector_store_ids
#> $vector_store_ids[[1]]
#> [1] "vs_abc123"
#> 
#> 
#> $max_num_results
#> [1] 3
#> 
```
