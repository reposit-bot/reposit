**IMPORTANT**: before you do anything else, run the `beans prime` command and heed its output.

Also read AGENTS.md

# Reposit - Agent Knowledge Commons

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

Avoid hitting external API (esp. OpenAI) in tests. See https://hexdocs.pm/req_llm/1.3.0/fixture-testing.html for how to test req_llm.

### 4. DaisyUI + Tailwind + Phoenix LiveView Best Practices

- Where possible, use default DaisyUI components and colors (see DaisyUI.md)
- For unique components, write custom Tailwind components
- Follow Phoenix LiveView patterns (streams, async assigns, etc.)
- Keep components simple and composable

### 5. Commit as We Go

Each task/bean should be a separate commit (can be more granular if it makes sense):

- Complete task → run tests → commit
- Commit message should reference the bean ID
- Example: `git commit -m "reposit-w4hh: Phoenix API application setup"`
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

## Project Structure

```
lib/
  reposit/
    application.ex     # OTP application
    content_safety.ex  # Content moderation
    embeddings.ex      # OpenAI integration via req_llm
    mailer.ex          # Email (Swoosh)
    postgrex_types.ex  # Custom Postgres types (pgvector)
    rate_limiter.ex    # Rate limiting with Hammer
    repo.ex            # Ecto repo
    schema.ex          # Base schema module
    solutions.ex       # Solutions context
    solutions/
      solution.ex      # Schema
    votes.ex           # Votes context
    votes/
      vote.ex          # Schema
  reposit_web/
    components/
      core_components.ex  # Phoenix core components
      layouts.ex          # Layout components
      layouts/            # Layout templates
    controllers/
      api/v1/
        fallback_controller.ex   # Error handling
        health_controller.ex     # Health check
        solutions_controller.ex  # Solutions API
        votes_controller.ex      # Votes API
      page_controller.ex
      error_html.ex
      error_json.ex
    live/
      demo_live.ex        # Demo page
      home_live.ex        # Home page
      moderation_live.ex  # Moderation dashboard
      search_live.ex      # Search interface
      solutions_live/
        index.ex          # Solutions list
        show.ex           # Solution detail
    plugs/
      rate_limit.ex       # Rate limiting plug
    endpoint.ex
    router.ex
    telemetry.ex
```

## Commands

```bash
# First-time setup (deps, DB, assets)
mix setup

# Pre-commit checks (compile, format, sobelow, test)
mix precommit

# Format code
mix format

# Run tests with coverage
mix coveralls

# Start dev server
mix phx.server

# Start Postgres via docker-compose
docker-compose up -d

# Run specific test file
mix test test/reposit/solutions_test.exs

# Check for outdated deps
mix hex.outdated
```

## Environment Variables

- `OPENAI_API_KEY` - Required for embeddings (set in shell or .envrc)

## Beans

Track all work with beans, not todo lists. See `beans prime` for usage.
