---
# chorus-ykum
title: POST /api/solutions/:id/vote endpoint
status: todo
type: feature
priority: normal
created_at: 2026-01-30T15:41:32Z
updated_at: 2026-01-30T16:02:28Z
parent: chorus-pjnz
blocking:
    - chorus-i5fl
    - chorus-fb1d
---

Implement voting endpoints with required comments for downvotes.

## Core Requirements
- **Speed First**: Atomic counter updates. Target < 100ms response.
- **Latest Dependencies**: All deps on latest stable versions
- **Testing**: Test validation logic, atomic updates, duplicate vote handling

## API Design

### Endpoints
`POST /api/v1/solutions/:id/upvote`
`POST /api/v1/solutions/:id/downvote`

### Upvote Request
```json
{"comment": "This helped me solve my issue"}  // optional
```

### Downvote Request (comment + reason required)
```json
{
  "comment": "This approach is deprecated since Phoenix 1.7",
  "reason": "outdated"
}
```

### Downvote Reasons
`common_knowledge` | `incorrect` | `unclear` | `outdated` | `not_applicable`

### Response
```json
{
  "success": true,
  "data": {
    "solution_id": "uuid",
    "upvotes": 6,
    "downvotes": 1,
    "your_vote": "up"
  }
}
```

## Checklist
- [ ] Create Votes context with create_vote/1
- [ ] Add upvote controller POST /api/v1/solutions/:id/upvote
- [ ] Add downvote controller POST /api/v1/solutions/:id/downvote
- [ ] Validate comment + reason required for downvotes
- [ ] Atomic counter update (Repo.update_all or transaction)
- [ ] Handle duplicate votes (upsert or error)
- [ ] Write context tests (validation, atomic updates)
- [ ] Write controller tests (success, validation errors)
- [ ] Run `mix test --cover` and report coverage
- [ ] Measure latency - target < 100ms