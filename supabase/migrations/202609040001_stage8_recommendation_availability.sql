-- Stage 8 hardening: recommendations are re-authorized when read or created.
-- A stored recommendation is never treated as an entitlement to content.
create or replace function public.student_target_is_available(
  requested_student uuid,
  requested_target uuid,
  requested_type public.graph_entity_type
) returns boolean
language sql stable security definer set search_path=public as $$
  select case requested_type
    when 'course' then exists (
      select 1 from student_profiles s
      join courses c on c.id=requested_target and c.status='published' and c.approved_at is not null
      left join school_course_adoptions a on a.school_id=s.school_id and a.course_id=c.id and a.active
      left join school_course_assignments x on x.school_id=s.school_id and x.course_id=c.id and x.is_active
        and (x.grade_id is null or x.grade_id=s.grade_id) and (x.class_id is null or x.class_id=s.class_id)
        and (x.available_from is null or x.available_from<=now()) and (x.available_until is null or x.available_until>=now())
      where s.id=requested_student and s.status='active' and
        ((c.scope='school' and c.school_id=s.school_id and (c.grade_id is null or c.grade_id=s.grade_id))
          or (c.scope='global' and (a.id is not null or x.id is not null)))
    )
    when 'pathway' then exists (
      select 1 from student_profiles s join grades g on g.id=s.grade_id
      join school_pathway_settings x on x.school_id=s.school_id and x.pathway_id=requested_target and x.enabled
      join learning_pathways p on p.id=x.pathway_id and p.status='published'
      where s.id=requested_student
        and (coalesce(x.minimum_grade,p.minimum_grade) is null or g.level_number>=coalesce(x.minimum_grade,p.minimum_grade))
        and (coalesce(x.maximum_grade,p.maximum_grade) is null or g.level_number<=coalesce(x.maximum_grade,p.maximum_grade))
    )
    when 'skill' then exists (
      select 1 from skills sk join student_profiles st on st.id=requested_student
      join courses c on c.id=sk.course_id and c.status='published' and c.approved_at is not null
      left join school_course_adoptions a on a.school_id=st.school_id and a.course_id=c.id and a.active
      left join school_course_assignments x on x.school_id=st.school_id and x.course_id=c.id and x.is_active
        and (x.grade_id is null or x.grade_id=st.grade_id) and (x.class_id is null or x.class_id=st.class_id)
      where sk.id=requested_target and ((c.scope='school' and c.school_id=st.school_id) or (c.scope='global' and (a.id is not null or x.id is not null)))
    )
    when 'content_node' then exists (
      select 1 from content_nodes n join student_profiles s on s.id=requested_student
      join courses c on c.id=n.course_id and c.status='published' and c.approved_at is not null
      left join school_course_adoptions a on a.school_id=s.school_id and a.course_id=c.id and a.active
      left join school_course_assignments x on x.school_id=s.school_id and x.course_id=c.id and x.is_active
        and (x.grade_id is null or x.grade_id=s.grade_id) and (x.class_id is null or x.class_id=s.class_id)
      where n.id=requested_target and n.status='published' and n.approved_at is not null
        and ((c.scope='school' and c.school_id=s.school_id) or (c.scope='global' and (a.id is not null or x.id is not null)))
    )
    when 'project' then exists (
      select 1 from content_nodes n join student_profiles s on s.id=requested_student
      join courses c on c.id=n.course_id and c.status='published' and c.approved_at is not null
      left join school_course_adoptions a on a.school_id=s.school_id and a.course_id=c.id and a.active
      left join school_course_assignments x on x.school_id=s.school_id and x.course_id=c.id and x.is_active
        and (x.grade_id is null or x.grade_id=s.grade_id) and (x.class_id is null or x.class_id=s.class_id)
      where n.id=requested_target and n.content_type='project' and n.status='published' and n.approved_at is not null
        and ((c.scope='school' and c.school_id=s.school_id) or (c.scope='global' and (a.id is not null or x.id is not null)))
        and not exists (
          select 1 from learning_graph_relationships edge
          where edge.source_id=n.id and edge.relationship_type='prerequisite' and edge.is_required
            and not exists (
              select 1 where
                (edge.target_type='course' and exists(select 1 from learning_events e where e.student_id=s.id and e.event_type='course_completed' and e.course_id=edge.target_id))
                or (edge.target_type='skill' and exists(select 1 from student_skill_mastery m where m.student_id=s.id and m.skill_id=edge.target_id and m.mastery_level in('on_track','strong')))
                or (edge.target_type='content_node' and exists(select 1 from student_content_progress cp where cp.student_id=s.id and cp.content_node_id=edge.target_id and cp.status='completed'))
                or (edge.target_type='pathway' and exists(select 1 from student_pathway_progress pp where pp.student_id=s.id and pp.pathway_id=edge.target_id and pp.status='completed'))
            )
        )
    )
    else false
  end;
$$;

revoke all on function public.student_target_is_available(uuid,uuid,public.graph_entity_type) from public;

create or replace function public.teacher_recommend_learning(requested_student uuid,requested_target uuid,requested_target_type text,requested_note text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare teacher teacher_profiles;result uuid;kind graph_entity_type;
begin
  select t.* into teacher from teacher_profiles t join profiles p on p.id=t.profile_id where p.user_id=auth.uid();
  if not found or not teacher_can_view_student(requested_student) then raise exception 'Student is outside your assigned classes';end if;
  begin kind:=requested_target_type::graph_entity_type;exception when invalid_text_representation then raise exception 'Unsupported recommendation type';end;
  if not student_target_is_available(requested_student,requested_target,kind) then
    raise exception 'Target is unavailable or its prerequisites are incomplete';
  end if;
  insert into student_recommendations(school_id,student_id,recommendation_type,target_type,target_id,score,reason_code,reason_text,generated_by,teacher_id)
  values(teacher.school_id,requested_student,'teacher_recommended',kind,requested_target,35,'teacher_recommended',
    'Recommended by '||(select first_name||' '||last_name from profiles where id=teacher.profile_id)||coalesce(': '||nullif(trim(requested_note),''),''),'teacher',teacher.id)
  returning id into result;return result;
end$$;

create or replace function public.generate_student_recommendations() returns jsonb
language sql security invoker set search_path=public as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'targetId',r.target_id,'targetType',r.target_type,
    'title',coalesce(c.title,p.title,s.name,n.title),
    'description',coalesce(c.description,p.description,n.body,''),
    'recommendationType',r.recommendation_type,
    'category',case when r.recommendation_type='practice' then 'learning' else 'exploration' end,
    'score',r.score,'reasonCode',r.reason_code,'reasonText',r.reason_text
  ) order by r.score desc),'[]'::jsonb)
  from student_recommendations r
  join student_profiles me on me.id=r.student_id and owns_student(me.id)
  left join courses c on r.target_type='course' and c.id=r.target_id
  left join learning_pathways p on r.target_type='pathway' and p.id=r.target_id
  left join skills s on r.target_type='skill' and s.id=r.target_id
  left join content_nodes n on r.target_type in ('content_node','project') and n.id=r.target_id
  where r.status='active' and (r.expires_at is null or r.expires_at>now())
    and student_target_is_available(me.id,r.target_id,r.target_type)
    and not exists(select 1 from recommendation_feedback f where f.recommendation_id=r.id and f.feedback_type='not_interested');
$$;

comment on function public.student_target_is_available is 'Server-side Stage 8 authorization boundary: checks publication, tenancy, school enablement, grade and project prerequisites.';
