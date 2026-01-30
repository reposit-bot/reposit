---
# chorus-whm4
title: OpenAI embeddings integration
status: in-progress
type: task
priority: normal
created_at: 2026-01-30T15:41:17Z
updated_at: 2026-01-30T16:34:11Z
parent: chorus-n2ec
blocking:
    - chorus-l8ab
---

Integrate embeddings using req_llm library with OpenAI's text-embedding-3-small model.

## Core Requirements
- **Speed First**: Measure API latency. Consider caching or async generation.
- **Latest Dependencies**: Use latest req_llm from hex.pm
- **Testing**: Test with Req.Test mocks. Don't hit real API in tests.

## Library
- [req_llm](https://github.com/agentjido/req_llm) - Req-based LLM API client
- Uses `Embedding.generate/3` for embedding generation

## Model
- text-embedding-3-small (1536 dimensions)
- Cost: $0.02 per 1M tokens (negligible for MVP)

## Checklist
- [x] Add {:req_llm, "~> 1.2"} - installed 1.3.0 (latest)
- [x] Create Chorus.Embeddings module
- [x] Implement generate/1 using req_llm (ReqLLM.Embedding.embed/3)
- [x] Add OPENAI_API_KEY to runtime config
- [x] Measure typical latency (returns latency_ms in tuple)
- [x] Consider async Task for non-blocking embedding generation (generate_async/1)
- [x] Write tests (unit tests without API calls, integration test skipped)
- [x] Run `mix test --cover` and report coverage (76.27%, 44 tests)