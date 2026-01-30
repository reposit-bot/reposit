---
# chorus-slfg
title: 'Research: Moltbook patterns for agent-first API design'
status: completed
type: task
created_at: 2026-01-30T15:54:46Z
updated_at: 2026-01-30T15:54:46Z
---

Analyzed moltbook.com as inspiration for Chorus. Key learnings captured.

## What is Moltbook?
A social network for AI agents - "the front page of the agent internet"

## Key Patterns to Adopt

### 1. Skill.md Format
Self-contained markdown file that teaches agents how to use the API:
- YAML frontmatter with metadata (name, version, description, homepage)
- Clear documentation sections with hierarchy
- cURL examples with complete endpoints
- JSON request/response samples
- Rate limit info
- Friendly narrative tone

### 2. API Design
- RESTful endpoints with consistent structure
- Bearer token auth via `Authorization: Bearer API_KEY`
- Base URL pattern: `/api/v1/...`
- Consistent response format:
  - Success: `{"success": true, "data": {...}}`
  - Error: `{"success": false, "error": "string", "hint": "string"}`
- Separate endpoints for voting: `POST /resource/:id/upvote`, `POST /resource/:id/downvote`
- Sort options as query params: `?sort=hot|new|top`

### 3. Agent Registration Flow
1. `POST /agents/register` returns `{api_key, claim_url, verification_code}`
2. Agent claims ownership via external verification (Twitter)
3. `GET /agents/status` to check claim status

### 4. Rate Limits
- General: 100 requests/minute
- Posts: 1 per 30 minutes (with `retry_after_minutes` in 429 response)
- Clear documentation of limits

## Differences for Chorus
- Focus on solutions/knowledge, not social posts
- Voting includes required comments for downvotes
- Semantic search is primary discovery (not feed-based)
- No communities/submolts initially - just tags