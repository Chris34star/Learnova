-- Learnova Stage 6: tenant-safe student learning engine. Apply after Stage 5.
create type public.learning_progress_status as enum ('not_started','in_progress','completed');
create type public.learning_event_type as enum ('course_started','lesson_started','lesson_completed','activity_completed','course_completed','project_started','project_milestone_completed');
create type public.prerequisite_mode as enum ('recommended','required');
create type public.project_status as enum ('not_started','in_progress','completed');

create table public.school_course_assignments (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 course_id uuid not null references public.courses(id) on delete cascade, grade_id uuid references public.grades(id) on delete cascade,
 class_id uuid references public.classes(id) on delete cascade, is_active boolean not null default true,
 available_from timestamptz, available_until timestamptz, prerequisite_mode prerequisite_mode not null default 'recommended',
 created_at timestamptz not null default now(),
 unique nulls not distinct (school_id,course_id,grade_id,class_id)
);
create table public.learning_sessions (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 student_id uuid not null references public.student_profiles(id) on delete cascade, course_id uuid not null references public.courses(id) on delete cascade,
 started_at timestamptz not null default now(), ended_at timestamptz, duration_seconds integer check(duration_seconds is null or duration_seconds >= 0),
 last_content_node_id uuid references public.content_nodes(id) on delete set null, created_at timestamptz not null default now()
);
create table public.student_content_progress (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 student_id uuid not null references public.student_profiles(id) on delete cascade, course_id uuid not null references public.courses(id) on delete cascade,
 content_node_id uuid not null references public.content_nodes(id) on delete cascade, status learning_progress_status not null default 'not_started',
 started_at timestamptz, completed_at timestamptz, last_position_json jsonb, time_spent_seconds integer not null default 0 check(time_spent_seconds >= 0),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(student_id,content_node_id)
);
create table public.learning_events (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 student_id uuid not null references public.student_profiles(id) on delete cascade, course_id uuid references public.courses(id) on delete cascade,
 content_node_id uuid references public.content_nodes(id) on delete set null, event_type learning_event_type not null,
 metadata_json jsonb not null default '{}', created_at timestamptz not null default now()
);
create table public.student_projects (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 student_id uuid not null references public.student_profiles(id) on delete cascade, course_id uuid not null references public.courses(id) on delete cascade,
 title text not null, status project_status not null default 'not_started', current_milestone_id uuid,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(student_id,course_id)
);
create table public.student_project_milestones (
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.student_projects(id) on delete cascade,
 content_node_id uuid not null references public.content_nodes(id) on delete cascade, status project_status not null default 'not_started',
 completed_at timestamptz, unique(project_id,content_node_id)
);
alter table public.student_projects add constraint student_projects_current_milestone_fk foreign key(current_milestone_id) references public.student_project_milestones(id) on delete set null;
create index progress_student_course on public.student_content_progress(student_id,course_id,status);
create index events_student_recent on public.learning_events(student_id,created_at desc);
create index sessions_student_recent on public.learning_sessions(student_id,started_at desc);
create trigger student_progress_updated before update on public.student_content_progress for each row execute function public.touch_updated_at();
create trigger student_projects_updated before update on public.student_projects for each row execute function public.touch_updated_at();

-- One narrow function owns availability and override resolution. Required learning is
-- deliberately limited to lessons, activities, practice, projects, challenges and milestones.
create function public.student_available_courses()
returns setof public.courses language sql stable security invoker as $$
 select distinct c.* from student_profiles s
 join courses c on c.status='published' and c.approved_at is not null
 left join school_course_adoptions a on a.school_id=s.school_id and a.course_id=c.id and a.active
 left join school_course_assignments x on x.school_id=s.school_id and x.course_id=c.id and x.is_active
   and (x.grade_id is null or x.grade_id=s.grade_id) and (x.class_id is null or x.class_id=s.class_id)
   and (x.available_from is null or x.available_from<=now()) and (x.available_until is null or x.available_until>=now())
 where s.profile_id=(select id from profiles where user_id=auth.uid()) and s.status='active'
   and ((c.scope='school' and c.school_id=s.school_id and (c.grade_id is null or c.grade_id=s.grade_id))
     or (c.scope='global' and (a.id is not null or x.id is not null)))
 order by c.title;
$$;
create function public.student_course_nodes(requested_course_id uuid)
returns setof public.content_nodes language sql stable security invoker as $$
 with me as (select s.* from student_profiles s where s.profile_id=(select id from profiles where user_id=auth.uid())),
 allowed as (select id from student_available_courses() where id=requested_course_id),
 roots as (select n.* from content_nodes n,me where n.course_id=requested_course_id and n.status='published' and n.approved_at is not null
   and ((n.scope='global' and not n.is_override) or (n.scope='school' and n.school_id=me.school_id and not n.is_override))),
 resolved as (select coalesce(o.id,r.id) id from roots r,me left join lateral (
   select x.id from content_nodes x where x.school_id=me.school_id and x.source_content_id=r.id and x.is_override
   and x.status='published' and x.approved_at is not null order by x.updated_at desc limit 1) o on true)
 select n.* from content_nodes n join resolved r on r.id=n.id where exists(select 1 from allowed) order by n.parent_id nulls first,n.sort_order,n.title;
