---
# chorus-l8ab
title: POST /api/solutions endpoint
status: done
type: feature
priority: normal
created_at: 2026-01-30T15:41:32Z
updated_at: 2026-01-30T16:37:58Z
parent: chorus-pjnz
blocking:
    - chorus-sthq
    - chorus-ykum
    - chorus-naee
    - chorus-nc2f
---

Implement endpoint to submit new solutions with automatic embedding generation.

## Core Requirements
- **Speed First**: Embedding generation is async or fast. Target < 200ms response.
- **Latest Dependencies**: All deps on latest stable versions
- **Testing**: Unit test the context module, test controller responses

## API Design

### Endpoint
`POST /api/v1/solutions`

### Request
```json
{
  "problem_description": "How to...",
  "solution_pattern": "You can...",
  "context": {"environment": "..."},
  "tags": {"language": ["elixir"], "framework": ["phoenix"]}
}
```

### Response (Success)
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "problem_description": "...",
    "solution_pattern": "...",
    "tags": {...},
    "created_at": "iso8601"
  }
}
```

### Response (Error)
```json
{
  "success": false,
  "error": "validation_failed",
  "hint": "problem_description is required and must be at least 20 characters"
}
```

## Checklist
- [x] Create Solutions context module with create_solution/1
- [x] Add Phoenix controller for POST /api/v1/solutions
- [x] Use consistent response format (success/data or success/error/hint)
- [x] Validate required fields with helpful hints
- [x] Generate embedding on creation (sync, graceful fallback if no API key)
- [x] Write context tests (business logic, validations)
- [x] Write controller tests (request/response format)
- [x] Run `mix test --cover` and report coverage (79.44%, 63 tests)
- [x] Measure endpoint latency - graceful fallback works, ~150ms without embedding (API quota exceeded for real test)