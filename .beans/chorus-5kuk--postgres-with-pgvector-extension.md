---
# chorus-5kuk
title: Postgres with pgvector extension
status: completed
type: task
priority: normal
created_at: 2026-01-30T15:41:17Z
updated_at: 2026-01-30T16:31:06Z
parent: chorus-n2ec
blocking:
    - chorus-7g3w
---

Set up PostgreSQL database with pgvector extension for vector similarity search.

## Core Requirement
**All dependencies must be on their latest stable versions.** Check hex.pm for latest pgvector library.

## Checklist
- [x] Configure Ecto for PostgreSQL (done by Phoenix)
- [x] Add {:pgvector, "~> 0.3.1"} - latest version from hex.pm
- [x] Create migration to enable pgvector extension
- [x] Configure Postgrex types for pgvector (Chorus.PostgrexTypes)
- [x] Test vector operations work correctly (cosine similarity search)
- [ ] ~~Configure vector type in Ecto schemas~~ (part of chorus-7g3w schema design)
- [ ] ~~Add index on embedding column~~ (part of chorus-7g3w schema design)