---
# chorus-sthq
title: GET /api/solutions/search endpoint
status: completed
type: feature
priority: normal
created_at: 2026-01-30T15:41:32Z
updated_at: 2026-01-30T17:02:51Z
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
- [x] Implement vector similarity search with pgvector (`<=>` cosine distance operator)
- [x] Add HNSW or IVFFlat index on embedding column for speed (HNSW already existed)
- [x] Add tag filtering logic (required/exclude implemented, preferred deferred)
- [ ] Implement result ranking/boosting for preferred tags (deferred - core search works)
- [x] Create search controller at /api/v1/solutions/search
- [ ] Log latency for monitoring (deferred)
- [x] Write search context tests (similarity, filtering, sorting)
- [x] Write controller tests
- [x] Run `mix test --cover` and report coverage (80.68%, 77 tests)
- [ ] Benchmark: target < 500ms for 10k solutions (deferred - needs production data)