$$;
create function public.student_course_progress()
returns table(course_id uuid,required_count bigint,completed_count bigint,progress_percent integer,current_content_node_id uuid)
language sql stable security invoker as $$
 with available as (select id from student_available_courses()), me as (select id from student_profiles where profile_id=(select id from profiles where user_id=auth.uid())), nodes as
 (select a.id course_id,n.id,n.sort_order from available a cross join lateral student_course_nodes(a.id) n where n.content_type in ('lesson','activity','practice','project','challenge','milestone'))
 select n.course_id,count(*),count(*) filter(where p.status='completed'),case when count(*)=0 then 0 else round(100.0*count(*) filter(where p.status='completed')/count(*))::integer end,
 (array_agg(n.id order by case when p.status='completed' then 1 else 0 end,n.sort_order,n.id))[1]
 from nodes n cross join me left join student_content_progress p on p.student_id=me.id and p.content_node_id=n.id group by n.course_id;
$$;

-- Atomic save prevents completion loss and validates student, tenant, course and published node.
create function public.save_learning_progress(requested_course_id uuid, requested_node_id uuid, requested_status learning_progress_status,
 requested_position jsonb default null, elapsed_seconds integer default 0, requested_event learning_event_type default null)
returns public.student_content_progress language plpgsql security definer set search_path=public as $$
declare me student_profiles; saved student_content_progress;
begin
 select s.* into me from student_profiles s join profiles p on p.id=s.profile_id where p.user_id=auth.uid() and p.status='active';
 if me.id is null or not exists(select 1 from student_available_courses() c where c.id=requested_course_id)
   or not exists(select 1 from student_course_nodes(requested_course_id) n where n.id=requested_node_id) then raise exception 'Learning content is not available'; end if;
 insert into student_content_progress(school_id,student_id,course_id,content_node_id,status,started_at,completed_at,last_position_json,time_spent_seconds)
 values(me.school_id,me.id,requested_course_id,requested_node_id,requested_status,now(),case when requested_status='completed' then now() end,requested_position,greatest(elapsed_seconds,0))
 on conflict(student_id,content_node_id) do update set status=excluded.status,
   completed_at=case when excluded.status='completed' then coalesce(student_content_progress.completed_at,now()) else student_content_progress.completed_at end,
   last_position_json=coalesce(excluded.last_position_json,student_content_progress.last_position_json),
   time_spent_seconds=student_content_progress.time_spent_seconds+greatest(elapsed_seconds,0),updated_at=now() returning * into saved;
 if requested_event is not null then insert into learning_events(school_id,student_id,course_id,content_node_id,event_type) values(me.school_id,me.id,requested_course_id,requested_node_id,requested_event); end if;
 if elapsed_seconds > 0 then
   insert into learning_sessions(school_id,student_id,course_id,started_at,ended_at,duration_seconds,last_content_node_id)
   values(me.school_id,me.id,requested_course_id,now()-make_interval(secs=>least(elapsed_seconds,300)),now(),least(elapsed_seconds,300),requested_node_id);
 end if;
 if requested_status='completed'
   and not exists(select 1 from student_course_nodes(requested_course_id) n where n.content_type in ('lesson','activity','practice','project','challenge','milestone') and not exists(select 1 from student_content_progress p where p.student_id=me.id and p.content_node_id=n.id and p.status='completed'))
   and not exists(select 1 from learning_events e where e.student_id=me.id and e.course_id=requested_course_id and e.event_type='course_completed') then
   insert into learning_events(school_id,student_id,course_id,content_node_id,event_type) values(me.school_id,me.id,requested_course_id,requested_node_id,'course_completed');
 end if;
 return saved;
end $$;

