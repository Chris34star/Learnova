# Learnova

Learnova is a multi-tenant EdTech MVP for governed school learning, deterministic mastery, explainable recommendations, contextual Nuru tutoring, project-first Skills Lab pathways, and evidence-aware teacher/school intelligence. It is intended for a **small controlled pilot after a deployed staging acceptance run**, not an unrestricted production launch.

## Architecture and technology

- **Browser:** React 18, TypeScript, Vite, React Router, Tailwind CSS, and role-protected route trees.
- **Backend:** Supabase Auth, PostgreSQL, RLS, narrowly authorized RPCs, and a Deno Edge Function.
- **Tenancy:** an active backend `profiles` row is the authority for role and `school_id`; clients do not choose either. Tenant tables use RLS and caller-derived helper functions.
- **Content:** global or school-scoped courses and nodes, school adoption by reference, node-level overrides, versioning, and draft → review → approval → publication governance. Students receive only approved, published, available content.
- **Learning:** learning sessions and persisted node progress remain separate from assessment evidence. The deterministic mastery update uses correctness, difficulty, hint use, recent consistency, and evidence count; confidence rises with evidence.
- **Discovery:** interests, prerequisites, availability, graph relationships, and teacher recommendations produce stored human-readable reasons.
- **Nuru:** the browser sends resource identifiers; PostgreSQL assembles bounded approved context and derives learning/practice/assessment/project mode. The authenticated Edge Function enforces origin allowlisting, tenant context, rate limits, assessment hint rules, provider timeout handling, and generic user errors.
- **Skills Lab:** governed pathways lead to project milestones, revision/approval review, moderate project skill evidence, and a private student portfolio.
- **Intelligence:** aggregate RPCs compute completion and understanding separately, suppress confident support labels at low evidence, and build explainable daily plans. Study duration guides scheduling only; exam mode changes priorities, not mastery.

## Roles

| Role | Authority |
|---|---|
| Platform admin | Creates schools and governs global content/pathways. Provisioned only through a trusted backend/dashboard. |
| School admin | Manages their school, people, settings, adoption, review/publication, pathways, schedules, and aggregate analytics. |
| Teacher | Accesses assigned classes/students, authors drafts, assigns/recommends learning, records interventions, and reviews authorized projects. |
| Student | Accesses only their available learning, attempts, progress, plan, projects, recommendations, Nuru context, and private portfolio. |

## Major routes

- Public/auth: `/`, `/demo`, `/launch`, `/login`, `/forgot-password`, `/reset-password`
- Student: `/app`, `/app/learn`, `/app/course/:courseId`, `/app/lesson/:lessonId`, `/app/practice`, `/app/progress`, `/app/schedule`, `/app/explore`, `/app/interests`, `/app/skills`, `/app/skills/:pathwayId`, `/app/project/:studentProjectId`, `/app/portfolio`
- Teacher: `/teacher`, `/teacher/classes`, `/teacher/classes/:classId/insights`, `/teacher/students/:studentId`, `/teacher/content`, `/teacher/projects`, `/teacher/recommend`
- School admin: `/school`, `/school/onboarding`, `/school/content`, `/school/content/review`, `/school/pathways`, `/school/schedule`, `/school/analytics`, `/school/settings`
- Platform admin: `/platform`, `/platform/schools`, `/platform/content`, `/platform/content/proposals`, `/platform/pathways`

## Database, security, and privacy

Apply every timestamped file in `supabase/migrations` in order. They are the source of truth for schema, constraints, indexes, triggers, functions, and RLS; do not maintain unrecorded production SQL. The Stage 12 migration closes teacher publication and tenant-rebinding gaps, restricts sensitive RPC execution to authenticated callers, bounds important inputs, and adds indexes matching pilot query paths.

Assessment answer keys remain in protected base tables. Students receive the `student_question_bank` projection through caller-owned RPCs, without `answer_data_json`, option correctness, or explanations; grading occurs in `submit_question_answer`, which locks and verifies the student's active attempt before returning post-answer feedback. Nuru secrets and the Supabase service-role key exist only in the Edge Function environment.

