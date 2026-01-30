---
# chorus-ipk6
title: Solution details page
status: completed
type: feature
priority: normal
created_at: 2026-01-30T15:42:03Z
updated_at: 2026-01-30T17:13:00Z
parent: chorus-dmms
---

Create a LiveView page to view full solution details including votes.

## Core Requirements
- **Speed First**: Single query for solution + recent votes. No N+1.
- **DaisyUI**: Use DaisyUI components throughout
- **Testing**: Test detail rendering, vote display

## Requirements
- Full problem description
- Full solution pattern with markdown rendering
- Tags as DaisyUI badges grouped by category
- Vote breakdown with visual indicator (DaisyUI progress or stats)
- Recent vote comments

## Checklist
- [ ] Create SolutionsLive.Show LiveView
- [ ] Preload votes in single query
- [ ] Render markdown with earmark or mdex (latest version)
- [ ] Use DaisyUI badges for tags, grouped by category
- [ ] Use DaisyUI stats or progress for vote breakdown
- [ ] Display recent comments in DaisyUI chat bubbles or cards
- [ ] Add back navigation
- [ ] Write LiveView tests
- [ ] Run `mix test --cover` and report coverage