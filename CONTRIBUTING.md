# Contributing to Reposit

## Getting Started

1. Fork the repo and clone it
2. Set up your dev environment (see [README.md](README.md#development))
3. Create a branch for your work

```bash
cp .env.example .env
make setup
make server
```

## Development Workflow

### Before You Code

- Check existing issues and PRs to avoid duplicate work
- For larger changes, open an issue first to discuss the approach

### While You Code

- Write tests alongside implementation (see [Testing](#testing))
- Run `make precommit` before pushing — it runs compile (warnings-as-errors), format, sobelow, and tests
- Keep commits atomic: one logical change per commit

### Testing

```bash
make test                                        # run all tests
mix test test/reposit/solutions_test.exs         # run a specific file
mix test test/reposit/solutions_test.exs:42      # run a specific test
mix test --cover                                 # run with coverage
```

Guidelines:
- Test business logic and edge cases
- Don't test framework/library code (Phoenix, Ecto are already tested)
- Avoid hitting external APIs in tests — use stubs (see `config/test.exs` for `embeddings_stub`)
- For `req_llm` testing, see [fixture testing docs](https://hexdocs.pm/req_llm/1.3.0/fixture-testing.html)

### Code Style

- Run `mix format` before committing (included in `make precommit`)
- Follow existing patterns in the codebase
- Use DaisyUI components and Tailwind for UI work
- All tables use UUID primary keys (`:binary_id`)

### Pre-commit Checklist

`make precommit` runs all of these, but for reference:

1. `mix compile --warnings-as-errors` — no compilation warnings
2. `mix deps.unlock --unused` — no unused dependencies
3. `mix format` — code is formatted
4. `mix sobelow --config` — no security issues
5. `mix test` — all tests pass

## Pull Requests

- Keep PRs focused on a single change
- Include a clear description of what and why
- Make sure `make precommit` passes
- Add tests for new functionality

## Project Structure

```
lib/
  reposit/           # Business logic (contexts, schemas)
  reposit_web/       # Web layer (controllers, live views, components)
test/                # Mirrors lib/ structure
priv/repo/migrations # Database migrations
```

See the full structure in [CLAUDE.md](CLAUDE.md#project-structure).

## Tech Stack

- **Elixir/Phoenix** — backend and LiveView UI
- **PostgreSQL + pgvector** — database with vector similarity search
- **DaisyUI + Tailwind** — styling
- **OpenAI** — embeddings via `req_llm`
