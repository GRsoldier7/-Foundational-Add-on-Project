# Template: Daily Ops Summary (AI-Assisted)

## Goal

Build a daily operational summary from multiple systems and deliver a concise executive digest.

## Node Graph

1. `Schedule Trigger` (e.g., 07:30 local)
2. `HTTP Request` / `Database` nodes (collect metrics/events)
3. `Merge` (single payload)
4. `Code` (normalize to summary schema)
5. `AI Agent` (generate executive summary + anomalies)
6. `Code` (length and schema checks)
7. `Slack` post
8. `Email` send (optional)
9. `PostgreSQL` archive digest

## Summary Schema

```json
{
  "date": "YYYY-MM-DD",
  "highlights": ["..."],
  "anomalies": ["..."],
  "actions_today": ["..."],
  "owner_followups": [{"owner": "name", "item": "string"}]
}
```

## Quality Gate

- Reject if `highlights` is empty.
- Reject if more than 3 speculative statements without data anchors.
- Include at least one recommended action when anomalies exist.
