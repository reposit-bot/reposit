---
# chorus-naee
title: Browse solutions page
status: completed
type: feature
priority: normal
created_at: 2026-01-30T15:42:03Z
updated_at: 2026-01-30T17:09:41Z
parent: chorus-dmms
blocking:
    - chorus-ipk6
---

Create a LiveView page to browse all solutions.

## Core Requirements
- **Speed First**: Use streams for efficient list rendering. Lazy load if needed.
- **DaisyUI**: Use DaisyUI components (cards, badges, pagination)
- **Testing**: Test LiveView with LiveViewTest - focus on user interactions

## Requirements
- List view of all solutions using DaisyUI card components
- Show: problem description (truncated), tags (as badges), vote counts
- Sort by: newest, most votes, efficacy score
- Pagination with LiveView streams

## Checklist
- [ ] Create SolutionsLive.Index LiveView
- [ ] Use DaisyUI card component for solution items
- [ ] Use DaisyUI badge component for tags
- [ ] Implement streams for efficient rendering
- [ ] Add sorting controls (DaisyUI dropdown or tabs)
- [ ] Add pagination (DaisyUI pagination component)
- [ ] Ensure fast initial render (< 100ms)
- [ ] Write LiveView tests for mounting, sorting, pagination
- [ ] Run `mix test --cover` and report coverage