Stored MVP data includes accounts/profile membership, school configuration, governed content, learning progress/events, assessment attempts, mastery evidence, interests/recommendations, Nuru interactions/feedback, project submissions, and teacher feedback/interventions. Do not add biometrics, fingerprinting, private-life profiling, sensitive-trait inference, public student profiles, leaderboards, or cross-school comparisons. Nuru transcripts are student-private; educators receive aggregates rather than full conversations.

## Local setup and environment variables

```bash
npm ci
cp .env.example .env.local
npm run dev
```

Only these public browser variables are supported:

| Variable | Environment | Secret? |
|---|---|---|
| `VITE_SUPABASE_URL` | local/staging/production browser build | No |
| `VITE_SUPABASE_ANON_KEY` | local/staging/production browser build | No; still protect data with RLS |

Set these only in Supabase Edge Function secrets: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `OPENAI_API_KEY`, optional `NURU_AI_MODEL`, and comma-separated `ALLOWED_ORIGINS`. Production must set `ALLOWED_ORIGINS`; its fallback permits only local Vite origins. Use separate Supabase projects and credentials for development, pilot/staging, and production. Never commit `.env*` files or place privileged keys in `VITE_*` variables.

## Testing

```bash
npm run typecheck
npm run lint
npm test
npm run build
```

The automated suites cover schema/governance contracts, learning, deterministic assessment/mastery cases, recommendations, Nuru restrictions, Skills Lab/projects, intelligence/scheduling, and Stage 12 security regressions. They are mostly deterministic contract tests; they do **not** replace a real hosted two-tenant RLS attack test or browser journey.

### MVP acceptance matrix (repository verification, 2026-09-04)

`PASS` means exercised by an automated contract/build check; `PARTIAL` means code/schema inspection passed but a configured hosted journey remains required.

| Area | Status | Evidence / remaining check |
|---|---|---|
| Authentication, session, role routing | PARTIAL | Protected/role routes and recovery exist; hosted email, expiry, refresh, and redirect flow pending. |
| Pilot onboarding | PARTIAL | School/people/class/settings UI exists; trusted Auth-user provisioning remains manual. |
| Multi-tenancy and roles | PARTIAL | RLS/policies and caller-derived RPC authorization inspected/hardened; live School A → School B token attacks pending. |
| Content governance / teacher creation | PASS | Draft/review/publish boundaries and tenant/author checks covered by schema contracts. |
| Global content / adoption / overrides | PASS | Reference/override resolution and published-content contracts pass. |
| Question bank / answer protection | PASS | Normalization, uniqueness, published projection, owned server grading, and duplicate-submit constraint verified. |
| Learning, lesson progress, assessments | PASS | Persistence and assessment contracts pass. |
| Mastery / confidence / targeted practice | PASS | Deterministic behavioral suite covers low evidence, sustained evidence, setbacks, recovery, and progress separation. |
| Recommendations / interests / prerequisites | PASS | Availability, graph, cycle, and explainable-reason cases pass. |
| Nuru tutoring / assessment restrictions | PASS | Server-derived mode, minimized context, hint restrictions, auth/rate/CORS/timeout contracts pass. Live provider call pending. |
| Skills Lab / pathways / projects / review / portfolio | PASS | Ownership, availability, milestones, idempotent start, submission/review, evidence, and privacy contracts pass. |
| Teacher intelligence / interventions | PASS | Assigned-class auth, evidence threshold, explanation, and intervention contracts pass. |
| Daily plan / schedules / exam mode | PASS | Priority, reason, duration/mastery separation, expiry-date, and tenant contracts pass. |
| School analytics / empty state | PASS | Aggregate authorization and zero-safe calculations covered by contracts. |
| Error handling / observability | PASS | Recoverable UI patterns plus structured Nuru events, request IDs, generic errors, and provider failure handling inspected. |
| Mobile behavior | PARTIAL | Responsive layouts inspected; physical/mobile browser matrix pending. |
| Accessibility | PARTIAL | Semantic labels/focus patterns inspected; keyboard and assistive-technology browser audit pending. |
| Production deployment | PARTIAL | Production build and static headers pass; no deployment credentials/domain were available for remote smoke testing. |

