-- Learnova Stage 3: tenant-safe identity and academic foundation.
create extension if not exists pgcrypto;

create type public.user_role as enum ('platform_admin','school_admin','teacher','student');
create type public.profile_status as enum ('active','inactive','pending');
create type public.school_status as enum ('trial','active','inactive');
create type public.student_status as enum ('active','inactive','graduated');

create table public.schools (
 id uuid primary key default gen_random_uuid(), name text not null, slug text not null unique,
 logo_url text, school_type text, country text not null, county text, city text,
 contact_email text, contact_phone text, status school_status not null default 'trial',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.profiles (
 id uuid primary key default gen_random_uuid(), user_id uuid not null unique references auth.users(id) on delete cascade,
 school_id uuid references public.schools(id), role user_role not null, first_name text not null,
 last_name text not null, display_name text not null, avatar_url text, phone text,
 status profile_status not null default 'pending', created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 constraint platform_tenant_check check ((role = 'platform_admin' and school_id is null) or (role <> 'platform_admin' and school_id is not null))
);
create table public.academic_years (id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade, name text not null, start_date date not null, end_date date not null, is_current boolean not null default false, created_at timestamptz not null default now(), unique(school_id,name));
create table public.grades (id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade, name text not null, level_number integer, display_order integer not null default 0, is_active boolean not null default true, created_at timestamptz not null default now(), unique(school_id,name));
create table public.classes (id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade, grade_id uuid not null references public.grades(id), name text not null, class_teacher_id uuid, created_at timestamptz not null default now(), unique(school_id,name));
create table public.student_profiles (id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade, profile_id uuid not null unique references public.profiles(id), student_number text, grade_id uuid not null references public.grades(id), class_id uuid references public.classes(id), date_of_birth date, status student_status not null default 'active', created_at timestamptz not null default now(), unique(school_id,student_number));
create table public.teacher_profiles (id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade, profile_id uuid not null unique references public.profiles(id), staff_number text, title text, created_at timestamptz not null default now(), unique(school_id,staff_number));
alter table public.classes add constraint classes_teacher_fk foreign key (class_teacher_id) references public.teacher_profiles(id) on delete set null;
create table public.teacher_classes (id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade, teacher_id uuid not null references public.teacher_profiles(id) on delete cascade, class_id uuid not null references public.classes(id) on delete cascade, created_at timestamptz not null default now(), unique(teacher_id,class_id));
create table public.subjects (id uuid primary key default gen_random_uuid(), school_id uuid references public.schools(id) on delete cascade, name text not null, slug text not null, description text, is_global boolean not null default false, status text not null default 'active' check(status in ('active','inactive')), created_at timestamptz not null default now(), constraint global_subject_scope check ((is_global and school_id is null) or (not is_global and school_id is not null)), unique(school_id,slug));
create unique index global_subject_slug on public.subjects(slug) where school_id is null;
create table public.grade_subjects (id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade, grade_id uuid not null references public.grades(id) on delete cascade, subject_id uuid not null references public.subjects(id), created_at timestamptz not null default now(), unique(grade_id,subject_id));
create table public.school_settings (id uuid primary key default gen_random_uuid(), school_id uuid not null unique references public.schools(id) on delete cascade, timezone text not null default 'Africa/Nairobi', default_study_minutes integer not null default 30 check(default_study_minutes between 5 and 480), default_start_time time, default_end_time time, onboarding_completed boolean not null default false, created_at timestamptz not null default now(), updated_at timestamptz not null default now());

-- Security-definer helpers prevent recursive profile policies and expose no user data.
create function public.current_profile_role() returns user_role language sql stable security definer set search_path=public as $$ select role from profiles where user_id=auth.uid() and status='active' $$;
create function public.current_school_id() returns uuid language sql stable security definer set search_path=public as $$ select school_id from profiles where user_id=auth.uid() and status='active' $$;
create function public.is_platform_admin() returns boolean language sql stable security definer set search_path=public as $$ select coalesce(current_profile_role()='platform_admin',false) $$;

alter table public.schools enable row level security; alter table public.profiles enable row level security;
alter table public.academic_years enable row level security; alter table public.grades enable row level security;
alter table public.classes enable row level security; alter table public.student_profiles enable row level security;
alter table public.teacher_profiles enable row level security; alter table public.teacher_classes enable row level security;
alter table public.subjects enable row level security; alter table public.grade_subjects enable row level security;
alter table public.school_settings enable row level security;

-- A user can bootstrap only by reading their own profile; platform admins can inspect all profiles.
create policy profiles_read on public.profiles for select using (user_id=auth.uid() or is_platform_admin() or (current_profile_role() in ('school_admin','teacher') and school_id=current_school_id()));
-- School admins manage profiles only inside their tenant. Account creation remains server-side.
create policy profiles_school_update on public.profiles for update using (is_platform_admin() or (current_profile_role()='school_admin' and school_id=current_school_id())) with check (is_platform_admin() or (current_profile_role()='school_admin' and school_id=current_school_id()));
-- A tenant sees its school; platform admins see and manage every school.
create policy schools_read on public.schools for select using (is_platform_admin() or id=current_school_id());
create policy schools_platform_write on public.schools for all using (is_platform_admin()) with check (is_platform_admin());
create policy schools_admin_update on public.schools for update using (current_profile_role()='school_admin' and id=current_school_id()) with check (id=current_school_id());

-- Reusable tenant policies: all active school roles may read; only school/platform admins write.
do $$ declare t text; begin foreach t in array array['academic_years','grades','classes','teacher_classes','grade_subjects','school_settings'] loop
 execute format('create policy %I on public.%I for select using (is_platform_admin() or school_id=current_school_id())',t||'_read',t);
 execute format('create policy %I on public.%I for all using (is_platform_admin() or (current_profile_role()=''school_admin'' and school_id=current_school_id())) with check (is_platform_admin() or (current_profile_role()=''school_admin'' and school_id=current_school_id()))',t||'_admin_write',t);
end loop; end $$;
-- Staff records are not a student directory; only tenant staff/admins and platform admins read them.
create policy teacher_profiles_read on public.teacher_profiles for select using (is_platform_admin() or (current_profile_role() in ('school_admin','teacher') and school_id=current_school_id()));
create policy teacher_profiles_admin_write on public.teacher_profiles for all using (is_platform_admin() or (current_profile_role()='school_admin' and school_id=current_school_id())) with check (is_platform_admin() or (current_profile_role()='school_admin' and school_id=current_school_id()));
-- Students see only their own student record; teachers/admins see tenant students.
create policy students_read on public.student_profiles for select using (is_platform_admin() or (school_id=current_school_id() and (current_profile_role() in ('school_admin','teacher') or profile_id=(select id from profiles where user_id=auth.uid()))));
create policy students_admin_write on public.student_profiles for all using (is_platform_admin() or (current_profile_role()='school_admin' and school_id=current_school_id())) with check (is_platform_admin() or (current_profile_role()='school_admin' and school_id=current_school_id()));
-- Global subjects are readable by every authenticated user; tenant subjects stay tenant-bound.
create policy subjects_read on public.subjects for select using (auth.uid() is not null and (is_global or is_platform_admin() or school_id=current_school_id()));
create policy subjects_admin_write on public.subjects for all using (is_platform_admin() or (current_profile_role()='school_admin' and school_id=current_school_id() and not is_global)) with check (is_platform_admin() or (current_profile_role()='school_admin' and school_id=current_school_id() and not is_global));

create function public.touch_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end $$;
create trigger schools_updated before update on public.schools for each row execute function touch_updated_at();
create trigger profiles_updated before update on public.profiles for each row execute function touch_updated_at();
create trigger settings_updated before update on public.school_settings for each row execute function touch_updated_at();
