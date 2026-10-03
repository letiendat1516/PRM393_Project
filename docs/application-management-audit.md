# Application Management Audit

Audit date: 2026-07-12  
Scope: repository documentation, manifests and lock files, environment templates, source structure, client/server boundaries, authentication, Supabase initialization, HTTP pipeline, application-management layers, database documentation/live schema, generated types, tests, and project commands.

## Executive summary

JobHub follows a documented React -> Express Controller -> Service -> Repository -> Supabase architecture. Authentication is custom JWT authentication backed by the `job_seeker`, `employer`, and `admin` tables; Supabase Auth is intentionally not used.

The application-management feature is not implemented yet. Its routes and frontend service exist, but every backend controller, service, and repository method throws HTTP 501. The live `application` table exists and currently contains zero rows.

The highest-priority issue for future application-management work is authorization. None of the four `/api/applications` routes currently uses `authenticate`, `authorize`, or request validation. This does not expose application data today because every handler stops at 501, but it becomes a critical access-control vulnerability as soon as persistence is implemented.

No application code was changed during this audit. Only this document was added.

## Sources reviewed

- Root and workspace `package.json`/lock files.
- `README.md` and all non-empty documents relevant to architecture, database, modules, migrations, and agent rules.
- Backend configuration, server/app assembly, middleware, routes, controllers, services, repositories, validators, utilities, AI integration, and existing tests.
- Frontend routing, auth context, API client, service modules, Supabase client, application modal, and application entry points.
- Local `supabase/config.toml`, including ignored-file inspection.
- Live Supabase PostgREST schema and all rows exposed in the public schema, using the backend secret in read-only requests. Row values and secrets are intentionally not reproduced here.

Two documentation files named by the repository rules are empty: `docs/03_BACKEND_STRUCTURE.md` and `docs/04_FRONTEND_STRUCTURE.md`. `docs/05_UI_GUIDELINES.md` is also empty.

## Repository and package state

### Root

The root manifest contains only the Supabase CLI development dependency (`supabase` 2.109.1). It has no scripts. The root lock file uses lockfile version 3 and records 16 packages.

### Backend

- Runtime: Node.js >= 20, Express 4, ECMAScript modules.
- Data client: `@supabase/supabase-js` 2.45.x.
- Auth/security: `bcryptjs`, `jsonwebtoken`, Helmet, CORS, and Express rate limiting.
- Validation/logging: Zod and Pino.
- Test runner: Vitest.
- Backend lock file: lockfile version 3, 302 package entries.
- `backend/node_modules` was absent during the audit, so backend commands were not executed.

### Frontend

- React 18 + Vite 5 + React Router 6.
- Axios is the normal backend API transport.
- Tailwind, Framer Motion, and PDF.js are included.
- A browser Supabase client dependency also exists.
- Frontend lock file: lockfile version 3, 409 package entries.
- There is no TypeScript configuration or typecheck script.

### Existing working tree

The repository was already dirty before this document was created. Existing changes include backend/root manifest and lock-file changes plus untracked root `package.json` and `supabase/`. Those changes were treated as user-owned and were not modified by this audit.

## Environment templates

`backend/.env.example` documents server, JWT, Supabase, DeepSeek, and logging variables. It correctly keeps the service secret in the backend template, but it contains the real project URL and publishable key rather than placeholders. Publishable keys are designed for client use, but placeholders are still preferable in a reusable template.

`frontend/.env.example` currently documents only `VITE_API_BASE_URL`. The implemented `frontend/src/lib/supabase.js` additionally requires `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY`, so the example does not fully describe the frontend runtime contract.

The real `.env` files are Git-ignored. Secret values were not copied into this report.

## Source structure and boundaries

### Backend request flow

`backend/src/server.js` validates production-required environment variables, imports the Express app, starts the HTTP server, and handles SIGTERM/SIGINT shutdown.

`backend/src/app.js` assembles the pipeline in this order:

1. Disable `x-powered-by` and apply Helmet.
2. Apply configured CORS with credentials.
3. Apply a global 15-minute rate limit.
4. Parse JSON and URL-encoded bodies up to 10 MB.
5. Attach Pino request logging.
6. Serve `/health` and mount the API at `/api`.
7. Apply the 404 and centralized error handlers.

