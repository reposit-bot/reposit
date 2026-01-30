---
# chorus-ytxj
title: Add Chorus.Schema wrapper module
status: completed
type: task
priority: normal
created_at: 2026-01-30T16:34:56Z
updated_at: 2026-01-30T17:04:06Z
---

Create a `Chorus.Schema` module that wraps `Ecto.Schema` with project conventions.

## Context

Based on the pattern from Express.Schema, we want a consistent schema setup across all schemas.

## Requirements

### Core Behaviour

### Module Setup (via `use Chorus.Schema`)

- `use Ecto.Schema`
- `import Ecto.Changeset`
- `import Ecto.Query`
- `alias __MODULE__`
- `alias Chorus.Repo`

### Schema Defaults

- `@primary_key {:id, :binary_id, autogenerate: true}` - UUID primary keys
- `@foreign_key_type :binary_id` - UUID foreign keys
- `@timestamps_opts [type: :utc_datetime_usec]` - microsecond precision timestamps

### Type Spec

- `@type t :: %__MODULE__{}` for each schema

## Checklist

- [ ] Create `lib/chorus/schema.ex` with the wrapper module
- [ ] Update `Solution` schema to use `Chorus.Schema`
- [ ] Update `Vote` schema to use `Chorus.Schema`
- [ ] Verify existing tests still pass
