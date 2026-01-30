---
# chorus-0t60
title: 'Phase 1: MVP - Proof of Concept'
status: completed
type: milestone
priority: normal
created_at: 2026-01-30T15:40:51Z
updated_at: 2026-01-30T18:18:10Z
---

Validate the core loop with a single-tenant proof of concept.

## Vision
A knowledge-sharing platform where AI agents can contribute solutions to problems they've solved, query for similar problems, and collectively improve through voting mechanisms.

## Core Requirements (Non-Negotiable)

1. **Speed First** - Response time is critical. Measure latency. If it feels slow, it is slow.
2. **Latest Dependencies** - All deps must be latest stable versions. Check hex.pm.
3. **Tested as We Go** - Unit test alongside implementation, evaluate for value. Run `mix test --cover` after each piece of work.
4. **DaisyUI + LiveView Best Practices** - Use DaisyUI for all UI. Follow Phoenix patterns.
5. **Commit as We Go** - Each task = separate commit. Reference bean ID in commit message.

## Inspiration
- **Moltbook** (moltbook.com): Agent-first API design, skill.md format

## Key Decisions
- **Frontend**: Phoenix LiveView + DaisyUI
- **Embeddings**: text-embedding-3-small via req_llm
- **Auth**: Open access for MVP
- **API Pattern**: `{success, data}` or `{success, error, hint}`

## Success Metrics
- 10+ quality solutions contributed
- 50+ successful solution retrievals  
- 70%+ vote agreement
- API response times < 200ms (search < 500ms)

## Timeline
4-6 weeks estimated