Routes call controllers, controllers call services, and implemented services call repositories. Auth, employer, and job repositories use Supabase. Several later-phase modules remain explicit 501 scaffolds.

### Frontend boundary

`frontend/src/services/apiClient.js` is the intended single HTTP gateway. It uses `/api` by default, attaches the JWT from `localStorage`, enables credentials, and normalizes the backend error envelope.

Most components follow the service boundary. The separate `frontend/src/lib/supabase.js` creates a browser Supabase client directly. No other frontend source currently imports or queries that client, so it is presently unused. Its existence conflicts with the architectural rule that presentation communicates only with the REST backend; it should not become an application-data access path without an explicit architecture decision and RLS design.

## Authentication flow

1. Registration/login requests enter `/api/auth` and are validated with Zod for the implemented endpoints.
2. `AuthService` searches all three account tables through `AuthRepository`.
3. Passwords are hashed/verified with bcrypt using 10 salt rounds.
4. The backend signs a JWT containing `sub`, `role`, `email`, `name`, `created_at`, and `remember`.
5. The frontend stores the token as `jobhub.accessToken` in `localStorage`.
6. The Axios request interceptor sends it as `Authorization: Bearer <token>`.
7. `authenticate` verifies the token and assigns the decoded principal to `req.user`.
8. `authorize(...roles)` enforces role membership when a route actually mounts it.
9. `AuthContext` restores sessions through `GET /auth/me`, removes the token on 401/403, and retries transient failures up to three times.

Notable findings:

- Supabase Auth is not involved.
- Access and “remember me” sessions are both stateless JWTs. There is no refresh-token persistence or revocation mechanism.
- Logout is client-side token deletion only.
- The routes for logout, refresh, forgot/reset password, and change password reference controller methods that do not exist. Requests reach an `asyncHandler` wrapper and fail at runtime instead of returning an intentional 501.
- `change-password` is not authenticated or validated at the route level.
- The JWT secret has a development fallback. Production validation prevents a missing production secret, but accidental non-production deployment would use the known fallback.
- Browser `localStorage` makes tokens accessible to any successful XSS payload; the current design relies heavily on preventing script injection.

## Supabase initialization

The backend configuration loads `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY`. `backend/src/config/supabase.js` lazily creates a singleton client using the service secret with session persistence and token refresh disabled. Missing credentials return `null` with a warning rather than failing in development.

The client is currently consumed by `AuthRepository`, `EmployerRepository`, `JobRepository`, and the AI logger. Resume, application, recommendation, and job-seeker repositories are still scaffolds.

Because the backend uses a service secret, its queries bypass normal RLS protections. Correct authorization must therefore be enforced before repository calls; database RLS cannot compensate for missing Express authorization in this path.

## Middleware audit

| Middleware | Purpose | Audit note |
| --- | --- | --- |
| `authenticate` | Verify bearer JWT and populate `req.user` | Appropriate, but not mounted on application routes. |
| `authorize` | Role-based access control | Appropriate, but coverage is inconsistent across route modules. |
| `validateRequest` | Parse/normalize bodies with Zod | No application validator exists or is mounted. |
| `errorHandler` | Normalize errors and hide non-operational 500 details | Development responses include stack traces by design. |
| `notFoundHandler` | Convert unmatched paths to a standard 404 | Correctly mounted last before error handling. |
| Helmet/CORS/rate limiter | General HTTP hardening | Global rate limiting exists; application-specific abuse limits do not. |

## Routes, controllers, services, and repositories

The API aggregator mounts auth, jobs, employers, resumes, applications, and recommendations. Job and employer modules contain meaningful implementations. Resume, application, and portions of recommendation/job-seeker functionality remain scaffolds.

### Application route surface

| Method and path | Intended actor | Current handler | Current protection |
| --- | --- | --- | --- |
| `POST /api/applications` | Job seeker | `ApplicationController.applyJob` -> 501 | None |
| `GET /api/applications/me` | Job seeker | `ApplicationController.getMyApplications` -> 501 | None |
| `GET /api/applications/:id` | Owner job seeker or owning employer | `ApplicationController.getApplicationById` -> 501 | None |
| `PATCH /api/applications/:id/status` | Employer owning the job | `ApplicationController.updateApplicationStatus` -> 501 | None |

