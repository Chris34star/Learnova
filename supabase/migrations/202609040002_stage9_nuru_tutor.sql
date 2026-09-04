-- Stage 9: contextual student tutor. All trusted context is resolved in the database.
create type public.nuru_mode as enum ('learning','practice','assessment','review','explore');
create type public.nuru_rating as enum ('helpful','not_helpful');
create table public.nuru_settings (
 school_id uuid primary key references public.schools(id) on delete cascade,
 enabled boolean not null default true, practice_hints_enabled boolean not null default true,
 assessment_enabled boolean not null default true, assessment_max_hint_level smallint not null default 2 check(assessment_max_hint_level between 0 and 3),
 temporary_practice_enabled boolean not null default true, requests_per_ten_minutes integer not null default 12 check(requests_per_ten_minutes between 1 and 60),
 updated_at timestamptz not null default now()
);
create table public.nuru_interactions (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 student_id uuid not null references public.student_profiles(id) on delete cascade, course_id uuid references public.courses(id) on delete set null,
 content_node_id uuid references public.content_nodes(id) on delete set null, assessment_attempt_id uuid references public.assessment_attempts(id) on delete set null,
 interaction_type text not null, mode public.nuru_mode not null, hint_level smallint not null default 0,
 student_question text not null check(length(student_question)<=600), response_summary text not null check(length(response_summary)<=1200),
 provider text not null, model text not null, input_tokens integer, output_tokens integer, created_at timestamptz not null default now()
);
create table public.nuru_feedback (
 id uuid primary key default gen_random_uuid(), interaction_id uuid not null references public.nuru_interactions(id) on delete cascade,
 student_id uuid not null references public.student_profiles(id) on delete cascade, rating public.nuru_rating not null,
 reason text check(length(reason)<=300), created_at timestamptz not null default now(), unique(interaction_id,student_id)
);
create table public.nuru_temporary_practice (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 student_id uuid not null references public.student_profiles(id) on delete cascade, interaction_id uuid references public.nuru_interactions(id) on delete cascade,
 skill_id uuid references public.skills(id) on delete set null, prompt text not null, answer_validation jsonb not null,
 difficulty public.question_difficulty not null default 'developing', source_type text not null default 'temporary_ai_practice' check(source_type='temporary_ai_practice'),
 expires_at timestamptz not null default now()+interval '24 hours', created_at timestamptz not null default now()
);
alter table public.nuru_settings enable row level security; alter table public.nuru_interactions enable row level security;
alter table public.nuru_feedback enable row level security; alter table public.nuru_temporary_practice enable row level security;
create policy nuru_settings_read on public.nuru_settings for select using(school_id=current_school_id());
create policy nuru_feedback_own on public.nuru_feedback for all using(owns_student(student_id)) with check(owns_student(student_id) and exists(select 1 from nuru_interactions i where i.id=interaction_id and i.student_id=nuru_feedback.student_id));
create policy nuru_temp_own on public.nuru_temporary_practice for select using(owns_student(student_id));
-- Full transcripts are deliberately not exposed to teachers; aggregate RPCs provide educational signals.
create policy nuru_interaction_own on public.nuru_interactions for select using(owns_student(student_id));

