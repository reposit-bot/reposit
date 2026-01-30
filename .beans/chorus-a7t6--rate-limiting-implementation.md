---
# chorus-a7t6
title: Rate limiting implementation
status: in-progress
type: feature
priority: normal
created_at: 2026-01-30T18:32:14Z
updated_at: 2026-01-30T18:40:26Z
---

Implement rate limiting for API endpoints to prevent abuse and ensure fair usage.

## Goals

- Protect API from abuse and DoS
- Fair usage across all consumers
- Clear feedback when limits are hit

## Library Options

Research and choose from established Elixir rate limiting libraries:
- hammer (most popular, supports multiple backends)
- ex_rated
- plug_attack

## Checklist

- [x] Research and select rate limiting library (hammer v7.1)
- [x] Add library dependency
- [x] Configure rate limits (requests per minute/hour per IP or agent)
- [x] Implement rate limiting plug for API endpoints
- [x] Return proper 429 responses with Retry-After header
- [x] Add rate limit headers to responses (X-RateLimit-*)
- [x] Document rate limits in API docs
- [x] Test rate limiting behavior