`ApplicationService` declares the expected use cases—submission, candidate listing, lookup, and employer status changes—but all methods throw 501. `ApplicationRepository` similarly declares create/find/list/update operations but performs no database calls.

The frontend `applicationService` exposes only apply and “my applications.” It is not called by the current application modal. `ApplyModal` uses mock CV data and delegates submission to an `onSubmit` callback. Job cards/detail/list items open this presentation-only modal, so no application is persisted.

### Required implementation safeguards

Before application persistence is enabled:

- Require `authenticate` + `authorize('job_seeker')` for submit and candidate listing.
- Require authentication for lookup and enforce record ownership in the service.
- Require `authenticate` + `authorize('employer')` for employer status changes, then verify that the application’s job belongs to that employer.
- Add Zod schemas for application submission, route IDs, pagination/filter queries, and status updates.
- Derive `job_seeker_id`/`employer_id` from `req.user.sub`; never accept actor IDs from the request body.
- Validate that the job exists, is approved/open, and is before its deadline.
- Validate that the selected resume belongs to the authenticated candidate.
- Use the database unique constraint to prevent duplicate applications and map unique violations to HTTP 409.
- Define an explicit status-transition matrix and separate candidate withdrawal from employer decisions.
- Avoid exposing `password_hash`, private resume paths, AI prompts, or unrelated applicant data in joined responses.
- Add pagination, deterministic ordering, and audit/history semantics before status management is considered complete.

## Database audit

### Local database artifacts

There is no `supabase/migrations/` directory and no checked-in SQL migration history. `supabase/` contains only CLI configuration and its own ignore file.

`docs/08_DATABASE.md` is the baseline DDL and defines enums, 17 tables, foreign keys, triggers, indexes, and the application uniqueness constraint. `docs/11_MIGRATIONS.md` contains three manually applied follow-up migrations for employer fields and AI matching logs. The documented workflow instructs developers to paste SQL into the Supabase SQL Editor, which makes reproducibility and environment drift difficult to verify.

No generated Supabase database types were found. The project is JavaScript-only, and there is no `database.types.ts`, schema snapshot, or equivalent generated contract.

### Live public schema and data

The live PostgREST schema was successfully read. All exposed rows in every table were fetched read-only; the table counts below reflect the live project at audit time. Sensitive values were not retained in this document.

| Table | Rows | Live columns |
| --- | ---: | --- |
| `admin` | 1 | `admin_id`, `full_name`, `email`, `password_hash`, `created_at` |
| `ai_analysis` | 0 | `analysis_id`, `resume_id`, `summary`, `extracted_skills`, `total_experience_years`, `education_level`, `raw_text`, `model_version`, `analyzed_at` |
| `ai_matching_log` | 83 | `log_id`, `job_seeker_id`, prompt/response/model/token/timing/result fields |
| `application` | 0 | `application_id`, `job_seeker_id`, `job_id`, `resume_id`, `cover_letter`, `application_date`, `status`, `updated_at` |
| `category` | 1 | `category_id`, `name` |
| `education` | 0 | `education_id`, `job_seeker_id`, school/degree/major/year fields |
| `employer` | 1 | identity, company profile, verification/activity, contact, and timestamp fields |
| `job` | 1 | employer/category IDs, job detail, salary, location/type/status, deadline, approval, and timestamps |
| `job_recommendation` | 0 | recommendation, seeker/job/resume IDs, score/reason/status/time |
| `job_seeker` | 1 | identity, profile, verification/activity, and timestamp fields |
| `job_seeker_skill` | 0 | seeker/skill IDs, experience, detail, source |
| `job_skill` | 2 | job/skill IDs, requirement, experience, weight |
| `notification` | 1 | recipient IDs, type/title/message/read/time |
| `resume` | 0 | resume/seeker IDs, title, file metadata, primary flag, upload time |
| `saved_job` | 0 | seeker/job IDs and saved time |
| `skill` | 2 | `skill_id`, `skill_name`, timestamps |
| `work_experience` | 0 | experience/seeker IDs, company/position/date/description fields |

