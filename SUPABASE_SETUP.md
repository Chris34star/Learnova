# Learnova Supabase setup

## 1. Create a project
Create a Supabase project for the intended environment. Development, staging, and production should use separate projects.

## 2. Configure the browser client
Copy `.env.example` to `.env.local` and provide the project URL and **anon** key. Never use a service-role key in Vite variables; every `VITE_` value is public to the browser.

## 3. Run all migrations
With the Supabase CLI linked to the project, run `supabase db push`. Apply **every** timestamped file in `supabase/migrations` in filename order; do not apply only the foundation migration and do not make undocumented production edits in the SQL editor. The migrations create the complete MVP schema, constraints, helpers, triggers, indexes, grants, and RLS policies.

## 4. Create the first platform administrator safely
1. In the Supabase dashboard, create a user under Authentication → Users.
2. In the SQL editor, insert a profile for that exact auth user ID. Do this only from the trusted dashboard/CLI, never from the browser:
   ```sql
   insert into public.profiles (user_id, school_id, role, first_name, last_name, display_name, status)
   values ('AUTH_USER_UUID', null, 'platform_admin', 'Platform', 'Owner', 'Platform Owner', 'active');
   ```
3. Sign in at `/login`. The role router opens `/platform`.

School users require both an Auth user and a tenant-bound profile. Provision them from the trusted dashboard for the pilot. The frontend intentionally cannot create Auth users or assign privileged roles.

## 5. Optional synthetic development data
Run `supabase/seed.sql` manually only in development or an approved synthetic pilot environment. The file is never run automatically. Create school-user Auth accounts and linked profiles separately, and never represent seed identities as real learners.

## 6. Test permissions
Create two test schools and one active account per role. Confirm in the UI and SQL/API client that:
- unauthenticated requests cannot read protected tables or routes;
- students cannot open `/school` and can select only their own `student_profiles` row;
- teachers cannot open `/platform` and can read only their tenant;
- school admins cannot open `/platform`, select another tenant, or write global subjects;
- platform admins can list and create schools.

Test tenant isolation using the anon key and real user access tokens, not the SQL editor's elevated role. The SQL editor/service role bypasses RLS.

## 7. Start the app
Run `npm install`, then `npm run dev`. Authentication sessions persist and refresh through Supabase Auth. Password recovery must include the deployed `/reset-password` URL in Authentication → URL Configuration.

## 8. Edge Function and production configuration
Deploy `nuru-tutor` and set `OPENAI_API_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, optional `NURU_AI_MODEL`, and the exact comma-separated HTTPS origins in `ALLOWED_ORIGINS`. These are server-side values; never prefix them with `VITE_`. Confirm the host applies `public/_headers`, SPA fallback, and HTTPS.

Before admitting real pilot data, complete the two-school token attack matrix, production smoke test, and backup/restore rehearsal described in the root README. Supabase backup/PITR availability depends on the selected project plan and must be confirmed in the project dashboard.
