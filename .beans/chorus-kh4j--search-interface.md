---
# chorus-kh4j
title: Search interface
status: todo
type: feature
priority: normal
created_at: 2026-01-30T15:42:03Z
updated_at: 2026-01-30T16:03:55Z
parent: chorus-dmms
---

Create a LiveView search interface for testing semantic search functionality.

## Core Requirements
- **Speed First**: Debounce input (300ms). Show loading state.
- **DaisyUI**: Use DaisyUI form components, loading indicators
- **Testing**: Test search flow, loading states, results display

## Requirements
- Text input for problem description (DaisyUI textarea)
- Tag filters with autocomplete (DaisyUI select or combobox)
- Results display with relevance scores
- Link to solution details

## Checklist
- [ ] Create SearchLive LiveView
- [ ] Use DaisyUI form components (textarea, select)
- [ ] Implement debounced search (phx-debounce="300")
- [ ] Show DaisyUI loading spinner during search
- [ ] Use DaisyUI cards for results
- [ ] Handle no results with helpful message
- [ ] Write LiveView tests for search flow
- [ ] Run `mix test --cover` and report coverage