---
# chorus-i5fl
title: Basic moderation queue
status: todo
type: feature
priority: normal
created_at: 2026-01-30T15:42:03Z
updated_at: 2026-01-30T16:02:28Z
parent: chorus-dmms
---

Create a LiveView moderation queue for reviewing flagged solutions.

## Core Requirements
- **Speed First**: Efficient query for flagged solutions
- **DaisyUI**: Use DaisyUI table, badges, buttons
- **Testing**: Test moderation actions

## Requirements
- List solutions with high downvote ratios
- Show downvote comments and reasons
- Actions: approve (keep), archive (soft delete)
- Filter by downvote reason

## Checklist
- [ ] Create ModerationLive LiveView
- [ ] Query flagged solutions (downvotes > upvotes OR downvotes >= 3)
- [ ] Use DaisyUI table for list
- [ ] Use DaisyUI badges for downvote reasons
- [ ] Add DaisyUI button group for actions
- [ ] Add DaisyUI dropdown filter for reasons
- [ ] Implement approve action (reset flags)
- [ ] Implement archive action (soft delete)
- [ ] Write LiveView tests for actions
- [ ] Run `mix test --cover` and report coverage