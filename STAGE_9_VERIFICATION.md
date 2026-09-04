# Stage 9 — Nuru Learning Assistant Verification

## Architecture and security

Nuru is an embedded learning surface, not a chat route. `NuruLearningAssistant` owns the compact floating composer while its structured answer renders in the lesson, practice, or Explore workspace. The browser submits identifiers only. The `nuru-tutor` Edge Function authenticates the JWT and calls `nuru_build_context`; that security-definer boundary verifies the active student, tenant, publication, school enablement, effective school override, delivered assessment question, and stored recommendation. A client-supplied mode is neither accepted nor read.

`TutorAIProvider` separates tutoring operations from the OpenAI adapter. Provider credentials exist only as Edge Function environment variables. System policy treats both lesson content and student text as untrusted, demands concise structured JSON, and prohibits assessment answers. Output is allow-listed and length-limited before return and logging. No reasoning trace is stored.

## Learning context

The builder selects only request-relevant data: student ID/grade, school ID and Nuru settings; effective course/lesson and up to 6,000 characters of approved content; active attempt and delivered question; scoped mastery evidence; or the authorized RecommendationEngine reason. It does not load a student's entire history. `student_course_nodes` supplies a published school override in preference to its global source.

## Integrations

- **Lessons:** simplify, explain, another example, review prompts, and contextual workspace answers.
- **Practice:** progressive hint levels; before submission, answer-like example/mistake requests become hints. After submission, the approved explanation is available for mistake help.
- **Assessment:** active server-side non-practice attempts force `assessment` mode. Examples, practice generation, and mistake requests are restricted; school-configured hint availability and maximum level apply.
- **Mastery:** score, confidence, and evidence count are supplied so low evidence can be described uncertainly and gaps supportively.
- **Explore:** Nuru can explain only an existing available recommendation reason and neutrally help compare school-approved options.
- **Temporary practice:** separate expiring `nuru_temporary_practice` storage is explicitly typed `temporary_ai_practice`; it has no path into published `questions`.
- **Feedback and insight:** own-interaction feedback uses a server-authorized RPC. Educators receive topic/category counts only via `nuru_usage_summary`, never private transcripts.

## Cost and resilience controls

Questions are capped at 600 characters, approved context at 6,000 characters, responses at 1,200 characters/350 provider tokens, follow-ups at three, and usage at a configurable rolling ten-minute limit (default 12). Provider errors return 503 without affecting lesson state; the UI distinguishes rate limit, network, and retry states.

## Functional verification report

| # | Scenario | Result | Evidence |
|---|---|---|---|
| 1 | Linear Equations contextual explanation in workspace | PASS | Effective lesson title/content is server-loaded; response surface is inline. |
| 2 | School override | PASS | `student_course_nodes` resolves the approved published school version. |
| 3 | Active graded assessment | PASS | Backend coerces answer-like actions to conceptual hints. |
| 4 | Frontend mode tampering | PASS | Request has no mode field; database derives it from the owned active attempt. |
| 5 | Wrong answer | PASS | Approved explanation is exposed only after a recorded attempt. |
| 6 | Hint ladder | PASS | `hint_level` increments, is capped server-side, and is logged. |
| 7 | Mastery at 42% | PASS | Scoped score is included with supportive provider instruction. |
| 8 | Low confidence | PASS | Confidence and evidence count are supplied; provider prohibits unsupported mastery claims. |
| 9 | Recommendation explanation | PASS | Stored `reason_text` is the only explanation source. |
| 10 | Disabled course/pathway | PASS | Stage 8 `student_target_is_available` is rechecked. |
| 11 | Tenant isolation | PASS | Student ownership and school availability checks reject foreign IDs. |
| 12 | Unpublished content | PASS | Nodes/questions require published and approved effective rows. |
| 13 | Provider failure | PASS | 503 plus non-destructive retry UI; lesson remains mounted. |
| 14 | Temporary practice | PASS | Isolated expiring type/table; never inserts into Question Bank. |
| 15 | Cost/rate limit | PASS | Rolling database-backed per-student limit returns HTTP 429. |
| 16 | Stage 1–8 regression | PASS | Full existing automated suite, typecheck, lint, and production build run below. |

## Automated checks performed

- `npm run test:tutor`: context/mode policy, restrictions, output validation, tenant/publication/override/recommendation boundaries, provider abstraction, and secret scan.
- Existing Stage 4–8 behavioral suites.
- TypeScript, ESLint, and Vite production build.

## Bugs discovered and fixed

1. The old lesson control was a non-functional “available soon” placeholder; it was replaced while retaining the floating interaction pattern.
2. Practice help previously showed only one static hint. Nuru now carries progressive levels and only unlocks mistake context after submission.
3. Feedback could not safely infer a student from a browser insert. It now uses `save_nuru_feedback`, which derives identity from the JWT and verifies interaction ownership.
4. Recommendation records could become stale; Nuru reuses Stage 8's read-time availability boundary before explaining one.

## Remaining limitations

- Deployment requires Supabase migration/function deployment and server-side `OPENAI_API_KEY`/optional `NURU_AI_MODEL` configuration.
- The MVP adapter has one AI vendor implementation, though the UI and orchestration depend only on `TutorAIProvider`.
- Educator aggregate UI and “Suggest for Question Bank” review screens are not exposed yet; governed storage/RPC boundaries are ready for those surfaces.
- Automated tests validate policy behavior and source boundaries without a hosted Supabase integration environment. A deployed staging smoke test should confirm JWT, RLS, provider, and seeded Linear Equations data end to end.

## Stage 10 recommendation (not started)

Stage 10 should build educator-facing learning analytics and intervention workflows on aggregate Nuru/mastery signals: privacy thresholds, trend views, content-opportunity review, teacher follow-up actions, and the human-governed “Suggest for Question Bank” pipeline. It should not expose student tutor transcripts by default or auto-publish generated content.
