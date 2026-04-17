# Template: Event Triage + Auto-Remediation

## Goal

Classify incoming incidents and trigger safe automated remediation for known cases.

## Node Graph

1. `Webhook` (monitoring alert ingress)
2. `Set` (normalize severity + source + fingerprint)
3. `Code` (dedupe via fingerprint TTL cache)
4. `AI Agent` (triage classify: known/unknown/critical)
5. `Switch` on class
6. `Execute Workflow` known remediation
7. `Execute Workflow` unknown escalation
8. `Slack` + `Email` status update
9. `PostgreSQL` incident log

## Known Remediation Examples

- Restart unhealthy container
- Clear stuck queue consumer
- Rotate temporary API token
- Re-run failed scheduled sync

## Safety Conditions

- Require severity threshold before destructive remediation.
- Require idempotency key to prevent repeat actions.
- Stop after one remediation attempt, then escalate.
