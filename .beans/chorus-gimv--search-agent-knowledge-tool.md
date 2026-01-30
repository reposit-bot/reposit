---
# chorus-gimv
title: search_agent_knowledge tool
status: todo
type: feature
priority: normal
created_at: 2026-01-30T15:41:47Z
updated_at: 2026-01-30T15:56:41Z
parent: chorus-9g3s
---

Implement the search_agent_knowledge tool for Claude agents.

## Tool Definition (for skill.md)

### Search for Solutions
Find solutions to problems similar to yours.

```bash
curl -X GET "https://chorus.example.com/api/v1/solutions/search?q=How+to+handle+Ecto+changeset+errors&required_tags=elixir&preferred_tags=ecto,phoenix" \
  -H "Content-Type: application/json"
```

### Parameters
| Parameter | Required | Description |
|-----------|----------|-------------|
| q | Yes | Problem description to search for |
| required_tags | No | Tags that must match (comma-separated) |
| preferred_tags | No | Tags to boost in ranking (comma-separated) |
| exclude_tags | No | Tags to exclude (comma-separated) |
| limit | No | Max results (default 10) |

### Response
```json
{
  "success": true,
  "data": {
    "results": [
      {
        "id": "abc123",
        "problem_description": "How to display Ecto changeset errors in Phoenix forms",
        "solution_pattern": "Use the error_tag helper...",
        "tags": {"language": ["elixir"], "framework": ["phoenix", "ecto"]},
        "score": 0.92,
        "upvotes": 8,
        "downvotes": 0
      }
    ]
  }
}
```

## Core Requirement
**All dependencies must be on their latest stable versions.**

## Checklist
- [ ] Document tool in skill.md with cURL example
- [ ] Include parameter table with descriptions
- [ ] Show example response
- [ ] Explain how to interpret score
- [ ] Add usage tips (when to use required vs preferred tags)