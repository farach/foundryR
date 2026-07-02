# Package index

## Setup and configuration

Configure your Azure AI Foundry credentials and verify your setup. These
functions manage authentication for all API calls.

- [`foundry_check_setup()`](https://farach.github.io/foundryR/reference/foundry_check_setup.md)
  : Check foundryR Setup
- [`foundry_set_key()`](https://farach.github.io/foundryR/reference/foundry_set_key.md)
  : Set Azure AI Foundry API Key
- [`foundry_set_token()`](https://farach.github.io/foundryR/reference/foundry_set_token.md)
  : Set Azure AI Foundry Bearer Token
- [`foundry_set_token_provider()`](https://farach.github.io/foundryR/reference/foundry_set_token_provider.md)
  : Set a Microsoft Entra ID token provider
- [`foundry_token_azure_cli()`](https://farach.github.io/foundryR/reference/foundry_token_azure_cli.md)
  : Create an Azure CLI token provider
- [`foundry_token_azure_identity()`](https://farach.github.io/foundryR/reference/foundry_token_azure_identity.md)
  : Create a Microsoft Entra ID token provider using AzureAuth
- [`foundry_set_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_endpoint.md)
  : Set Azure AI Foundry Endpoint
- [`foundry_get_endpoint()`](https://farach.github.io/foundryR/reference/foundry_get_endpoint.md)
  : Get Azure AI Foundry Endpoint
- [`foundry_set_project_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_project_endpoint.md)
  : Set Azure AI Foundry project endpoint
- [`foundry_get_project_endpoint()`](https://farach.github.io/foundryR/reference/foundry_get_project_endpoint.md)
  : Get Azure AI Foundry project endpoint
- [`foundry_set_speech_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_speech_endpoint.md)
  : Set Microsoft Foundry Speech endpoint
- [`foundry_set_speech_key()`](https://farach.github.io/foundryR/reference/foundry_set_speech_key.md)
  : Set Microsoft Foundry Speech API key

## Content Safety

Azure AI Content Safety features for responsible AI pipelines. Moderate
content, detect hallucinations, and protect against prompt injection.

- [`foundry_moderate()`](https://farach.github.io/foundryR/reference/foundry_moderate.md)
  : Moderate Text Content
- [`foundry_moderate_image()`](https://farach.github.io/foundryR/reference/foundry_moderate_image.md)
  : Moderate image content
- [`foundry_moderate_multimodal()`](https://farach.github.io/foundryR/reference/foundry_moderate_multimodal.md)
  : Moderate an image together with its text
- [`foundry_protected_material()`](https://farach.github.io/foundryR/reference/foundry_protected_material.md)
  : Detect protected material in text
- [`foundry_protected_code()`](https://farach.github.io/foundryR/reference/foundry_protected_code.md)
  : Detect protected material in code
- [`foundry_blocklists()`](https://farach.github.io/foundryR/reference/foundry_blocklists.md)
  [`foundry_blocklist_create()`](https://farach.github.io/foundryR/reference/foundry_blocklists.md)
  [`foundry_blocklist_get()`](https://farach.github.io/foundryR/reference/foundry_blocklists.md)
  [`foundry_blocklist_delete()`](https://farach.github.io/foundryR/reference/foundry_blocklists.md)
  [`foundry_blocklist_items()`](https://farach.github.io/foundryR/reference/foundry_blocklists.md)
  [`foundry_blocklist_add_items()`](https://farach.github.io/foundryR/reference/foundry_blocklists.md)
  [`foundry_blocklist_remove_items()`](https://farach.github.io/foundryR/reference/foundry_blocklists.md)
  : Manage Content Safety text blocklists
- [`foundry_groundedness()`](https://farach.github.io/foundryR/reference/foundry_groundedness.md)
  : Detect Groundedness of LLM Responses
- [`foundry_llm_resource()`](https://farach.github.io/foundryR/reference/foundry_llm_resource.md)
  : Describe a bring-your-own Azure OpenAI resource for groundedness
- [`foundry_shield()`](https://farach.github.io/foundryR/reference/foundry_shield.md)
  : Shield Prompt from Injection Attacks
- [`foundry_task_adherence()`](https://farach.github.io/foundryR/reference/foundry_task_adherence.md)
  : Check an agent transcript for task adherence
- [`foundry_agent_tool()`](https://farach.github.io/foundryR/reference/foundry_agent_tool.md)
  : Describe an agent tool for task adherence
- [`foundry_agent_tool_call()`](https://farach.github.io/foundryR/reference/foundry_agent_tool_call.md)
  : Describe an agent tool call for task adherence
- [`foundry_agent_message()`](https://farach.github.io/foundryR/reference/foundry_agent_message.md)
  : Describe an agent message for task adherence
- [`foundry_set_content_safety_key()`](https://farach.github.io/foundryR/reference/foundry_set_content_safety_key.md)
  : Set Azure Content Safety API Key
- [`foundry_set_content_safety_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_content_safety_endpoint.md)
  : Set Azure Content Safety Endpoint

## Responses API and extraction

Use Microsoft Foundry’s newer v1 Responses API for stateful turns,
user-defined tools, schema-constrained extraction, and web-grounded
answers.

- [`foundry_response()`](https://farach.github.io/foundryR/reference/foundry_response.md)
  : Create a response with the Azure OpenAI Responses API
- [`foundry_agent()`](https://farach.github.io/foundryR/reference/foundry_agent.md)
  : Run a bounded Responses API tool-calling loop
- [`foundry_tool()`](https://farach.github.io/foundryR/reference/foundry_tool.md)
  : Define an R function as a Responses API tool
- [`foundry_response_retrieve()`](https://farach.github.io/foundryR/reference/foundry_response_retrieve.md)
  : Retrieve a stored Responses API response
- [`foundry_response_delete()`](https://farach.github.io/foundryR/reference/foundry_response_delete.md)
  : Delete a stored Responses API response
- [`foundry_response_cancel()`](https://farach.github.io/foundryR/reference/foundry_response_cancel.md)
  : Cancel a background Responses API response
- [`foundry_response_input_items()`](https://farach.github.io/foundryR/reference/foundry_response_input_items.md)
  : List input items for a Responses API response
- [`foundry_extract()`](https://farach.github.io/foundryR/reference/foundry_extract.md)
  : Extract structured data from text using JSON Schema
- [`foundry_web_search()`](https://farach.github.io/foundryR/reference/foundry_web_search.md)
  : Search the web with the Responses API
- [`foundry_schema()`](https://farach.github.io/foundryR/reference/foundry_schema.md)
  : Build a strict JSON Schema object
- [`schema_string()`](https://farach.github.io/foundryR/reference/schema_constructors.md)
  [`schema_enum()`](https://farach.github.io/foundryR/reference/schema_constructors.md)
  [`schema_number()`](https://farach.github.io/foundryR/reference/schema_constructors.md)
  [`schema_integer()`](https://farach.github.io/foundryR/reference/schema_constructors.md)
  [`schema_boolean()`](https://farach.github.io/foundryR/reference/schema_constructors.md)
  [`schema_array()`](https://farach.github.io/foundryR/reference/schema_constructors.md)
  [`schema_object()`](https://farach.github.io/foundryR/reference/schema_constructors.md)
  : Schema constructors for structured outputs
- [`as_foundry_schema()`](https://farach.github.io/foundryR/reference/as_foundry_schema.md)
  : Convert an object to a foundryR JSON Schema

## Conversations and vector stores

Manage server-side Responses API conversations and Azure-hosted vector
stores for shared retrieval workflows.

- [`foundry_conversation_create()`](https://farach.github.io/foundryR/reference/foundry_conversations.md)
  [`foundry_conversations()`](https://farach.github.io/foundryR/reference/foundry_conversations.md)
  [`foundry_conversation_get()`](https://farach.github.io/foundryR/reference/foundry_conversations.md)
  [`foundry_conversation_update()`](https://farach.github.io/foundryR/reference/foundry_conversations.md)
  [`foundry_conversation_delete()`](https://farach.github.io/foundryR/reference/foundry_conversations.md)
  [`foundry_conversation_items()`](https://farach.github.io/foundryR/reference/foundry_conversations.md)
  [`foundry_conversation_items_add()`](https://farach.github.io/foundryR/reference/foundry_conversations.md)
  : Manage Responses API conversations
- [`foundry_vector_store_create()`](https://farach.github.io/foundryR/reference/foundry_vector_stores.md)
  [`foundry_vector_stores()`](https://farach.github.io/foundryR/reference/foundry_vector_stores.md)
  [`foundry_vector_store_get()`](https://farach.github.io/foundryR/reference/foundry_vector_stores.md)
  [`foundry_vector_store_modify()`](https://farach.github.io/foundryR/reference/foundry_vector_stores.md)
  [`foundry_vector_store_delete()`](https://farach.github.io/foundryR/reference/foundry_vector_stores.md)
  [`foundry_vector_store_files()`](https://farach.github.io/foundryR/reference/foundry_vector_stores.md)
  [`foundry_vector_store_file_add()`](https://farach.github.io/foundryR/reference/foundry_vector_stores.md)
  [`foundry_vector_store_file_remove()`](https://farach.github.io/foundryR/reference/foundry_vector_stores.md)
  [`foundry_vector_store_file_batch()`](https://farach.github.io/foundryR/reference/foundry_vector_stores.md)
  [`foundry_vector_search()`](https://farach.github.io/foundryR/reference/foundry_vector_stores.md)
  : Manage Azure OpenAI vector stores
- [`foundry_tool_file_search()`](https://farach.github.io/foundryR/reference/foundry_tool_file_search.md)
  : Create a file-search tool definition

## Text embeddings

Generate vector embeddings for semantic search, clustering, and machine
learning. Includes batch processing and similarity computation.

- [`foundry_embed()`](https://farach.github.io/foundryR/reference/foundry_embed.md)
  : Generate Text Embeddings
- [`foundry_embed_batch()`](https://farach.github.io/foundryR/reference/foundry_embed_batch.md)
  : Generate Text Embeddings in Parallel Batches
- [`foundry_similarity()`](https://farach.github.io/foundryR/reference/foundry_similarity.md)
  : Compute Cosine Similarity Between Embeddings

## Files and Batch API

Upload files, prepare JSONL request files, and manage asynchronous batch
jobs for large-scale annotation, extraction, and classification.

- [`foundry_file_upload()`](https://farach.github.io/foundryR/reference/foundry_file_upload.md)
  : Upload a file to Microsoft Foundry
- [`foundry_files()`](https://farach.github.io/foundryR/reference/foundry_files.md)
  : List uploaded Microsoft Foundry files
- [`foundry_file_get()`](https://farach.github.io/foundryR/reference/foundry_file_get.md)
  : Retrieve a Microsoft Foundry file
- [`foundry_file_delete()`](https://farach.github.io/foundryR/reference/foundry_file_delete.md)
  : Delete a Microsoft Foundry file
- [`foundry_file_download()`](https://farach.github.io/foundryR/reference/foundry_file_download.md)
  : Download Microsoft Foundry file content
- [`foundry_batch_requests()`](https://farach.github.io/foundryR/reference/foundry_batch_requests.md)
  : Write JSONL requests for the Batch API
- [`foundry_batch_create()`](https://farach.github.io/foundryR/reference/foundry_batch_create.md)
  : Create a Microsoft Foundry batch
- [`foundry_batches()`](https://farach.github.io/foundryR/reference/foundry_batches.md)
  : List Microsoft Foundry batches
- [`foundry_batch_get()`](https://farach.github.io/foundryR/reference/foundry_batch_get.md)
  : Retrieve a Microsoft Foundry batch
- [`foundry_batch_cancel()`](https://farach.github.io/foundryR/reference/foundry_batch_cancel.md)
  : Cancel a Microsoft Foundry batch
- [`foundry_batch_wait()`](https://farach.github.io/foundryR/reference/foundry_batch_wait.md)
  : Wait for a Microsoft Foundry batch to finish
- [`foundry_batch_results()`](https://farach.github.io/foundryR/reference/foundry_batch_results.md)
  : Parse completed Microsoft Foundry batch results
- [`foundry_extract_batch()`](https://farach.github.io/foundryR/reference/foundry_extract_batch.md)
  : Extract structured data with the Batch API
- [`foundry_usage()`](https://farach.github.io/foundryR/reference/foundry_usage.md)
  : Summarise token usage for foundryR results

## Validation and provenance

Validate LLM annotation against human labels, measure
repeated-extraction consistency, and record reproducibility metadata.

- [`foundry_agreement()`](https://farach.github.io/foundryR/reference/foundry_agreement.md)
  : Compute agreement metrics for LLM annotation
- [`foundry_consistency()`](https://farach.github.io/foundryR/reference/foundry_consistency.md)
  : Measure repeated-extraction consistency
- [`foundry_provenance()`](https://farach.github.io/foundryR/reference/foundry_provenance.md)
  : Capture model and schema provenance

## tidymodels integration

Add Foundry text embeddings to tidymodels recipes.

- [`step_foundry_embed()`](https://farach.github.io/foundryR/reference/step_foundry_embed.md)
  [`tidy(`*`<step_foundry_embed>`*`)`](https://farach.github.io/foundryR/reference/step_foundry_embed.md)
  : Foundry Embedding Recipe Step
- [`bake(`*`<step_foundry_embed>`*`)`](https://farach.github.io/foundryR/reference/bake.step_foundry_embed.md)
  : Apply the Foundry embedding step to new data
- [`prep(`*`<step_foundry_embed>`*`)`](https://farach.github.io/foundryR/reference/prep.step_foundry_embed.md)
  : Prepare the Foundry embedding step
- [`print(`*`<step_foundry_embed>`*`)`](https://farach.github.io/foundryR/reference/print.step_foundry_embed.md)
  : Print method for step_foundry_embed
- [`required_pkgs(`*`<step_foundry_embed>`*`)`](https://farach.github.io/foundryR/reference/required_pkgs.step_foundry_embed.md)
  : Required packages for step_foundry_embed
- [`foundry_cache_clear()`](https://farach.github.io/foundryR/reference/foundry_cache_clear.md)
  : Clear the foundryR embedding cache

## Chat completions

Send chat-completion requests to Azure AI Foundry deployments.

- [`foundry_chat()`](https://farach.github.io/foundryR/reference/foundry_chat.md)
  : Chat with an Azure AI Model

## Audio and speech

Transcribe and translate research audio, including MAI-Transcribe models
through LLM Speech, and synthesize text-to-speech audio files.

- [`foundry_transcribe()`](https://farach.github.io/foundryR/reference/foundry_transcribe.md)
  : Transcribe an audio file with Microsoft Foundry
- [`foundry_translate_audio()`](https://farach.github.io/foundryR/reference/foundry_translate_audio.md)
  : Translate an audio file with Microsoft Foundry
- [`foundry_speak()`](https://farach.github.io/foundryR/reference/foundry_speak.md)
  : Generate speech audio from text

## Experimental media

Generate and edit images with v1 preview image models, and manage
preview video generation jobs.

- [`foundry_image()`](https://farach.github.io/foundryR/reference/foundry_image.md)
  : Generate Images with DALL-E
- [`foundry_image_edit()`](https://farach.github.io/foundryR/reference/foundry_image_edit.md)
  : Edit an image with Microsoft Foundry
- [`foundry_save_image()`](https://farach.github.io/foundryR/reference/foundry_save_image.md)
  : Save Generated Image to File
- [`foundry_set_image_endpoint()`](https://farach.github.io/foundryR/reference/foundry_set_image_endpoint.md)
  : Set Image Generation Endpoint
- [`foundry_set_image_key()`](https://farach.github.io/foundryR/reference/foundry_set_image_key.md)
  : Set Image Generation API Key
- [`foundry_video_job_create()`](https://farach.github.io/foundryR/reference/foundry_video_job_create.md)
  : Create a Microsoft Foundry video generation job
- [`foundry_video_jobs()`](https://farach.github.io/foundryR/reference/foundry_video_jobs.md)
  : List Microsoft Foundry video generation jobs
- [`foundry_video_job_get()`](https://farach.github.io/foundryR/reference/foundry_video_job_get.md)
  : Retrieve a Microsoft Foundry video generation job
- [`foundry_video_job_delete()`](https://farach.github.io/foundryR/reference/foundry_video_job_delete.md)
  : Delete a Microsoft Foundry video generation job
- [`foundry_video_get()`](https://farach.github.io/foundryR/reference/foundry_video_get.md)
  : Retrieve a Microsoft Foundry video generation
- [`foundry_video_download()`](https://farach.github.io/foundryR/reference/foundry_video_download.md)
  : Download Microsoft Foundry generated video content

## Model discovery

Explore available model deployments in your Azure AI Foundry resource.

- [`foundry_models()`](https://farach.github.io/foundryR/reference/foundry_models.md)
  : List or retrieve available model deployments
