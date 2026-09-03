-- Learnova Stage 7: governed questions, secure assessment delivery and explainable mastery.
create type public.question_type as enum ('multiple_choice','multiple_select','true_false','short_answer','numeric');
create type public.question_difficulty as enum ('foundation','developing','proficient','challenge');
create type public.assessment_type as enum ('practice','checkpoint','mastery_quiz','diagnostic');
create type public.selection_mode as enum ('fixed','pool');
create type public.attempt_status as enum ('in_progress','submitted','abandoned');
create type public.mastery_level as enum ('still_learning','needs_practice','developing','on_track','strong');

-- Thresholds live in one tenant-overridable configuration rather than in clients.
create table public.mastery_settings (
 school_id uuid primary key references public.schools(id) on delete cascade,
 minimum_evidence integer not null default 3 check(minimum_evidence between 2 and 20),
 gap_threshold numeric(5,2) not null default 60, strong_threshold numeric(5,2) not null default 80,
 recent_window integer not null default 10 check(recent_window between 3 and 30),
 class_minimum_students integer not null default 5 check(class_minimum_students > 1), updated_at timestamptz not null default now()
);
create table public.skills (
 id uuid primary key default gen_random_uuid(), scope content_scope not null, school_id uuid references public.schools(id) on delete cascade,
 course_id uuid not null references public.courses(id) on delete cascade, content_node_id uuid references public.content_nodes(id) on delete set null,
 name text not null, description text not null default '', difficulty_level question_difficulty,
 parent_skill_id uuid references public.skills(id) on delete set null, created_at timestamptz not null default now(),
 constraint skill_scope check((scope='global' and school_id is null) or (scope='school' and school_id is not null))
);
create table public.questions (
 id uuid primary key default gen_random_uuid(), scope content_scope not null, school_id uuid references public.schools(id) on delete cascade,
 course_id uuid not null references public.courses(id) on delete cascade, content_node_id uuid references public.content_nodes(id) on delete set null,
 skill_id uuid references public.skills(id) on delete set null, question_type question_type not null, question_text text not null,
 normalized_question text not null, question_hash text not null, difficulty question_difficulty not null default 'foundation',
 answer_data_json jsonb not null, explanation text not null, hint text, points numeric(8,2) not null default 1 check(points>0),
 status content_status not null default 'draft', approved_by uuid references public.profiles(id), approved_at timestamptz,
 created_by uuid not null references public.profiles(id), created_by_ai boolean not null default false,
 generation_request_id uuid references public.ai_generation_requests(id) on delete set null,
 source_question_id uuid references public.questions(id) on delete set null, version integer not null default 1 check(version>0),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 constraint question_scope check((scope='global' and school_id is null) or (scope='school' and school_id is not null)),
 constraint published_question_approved check(status<>'published' or approved_at is not null)
);
create unique index questions_global_hash on public.questions(question_hash) where school_id is null and status<>'archived';
create unique index questions_school_hash on public.questions(school_id,question_hash) where school_id is not null and status<>'archived';
create table public.question_options (id uuid primary key default gen_random_uuid(), question_id uuid not null references public.questions(id) on delete cascade, text text not null, is_correct boolean not null default false, feedback text, sort_order integer not null default 0);
create table public.question_skills (question_id uuid references public.questions(id) on delete cascade, skill_id uuid references public.skills(id) on delete cascade, weight numeric(5,2) not null default 1 check(weight>0), primary key(question_id,skill_id));
create table public.question_tags (question_id uuid references public.questions(id) on delete cascade, tag_id uuid references public.tags(id) on delete cascade, primary key(question_id,tag_id));
create table public.assessments (
 id uuid primary key default gen_random_uuid(), scope content_scope not null, school_id uuid references public.schools(id) on delete cascade,
 course_id uuid not null references public.courses(id) on delete cascade, content_node_id uuid references public.content_nodes(id) on delete set null,
 title text not null, description text not null default '', assessment_type assessment_type not null,
 question_selection_mode selection_mode not null default 'fixed', question_count integer check(question_count>0),
 passing_threshold numeric(5,2) check(passing_threshold between 0 and 100), attempt_limit integer check(attempt_limit>0),
 pool_filters jsonb not null default '{}', status content_status not null default 'draft', created_by uuid not null references public.profiles(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 constraint assessment_scope check((scope='global' and school_id is null) or (scope='school' and school_id is not null))
);
create table public.assessment_questions (assessment_id uuid references public.assessments(id) on delete cascade, question_id uuid references public.questions(id) on delete restrict, sort_order integer not null default 0, weight numeric(5,2) not null default 1, primary key(assessment_id,question_id));
create table public.assessment_attempts (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 student_id uuid not null references public.student_profiles(id) on delete cascade, assessment_id uuid not null references public.assessments(id),
 course_id uuid not null references public.courses(id), started_at timestamptz not null default now(), submitted_at timestamptz,
 status attempt_status not null default 'in_progress', raw_score numeric(10,2), percentage_score numeric(5,2), created_at timestamptz not null default now()
);
create table public.attempt_questions (assessment_attempt_id uuid references public.assessment_attempts(id) on delete cascade, question_id uuid references public.questions(id), sort_order integer not null, primary key(assessment_attempt_id,question_id), unique(assessment_attempt_id,sort_order));
create table public.question_attempts (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 student_id uuid not null references public.student_profiles(id) on delete cascade, assessment_attempt_id uuid not null references public.assessment_attempts(id) on delete cascade,
 question_id uuid not null references public.questions(id), selected_answer_json jsonb not null, is_correct boolean, score_awarded numeric(8,2) not null default 0,
 time_spent_seconds integer check(time_spent_seconds>=0), hint_used boolean not null default false, attempt_number integer not null default 1,
 submitted_at timestamptz not null default now(), created_at timestamptz not null default now(), unique(assessment_attempt_id,question_id,attempt_number)
);
create table public.student_skill_mastery (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 student_id uuid not null references public.student_profiles(id) on delete cascade, skill_id uuid not null references public.skills(id) on delete cascade,
 mastery_score numeric(5,2) not null default 50 check(mastery_score between 0 and 100), confidence_score numeric(5,2) not null default 0 check(confidence_score between 0 and 100),
 evidence_count integer not null default 0, correct_count integer not null default 0, incorrect_count integer not null default 0,
 recent_correct_count integer not null default 0, recent_attempt_count integer not null default 0, last_practiced_at timestamptz,
 mastery_level mastery_level not null default 'still_learning', needs_practice boolean not null default false,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(student_id,skill_id)
);
create table public.mastery_events (id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade, student_id uuid not null references public.student_profiles(id) on delete cascade, skill_id uuid not null references public.skills(id), previous_score numeric(5,2) not null, new_score numeric(5,2) not null, reason text not null, evidence_source text not null, source_attempt_id uuid references public.question_attempts(id) on delete set null, created_at timestamptz not null default now());
create table public.student_question_history (student_id uuid references public.student_profiles(id) on delete cascade, question_id uuid references public.questions(id) on delete cascade, times_seen integer not null default 0, times_correct integer not null default 0, times_incorrect integer not null default 0, last_seen_at timestamptz, primary key(student_id,question_id));
create table public.practice_recommendations (id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade, student_id uuid not null references public.student_profiles(id) on delete cascade, skill_id uuid not null references public.skills(id), course_id uuid not null references public.courses(id), reason text not null, priority integer not null default 1, status text not null default 'active' check(status in ('active','completed','dismissed','expired')), generated_by text not null check(generated_by in ('rules_engine','teacher','future_ai')), created_at timestamptz not null default now(), completed_at timestamptz);
create unique index one_active_practice_recommendation on public.practice_recommendations(student_id,skill_id) where status='active';
create table public.practice_assignments (id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade, teacher_id uuid not null references public.teacher_profiles(id), class_id uuid references public.classes(id), student_id uuid references public.student_profiles(id), skill_id uuid not null references public.skills(id), question_count integer not null check(question_count between 1 and 50), difficulty_range jsonb not null default '["foundation","developing"]', due_at timestamptz, status text not null default 'active' check(status in ('active','completed','cancelled')), created_at timestamptz not null default now(), constraint assignment_target check((class_id is not null) <> (student_id is not null)));

create index question_delivery on public.questions(course_id,difficulty,status); create index attempt_student on public.question_attempts(student_id,submitted_at desc); create index mastery_student on public.student_skill_mastery(student_id,needs_practice); create index recommendations_student on public.practice_recommendations(student_id,status);

-- Only this projection is deliverable to students: answer keys and option correctness are absent.
create view public.student_question_bank with (security_invoker=true) as
 select q.id,q.course_id,q.content_node_id,q.question_type,q.question_text,q.difficulty,q.hint,q.points,
   coalesce((select jsonb_agg(jsonb_build_object('id',o.id,'text',o.text,'sort_order',o.sort_order) order by o.sort_order) from question_options o where o.question_id=q.id),'[]') options
 from questions q where q.status='published' and q.approved_at is not null;

create function public.owns_student(s uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from student_profiles sp join profiles p on p.id=sp.profile_id where sp.id=s and p.user_id=auth.uid()) $$;
create function public.teacher_can_view_student(s uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from student_profiles sp join teacher_profiles tp on tp.school_id=sp.school_id join profiles p on p.id=tp.profile_id join teacher_classes tc on tc.teacher_id=tp.id and tc.class_id=sp.class_id where sp.id=s and p.user_id=auth.uid()) $$;

-- Deterministic server-side validation; never returns an answer key before submission.
create function public.submit_question_answer(attempt uuid, question uuid, answer jsonb, used_hint boolean default false, elapsed integer default null)
returns jsonb language plpgsql security definer set search_path=public as $$
declare aa assessment_attempts; q questions; correct boolean:=false; awarded numeric:=0; qa_id uuid; selected_ids uuid[]; correct_ids uuid[]; accepted text[];
begin
 select * into aa from assessment_attempts where id=attempt and status='in_progress' for update;
 if not found or not owns_student(aa.student_id) then raise exception 'Active attempt not found'; end if;
 if not exists(select 1 from attempt_questions where assessment_attempt_id=attempt and question_id=question) then raise exception 'Question is not part of this attempt'; end if;
 select * into q from questions where id=question and status='published' and approved_at is not null;
 if not found then raise exception 'Question unavailable'; end if;
 if q.question_type='multiple_choice' then correct:=exists(select 1 from question_options where question_id=q.id and id=(answer->>'option_id')::uuid and is_correct);
 elsif q.question_type='multiple_select' then
   select array_agg(value::uuid order by value) into selected_ids from jsonb_array_elements_text(answer->'option_ids');
   select array_agg(id order by id) into correct_ids from question_options where question_id=q.id and is_correct;
   correct:=coalesce(selected_ids=correct_ids,false);
 elsif q.question_type='true_false' then correct:=lower(answer->>'value')=lower(q.answer_data_json->>'value');
 elsif q.question_type='numeric' then correct:=abs((answer->>'value')::numeric-(q.answer_data_json->>'value')::numeric)<=coalesce((q.answer_data_json->>'tolerance')::numeric,0);
 else select array_agg(lower(trim(value))) into accepted from jsonb_array_elements_text(q.answer_data_json->'accepted_answers'); correct:=lower(trim(answer->>'value'))=any(accepted); end if;
 awarded:=case when correct then q.points else 0 end;
 insert into question_attempts(school_id,student_id,assessment_attempt_id,question_id,selected_answer_json,is_correct,score_awarded,time_spent_seconds,hint_used)
 values(aa.school_id,aa.student_id,attempt,question,answer,correct,awarded,elapsed,used_hint) returning id into qa_id;
 perform update_skill_mastery(qa_id);
 return jsonb_build_object('is_correct',correct,'score_awarded',awarded,'feedback',case when correct then 'That''s right.' else 'Not quite.' end,'explanation',q.explanation,'correct_answer',q.answer_data_json);
end $$;

-- Incremental exponentially-smoothed evidence. Difficulty controls evidence weight; hints modestly reduce positive evidence.
create function public.update_skill_mastery(qa uuid) returns void language plpgsql security definer set search_path=public as $$
declare a question_attempts; q questions; sk record; old student_skill_mastery; prior numeric; target numeric; next_score numeric; n integer; rc integer; recent integer; minimum integer; gap numeric; level mastery_level;
begin
 select * into a from question_attempts where id=qa; select * into q from questions where id=a.question_id;
 for sk in select skill_id,weight from question_skills where question_id=q.id union select q.skill_id,1 where q.skill_id is not null and not exists(select 1 from question_skills where question_id=q.id) loop
   insert into student_skill_mastery(school_id,student_id,skill_id) values(a.school_id,a.student_id,sk.skill_id) on conflict(student_id,skill_id) do nothing;
   select * into old from student_skill_mastery where student_id=a.student_id and skill_id=sk.skill_id for update; prior:=old.mastery_score;
   target:=case when a.is_correct then 100 else 0 end; if a.is_correct and a.hint_used then target:=90; end if;
   -- 18% recent evidence prevents a single result from causing a dramatic swing; challenge evidence is modestly stronger.
   next_score:=round((prior+(target-prior)*(0.18*case q.difficulty when 'foundation' then 1.0 when 'developing' then 1.2 when 'proficient' then 1.4 else 1.6 end*sk.weight))::numeric,2);
   next_score:=greatest(0,least(100,next_score)); n:=old.evidence_count+1;
   select count(*),count(*) filter(where is_correct) into recent,rc from (select is_correct from question_attempts x join question_skills qs on qs.question_id=x.question_id where x.student_id=a.student_id and qs.skill_id=sk.skill_id order by x.submitted_at desc limit 10) z;
   select coalesce(minimum_evidence,3),coalesce(gap_threshold,60) into minimum,gap from mastery_settings where school_id=a.school_id;
   minimum:=coalesce(minimum,3); gap:=coalesce(gap,60);
   level:=case when n<minimum then 'still_learning' when next_score<40 then 'needs_practice' when next_score<60 then 'developing' when next_score<80 then 'on_track' else 'strong' end;
   update student_skill_mastery set mastery_score=next_score,confidence_score=least(100,round((100*(1-exp(-n/6.0)))::numeric,2)),evidence_count=n,correct_count=correct_count+(a.is_correct)::int,incorrect_count=incorrect_count+((not a.is_correct))::int,recent_correct_count=rc,recent_attempt_count=recent,last_practiced_at=a.submitted_at,mastery_level=level,needs_practice=(n>=minimum and next_score<gap),updated_at=now() where id=old.id;
   insert into mastery_events(school_id,student_id,skill_id,previous_score,new_score,reason,evidence_source,source_attempt_id) values(a.school_id,a.student_id,sk.skill_id,prior,next_score,format('%s %s question; recent evidence %s/%s',q.difficulty,case when a.is_correct then 'correct' else 'incorrect' end,rc,recent),'question_attempt',a.id);
   insert into student_question_history(student_id,question_id,times_seen,times_correct,times_incorrect,last_seen_at) values(a.student_id,q.id,1,(a.is_correct)::int,((not a.is_correct))::int,a.submitted_at) on conflict(student_id,question_id) do update set times_seen=student_question_history.times_seen+1,times_correct=student_question_history.times_correct+excluded.times_correct,times_incorrect=student_question_history.times_incorrect+excluded.times_incorrect,last_seen_at=excluded.last_seen_at;
   if n>=minimum and next_score<gap then insert into practice_recommendations(school_id,student_id,skill_id,course_id,reason,priority,generated_by) values(a.school_id,a.student_id,sk.skill_id,q.course_id,'Recent practice suggests this area could use another round.',greatest(1,ceil((gap-next_score)/10)),'rules_engine') on conflict(student_id,skill_id) where status='active' do update set priority=excluded.priority,reason=excluded.reason; end if;
 end loop;
end $$;

create function public.select_practice_questions(target_skill uuid, requested_count integer default 5) returns setof public.student_question_bank language sql security definer set search_path=public as $$
 select b.* from student_question_bank b join questions q on q.id=b.id join question_skills qs on qs.question_id=q.id
 left join student_question_history h on h.question_id=q.id and owns_student(h.student_id)
 left join student_skill_mastery m on m.skill_id=target_skill and owns_student(m.student_id)
 where qs.skill_id=target_skill and (q.scope='global' or q.school_id=current_school_id())
 -- A smoothed skill score (not one answer) chooses an adjacent difficulty band.
 order by abs((case q.difficulty when 'foundation' then 1 when 'developing' then 2 when 'proficient' then 3 else 4 end)-
   (case when coalesce(m.evidence_count,0)<3 or m.mastery_score<55 then 1 when m.mastery_score<72 then 2 when m.mastery_score<86 then 3 else 4 end)),
   h.last_seen_at nulls first,h.times_seen asc,random() limit greatest(1,least(requested_count,20));
$$;

create function public.start_practice_attempt(target_skill uuid, requested_count integer default 5) returns jsonb language plpgsql security definer set search_path=public as $$
declare student student_profiles; skill skills; assessment assessments; attempt_id uuid; question_rows jsonb;
begin
 select sp.* into student from student_profiles sp join profiles p on p.id=sp.profile_id where p.user_id=auth.uid() and p.role='student';
 if not found then raise exception 'Student profile required'; end if;
 select * into skill from skills s where s.id=target_skill and (s.scope='global' or s.school_id=student.school_id);
 if not found then raise exception 'Skill unavailable'; end if;
 select * into assessment from assessments a where a.course_id=skill.course_id and a.assessment_type='practice' and a.status='published' and (a.scope='global' or a.school_id=student.school_id) order by a.created_at limit 1;
 if not found then raise exception 'No published practice assessment is available for this skill'; end if;
 if assessment.attempt_limit is not null and (select count(*) from assessment_attempts where student_id=student.id and assessment_id=assessment.id and status='submitted')>=assessment.attempt_limit then raise exception 'Attempt limit reached'; end if;
 insert into assessment_attempts(school_id,student_id,assessment_id,course_id) values(student.school_id,student.id,assessment.id,skill.course_id) returning id into attempt_id;
 insert into attempt_questions(assessment_attempt_id,question_id,sort_order)
 select attempt_id,id,row_number() over() from select_practice_questions(target_skill,coalesce(requested_count,assessment.question_count,5));
 select jsonb_agg(to_jsonb(q) order by aq.sort_order) into question_rows from attempt_questions aq join student_question_bank q on q.id=aq.question_id where aq.assessment_attempt_id=attempt_id;
 if coalesce(jsonb_array_length(question_rows),0)=0 then delete from assessment_attempts where id=attempt_id; raise exception 'No approved published questions are available'; end if;
 return jsonb_build_object('attempt_id',attempt_id,'questions',question_rows);
end $$;

create function public.complete_assessment_attempt(attempt uuid) returns jsonb language plpgsql security definer set search_path=public as $$
declare aa assessment_attempts; raw numeric; possible numeric; percent numeric;
begin
 select * into aa from assessment_attempts where id=attempt and status='in_progress' for update;
 if not found or not owns_student(aa.student_id) then raise exception 'Active attempt not found'; end if;
 if exists(select 1 from attempt_questions aq where aq.assessment_attempt_id=attempt and not exists(select 1 from question_attempts qa where qa.assessment_attempt_id=attempt and qa.question_id=aq.question_id)) then raise exception 'Answer every delivered question before completing'; end if;
 select coalesce(sum(qa.score_awarded),0),coalesce(sum(q.points),0) into raw,possible from question_attempts qa join questions q on q.id=qa.question_id where qa.assessment_attempt_id=attempt;
 percent:=case when possible>0 then round(raw/possible*100,2) else 0 end;
 update assessment_attempts set status='submitted',submitted_at=now(),raw_score=raw,percentage_score=percent where id=attempt;
 return jsonb_build_object('raw_score',raw,'percentage_score',percent);
end $$;

create function public.assign_practice(student_id uuid default null,class_id uuid default null,skill_id uuid default null,question_count integer default 5,difficulty_range jsonb default '["foundation","developing"]',due_at timestamptz default null) returns uuid language plpgsql security definer set search_path=public as $$
declare teacher teacher_profiles; result uuid;
begin
 select tp.* into teacher from teacher_profiles tp join profiles p on p.id=tp.profile_id where p.user_id=auth.uid();
 if not found or ((student_id is null)=(class_id is null)) then raise exception 'Authorized teacher and one assignment target required'; end if;
 if student_id is not null and not teacher_can_view_student(student_id) then raise exception 'Student is outside your assigned classes'; end if;
 if class_id is not null and not exists(select 1 from teacher_classes where teacher_id=teacher.id and teacher_classes.class_id=assign_practice.class_id) then raise exception 'Class is not assigned to this teacher'; end if;
 if not exists(select 1 from skills s where s.id=skill_id and (s.scope='global' or s.school_id=teacher.school_id)) then raise exception 'Skill unavailable'; end if;
 insert into practice_assignments(school_id,teacher_id,class_id,student_id,skill_id,question_count,difficulty_range,due_at) values(teacher.school_id,teacher.id,class_id,student_id,skill_id,greatest(1,least(question_count,50)),difficulty_range,due_at) returning id into result; return result;
end $$;

-- RLS: students own evidence; educators see only authorized learners; admins get aggregates through RPCs/views.
do $$ declare t text; begin foreach t in array array['mastery_settings','skills','questions','question_options','question_skills','question_tags','assessments','assessment_questions','assessment_attempts','attempt_questions','question_attempts','student_skill_mastery','mastery_events','student_question_history','practice_recommendations','practice_assignments'] loop execute format('alter table public.%I enable row level security',t); end loop; end $$;
create policy skills_read on skills for select using(scope='global' or school_id=current_school_id());
create policy questions_staff_read on questions for select using(is_platform_admin() or current_profile_role() in ('school_admin','teacher') and (scope='global' or school_id=current_school_id()));
create policy question_options_staff_read on question_options for select using(current_profile_role()<>'student' and exists(select 1 from questions q where q.id=question_id and (q.scope='global' or q.school_id=current_school_id())));
create policy assessment_read on assessments for select using(status='published' and (scope='global' or school_id=current_school_id()) or current_profile_role()<>'student' and (scope='global' or school_id=current_school_id()));
create policy student_attempt_own on assessment_attempts for select using(owns_student(student_id) or teacher_can_view_student(student_id) or current_profile_role()='school_admin' and school_id=current_school_id());
create policy student_question_attempt_own on question_attempts for select using(owns_student(student_id) or teacher_can_view_student(student_id));
create policy student_mastery_own on student_skill_mastery for select using(owns_student(student_id) or teacher_can_view_student(student_id));
create policy mastery_events_own on mastery_events for select using(owns_student(student_id) or teacher_can_view_student(student_id));
create policy history_own on student_question_history for select using(owns_student(student_id));
create policy recommendations_own on practice_recommendations for select using(owns_student(student_id) or teacher_can_view_student(student_id));
create policy assignments_read on practice_assignments for select using(school_id=current_school_id() and (current_profile_role() in ('teacher','school_admin') or student_id is not null and owns_student(student_id) or class_id in(select class_id from student_profiles where owns_student(id))));
create policy assignments_teacher_write on practice_assignments for insert with check(school_id=current_school_id() and teacher_id=(select tp.id from teacher_profiles tp join profiles p on p.id=tp.profile_id where p.user_id=auth.uid()) and (student_id is null or teacher_can_view_student(student_id)));
create policy governed_question_write on questions for all using(is_platform_admin() or school_id=current_school_id() and current_profile_role() in ('school_admin','teacher')) with check(is_platform_admin() or school_id=current_school_id() and current_profile_role() in ('school_admin','teacher'));
create policy governed_skill_write on skills for all using(is_platform_admin() or school_id=current_school_id() and current_profile_role() in ('school_admin','teacher')) with check(is_platform_admin() or school_id=current_school_id() and current_profile_role() in ('school_admin','teacher'));
create policy governed_assessment_write on assessments for all using(is_platform_admin() or school_id=current_school_id() and current_profile_role() in ('school_admin','teacher')) with check(is_platform_admin() or school_id=current_school_id() and current_profile_role() in ('school_admin','teacher'));
create trigger questions_updated before update on questions for each row execute function touch_updated_at(); create trigger assessments_updated before update on assessments for each row execute function touch_updated_at();
grant select on public.student_question_bank to authenticated; grant execute on function public.submit_question_answer(uuid,uuid,jsonb,boolean,integer),public.select_practice_questions(uuid,integer),public.start_practice_attempt(uuid,integer),public.complete_assessment_attempt(uuid),public.assign_practice(uuid,uuid,uuid,integer,jsonb,timestamptz) to authenticated;
