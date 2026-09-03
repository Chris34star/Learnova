# Learnova Supabase setup

## 1. Create a project
Create a Supabase project for the intended environment. Development, staging, and production should use separate projects.

## 2. Configure the browser client
Copy `.env.example` to `.env.local` and provide the project URL and **anon** key. Never use a service-role key in Vite variables; every `VITE_` value is public to the browser.

## 3. Run the migration
With the Supabase CLI linked to the project, run `supabase db push`, or paste `supabase/migrations/202609030001_stage3_foundation.sql` into the SQL editor. The migration creates all Stage 3 tables, constraints, helpers, triggers, and RLS policies. RLS is enabled by the migration.

## 4. Create the first platform administrator safely
1. In the Supabase dashboard, create a user under Authentication → Users.
2. In the SQL editor, insert a profile for that exact auth user ID. Do this only from the trusted dashboard/CLI, never from the browser:
   ```sql
   insert into public.profiles (user_id, school_id, role, first_name, last_name, display_name, status)
   values ('AUTH_USER_UUID', null, 'platform_admin', 'Platform', 'Owner', 'Platform Owner', 'active');
   ```
3. Sign in at `/login`. The role router opens `/platform`.

School users require both an Auth user and a tenant-bound profile. Provision them from a trusted dashboard now; a future Edge Function can provide the admin workflow. The frontend intentionally does not create Auth users.

## 5. Optional development school
Run `supabase/seed.sql` manually to add Greenfield Academy, three grades/classes, and three global subjects. This file is never run automatically. Create school-user Auth accounts and linked profiles separately.

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

## Content architecture boundary
Stage 3 does not create content tables. Stage 4 should model immutable/versioned content nodes separately from tenant overrides: global trees can then be inherited without copying, while school overrides reference individual source nodes. Draft, approval, and publish states must encode the rule: AI may suggest or draft only after authorization; humans approve; only approved versions publish.