## Pilot deployment runbook

1. Create isolated pilot and production Supabase projects. Review the selected Supabase plan's current backup/PITR capability in its dashboard; enable the required retention before admitting real data. Do not claim point-in-time recovery unless shown as enabled.
2. Link the CLI and run `supabase db push`; verify the migration table contains every committed migration. Deploy `nuru-tutor`, configure server-only secrets, and set the exact HTTPS pilot origin in `ALLOWED_ORIGINS`.
3. Configure Supabase Site URL and redirect URLs, including `/reset-password`. Deploy `dist` on the existing static host with SPA fallback and the supplied `public/_headers`; verify the host actually applies those headers and HTTPS.
4. Provision only synthetic accounts first: platform admin; Greenfield Academy with Peter Mwangi (school admin), Ms. Wanjiku (teacher), and Amani Njoroge (student); and separate Horizon Academy admin/teacher/student accounts.
5. Using real user JWTs (never SQL editor/service role), attack cross-school IDs for profiles, classes, adoptions, attempts, projects, interventions, and analytics. Test student access to another student, draft content, raw questions/options, teacher/school analytics; teacher access to an unassigned class/student and direct publish; admin access to Horizon from Greenfield; and unauthenticated RPC/Edge access. Every operation must be denied.
6. Execute complete student, teacher, school-admin, and content-governance journeys, including refresh/resume, double clicks, empty school, 30–50-student class analytics, provider outage, common mobile widths, keyboard-only navigation, and browser network inspection for answer keys/secrets.
7. Smoke-test the deployed URL: auth, dashboard, lesson/save, practice/assessment, Nuru, teacher intelligence, Skills Lab/project/review, and school analytics. Record request IDs for failures and inspect Supabase Edge/Postgres logs.

### Backup and recovery

- Database backup retention and PITR vary by Supabase plan and must be confirmed/enabled in the production dashboard. Record the plan, retention, recovery point objective, and recovery time expectation in the pilot operations record.
- Migrations and application code are preserved in Git. Take a pre-release logical backup where the selected plan/process supports it, and rehearse restoration into a separate project before pilot launch.
- No application-managed file storage is currently used. If storage is introduced, configure and test a separate bucket backup/export process; database backups do not by themselves prove object recovery.
- Recovery order: contain writes, preserve logs/request IDs, restore/clone the database, apply any later committed migrations, redeploy Edge Functions/client, then run the synthetic smoke and tenant-isolation matrix before reopening access.

## Production health

Use hosting deployment alerts plus Supabase database/Auth/Edge Function logs. Nuru emits structured `nuru_success`, `nuru_unauthorized`, `nuru_context_denied`, and `nuru_failure` events with timestamp and request ID while avoiding prompt/context logging. Configure a simple alert for repeated function 5xx/provider failures and review auth/database errors during the controlled pilot. Do not add a large observability platform until pilot evidence warrants it.

## Known MVP limitations

- Hosted RLS attacks, provider-backed Nuru, email delivery, production auth redirects, domain/HTTPS/header verification, and deployed smoke tests cannot be completed from this repository without pilot infrastructure and credentials; these are launch gates.
- Auth-user creation remains a trusted Supabase-dashboard/operations step; the school onboarding UI configures application records rather than administering Auth identities.
- No parent portal, public portfolio, leaderboard, cross-school benchmarking, team projects, certificates, offline editing, or file uploads.
- Initial Skills Lab pathways are limited. Question duplicate detection is normalized/exact rather than semantic. Mastery intentionally uses explainable deterministic rules, not opaque ML.
- Assignment management is a thin MVP surface. Nuru depends on an external provider and degrades gracefully when unavailable.

See `SUPABASE_SETUP.md` for provisioning details. The next development decision should follow observed pilot feedback; there is no planned Stage 13.
