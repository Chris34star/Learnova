-- Stage 12: close governance privilege gaps, reduce RPC attack surface, and add pilot query indexes.

-- A teacher may edit only their own school draft/review item and may never change its tenant or publish it.
drop policy if exists nodes_teacher_own_draft on public.content_nodes;
create policy nodes_teacher_own_draft on public.content_nodes for update
 using(scope='school' and school_id=current_school_id() and current_profile_role()='teacher'
   and created_by=(select id from profiles where user_id=auth.uid()) and status in('draft','in_review'))
 with check(scope='school' and school_id=current_school_id()
   and created_by=(select id from profiles where user_id=auth.uid()) and status in('draft','in_review'));

drop policy if exists reviews_submit on public.content_reviews;
create policy reviews_submit on public.content_reviews for insert
 with check(submitted_by=(select id from profiles where user_id=auth.uid())
   and (is_platform_admin() or (school_id=current_school_id() and current_profile_role() in('teacher','school_admin'))));
drop policy if exists audit_insert on public.content_approval_actions;
create policy audit_insert on public.content_approval_actions for insert
 with check(actor_id=(select id from profiles where user_id=auth.uid())
   and (is_platform_admin() or (school_id=current_school_id() and current_profile_role() in('teacher','school_admin'))));

-- Replace the broad question/assessment ALL policies. Teachers author drafts; school admins approve/publish.
drop policy if exists governed_question_write on public.questions;
create policy questions_platform_write on public.questions for all using(is_platform_admin()) with check(is_platform_admin());
create policy questions_school_insert on public.questions for insert
 with check(scope='school' and school_id=current_school_id() and current_profile_role() in('teacher','school_admin')
   and status='draft' and approved_at is null and approved_by is null);
create policy questions_teacher_update on public.questions for update
 using(scope='school' and school_id=current_school_id() and current_profile_role()='teacher'
   and created_by=(select id from profiles where user_id=auth.uid()) and status in('draft','in_review'))
 with check(scope='school' and school_id=current_school_id()
   and created_by=(select id from profiles where user_id=auth.uid()) and status in('draft','in_review')
   and approved_at is null and approved_by is null);
create policy questions_admin_update on public.questions for update
 using(scope='school' and school_id=current_school_id() and current_profile_role()='school_admin')
 with check(scope='school' and school_id=current_school_id());

drop policy if exists governed_assessment_write on public.assessments;
create policy assessments_platform_write on public.assessments for all using(is_platform_admin()) with check(is_platform_admin());
create policy assessments_school_insert on public.assessments for insert
 with check(scope='school' and school_id=current_school_id() and current_profile_role() in('teacher','school_admin') and status='draft');
create policy assessments_teacher_update on public.assessments for update
 using(scope='school' and school_id=current_school_id() and current_profile_role()='teacher'
   and created_by=(select id from profiles where user_id=auth.uid()) and status in('draft','in_review'))
 with check(scope='school' and school_id=current_school_id()
   and created_by=(select id from profiles where user_id=auth.uid()) and status in('draft','in_review'));
create policy assessments_admin_update on public.assessments for update
 using(scope='school' and school_id=current_school_id() and current_profile_role()='school_admin')
 with check(scope='school' and school_id=current_school_id());

-- Project state transitions are RPC-only. Legacy ALL policies allowed owners to forge completion/review fields.
drop policy if exists projects_student_write on public.student_projects;
drop policy if exists milestones_access on public.student_project_milestones;
create policy milestones_read on public.student_project_milestones for select
 using(exists(select 1 from student_projects p where p.id=student_project_id and
   (owns_student(p.student_id) or teacher_can_view_student(p.student_id)
    or (p.school_id=current_school_id() and current_profile_role()='school_admin') or is_platform_admin())));

-- An update must remain owned by the same teacher and within that teacher's assigned class/student scope.
drop policy if exists interventions_teacher_update on public.learning_interventions;
create policy interventions_teacher_update on public.learning_interventions for update
 using(school_id=current_school_id() and current_profile_role()='teacher'
   and teacher_id=(select tp.id from teacher_profiles tp join profiles p on p.id=tp.profile_id where p.user_id=auth.uid()))
 with check(school_id=current_school_id() and current_profile_role()='teacher'
   and teacher_id=(select tp.id from teacher_profiles tp join profiles p on p.id=tp.profile_id where p.user_id=auth.uid())
   and (student_id is null or teacher_can_view_student(student_id))
   and (class_id is null or exists(select 1 from teacher_classes tc where tc.teacher_id=learning_interventions.teacher_id and tc.class_id=learning_interventions.class_id)));

-- Public receives EXECUTE by default in PostgreSQL. Explicitly expose only the narrow authenticated API.
revoke execute on function public.accept_content_proposal(uuid) from public,anon;
grant execute on function public.accept_content_proposal(uuid) to authenticated;
revoke execute on function public.authorize_nuru_generation(public.suggestion_scope,uuid,text,jsonb,text,text) from public,anon;
grant execute on function public.authorize_nuru_generation(public.suggestion_scope,uuid,text,jsonb,text,text) to authenticated;
revoke execute on function public.nuru_usage_summary(integer),public.save_nuru_feedback(uuid,public.nuru_rating,text) from public,anon;
revoke execute on function public.submit_question_answer(uuid,uuid,jsonb,boolean,integer),public.select_practice_questions(uuid,integer),public.start_practice_attempt(uuid,integer),public.complete_assessment_attempt(uuid),public.assign_practice(uuid,uuid,uuid,integer,jsonb,timestamptz) from public,anon;
revoke execute on function public.set_student_interest(text,text,text,text),public.configure_school_pathway(uuid,boolean,integer,integer,text),public.teacher_recommend_learning(uuid,uuid,text,text),public.record_recommendation_feedback(uuid,text),public.generate_student_recommendations(),public.refresh_student_pathway_progress(uuid) from public,anon;
revoke execute on function public.start_student_project(uuid),public.save_project_milestone(uuid,uuid,public.project_status,text),public.submit_student_project(uuid,jsonb,text),public.review_student_project(uuid,public.project_review_status,text,jsonb),public.student_project_progress(uuid),public.nuru_build_project_context(uuid) from public,anon;
revoke execute on function public.configure_grade_learning(uuid,integer,time,time),public.save_exam_mode(uuid,uuid,text,text,date,date,uuid[],boolean),public.record_learning_intervention(uuid,uuid,uuid,text,text,text,date),public.teacher_class_intelligence(uuid),public.student_daily_plan(),public.school_intelligence() from public,anon;

-- Bound user-authored text at the database boundary. NOT VALID avoids blocking rollout on legacy rows while enforcing new writes.
alter table public.learning_interventions add constraint intervention_reason_code_length check(length(reason_code) between 1 and 200) not valid;
alter table public.questions add constraint question_text_length check(length(question_text) between 1 and 4000) not valid;
alter table public.assessments add constraint assessment_title_length check(length(title) between 1 and 200) not valid;

create index if not exists assessment_attempts_school_student_status_idx on public.assessment_attempts(school_id,student_id,status,created_at desc);
create index if not exists student_progress_school_student_course_idx on public.student_content_progress(school_id,student_id,course_id);
create index if not exists interventions_school_student_status_idx on public.learning_interventions(school_id,student_id,status,created_at desc);
create index if not exists student_projects_school_student_status_idx on public.student_projects(school_id,student_id,status,updated_at desc);
create index if not exists learning_assignments_school_class_status_idx on public.learning_assignments(school_id,class_id,status,created_at desc);

comment on function public.accept_content_proposal(uuid) is 'Authenticated platform-admin operation; authorization is derived from auth.uid().';
