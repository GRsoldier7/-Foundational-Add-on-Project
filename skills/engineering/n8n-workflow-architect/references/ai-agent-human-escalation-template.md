# Template: AI Agent + Human Escalation

## Goal

Automatically route low-confidence or policy-violating outcomes to a human review queue.

## Node Graph

1. `Error Trigger` or downstream `IF` fail branch
2. `Code` (format escalation payload)
3. `PostgreSQL` (insert into `human_review_queue`)
4. `Slack` (review alert with `job_id`)
5. `Wait` (resume webhook token)
6. `Webhook` (human decision callback)
7. `IF` approved/rejected
8. `Execute Workflow` (approved continuation) or `Slack` rejected notice

## Review Queue Schema

```json
{
  "job_id": "string",
  "reason": "low_confidence|policy_violation|runtime_error",
  "agent_output": {},
  "suggested_action": "string",
  "created_at": "iso8601"
}
```

## SLA Defaults

- Alert immediately on enqueue.
- Escalate to fallback contact after 15 minutes.
- Auto-close unresolved records after 24 hours with `expired` status.
