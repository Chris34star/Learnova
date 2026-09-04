# Learnova

## Project Overview
Learnova is a multi-tenant educational SaaS for schools, teachers, and students. It combines governed curriculum, mastery-aware learning, explainable discovery, contextual Nuru support, and a project-first Skills Lab. Stage 10 deliberately reuses courses, content nodes, skills, learning progress, graph relationships, and recommendations rather than creating a second course engine.

## Architecture
- **Client:** React single-page application with role-protected route trees and responsive workspace shells.
- **Data/API:** Supabase Auth, PostgreSQL, Row Level Security (RLS), narrow security-definer RPCs, and Edge Functions.
- **Content:** Global or school-scoped governed courses; approved school overrides resolve over inherited global nodes.
- **Learning:** Sessions and node progress feed assessments, mastery, pathways, recommendations, projects, and private portfolios.
- **AI:** Nuru providers run server-side. The browser sends identifiers; trusted, approved context is assembled in PostgreSQL.

## Technology Stack
React 18, TypeScript, Vite, React Router, Tailwind CSS, Lucide, Supabase/PostgreSQL, and Supabase Edge Functions (Deno).

## Roles
- **Platform admin:** governs global schools, content, proposals, and pathways.
- **School admin:** configures the tenant, staff, learners, inherited content, pathway availability, and aggregate analytics.
- **Teacher:** works with authorized classes, content, assignments, recommendations, learning insight, and project reviews.
- **Student:** learns, practices, explores, asks Nuru, builds projects, and views a private portfolio.

## Completed Development Stages
1. Public website and launch foundation.
2. Interactive product demo.
3. Authentication, roles, schools, people, classes, subjects, and multi-tenancy.
4. Governed global/school content, inheritance, overrides, review, and versioning.
5. Human-governed Nuru Content Studio.
6. Student learning sessions, progress, resume, and completion.
7. Question Bank, secure assessments, mastery, weakness detection, and targeted practice.
8. Skill graph, interests, pathways, explainable Explore Next recommendations, and school availability.
9. Contextual student Nuru with server-derived modes, assessment safeguards, limits, and feedback.
10. Project-first Skills Lab with pathways, challenges, milestones, submissions, teacher review, moderate project evidence, assignments, and private portfolios.
11. Teacher and school intelligence with evidence-aware class opportunities, explainable interventions, flexible daily plans, grade study guidance, and exam-mode prioritization.

## Database Architecture
Timestamped migrations in `supabase/migrations` define tenant-aware tables, enums, functions, and RLS. Stage 10 adds governed `projects` and `project_milestones`; upgrades `student_projects` and milestone progress; and adds `project_reviews`, `student_challenge_attempts`, `learning_assignments`, and distinct `project_skill_evidence`. Project percentage is derived from required milestones. Project evidence is configurable and capped at moderate weight; it does not imply full mastery or replace assessment evidence.

Stage 11 adds `grade_learning_settings`, `exam_modes`, and `learning_interventions`. Secure RPCs compute class and school intelligence from source learning records rather than persisting opaque risk scores. Class insights require configured mastery evidence and medium confidence; completion and understanding are returned separately. Grade duration and study windows are planning guidance only and never mastery evidence. Exam mode temporarily promotes required and relevant work while keeping Skills Lab work available.

Development seeds provide only two focused examples: **Web Creator → Personal Website** and **Young Entrepreneur → Mini Business Pitch**. Seeds are optional and require provisioned accountable profiles.

## Main Routes
- Public: `/`, `/demo`, `/launch`, `/login`
- Student learning: `/app`, `/app/learn`, `/app/course/:courseId`, `/app/lesson/:lessonId`, `/app/practice`
- Student planning: `/app/schedule`
- Student discovery: `/app/explore`, `/app/interests`, `/app/skills`, `/app/skills/:pathwayId`
- Project work: `/app/project/:studentProjectId`, `/app/portfolio`
- Teacher: `/teacher`, `/teacher/classes`, `/teacher/classes/:classId/insights`, `/teacher/students`, `/teacher/projects`, `/teacher/assignments`, `/teacher/recommend`
- School: `/school`, `/school/content`, `/school/pathways`, `/school/analytics`, `/school/schedule`, `/school/settings`
- Platform: `/platform`, `/platform/content`, `/platform/pathways`

## Security Model
Authentication and role gates protect all application route trees. PostgreSQL RLS remains the data boundary: student project URLs require ownership, teachers require an authorized class/student relationship, and school administrators remain tenant-scoped. Mutation RPCs derive caller identity and school from the JWT, validate project publication/availability and milestone membership, enforce legal submission/review transitions, and reject unpublished or cross-tenant records. Portfolios are never public. Nuru project context includes only the owned published project, current milestone, relevant approved lesson, and a guidance-not-completion mentor policy.

## Testing and Verification Summary
Behavioral suites cover content governance, Nuru Studio, learning, assessments/mastery, recommendations, contextual tutoring, and Skills Lab contracts. Stage 10 verification checks derived milestone progress, transitions, publication and tenant boundaries, assignment targeting, portfolio eligibility, moderate mastery evidence, and project-mode Nuru context. TypeScript, lint, and production build are run before release.

Stage 10 verification: **Build PASS; TypeScript PASS; Skills Lab contracts PASS; existing Stage 4–9 regression suites PASS.** Hosted multi-user/RLS and provider-backed journeys still require a configured Supabase staging project.

## Current Known Limitations
- The repository has no hosted Supabase credentials, so full Amani/teacher logout-login and two-school RLS browser journeys must be completed in staging after migrations and seeds are deployed.
- MVP submissions support text, safe external/repository URLs, checklist results, and reflection; file-upload architecture is reserved but storage is not implemented.
- Team projects and completion certificates are schema-ready future work, not active experiences.
- Teacher assignment creation and advanced Skills Lab analytics use the general architecture but remain thin UI surfaces.
- Project editing requires connectivity; offline editing is not supported.

## Development Setup
```bash
npm install
cp .env.example .env
npm run dev
```
Configure the public Supabase URL and anonymous key in `.env`, apply migrations in timestamp order, then optionally run `supabase/seed.sql`. Never expose service-role or AI provider keys in the browser.

Useful checks:
```bash
npm run typecheck
npm run lint
npm run build
npm run test:content
npm run test:nuru
npm run test:learning
npm run test:assessment
npm run test:recommendations
npm run test:tutor
npm run test:skills
npm run test:intelligence
```

## Deployment Notes
Build with `npm run build` and deploy `dist` with SPA fallback routing. Apply database migrations before the client release, deploy the `nuru-tutor` Edge Function, and configure server-side provider secrets. Validate JWT/RLS behavior with at least two schools, students in different classes, a teacher, and draft/published content before production rollout. See `SUPABASE_SETUP.md` and focused architecture documents in `docs/` for deeper operational and engine details.
