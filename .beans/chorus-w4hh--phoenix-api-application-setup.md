---
# chorus-w4hh
title: Phoenix API application setup
status: in-progress
type: task
priority: normal
created_at: 2026-01-30T15:41:17Z
updated_at: 2026-01-30T16:06:47Z
parent: chorus-n2ec
blocking:
    - chorus-5kuk
    - chorus-whm4
---

Initialize a new Phoenix API application with LiveView for the web UI.

## Core Requirements
- **Speed First**: Configure for performance from the start
- **Latest Dependencies**: Verify ALL generated deps are latest (check hex.pm)
- **DaisyUI**: Ships with Phoenix - will be our UI framework
- **Testing**: Set up ExUnit with coverage reporting

## Stack
- Phoenix 1.7+ with LiveView
- DaisyUI + Tailwind (included by default)
- API endpoints under /api/v1
- LiveView for admin/browsing UI

## Checklist
- [ ] Create new Phoenix project: `mix phx.new chorus --database postgres`
- [ ] Verify all generated deps are latest versions (run `mix hex.outdated`)
- [ ] Update any outdated deps to latest
- [ ] Configure test coverage in mix.exs (`test_coverage: [tool: ExCoveralls]` or built-in)
- [ ] Set up basic health check endpoint `GET /api/health`
- [ ] Verify LiveView works with a simple test page
- [ ] Verify DaisyUI components render correctly
- [ ] Add DaisyUI.md reference file to project root for LLM context
- [ ] Run `mix test --cover` and report baseline coverage
- [ ] Commit with all deps on latest versions