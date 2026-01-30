---
# chorus-5kuk
title: Postgres with pgvector extension
status: todo
type: task
priority: normal
created_at: 2026-01-30T15:41:17Z
updated_at: 2026-01-30T15:55:47Z
parent: chorus-n2ec
blocking:
    - chorus-7g3w
---

Set up PostgreSQL database with pgvector extension for vector similarity search.

## Core Requirement
**All dependencies must be on their latest stable versions.** Check hex.pm for latest pgvector library.

## Checklist
- [ ] Configure Ecto for PostgreSQL
- [ ] Add {:pgvector, "~> 0.x"} - use latest version from hex.pm
- [ ] Create migration to enable pgvector extension
- [ ] Configure vector type in Ecto schemas (1536 dimensions for text-embedding-3-small)
- [ ] Test vector operations work correctly
- [ ] Add index on embedding column for fast similarity search