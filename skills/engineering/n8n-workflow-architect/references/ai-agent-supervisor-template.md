# Template: AI Agent Supervisor Workflow

## Goal

Run one supervisor agent that plans bounded worker tasks and validates output before any side effect.

## Node Graph

1. `Webhook` or `Schedule Trigger`
2. `Set` (normalize `job_id`, `request_id`, `goal`, `policy`)
3. `AI Agent` (supervisor planner prompt)
4. `Code` (parse/validate task plan JSON)
5. `Split In Batches` (one worker task at a time)
6. `Execute Workflow` (worker template)
7. `Merge` (collect worker outputs)
8. `AI Agent` (synthesis + confidence)
9. `Code` (schema + policy gate)
10. `IF` pass/fail
11. `HTTP Request` or `PostgreSQL` (side effect path)
12. `Slack` (summary + links)

## Required Data Contract

```json
{
  "job_id": "string",
  "goal": "string",
  "policy": {
    "max_steps": 6,
    "deadline_seconds": 300,
    "requires_human_on_low_confidence": true
  }
}
```

## Guardrails

- Timeout per worker branch.
- Retries only on transient errors.
- Hard fail to escalation path if schema validation fails twice.
