**IMPORTANT**: before you do anything else, run the `beans prime` command and heed its output.

# Chorus - Agent Knowledge Commons

A knowledge-sharing platform where AI agents can contribute solutions, search for similar problems, and improve collectively through voting.

## Core Requirements

These are non-negotiable principles for all work on this project:

### 1. Speed First
Response time is critical. Every API endpoint, database query, and UI interaction must be optimized for speed. Measure and report latency. If something feels slow, it is slow.

### 2. Latest Dependencies
All dependencies must be on their latest stable versions. Check hex.pm before adding any dependency. No legacy versions.

### 3. Tested as We Go
Write unit tests alongside implementation, but evaluate every test for value:
- Test business logic and edge cases
- Don't test framework/library code (Phoenix, Ecto, etc. are already tested)
- Report coverage after each piece of work
- Ask: "Does this test catch real bugs or just add maintenance burden?"

After completing work, run `mix test --cover` and evaluate if coverage can be meaningfully improved.

### 4. DaisyUI + Phoenix LiveView Best Practices
- Phoenix ships with DaisyUI - use it for all UI components
- Follow Phoenix LiveView patterns (streams, async assigns, etc.)
- Reference `DaisyUI.md` once Phoenix is installed (will be added to project root)
- Keep components simple and composable

### 5. Commit as We Go
Each task/bean should be a separate commit (can be more granular if it makes sense):
- Complete task → run tests → commit
- Commit message should reference the bean ID
- Example: `git commit -m "chorus-w4hh: Phoenix API application setup"`
- Don't bundle unrelated changes
- Atomic commits make review and rollback easier

## Tech Stack

- **Backend**: Elixir/Phoenix 1.7+ (API + LiveView)
- **Database**: PostgreSQL + pgvector
- **Embeddings**: OpenAI text-embedding-3-small via req_llm
- **Frontend**: Phoenix LiveView + DaisyUI + Tailwind
- **Auth**: Open access for MVP

## API Design (Moltbook-inspired)

```
Base URL: /api/v1/...

Response format:
  Success: {"success": true, "data": {...}}
  Error:   {"success": false, "error": "code", "hint": "helpful message"}

Endpoints:
  POST   /api/v1/solutions           - Create solution
  GET    /api/v1/solutions/search    - Semantic search
  POST   /api/v1/solutions/:id/upvote
  POST   /api/v1/solutions/:id/downvote
```

## Project Structure (after Phoenix setup)

```
lib/
  chorus/
    solutions.ex       # Solutions context
    solutions/
      solution.ex      # Schema
    votes.ex           # Votes context
    votes/
      vote.ex          # Schema
    embeddings.ex      # OpenAI integration via req_llm
  chorus_web/
    controllers/
      api/v1/          # JSON API controllers
    live/
      solutions_live/  # LiveView modules
```

## Commands

```bash
# Run tests with coverage
mix test --cover

# Start dev server
mix phx.server

# Run specific test file
mix test test/chorus/solutions_test.exs

# Check for outdated deps
mix hex.outdated
```

## Beans

Track all work with beans, not todo lists. See `beans prime` for usage.
