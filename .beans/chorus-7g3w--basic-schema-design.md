---
# chorus-7g3w
title: Basic schema design
status: completed
type: task
priority: normal
created_at: 2026-01-30T15:41:17Z
updated_at: 2026-01-30T16:33:56Z
parent: chorus-n2ec
blocking:
    - chorus-l8ab
---

Design and implement the core database schemas for solutions, votes, and metadata.

## Core Requirements
- **Speed First**: Add proper indexes from the start. Plan for pgvector index on embeddings.
- **Latest Dependencies**: Use latest pgvector Elixir library
- **Testing**: Test schema validations, especially downvote comment requirement

## Schema

### solutions
```elixir
- id (uuid, primary key)
- problem_description (text, required, min 20 chars)
- solution_pattern (text, required, min 50 chars)
- context_requirements (map, optional)
- embedding (vector(1536))
- tags (map) - {language: [], framework: [], domain: [], platform: []}
- upvotes (integer, default 0)
- downvotes (integer, default 0)
- inserted_at / updated_at (utc_datetime_usec for precision)
```

### votes
```elixir
- id (uuid, primary key)
- solution_id (references solutions, on_delete: :delete_all)
- agent_session_id (string, required)
- vote_type (:up | :down)
- comment (text, required when vote_type is :down)
- reason (enum, required when vote_type is :down)
- inserted_at (utc_datetime_usec)
```

## Indexes (for speed)
- solutions: embedding (HNSW), inserted_at, (upvotes - downvotes) for sorting
- votes: solution_id, unique on [solution_id, agent_session_id]

## Checklist
- [x] Create solutions migration with all fields
- [x] Create votes migration with foreign key
- [x] Add HNSW index on embedding column (vector_cosine_ops)
- [x] Create Ecto enums for vote_type and reason (Ecto.Enum)
- [x] Create Solution schema with changeset validations
- [x] Create Vote schema with conditional validation (comment required for downvotes)
- [x] Add unique constraint for one vote per agent per solution
- [x] Write schema tests (valid changesets, invalid changesets, edge cases)
- [x] Run `mix test --cover` and report coverage (80.58%, 37 tests)