create function public.nuru_build_context(requested_course uuid default null,requested_node uuid default null,requested_attempt uuid default null,requested_question uuid default null,requested_recommendation uuid default null)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare me student_profiles; grade_level integer; effective_node content_nodes; course_row courses; attempt_row assessment_attempts; attempt_kind assessment_type; question_row questions; settings nuru_settings; recommendation student_recommendations; result jsonb;
begin
 select s.* into me from student_profiles s join profiles p on p.id=s.profile_id where p.user_id=auth.uid() and p.role='student' and s.status='active';
 if not found then raise exception 'Authorized active student required';end if;
 select g.level_number into grade_level from grades g where g.id=me.grade_id;
 select coalesce(ns,(me.school_id,true,true,true,2,true,12,now())::nuru_settings) into settings from nuru_settings ns where ns.school_id=me.school_id;
 if not settings.enabled then raise exception 'Nuru is disabled by your school';end if;
 if requested_attempt is not null then select a,x.assessment_type into attempt_row,attempt_kind from assessment_attempts a join assessments x on x.id=a.assessment_id where a.id=requested_attempt and a.student_id=me.id and a.school_id=me.school_id and a.status='in_progress';end if;
 if requested_course is not null and not student_target_is_available(me.id,requested_course,'course') then raise exception 'Course is not available';end if;
 if requested_node is not null then
   if not student_target_is_available(me.id,requested_node,'content_node') then raise exception 'Lesson is not available';end if;
   -- student_course_nodes already resolves a published school override over its global source.
   select n.* into effective_node from student_course_nodes((select course_id from content_nodes where id=requested_node)) n where n.id=requested_node or n.source_content_id=requested_node limit 1;
   if not found then raise exception 'Published lesson context required';end if;
   select * into course_row from courses where id=effective_node.course_id;
 end if;
 if requested_question is not null and attempt_row.id is not null then select q.* into question_row from questions q join attempt_questions aq on aq.question_id=q.id where aq.assessment_attempt_id=attempt_row.id and q.id=requested_question and q.status='published' and q.approved_at is not null;end if;
 if requested_recommendation is not null then select r.* into recommendation from student_recommendations r where r.student_id=me.id and r.target_id=requested_recommendation and r.status='active' and student_target_is_available(me.id,r.target_id,r.target_type) order by r.score desc limit 1;end if;
 result:=jsonb_build_object('student',jsonb_build_object('id',me.id,'grade',grade_level),'school',jsonb_build_object('id',me.school_id),'settings',to_jsonb(settings),
  'mode',case when attempt_row.id is not null and attempt_kind<>'practice' then 'assessment' when attempt_row.id is not null then 'practice' when requested_recommendation is not null then 'explore' else 'learning' end,
  'currentCourse',case when course_row.id is null then null else jsonb_build_object('id',course_row.id,'title',course_row.title) end,
  'currentLesson',case when effective_node.id is null then null else jsonb_build_object('id',effective_node.id,'title',effective_node.title,'approvedContent',left(coalesce(effective_node.body,'')||' '||coalesce(effective_node.structured_content::text,''),6000),'objectives',effective_node.learning_objectives,'isSchoolOverride',effective_node.is_override) end,
  'assessment',case when attempt_row.id is null then null else jsonb_build_object('id',attempt_row.id,'type',attempt_kind,'graded',attempt_kind<>'practice','hintsAllowed',case when attempt_kind='practice' then settings.practice_hints_enabled else settings.assessment_enabled and settings.assessment_max_hint_level>0 end,'maximumHintLevel',case when attempt_kind='practice' then 3 else settings.assessment_max_hint_level end) end,
  'currentQuestion',case when question_row.id is null then null else jsonb_build_object('id',question_row.id,'text',question_row.question_text,'hint',question_row.hint,'explanation',case when exists(select 1 from question_attempts qa where qa.assessment_attempt_id=attempt_row.id and qa.question_id=question_row.id) then question_row.explanation else null end,'attempted',exists(select 1 from question_attempts qa where qa.assessment_attempt_id=attempt_row.id and qa.question_id=question_row.id)) end,
  'mastery',(select coalesce(jsonb_agg(jsonb_build_object('skill',sk.name,'score',m.mastery_score,'confidence',m.confidence_score,'evidenceCount',m.evidence_count)),'[]') from student_skill_mastery m join skills sk on sk.id=m.skill_id where m.student_id=me.id and (course_row.id is null or sk.course_id=course_row.id) limit 8),
  'recommendation',case when recommendation.id is null then null else jsonb_build_object('targetId',recommendation.target_id,'reason',recommendation.reason_text) end);
 return jsonb_strip_nulls(result);
end$$;
revoke all on function public.nuru_build_context(uuid,uuid,uuid,uuid,uuid) from public; grant execute on function public.nuru_build_context(uuid,uuid,uuid,uuid,uuid) to authenticated;
grant select,insert on public.nuru_interactions,public.nuru_feedback,public.nuru_temporary_practice to service_role;

create function public.nuru_usage_summary(days integer default 7) returns table(topic text,interaction_type text,request_count bigint)
language sql stable security definer set search_path=public as $$select coalesce(n.title,c.title,'General learning'),i.interaction_type,count(*) from nuru_interactions i left join content_nodes n on n.id=i.content_node_id left join courses c on c.id=i.course_id where i.school_id=current_school_id() and current_profile_role() in('teacher','school_admin') and i.created_at>=now()-make_interval(days=>least(greatest(days,1),90)) group by 1,2 order by 3 desc$$;
grant execute on function public.nuru_usage_summary(integer) to authenticated;

create function public.save_nuru_feedback(requested_interaction uuid,requested_rating public.nuru_rating,requested_reason text default null) returns uuid
language plpgsql security definer set search_path=public as $$declare me uuid;result uuid;begin
 select s.id into me from student_profiles s join profiles p on p.id=s.profile_id where p.user_id=auth.uid();
 if me is null or not exists(select 1 from nuru_interactions i where i.id=requested_interaction and i.student_id=me) then raise exception 'Interaction unavailable';end if;
 insert into nuru_feedback(interaction_id,student_id,rating,reason) values(requested_interaction,me,requested_rating,left(requested_reason,300))
 on conflict(interaction_id,student_id) do update set rating=excluded.rating,reason=excluded.reason returning id into result;return result;
end$$;
grant execute on function public.save_nuru_feedback(uuid,public.nuru_rating,text) to authenticated;
