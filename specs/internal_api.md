# Buddy-OS Internal API Spec (Dev)

This is an internal dev contract between Buddy (agent) and the local execution layer.

Transport:
- Local HTTP on 127.0.0.1
- JSON requests/responses

Port:
- 8765 (dev default)

## Endpoints

GET /health
Response:
- 200 {"ok":true,"service":"buddy-actions","version":"0.1"}

GET /providers/ollama-local/models
Response:
- 200 {"ok":true,"provider":"ollama-local","models":["qwen2.5-coder:7b", "..."]}

POST /execute
Request:
{
  "action": "mkdir|write_file|list_dir|open_url|launch_app|shell",
  "params": { ... },
  "consent": false,
  "reason": "human readable intent"
}

Response (success):
{
  "ok": true,
  "action_id": "uuid",
  "result": { ... }
}

Response (consent required):
{
  "ok": false,
  "consent_required": true,
  "message": "why consent is required",
  "action_id": "uuid"
}

Response (denied/error):
{
  "ok": false,
  "error": "string",
  "action_id": "uuid"
}

## Policy Enforcement Order
1) Resolve action category
2) Enforce access preset + category rule
3) Enforce folder allow/deny
4) Enforce consent / re-auth gates
5) Execute
6) Audit log append (redacted)
