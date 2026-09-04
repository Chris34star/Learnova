-- Stage 11: explainable, tenant-safe intelligence and learning planning.
create type public.intervention_status as enum ('suggested','planned','active','completed','dismissed');

create table public.grade_learning_settings (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 grade_id uuid not null references public.grades(id) on delete cascade, recommended_minutes integer not null check(recommended_minutes between 5 and 180),
 study_start_time time, study_end_time time, updated_at timestamptz not null default now(), unique(school_id,grade_id),
 check(study_start_time is null or study_end_time is null or study_start_time < study_end_time)
);
create table public.exam_modes (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 class_id uuid references public.classes(id) on delete cascade, title text not null, description text not null default '',
 starts_on date not null, ends_on date not null, focus_course_ids uuid[] not null default '{}', enabled boolean not null default true,
 created_by uuid not null references public.profiles(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check(starts_on <= ends_on)
);
create table public.learning_interventions (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 teacher_id uuid not null references public.teacher_profiles(id), student_id uuid references public.student_profiles(id) on delete cascade,
 class_id uuid references public.classes(id) on delete cascade, skill_id uuid references public.skills(id) on delete set null,
 intervention_type text not null check(intervention_type in('targeted_practice','lesson_recommendation','course_recommendation','pathway_recommendation','teacher_note','check_in')),
 reason_code text not null, reason_data jsonb not null default '{}', note text check(length(note)<=2000), status intervention_status not null default 'planned',
 review_on date, reviewed_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check(student_id is not null or class_id is not null)
);
create index interventions_class_status on public.learning_interventions(school_id,class_id,status,created_at desc);
create index interventions_student_status on public.learning_interventions(student_id,status,created_at desc);
create index exam_modes_school_dates on public.exam_modes(school_id,enabled,starts_on,ends_on);


-- Tighten legacy school-wide teacher directory reads to assigned classes.
drop policy if exists classes_read on public.classes;
create policy classes_read on public.classes for select using(is_platform_admin() or school_id=current_school_id() and (current_profile_role()='school_admin' or current_profile_role()='student' and id=(select s.class_id from student_profiles s join profiles p on p.id=s.profile_id where p.user_id=auth.uid()) or current_profile_role()='teacher' and exists(select 1 from teacher_profiles tp join profiles p on p.id=tp.profile_id join teacher_classes tc on tc.teacher_id=tp.id where p.user_id=auth.uid() and tc.class_id=classes.id)));
drop policy if exists students_read on public.student_profiles;
create policy students_read on public.student_profiles for select using(is_platform_admin() or owns_student(id) or school_id=current_school_id() and (current_profile_role()='school_admin' or current_profile_role()='teacher' and teacher_can_view_student(id)));
drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles for select using(user_id=auth.uid() or is_platform_admin() or current_profile_role()='school_admin' and school_id=current_school_id() or current_profile_role()='teacher' and exists(select 1 from student_profiles s where s.profile_id=profiles.id and teacher_can_view_student(s.id)));

alter table public.grade_learning_settings enable row level security;
alter table public.exam_modes enable row level security;
alter table public.learning_interventions enable row level security;
create policy grade_settings_read on public.grade_learning_settings for select using(school_id=current_school_id() and current_profile_role() in('student','teacher','school_admin') or is_platform_admin());
create policy grade_settings_admin on public.grade_learning_settings for all using(school_id=current_school_id() and current_profile_role()='school_admin' or is_platform_admin()) with check(school_id=current_school_id() and current_profile_role()='school_admin' or is_platform_admin());
create policy exam_modes_read on public.exam_modes for select using(is_platform_admin() or school_id=current_school_id() and (current_profile_role()='school_admin' or current_profile_role()='student' and (class_id is null or class_id=(select s.class_id from student_profiles s join profiles p on p.id=s.profile_id where p.user_id=auth.uid())) or current_profile_role()='teacher' and (class_id is null or exists(select 1 from teacher_profiles tp join profiles p on p.id=tp.profile_id join teacher_classes tc on tc.teacher_id=tp.id where p.user_id=auth.uid() and tc.class_id=exam_modes.class_id))));
create policy exam_modes_admin on public.exam_modes for all using(school_id=current_school_id() and current_profile_role()='school_admin' or is_platform_admin()) with check(school_id=current_school_id() and current_profile_role()='school_admin' or is_platform_admin());
create policy interventions_read on public.learning_interventions for select using(school_id=current_school_id() and (current_profile_role()='school_admin' or student_id is not null and ((owns_student(student_id) and intervention_type<>'teacher_note') or teacher_can_view_student(student_id)) or class_id is not null and exists(select 1 from teacher_profiles tp join profiles p on p.id=tp.profile_id join teacher_classes tc on tc.teacher_id=tp.id where p.user_id=auth.uid() and tc.class_id=learning_interventions.class_id)));

create function public.configure_grade_learning(requested_grade uuid, requested_minutes integer, requested_start time default null, requested_end time default null)
returns public.grade_learning_settings language plpgsql security definer set search_path=public as $$ declare saved grade_learning_settings; begin
 if current_profile_role()<>'school_admin' or not exists(select 1 from grades where id=requested_grade and school_id=current_school_id()) then raise exception 'School administrator and tenant grade required'; end if;
 insert into grade_learning_settings(school_id,grade_id,recommended_minutes,study_start_time,study_end_time) values(current_school_id(),requested_grade,requested_minutes,requested_start,requested_end)
 on conflict(school_id,grade_id) do update set recommended_minutes=excluded.recommended_minutes,study_start_time=excluded.study_start_time,study_end_time=excluded.study_end_time,updated_at=now() returning * into saved; return saved; end $$;

create function public.save_exam_mode(requested_id uuid, requested_class uuid, requested_title text, requested_description text, requested_start date, requested_end date, requested_courses uuid[], requested_enabled boolean)
returns public.exam_modes language plpgsql security definer set search_path=public as $$ declare saved exam_modes; me uuid; begin
 if current_profile_role()<>'school_admin' then raise exception 'School administrator required'; end if; select id into me from profiles where user_id=auth.uid();
 if requested_class is not null and not exists(select 1 from classes where id=requested_class and school_id=current_school_id()) then raise exception 'Class is outside your school'; end if;
 if exists(select 1 from unnest(coalesce(requested_courses,'{}')) x where not exists(select 1 from courses c where c.id=x and (c.scope='global' or c.school_id=current_school_id()))) then raise exception 'Focus course is outside your school'; end if;
 insert into exam_modes(id,school_id,class_id,title,description,starts_on,ends_on,focus_course_ids,enabled,created_by) values(coalesce(requested_id,gen_random_uuid()),current_school_id(),requested_class,left(requested_title,120),left(coalesce(requested_description,''),1000),requested_start,requested_end,coalesce(requested_courses,'{}'),requested_enabled,me)
 on conflict(id) do update set class_id=excluded.class_id,title=excluded.title,description=excluded.description,starts_on=excluded.starts_on,ends_on=excluded.ends_on,focus_course_ids=excluded.focus_course_ids,enabled=excluded.enabled,updated_at=now() where exam_modes.school_id=current_school_id() returning * into saved;
 if saved.id is null then raise exception 'Exam mode is outside your school'; end if; return saved; end $$;

create function public.record_learning_intervention(requested_student uuid, requested_class uuid, requested_skill uuid, requested_type text, requested_reason text, requested_note text default null, requested_review date default null)
returns public.learning_interventions language plpgsql security definer set search_path=public as $$ declare teacher teacher_profiles;saved learning_interventions; begin
 select tp.* into teacher from teacher_profiles tp join profiles p on p.id=tp.profile_id where p.user_id=auth.uid();
 if not found or (requested_student is not null and not teacher_can_view_student(requested_student)) or (requested_class is not null and not exists(select 1 from teacher_classes where teacher_id=teacher.id and class_id=requested_class)) then raise exception 'Student or class is outside your assigned classes'; end if;
 insert into learning_interventions(school_id,teacher_id,student_id,class_id,skill_id,intervention_type,reason_code,note,review_on,status) values(teacher.school_id,teacher.id,requested_student,requested_class,requested_skill,requested_type,requested_reason,left(requested_note,2000),requested_review,case when requested_review is null then 'active' else 'planned' end) returning * into saved; return saved; end $$;
create policy interventions_teacher_insert on public.learning_interventions for insert with check(school_id=current_school_id() and current_profile_role()='teacher' and teacher_id=(select tp.id from teacher_profiles tp join profiles p on p.id=tp.profile_id where p.user_id=auth.uid()) and (student_id is null or teacher_can_view_student(student_id)));
create policy interventions_teacher_update on public.learning_interventions for update using(school_id=current_school_id() and teacher_id=(select tp.id from teacher_profiles tp join profiles p on p.id=tp.profile_id where p.user_id=auth.uid())) with check(school_id=current_school_id());

-- One aggregate query. Only an assigned teacher can invoke it; minimum evidence and tenant thresholds are applied before surfacing a support signal.
create function public.teacher_class_intelligence(requested_class uuid) returns jsonb language plpgsql stable security definer set search_path=public as $$ declare teacher teacher_profiles; result jsonb; begin
 select tp.* into teacher from teacher_profiles tp join profiles p on p.id=tp.profile_id where p.user_id=auth.uid();
 if not found or not exists(select 1 from teacher_classes tc where tc.teacher_id=teacher.id and tc.class_id=requested_class) then raise exception 'Class is outside your assigned classes'; end if;
 with cfg as (select coalesce(ms.minimum_evidence,3) minimum_evidence,coalesce(ms.gap_threshold,60) gap_threshold from (select 1)x left join mastery_settings ms on ms.school_id=teacher.school_id),
 members as (select s.id,p.display_name from student_profiles s join profiles p on p.id=s.profile_id where s.school_id=teacher.school_id and s.class_id=requested_class and s.status='active'),
 required_nodes as (select distinct a.course_id,n.id from school_course_assignments a join content_nodes n on n.course_id=a.course_id and n.status='published' and n.approved_at is not null and n.content_type in('lesson','activity','practice','project','challenge','milestone') where a.school_id=teacher.school_id and a.is_active and (a.class_id is null or a.class_id=requested_class)),
 completion as (select coalesce(round(100.0*count(*) filter(where cp.status='completed')/nullif(count(*),0)),0)::int value from members m cross join required_nodes n left join student_content_progress cp on cp.student_id=m.id and cp.content_node_id=n.id),
 eligible as (select sm.*,m.display_name,s.name skill_name,cfg.gap_threshold from student_skill_mastery sm join members m on m.id=sm.student_id join skills s on s.id=sm.skill_id cross join cfg where sm.evidence_count>=cfg.minimum_evidence and sm.confidence_score>=40),
 understanding as (select coalesce(round(avg(mastery_score)),0)::int value from eligible),
 gaps as (select skill_id,max(skill_name) skill_name,count(*) filter(where mastery_score<gap_threshold) affected,count(*) filter(where recent_attempt_count>=3 and recent_correct_count::numeric/recent_attempt_count>=.67) improving from eligible group by skill_id having count(*) filter(where mastery_score<gap_threshold)>0),
 support as (select e.student_id,e.display_name,e.skill_id,e.skill_name,round(e.mastery_score)::int mastery,round(e.confidence_score)::int confidence,e.evidence_count,case when e.recent_attempt_count>=3 and e.recent_correct_count::numeric/e.recent_attempt_count>=.67 then 'recent_improvement' when e.mastery_score<e.gap_threshold then 'low_mastery_sufficient_evidence' else 'repeated_recent_incorrect' end reason_code from eligible e where e.mastery_score<e.gap_threshold and not(e.recent_attempt_count>=3 and e.recent_correct_count::numeric/e.recent_attempt_count>=.67)),
 recent as (select count(*) value from learning_events le join members m on m.id=le.student_id where le.created_at>=now()-interval '7 days'),
 practice as (select count(*) value from question_attempts qa join members m on m.id=qa.student_id where qa.submitted_at>=now()-interval '7 days')
 select jsonb_build_object('class',jsonb_build_object('id',cl.id,'name',cl.name,'grade',g.name),'studentCount',(select count(*) from members),'recentActivity',(select value from recent),'practiceAttempts',(select value from practice),'completionPercent',(select value from completion),'understandingPercent',(select value from understanding),'masteryBands',jsonb_build_object('needsPractice',(select count(*) from eligible where mastery_level='needs_practice'),'developing',(select count(*) from eligible where mastery_level='developing'),'onTrack',(select count(*) from eligible where mastery_level='on_track'),'strong',(select count(*) from eligible where mastery_level='strong')),'gaps',coalesce((select jsonb_agg(to_jsonb(x) order by affected desc) from gaps x),'[]'),'support',coalesce((select jsonb_agg(to_jsonb(x) order by mastery) from support x),'[]'),'lowEvidenceCount',(select count(*) from student_skill_mastery sm join members m on m.id=sm.student_id cross join cfg where sm.evidence_count<cfg.minimum_evidence or sm.confidence_score<40)) into result from classes cl join grades g on g.id=cl.grade_id where cl.id=requested_class and cl.school_id=teacher.school_id; return result; end $$;

create function public.student_daily_plan() returns jsonb language plpgsql stable security definer set search_path=public as $$ declare me student_profiles;result jsonb; begin
 select s.* into me from student_profiles s join profiles p on p.id=s.profile_id where p.user_id=auth.uid() and p.role='student'; if not found then raise exception 'Student required'; end if;
 with active_exam as (select e.* from exam_modes e where e.school_id=me.school_id and e.enabled and current_date between e.starts_on and e.ends_on and (e.class_id is null or e.class_id=me.class_id) order by e.class_id nulls last limit 1),
 settings as (select coalesce(gs.recommended_minutes,ss.default_study_minutes,30) minutes,coalesce(gs.study_start_time,ss.default_start_time) starts,coalesce(gs.study_end_time,ss.default_end_time) ends from school_settings ss left join grade_learning_settings gs on gs.school_id=ss.school_id and gs.grade_id=me.grade_id where ss.school_id=me.school_id),
 items as (
  select 'assignment' kind,a.target_id,a.due_at,15 minutes,case when exists(select 1 from active_exam) then 100 else 80 end priority,'Assigned work from your teacher.' reason from learning_assignments a where a.school_id=me.school_id and a.status='active' and (a.student_id=me.id or a.class_id=me.class_id)
  union all select 'practice',pa.skill_id,pa.due_at,10,case when exists(select 1 from active_exam) then 95 else 75 end,'Practice assigned by your teacher.' from practice_assignments pa where pa.school_id=me.school_id and pa.status='active' and (pa.student_id=me.id or pa.class_id=me.class_id)
  union all select 'lesson',cp.content_node_id,null,15,case when exists(select 1 from active_exam) and cp.course_id=any((select focus_course_ids from active_exam)) then 90 else 70 end,'Continue because this is your active lesson.' from student_content_progress cp where cp.student_id=me.id and cp.status='in_progress'
  union all select 'recommendation',r.target_id,r.expires_at,10,85,r.reason_text from student_recommendations r where r.student_id=me.id and r.status='active' and (r.expires_at is null or r.expires_at>now())
  union all select 'project',sp.id,null,10,case when exists(select 1 from active_exam) then 30 else 50 end,'Continue your next project milestone.' from student_projects sp where sp.student_id=me.id and sp.status in('in_progress','needs_revision')
 ) select jsonb_build_object('recommendedMinutes',(select minutes from settings),'studyWindow',case when (select starts from settings) is null then null else to_char((select starts from settings),'HH12:MI AM')||case when (select ends from settings) is null then '' else ' – '||to_char((select ends from settings),'HH12:MI AM') end end,'examMode',(select jsonb_build_object('title',title,'description',description,'endsOn',ends_on) from active_exam),'items',coalesce((select jsonb_agg(to_jsonb(i) order by priority desc,due_at nulls last) from (select * from items limit 8)i),'[]')) into result; return result; end $$;

create function public.school_intelligence() returns jsonb language plpgsql stable security definer set search_path=public as $$ declare result jsonb; begin
 if current_profile_role()<>'school_admin' then raise exception 'School administrator required'; end if;
 select jsonb_build_object('activeStudents',(select count(*) from student_profiles where school_id=current_school_id() and status='active'),'activeLearners7d',(select count(distinct student_id) from learning_events where school_id=current_school_id() and created_at>=now()-interval '7 days'),'lessonsCompleted7d',(select count(*) from learning_events where school_id=current_school_id() and event_type='lesson_completed' and created_at>=now()-interval '7 days'),'averageCompletion',(select coalesce(round(100.0*count(*) filter(where status='completed')/nullif(count(*),0)),0) from student_content_progress where school_id=current_school_id()),'averageUnderstanding',(select coalesce(round(avg(mastery_score)),0) from student_skill_mastery where school_id=current_school_id()),'practiceAttempts7d',(select count(*) from question_attempts where school_id=current_school_id() and submitted_at>=now()-interval '7 days'),'projectsActive',(select count(*) from student_projects where school_id=current_school_id() and status in('in_progress','submitted','needs_revision')),'projectsCompleted',(select count(*) from student_projects where school_id=current_school_id() and status='completed'),'pathwaysActive',(select count(*) from student_pathway_progress where school_id=current_school_id() and status='in_progress'),'interventionsActive',(select count(*) from learning_interventions where school_id=current_school_id() and status in('planned','active'))) into result; return result; end $$;

grant execute on function public.configure_grade_learning(uuid,integer,time,time),public.save_exam_mode(uuid,uuid,text,text,date,date,uuid[],boolean),public.record_learning_intervention(uuid,uuid,uuid,text,text,text,date),public.teacher_class_intelligence(uuid),public.student_daily_plan(),public.school_intelligence() to authenticated;
comment on function public.teacher_class_intelligence is 'Deterministic class intelligence: configured evidence thresholds, no ranking or opaque risk score.';
comment on function public.student_daily_plan is 'A current, computed plan. Duration is planning guidance and never mastery evidence.';
