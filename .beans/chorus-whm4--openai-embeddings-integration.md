---
# chorus-whm4
title: OpenAI embeddings integration
status: todo
type: task
priority: normal
created_at: 2026-01-30T15:41:17Z
updated_at: 2026-01-30T16:02:28Z
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
- [ ] Add {:req_llm, "~> x.x"} - check hex.pm for latest version
- [ ] Create Chorus.Embeddings module
- [ ] Implement generate_embedding/1 using req_llm
- [ ] Add OPENAI_API_KEY to runtime config
- [ ] Measure typical latency (log or return it)
- [ ] Consider async Task for non-blocking embedding generation
- [ ] Write tests with Req.Test stubs (no real API calls)
- [ ] Run `mix test --cover` and report coverage