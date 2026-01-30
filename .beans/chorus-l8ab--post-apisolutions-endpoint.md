---
# chorus-l8ab
title: POST /api/solutions endpoint
status: todo
type: feature
priority: normal
created_at: 2026-01-30T15:41:32Z
updated_at: 2026-01-30T16:01:28Z
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
- [ ] Create Solutions context module with create_solution/1
- [ ] Add Phoenix controller for POST /api/v1/solutions
- [ ] Use consistent response format
- [ ] Validate required fields with helpful hints
- [ ] Generate embedding on creation (consider async for speed)
- [ ] Write context tests (business logic, validations)
- [ ] Write controller tests (request/response format)
- [ ] Run `mix test --cover` and report coverage
- [ ] Measure endpoint latency - target < 200ms