alter table public.school_course_assignments enable row level security; alter table public.learning_sessions enable row level security;
alter table public.student_content_progress enable row level security; alter table public.learning_events enable row level security;
alter table public.student_projects enable row level security; alter table public.student_project_milestones enable row level security;
create policy assignments_read on public.school_course_assignments for select using(school_id=current_school_id() or is_platform_admin());
create policy assignments_admin_write on public.school_course_assignments for all using(is_platform_admin() or (current_profile_role()='school_admin' and school_id=current_school_id())) with check(is_platform_admin() or (current_profile_role()='school_admin' and school_id=current_school_id()));
create policy progress_read on public.student_content_progress for select using(is_platform_admin() or (school_id=current_school_id() and (current_profile_role()='school_admin' or student_id=(select id from student_profiles where profile_id=(select id from profiles where user_id=auth.uid())) or (current_profile_role()='teacher' and exists(select 1 from teacher_classes tc join student_profiles s on s.class_id=tc.class_id join teacher_profiles t on t.id=tc.teacher_id where s.id=student_id and t.profile_id=(select id from profiles where user_id=auth.uid()))))));
create policy progress_student_write on public.student_content_progress for all using(student_id=(select id from student_profiles where profile_id=(select id from profiles where user_id=auth.uid())) and school_id=current_school_id()) with check(student_id=(select id from student_profiles where profile_id=(select id from profiles where user_id=auth.uid())) and school_id=current_school_id());
create policy sessions_read on public.learning_sessions for select using(is_platform_admin() or (school_id=current_school_id() and (current_profile_role()='school_admin' or student_id=(select id from student_profiles where profile_id=(select id from profiles where user_id=auth.uid())) or (current_profile_role()='teacher' and exists(select 1 from teacher_classes tc join student_profiles s on s.class_id=tc.class_id join teacher_profiles t on t.id=tc.teacher_id where s.id=student_id and t.profile_id=(select id from profiles where user_id=auth.uid()))))));
create policy sessions_student_write on public.learning_sessions for all using(student_id=(select id from student_profiles where profile_id=(select id from profiles where user_id=auth.uid())) and school_id=current_school_id()) with check(student_id=(select id from student_profiles where profile_id=(select id from profiles where user_id=auth.uid())) and school_id=current_school_id());
create policy events_read on public.learning_events for select using(is_platform_admin() or (school_id=current_school_id() and (current_profile_role()='school_admin' or student_id=(select id from student_profiles where profile_id=(select id from profiles where user_id=auth.uid())) or (current_profile_role()='teacher' and exists(select 1 from teacher_classes tc join student_profiles s on s.class_id=tc.class_id join teacher_profiles t on t.id=tc.teacher_id where s.id=student_id and t.profile_id=(select id from profiles where user_id=auth.uid()))))));
create policy events_student_insert on public.learning_events for insert with check(student_id=(select id from student_profiles where profile_id=(select id from profiles where user_id=auth.uid())) and school_id=current_school_id());
create policy projects_read on public.student_projects for select using(is_platform_admin() or (school_id=current_school_id() and (current_profile_role()='school_admin' or student_id=(select id from student_profiles where profile_id=(select id from profiles where user_id=auth.uid())) or (current_profile_role()='teacher' and exists(select 1 from teacher_classes tc join student_profiles s on s.class_id=tc.class_id join teacher_profiles t on t.id=tc.teacher_id where s.id=student_id and t.profile_id=(select id from profiles where user_id=auth.uid()))))));
create policy projects_student_write on public.student_projects for all using(student_id=(select id from student_profiles where profile_id=(select id from profiles where user_id=auth.uid())) and school_id=current_school_id()) with check(student_id=(select id from student_profiles where profile_id=(select id from profiles where user_id=auth.uid())) and school_id=current_school_id());
create policy milestones_access on public.student_project_milestones for all using(exists(select 1 from student_projects p where p.id=project_id and (p.student_id=(select id from student_profiles where profile_id=(select id from profiles where user_id=auth.uid())) or (p.school_id=current_school_id() and current_profile_role() in ('teacher','school_admin')) or is_platform_admin()))) with check(exists(select 1 from student_projects p where p.id=project_id and p.student_id=(select id from student_profiles where profile_id=(select id from profiles where user_id=auth.uid()))));

-- Replace Stage 4's broad course policy: students may inspect course metadata only
-- through the same approval, publication and availability boundary as the engine.
drop policy courses_read on public.courses;
create policy courses_read on public.courses for select using(
 is_platform_admin() or (current_profile_role() in ('school_admin','teacher') and (scope='global' or school_id=current_school_id()))
 or (current_profile_role()='student' and status='published' and approved_at is not null and (
   (scope='school' and school_id=current_school_id()) or
   (scope='global' and (exists(select 1 from school_course_adoptions a where a.course_id=courses.id and a.school_id=current_school_id() and a.active)
     or exists(select 1 from school_course_assignments x join student_profiles s on s.profile_id=(select id from profiles where user_id=auth.uid()) where x.course_id=courses.id and x.school_id=current_school_id() and x.is_active and (x.grade_id is null or x.grade_id=s.grade_id) and (x.class_id is null or x.class_id=s.class_id))))));

comment on function public.student_course_nodes is 'Stage 6 safety boundary: available, approved and published effective nodes only, with a published school override replacing its global source.';
comment on table public.learning_sessions is 'Active seconds only. Clients pause after five minutes without meaningful interaction and close sessions on page hide/unload.';
