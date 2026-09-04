-- Stage 10: project-first Skills Lab. Extends, rather than replaces, the shared learning engine.
create type public.project_instance_status as enum ('not_started','in_progress','submitted','needs_revision','completed');
create type public.project_scope as enum ('global','school');
create type public.project_type as enum ('individual','future_team');
create type public.project_publication_status as enum ('draft','approved','published','archived');
create type public.project_review_status as enum ('approved','revision_requested');
create type public.assignment_type as enum ('course','content','practice','challenge','project','pathway');

create table public.projects (
 id uuid primary key default gen_random_uuid(), scope project_scope not null, school_id uuid references public.schools(id) on delete cascade,
 course_id uuid references public.courses(id) on delete set null, pathway_id uuid references public.learning_pathways(id) on delete set null,
 title text not null, description text not null default '', project_type project_type not null default 'individual', difficulty text not null default 'beginner',
 estimated_minutes integer check(estimated_minutes is null or estimated_minutes>0), instructions text not null, success_criteria_json jsonb not null default '[]',
 submission_schema_json jsonb not null default '{"text":true,"externalUrl":true,"repositoryUrl":false,"reflection":true,"futureFileUpload":false}',
 status project_publication_status not null default 'draft', created_by uuid not null references public.profiles(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check((scope='global' and school_id is null) or (scope='school' and school_id is not null))
);
create table public.project_milestones (
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects(id) on delete cascade, title text not null, description text not null default '', instructions text not null,
 sort_order integer not null, required boolean not null default true, related_skill_id uuid references public.skills(id) on delete set null,
 related_content_node_id uuid references public.content_nodes(id) on delete set null, estimated_minutes integer check(estimated_minutes is null or estimated_minutes>0), created_at timestamptz not null default now(), unique(project_id,sort_order)
);

-- Upgrade Stage 6's lightweight instance without losing existing rows.
alter table public.student_projects alter column status drop default;
alter table public.student_projects alter column status type project_instance_status using status::text::project_instance_status;
alter table public.student_projects alter column status set default 'not_started';
alter table public.student_projects alter column course_id drop not null;
alter table public.student_projects add column project_id uuid references public.projects(id) on delete restrict;
alter table public.student_projects add column pathway_id uuid references public.learning_pathways(id) on delete set null;
alter table public.student_projects add column started_at timestamptz;
alter table public.student_projects add column submitted_at timestamptz;
alter table public.student_projects add column completed_at timestamptz;
alter table public.student_projects add column student_reflection text check(length(student_reflection)<=4000);
alter table public.student_projects add column teacher_feedback text check(length(teacher_feedback)<=4000);
alter table public.student_projects add column submission_json jsonb not null default '{}';
alter table public.student_projects drop constraint if exists student_projects_student_id_course_id_key;
create unique index student_project_definition_unique on public.student_projects(student_id,project_id) where project_id is not null;

alter table public.student_project_milestones rename column project_id to student_project_id;
alter table public.student_project_milestones alter column content_node_id drop not null;
alter table public.student_project_milestones add column project_milestone_id uuid references public.project_milestones(id) on delete cascade;
alter table public.student_project_milestones add column student_notes text check(length(student_notes)<=4000);
alter table public.student_project_milestones add column created_at timestamptz not null default now();
alter table public.student_project_milestones add column updated_at timestamptz not null default now();
alter table public.student_project_milestones drop constraint if exists student_project_milestones_project_id_content_node_id_key;
create unique index student_milestone_definition_unique on public.student_project_milestones(student_project_id,project_milestone_id) where project_milestone_id is not null;

create table public.project_reviews (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 student_project_id uuid not null references public.student_projects(id) on delete cascade, teacher_id uuid not null references public.teacher_profiles(id),
 status project_review_status not null, feedback text not null check(length(feedback) between 1 and 4000), criteria_results_json jsonb,
 created_at timestamptz not null default now()
);
create table public.student_challenge_attempts (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 student_id uuid not null references public.student_profiles(id) on delete cascade, content_node_id uuid not null references public.content_nodes(id) on delete cascade,
 status learning_progress_status not null default 'not_started', started_at timestamptz not null default now(), completed_at timestamptz,
 reflection text check(length(reflection)<=2000), unique(student_id,content_node_id)
);
create table public.learning_assignments (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 teacher_id uuid not null references public.teacher_profiles(id), assignment_type assignment_type not null, target_id uuid not null,
 class_id uuid references public.classes(id) on delete cascade, student_id uuid references public.student_profiles(id) on delete cascade,
 due_at timestamptz, instructions text check(length(instructions)<=2000), status text not null default 'active' check(status in('active','cancelled')),
 created_at timestamptz not null default now(), check(num_nonnulls(class_id,student_id)=1)
);
create table public.project_skill_evidence (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 student_id uuid not null references public.student_profiles(id) on delete cascade, student_project_id uuid not null references public.student_projects(id) on delete cascade,
 project_milestone_id uuid references public.project_milestones(id) on delete set null, skill_id uuid not null references public.skills(id),
 evidence_weight numeric(4,3) not null default .25 check(evidence_weight>0 and evidence_weight<=.5), created_at timestamptz not null default now(),
 unique(student_project_id,project_milestone_id,skill_id)
);

create or replace function public.student_project_progress(requested_student_project uuid) returns integer language sql stable security definer set search_path=public as $$
 select case when count(*) filter(where m.required)=0 then 0 else round(100.0*count(*) filter(where m.required and sm.status='completed')/count(*) filter(where m.required))::integer end
 from student_projects sp join project_milestones m on m.project_id=sp.project_id left join student_project_milestones sm on sm.student_project_id=sp.id and sm.project_milestone_id=m.id
 where sp.id=requested_student_project and (owns_student(sp.student_id) or teacher_can_view_student(sp.student_id) or (sp.school_id=current_school_id() and current_profile_role()='school_admin'));
$$;

create function public.start_student_project(requested_project uuid) returns public.student_projects language plpgsql security definer set search_path=public as $$
declare me student_profiles; definition projects;saved student_projects;
begin select s.* into me from student_profiles s join profiles p on p.id=s.profile_id where p.user_id=auth.uid() and p.role='student' and s.status='active';
 select * into definition from projects p where p.id=requested_project and p.status='published' and ((p.scope='school' and p.school_id=me.school_id) or (p.scope='global' and (p.pathway_id is null or exists(select 1 from school_pathway_settings x where x.school_id=me.school_id and x.pathway_id=p.pathway_id and x.enabled)))) and (p.pathway_id is null or student_target_is_available(me.id,p.pathway_id,'pathway'));
 if not found then raise exception 'Published project is not available';end if;
 insert into student_projects(school_id,student_id,project_id,course_id,pathway_id,title,status,started_at) values(me.school_id,me.id,definition.id,definition.course_id,definition.pathway_id,definition.title,'in_progress',now())
 on conflict(student_id,project_id) where project_id is not null do update set status=case when student_projects.status='not_started' then 'in_progress' else student_projects.status end,started_at=coalesce(student_projects.started_at,now()),updated_at=now() returning * into saved;
 insert into student_project_milestones(student_project_id,project_milestone_id,status) select saved.id,m.id,'not_started' from project_milestones m where m.project_id=definition.id on conflict do nothing;return saved;end$$;

create function public.save_project_milestone(requested_student_project uuid,requested_milestone uuid,requested_status project_status,requested_notes text default null) returns integer language plpgsql security definer set search_path=public as $$
declare instance student_projects;skill uuid;
begin select * into instance from student_projects where id=requested_student_project and owns_student(student_id) for update;if not found or instance.status in('submitted','completed') then raise exception 'Project milestone cannot be changed';end if;
 if not exists(select 1 from project_milestones where id=requested_milestone and project_id=instance.project_id)then raise exception 'Milestone is outside this project';end if;
 insert into student_project_milestones(student_project_id,project_milestone_id,status,student_notes,completed_at) values(instance.id,requested_milestone,requested_status,left(requested_notes,4000),case when requested_status='completed'then now()end)
 on conflict(student_project_id,project_milestone_id) where project_milestone_id is not null do update set status=excluded.status,student_notes=excluded.student_notes,completed_at=case when excluded.status='completed'then coalesce(student_project_milestones.completed_at,now())end,updated_at=now();
 select related_skill_id into skill from project_milestones where id=requested_milestone;if requested_status='completed' and skill is not null then insert into project_skill_evidence(school_id,student_id,student_project_id,project_milestone_id,skill_id)values(instance.school_id,instance.student_id,instance.id,requested_milestone,skill)on conflict do nothing;end if;
 return student_project_progress(instance.id);end$$;

create function public.submit_student_project(requested_student_project uuid,requested_submission jsonb,requested_reflection text) returns public.student_projects language plpgsql security definer set search_path=public as $$
declare saved student_projects;begin
 update student_projects sp set status='submitted',submission_json=requested_submission,student_reflection=left(requested_reflection,4000),submitted_at=now(),updated_at=now()
 where sp.id=requested_student_project and owns_student(sp.student_id) and sp.status in('in_progress','needs_revision') and not exists(select 1 from project_milestones m where m.project_id=sp.project_id and m.required and not exists(select 1 from student_project_milestones x where x.student_project_id=sp.id and x.project_milestone_id=m.id and x.status='completed')) returning * into saved;
 if not found then raise exception 'Complete required milestones before submission';end if;return saved;end$$;

create function public.review_student_project(requested_student_project uuid,requested_status project_review_status,requested_feedback text,requested_criteria jsonb default null) returns public.student_projects language plpgsql security definer set search_path=public as $$
declare teacher teacher_profiles;saved student_projects;begin select t.* into teacher from teacher_profiles t join profiles p on p.id=t.profile_id where p.user_id=auth.uid();
 if not found or not exists(select 1 from student_projects sp where sp.id=requested_student_project and sp.status='submitted' and teacher_can_view_student(sp.student_id))then raise exception 'Submitted project is outside your assigned students';end if;
 insert into project_reviews(school_id,student_project_id,teacher_id,status,feedback,criteria_results_json)values(teacher.school_id,requested_student_project,teacher.id,requested_status,left(requested_feedback,4000),requested_criteria);
 update student_projects set status=case when requested_status='approved'then'completed'::project_instance_status else'needs_revision'::project_instance_status end,teacher_feedback=left(requested_feedback,4000),completed_at=case when requested_status='approved'then now()end,updated_at=now() where id=requested_student_project returning * into saved;return saved;end$$;

create function public.nuru_build_project_context(requested_student_project uuid) returns jsonb language plpgsql stable security definer set search_path=public as $$
declare me student_profiles;sp student_projects;p projects;m project_milestones;begin select s.* into me from student_profiles s join profiles pr on pr.id=s.profile_id where pr.user_id=auth.uid() and pr.role='student';select x.* into sp from student_projects x where x.id=requested_student_project and x.student_id=me.id and x.school_id=me.school_id;select * into p from projects where id=sp.project_id and status='published';if not found then raise exception 'Project context unavailable';end if;
 select pm.* into m from project_milestones pm left join student_project_milestones sm on sm.project_milestone_id=pm.id and sm.student_project_id=sp.id where pm.project_id=p.id and coalesce(sm.status,'not_started')<>'completed' order by pm.sort_order limit 1;
 return jsonb_build_object('mode','project','student',jsonb_build_object('id',me.id),'school',jsonb_build_object('id',me.school_id),'settings',jsonb_build_object('requests_per_ten_minutes',coalesce((select requests_per_ten_minutes from nuru_settings where school_id=me.school_id),12),'temporary_practice_enabled',false),'project',jsonb_build_object('id',p.id,'title',p.title,'goal',p.description,'instructions',left(p.instructions,3000),'successCriteria',p.success_criteria_json),'currentMilestone',jsonb_build_object('id',m.id,'title',m.title,'instructions',left(m.instructions,2000)),'approvedLearning',(select coalesce(jsonb_agg(jsonb_build_object('title',n.title,'content',left(n.body,1000))),'[]') from content_nodes n where n.id=m.related_content_node_id and n.status='published' and n.approved_at is not null),'mentorPolicy','Use questions, hints, planning and small examples. Never produce the complete project.');end$$;

do $$declare t text;begin foreach t in array array['projects','project_milestones','project_reviews','student_challenge_attempts','learning_assignments','project_skill_evidence'] loop execute format('alter table public.%I enable row level security',t);end loop;end$$;
create policy projects_visible on projects for select using(is_platform_admin() or (current_profile_role() in('school_admin','teacher') and (scope='global' or school_id=current_school_id())) or (current_profile_role()='student' and status='published' and ((scope='school' and school_id=current_school_id())or(scope='global' and(pathway_id is null or exists(select 1 from school_pathway_settings s where s.school_id=current_school_id() and s.pathway_id=projects.pathway_id and s.enabled))))));
create policy milestones_visible on project_milestones for select using(exists(select 1 from projects p where p.id=project_id));
create policy reviews_authorized on project_reviews for select using(school_id=current_school_id() and (owns_student((select student_id from student_projects where id=student_project_id)) or teacher_can_view_student((select student_id from student_projects where id=student_project_id)) or current_profile_role()='school_admin'));
create policy challenges_authorized on student_challenge_attempts for select using(owns_student(student_id) or teacher_can_view_student(student_id));
create policy assignments_authorized on learning_assignments for select using(school_id=current_school_id() and (current_profile_role() in('teacher','school_admin') or owns_student(student_id) or exists(select 1 from student_profiles me where owns_student(me.id) and me.class_id=learning_assignments.class_id)));
create policy evidence_authorized on project_skill_evidence for select using(owns_student(student_id) or teacher_can_view_student(student_id) or (school_id=current_school_id() and current_profile_role()='school_admin'));
grant execute on function start_student_project(uuid),save_project_milestone(uuid,uuid,project_status,text),submit_student_project(uuid,jsonb,text),review_student_project(uuid,project_review_status,text,jsonb),student_project_progress(uuid),nuru_build_project_context(uuid) to authenticated;
comment on table project_skill_evidence is 'Moderate, configurable project evidence; distinct from assessment evidence and never implies 100% mastery.';
