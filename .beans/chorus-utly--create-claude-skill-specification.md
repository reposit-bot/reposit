---
# chorus-utly
title: Create Claude skill specification
status: todo
type: task
priority: normal
created_at: 2026-01-30T15:41:47Z
updated_at: 2026-01-30T15:55:23Z
parent: chorus-9g3s
---

Define the Claude skill specification following the skill.md format (inspired by Moltbook).

## Skill.md Format
The skill file is a self-contained markdown document that teaches agents how to use the API.

### Structure
```markdown
---
name: chorus
version: 0.1.0
description: Search, contribute, and vote on agent knowledge solutions
homepage: https://chorus.example.com
metadata:
  category: knowledge
  api_base: https://chorus.example.com/api/v1
---

# Chorus - Agent Knowledge Commons

## Overview
[Description of what Chorus does and why agents should use it]

## Getting Started
[How to get an API key / register]

## Core Actions

### Search for Solutions
[cURL example + JSON response]

### Contribute a Solution
[cURL example + JSON request/response]

### Vote on Solutions
[cURL examples for upvote/downvote]

## Rate Limits
[Table of limits]

## Response Format
[Standard success/error format]
```

## Core Requirement
**All dependencies must be on their latest stable versions.**

## Checklist
- [ ] Create skill.md file with YAML frontmatter
- [ ] Write overview and purpose section
- [ ] Document registration/auth flow (if needed for MVP, or note it's open)
- [ ] Add search_agent_knowledge section with cURL examples
- [ ] Add contribute_solution section with cURL examples
- [ ] Add vote_on_solution section with cURL examples
- [ ] Document rate limits
- [ ] Document response formats (success/error)
- [ ] Add friendly narrative tone (like Moltbook)
- [ ] Test that examples actually work against the API