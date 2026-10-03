# Application Management Data and API Contract

Date: 2026-07-12  
Status: implemented locally; database migration not deployed to shared Supabase.

## Decisions

- Preserve the existing `application.application_id` identifier.
- Preserve the existing `application_status` enum, but expose only `SUBMITTED`, `UNDER_REVIEW`, `ACCEPTED`, and `REJECTED` in this module.
- Allowed transitions are `SUBMITTED -> UNDER_REVIEW|ACCEPTED|REJECTED` and `UNDER_REVIEW -> ACCEPTED|REJECTED`. Accepted and rejected are terminal.
- Enforce one application per candidate/job in both the service and `UNIQUE(job_seeker_id, job_id)`.
- Resolve candidate/employer identity only from the verified JWT.
- Resolve the candidate's primary resume on the server; application requests cannot supply seeker, employer, resume owner, or status fields.
- Store every successful status transition in `application_status_history`.
- Use the `update_application_status` PostgreSQL RPC for an atomic current-status update and history insert with optimistic concurrency.
- Store `changed_by` plus `changed_by_role`; there is no FK for `changed_by` because accounts are split across three tables.
- Do not send notifications and do not invoke DeepSeek. Existing matching data is read when available.

## Migration

`supabase/migrations/20260712153000_application_management.sql` verifies the existing application constraints and enum, adds the missing indexes/history table, and defines the atomic RPC. It must be reviewed before deployment.

## API

All endpoints require a bearer JWT.

| Method | Path | Role | Purpose |
| --- | --- | --- | --- |
| `GET` | `/api/applications/apply-context/:jobId` | Job seeker | Validate/display candidate, primary resume, job, and duplicate state. |
| `POST` | `/api/applications` | Job seeker | Submit `{ jobId, coverLetter? }`. |
| `GET` | `/api/applications/me` | Job seeker | Paginated own applications. |
| `GET` | `/api/applications/me/:id` | Job seeker | Own application detail and history. |
| `GET` | `/api/applications/employer` | Employer | Paginated applications for owned jobs. |
| `GET` | `/api/applications/employer/:id` | Employer | Review an application for an owned job. |
| `PATCH` | `/api/applications/employer/:id/status` | Employer | Atomically transition status. |

List query parameters are `page`, `limit`, `status`, `jobId`, date range, sort, and the role-appropriate keyword/candidate-name filter.

Status update body:

```json
{
  "status": "UNDER_REVIEW",
  "expectedCurrentStatus": "SUBMITTED"
}
```

The expected status is mandatory and produces HTTP 409 when another update wins the race.

## Security and response rules

- Candidate ownership failures use 404 to avoid leaking application existence.
- Employer ownership failures use the project's 403 convention.
- Duplicate applications return 409.
- Invalid/inactive/expired job, missing profile fields, missing primary resume, and invalid transitions return 400.
- Raw Supabase errors, password hashes, service secrets, and full resume content are never returned.
- Employer list results contain summary fields only. Detailed candidate/resume/matching/history data is restricted to the owned-application review endpoint.

## Deployment dependency

Backend status-history reads and status updates require the local migration to be applied after review. Until then, application creation/listing can use the existing table, but detail history and status mutation will fail because the shared database does not yet contain the history table/RPC.