The live application schema matches the documented core shape. Its status type is `public.application_status`, documented as `SUBMITTED`, `UNDER_REVIEW`, `INTERVIEW`, `OFFER`, `ACCEPTED`, `REJECTED`, `WITHDRAWN`. The DDL also defines:

- Foreign keys to job seeker, job, and resume.
- Cascading deletion from seeker/job and `SET NULL` for a deleted resume.
- `UNIQUE (job_seeker_id, job_id)`.
- An `updated_at` trigger.
- Indexes on `job_seeker_id` and `job_id`.

### Database risks and drift

- Manual SQL documents are not an executable migration history.
- No generated types protect column names or enum values at build time.
- The service-secret backend bypasses RLS, magnifying route/service authorization mistakes.
- The frontend Supabase client could become a second, inconsistent data-access boundary.
- Application status history is not modeled; only the latest status is stored.
- The unique constraint prohibits reapplication forever, even after withdrawal/rejection. Confirm that this is the intended business rule.
- Deleting a job cascades and permanently deletes all its applications, which may conflict with audit/reporting requirements.
- `resume_id` becomes null when a resume is deleted, so historical applications lose the exact submitted document reference unless a snapshot/file-retention policy is added.
- AI matching logs contain full prompts/responses and currently have 83 rows. These may contain CV/PII and need retention/access/redaction rules.

## Existing tests

Only `backend/tests/health.test.js` exists. It asserts `true === true`; it does not import the app or test `/health`. There are no frontend tests and no application, auth, middleware, repository, database-integration, or authorization tests.

Minimum application-management coverage should include:

- Unauthenticated and wrong-role requests are rejected.
- Candidate/resume ownership and employer/job ownership.
- Duplicate submission conflict handling.
- Closed/unapproved/expired job rejection.
- Valid and invalid status transitions.
- Candidate/employer response field filtering.
- Database error mapping and pagination.
- Route-level integration tests against the Express app.

## Lint, test, typecheck, and build commands

Run commands from the relevant workspace because the root manifest has no scripts.

Backend:

```bash
cd backend
npm ci
npm run lint
npm run format:check
npm test
npm run dev
npm start
```

Frontend:

```bash
cd frontend
npm ci
npm run lint
npm run format:check
npm run build
npm run dev
npm run preview
```

There is no typecheck command because the repository contains no TypeScript/`tsconfig`. The frontend has a production build command; the backend has no build step and runs source JavaScript directly. These commands were not executed during this audit because the backend dependencies were not installed and the request was for a read-only code audit rather than dependency installation.

## Prioritized findings

### P0 — must be fixed before enabling applications

1. Protect every application route with authentication and role authorization.
2. Enforce candidate/resume and employer/job ownership in the service layer.
3. Add request validation and an explicit application status-transition policy.

### P1 — important correctness/security work

1. Replace manual SQL-only evolution with checked-in Supabase migrations and generate database types/schema contracts.
2. Decide retention behavior for applications when jobs/resumes are deleted and whether reapplication should be possible.
3. Add meaningful auth/application integration tests.
4. Remove or deliberately govern the unused frontend Supabase data path.
5. Implement auth scaffold endpoints deliberately or stop advertising undefined handlers.

### P2 — maintainability/documentation

1. Fill the empty backend/frontend structure documents.
2. Update the README phase table, which still describes authentication and later features as pending despite partial implementations.
3. Complete `frontend/.env.example` with the variables required by the existing frontend Supabase initializer, or remove that initializer if the REST-only boundary remains authoritative.
4. Add root workspace scripts if the team expects lint/test/build to run from the repository root.

## Readiness conclusion

The database foundation for application management exists, but the feature is not ready for use. The current UI is a demo surface, the backend returns 501 throughout the application stack, and the live table is empty. Implementation can build cleanly on the existing layered seams, provided authorization, ownership checks, validation, migration reproducibility, and tests are treated as prerequisites rather than follow-up hardening.
