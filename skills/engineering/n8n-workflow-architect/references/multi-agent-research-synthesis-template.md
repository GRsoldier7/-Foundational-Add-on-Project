# Template: Multi-Agent Research + Synthesis

## Goal

Run parallel specialized research workers and merge their findings into one verified briefing.

## Node Graph

1. `Manual Trigger` or `Webhook`
2. `Set` (topic + required sections)
3. `Code` (build worker task array)
4. `Split In Batches` (parallel mode)
5. `Execute Workflow` (worker: web/API/source retrieval)
6. `Merge` (all worker findings)
7. `AI Agent` (synthesize with citation slots)
8. `Code` (citation completeness check)
9. `IF` complete/incomplete
10. `Slack` + `Notion`/`Docs` write

## Worker Specializations

- Market/competitive scan
- Technical feasibility scan
- Risk/compliance scan
- Cost/time estimate scan

## Output Contract

```json
{
  "summary": "string",
  "key_findings": ["..."],
  "risks": ["..."],
  "citations": [
    {"source": "url-or-doc-id", "claim": "string"}
  ]
}
```

Reject output if citations are empty for factual claims.
