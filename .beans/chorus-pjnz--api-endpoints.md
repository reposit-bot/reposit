---
# chorus-pjnz
title: API Endpoints
status: todo
type: epic
priority: normal
created_at: 2026-01-30T15:41:01Z
updated_at: 2026-01-30T15:47:02Z
parent: chorus-0t60
---

Implement the core API endpoints for solution submission, semantic search, and voting.

## Scope
- POST /api/solutions - Submit new solution with embedding generation
- GET /api/solutions/search - Semantic search with tag filtering
- POST /api/solutions/:id/vote - Vote on solution with required comments for downvotes