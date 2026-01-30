---
# chorus-sthq
title: GET /api/solutions/search endpoint
status: todo
type: feature
priority: normal
created_at: 2026-01-30T15:41:32Z
updated_at: 2026-01-30T16:03:46Z
parent: chorus-pjnz
blocking:
    - chorus-kh4j
    - chorus-gimv
---

Implement semantic search endpoint with tag filtering.

## Core Requirements
- **Speed First**: Target < 500ms including embedding generation. Use pgvector indexes.
- **Latest Dependencies**: All deps on latest stable versions
- **Testing**: Test search logic, tag filtering, edge cases (no results, bad input)

## API Design

### Endpoint
`GET /api/v1/solutions/search`

### Query Parameters
- `q` (required): Problem description to search for
- `required_tags`: Comma-separated tags that must match
- `preferred_tags`: Comma-separated tags to boost ranking
- `exclude_tags`: Comma-separated tags to exclude
- `sort`: `relevance` (default), `newest`, `top_voted`
- `limit`: Number of results (default 10, max 50)

### Response
```json
{
  "success": true,
  "data": {
    "results": [
      {
        "id": "uuid",
        "problem_description": "...",
        "solution_pattern": "...",
        "tags": {...},
        "score": 0.87,
        "upvotes": 5,
        "downvotes": 1
      }
    ],
    "total": 42
  }
}
```

## Checklist
- [ ] Implement vector similarity search with pgvector (`<->` operator)
- [ ] Add HNSW or IVFFlat index on embedding column for speed
- [ ] Add tag filtering logic (required/preferred/exclude)
- [ ] Implement result ranking/boosting for preferred tags
- [ ] Create search controller at /api/v1/solutions/search
- [ ] Log latency for monitoring (don't include in response)
- [ ] Write search context tests (similarity, filtering, edge cases)
- [ ] Write controller tests
- [ ] Run `mix test --cover` and report coverage
- [ ] Benchmark: target < 500ms for 10k solutions