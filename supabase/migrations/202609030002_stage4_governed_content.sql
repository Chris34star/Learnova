-- Learnova Stage 4: governed, versioned content. Apply after Stage 3.
create type public.content_scope as enum ('global','school');
create type public.content_family as enum ('academic','skills');
create type public.content_status as enum ('draft','in_review','approved','published','rejected','archived');
create type public.content_type as enum ('module','topic','subtopic','lesson','explanation','example','activity','practice','quiz','project','resource','challenge','milestone');
create type public.review_decision as enum ('submitted','changes_requested','rejected','approved');
create type public.proposal_status as enum ('pending','changes_requested','rejected','accepted');
create type public.content_action as enum ('created','edited','submitted','approved','rejected','changes_requested','published','archived','override_created','override_removed','proposed_to_global');
create type public.relationship_type as enum ('prerequisite','recommended_after','related','next_level','supports_skill');

create table public.courses (
 id uuid primary key default gen_random_uuid(), scope content_scope not null, school_id uuid references public.schools(id) on delete cascade,
 title text not null, slug text not null, description text not null default '', content_family content_family not null,
 subject_id uuid references public.subjects(id) on delete set null, grade_id uuid references public.grades(id) on delete set null,
 difficulty text, learning_objectives jsonb not null default '[]', status content_status not null default 'draft',
 created_by uuid not null references public.profiles(id), approved_by uuid references public.profiles(id), approved_at timestamptz,
 origin_school_course_id uuid references public.courses(id), version integer not null default 1 check(version > 0),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 constraint course_scope_tenant check ((scope='global' and school_id is null) or (scope='school' and school_id is not null))
);
create unique index courses_global_slug on public.courses(slug) where school_id is null;
create unique index courses_school_slug on public.courses(school_id,slug) where school_id is not null;

create table public.content_nodes (
 id uuid primary key default gen_random_uuid(), course_id uuid not null references public.courses(id) on delete cascade,
 parent_id uuid references public.content_nodes(id) on delete cascade, sort_order integer not null default 0,
 content_type content_type not null, title text not null, structured_content jsonb not null default '{}', body text not null default '',
 learning_objectives jsonb not null default '[]', metadata jsonb not null default '{}', status content_status not null default 'draft',
 scope content_scope not null, school_id uuid references public.schools(id) on delete cascade,
 source_content_id uuid references public.content_nodes(id) on delete restrict, is_override boolean not null default false,
 origin_school_content_id uuid references public.content_nodes(id) on delete set null,
 version integer not null default 1 check(version > 0), created_by uuid not null references public.profiles(id),
 approved_by uuid references public.profiles(id), approved_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 constraint node_scope_tenant check ((scope='global' and school_id is null) or (scope='school' and school_id is not null)),
 constraint valid_override check ((is_override and scope='school' and source_content_id is not null) or (not is_override and source_content_id is null))
);
create unique index one_active_override on public.content_nodes(school_id,source_content_id) where is_override and status <> 'archived';
create index content_nodes_tree on public.content_nodes(course_id,parent_id,sort_order);

-- Immutable snapshots preserve every meaningful revision and make rollback possible later.
create table public.content_versions (
 id uuid primary key default gen_random_uuid(), content_node_id uuid not null references public.content_nodes(id) on delete cascade,
 version integer not null, title text not null, structured_content jsonb not null, body text not null,
 learning_objectives jsonb not null, metadata jsonb not null, status content_status not null,
 author_id uuid not null references public.profiles(id), change_summary text not null, created_at timestamptz not null default now(),
 unique(content_node_id,version)
);
create table public.school_course_adoptions (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 course_id uuid not null references public.courses(id) on delete cascade, adopted_by uuid not null references public.profiles(id),
 active boolean not null default true, created_at timestamptz not null default now(), unique(school_id,course_id)
);
create table public.content_reviews (
 id uuid primary key default gen_random_uuid(), content_node_id uuid not null references public.content_nodes(id) on delete cascade,
 version integer not null, school_id uuid references public.schools(id) on delete cascade, submitted_by uuid not null references public.profiles(id),
 assigned_to uuid references public.profiles(id), decision review_decision not null default 'submitted', note text,
 decided_by uuid references public.profiles(id), created_at timestamptz not null default now(), decided_at timestamptz
);
create table public.content_approval_actions (
 id uuid primary key default gen_random_uuid(), content_node_id uuid references public.content_nodes(id) on delete cascade,
 course_id uuid references public.courses(id) on delete cascade, school_id uuid references public.schools(id) on delete cascade,
 actor_id uuid not null references public.profiles(id), action content_action not null, note text, metadata jsonb not null default '{}', created_at timestamptz not null default now(),
 constraint action_target check(content_node_id is not null or course_id is not null)
);
create table public.content_proposals (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 source_content_id uuid not null references public.content_nodes(id) on delete restrict, proposed_by uuid not null references public.profiles(id),
 status proposal_status not null default 'pending', note text, reviewed_by uuid references public.profiles(id), reviewed_at timestamptz,
 resulting_global_content_id uuid references public.content_nodes(id), created_at timestamptz not null default now()
);
create table public.tags (id uuid primary key default gen_random_uuid(), name text not null unique, slug text not null unique);
create table public.content_tags (content_node_id uuid not null references public.content_nodes(id) on delete cascade, tag_id uuid not null references public.tags(id) on delete cascade, primary key(content_node_id,tag_id));
create table public.course_tags (course_id uuid not null references public.courses(id) on delete cascade, tag_id uuid not null references public.tags(id) on delete cascade, primary key(course_id,tag_id));
create table public.content_relationships (
 id uuid primary key default gen_random_uuid(), from_course_id uuid references public.courses(id) on delete cascade, from_content_id uuid references public.content_nodes(id) on delete cascade,
 to_course_id uuid references public.courses(id) on delete cascade, to_content_id uuid references public.content_nodes(id) on delete cascade,
 relationship relationship_type not null, created_at timestamptz not null default now(),
 constraint relationship_ends check ((from_course_id is not null) <> (from_content_id is not null) and (to_course_id is not null) <> (to_content_id is not null))
);

create trigger courses_updated before update on public.courses for each row execute function public.touch_updated_at();
create trigger content_nodes_updated before update on public.content_nodes for each row execute function public.touch_updated_at();

create function public.version_content_node() returns trigger language plpgsql security definer set search_path=public as $$
declare actor uuid;
begin
 actor:=coalesce((select id from profiles where user_id=auth.uid()),new.created_by);
 if tg_op='INSERT' then
  insert into content_versions(content_node_id,version,title,structured_content,body,learning_objectives,metadata,status,author_id,change_summary)
  values(new.id,new.version,new.title,new.structured_content,new.body,new.learning_objectives,new.metadata,new.status,actor,'Initial version');
 elsif (old.title,old.structured_content,old.body,old.learning_objectives,old.metadata,old.status)
       is distinct from (new.title,new.structured_content,new.body,new.learning_objectives,new.metadata,new.status) then
  new.version:=old.version+1;
  insert into content_versions(content_node_id,version,title,structured_content,body,learning_objectives,metadata,status,author_id,change_summary)
  values(new.id,new.version,new.title,new.structured_content,new.body,new.learning_objectives,new.metadata,new.status,actor,coalesce(new.metadata->>'change_summary','Content updated'));
 end if;
 return new;
end $$;
create trigger content_nodes_version_insert after insert on public.content_nodes for each row execute function public.version_content_node();
create trigger content_nodes_version_update before update on public.content_nodes for each row execute function public.version_content_node();

create function public.audit_content_node() returns trigger language plpgsql security definer set search_path=public as $$
declare actor uuid; event content_action;
begin
 actor:=coalesce((select id from profiles where user_id=auth.uid()),new.created_by);
 if tg_op='INSERT' then event:=case when new.is_override then 'override_created'::content_action else 'created'::content_action end;
 elsif new.status<>old.status then event:=case new.status when 'in_review' then 'submitted'::content_action when 'approved' then 'approved'::content_action when 'rejected' then 'rejected'::content_action when 'published' then 'published'::content_action when 'archived' then (case when old.is_override then 'override_removed'::content_action else 'archived'::content_action end) else 'edited'::content_action end;
 else event:='edited'; end if;
 insert into content_approval_actions(content_node_id,course_id,school_id,actor_id,action)
 values(new.id,new.course_id,new.school_id,actor,event);
 return new;
end $$;
create trigger content_nodes_audit after insert or update on public.content_nodes for each row execute function public.audit_content_node();

-- Proposal acceptance deliberately derives a separate, sanitized global draft.
create function public.accept_content_proposal(proposal_id uuid)
returns uuid language plpgsql security definer set search_path=public as $$
declare p content_proposals; source content_nodes; source_course courses; actor uuid; global_course uuid; global_node uuid;
begin
 if not is_platform_admin() then raise exception 'Platform administrator required'; end if;
 select * into p from content_proposals where id=proposal_id and status='pending' for update;
 if not found then raise exception 'Pending proposal not found'; end if;
 select * into source from content_nodes where id=p.source_content_id;
 select * into source_course from courses where id=source.course_id;
 select id into actor from profiles where user_id=auth.uid();
 insert into courses(scope,title,slug,description,content_family,difficulty,learning_objectives,status,created_by,origin_school_course_id)
 values('global',source_course.title,source_course.slug||'-proposal-'||left(p.id::text,8),source_course.description,source_course.content_family,source_course.difficulty,source_course.learning_objectives,'draft',actor,source_course.id)
 returning id into global_course;
 insert into content_nodes(course_id,content_type,title,structured_content,body,learning_objectives,metadata,status,scope,created_by,origin_school_content_id)
 values(global_course,source.content_type,source.title,source.structured_content,source.body,source.learning_objectives,
        source.metadata - 'school_id' - 'student_id' - 'student_ids' - 'author_email','draft','global',actor,source.id)
 returning id into global_node;
 update content_proposals set status='accepted',reviewed_by=actor,reviewed_at=now(),resulting_global_content_id=global_node where id=p.id;
 return global_node;
end $$;

-- An adopted tree stays referenced. The lateral join replaces only nodes overridden by this school.
create function public.effective_course_nodes(adoption_school_id uuid, adopted_course_id uuid)
returns setof public.content_nodes language sql stable security invoker as $$
 select resolved.* from content_nodes n
 left join lateral (
   select x.* from content_nodes x where x.school_id=adoption_school_id and x.source_content_id=n.id
     and x.is_override and x.status <> 'archived' order by x.updated_at desc limit 1
 ) o on true
 cross join lateral (select r.* from content_nodes r where r.id=coalesce(o.id,n.id)) resolved
 where n.course_id=adopted_course_id and n.scope='global'
   and exists(select 1 from school_course_adoptions a where a.school_id=adoption_school_id and a.course_id=adopted_course_id and a.active)
 order by n.parent_id nulls first,n.sort_order;
$$;

-- Student-facing code must use this view: publication plus prior human approval are mandatory.
create view public.student_published_content with (security_invoker=true) as
 select n.* from content_nodes n join courses c on c.id=n.course_id
 where n.status='published' and n.approved_at is not null and c.status='published' and c.approved_at is not null;

alter table public.courses enable row level security; alter table public.content_nodes enable row level security;
alter table public.content_versions enable row level security; alter table public.school_course_adoptions enable row level security;
alter table public.content_reviews enable row level security; alter table public.content_approval_actions enable row level security;
alter table public.content_proposals enable row level security; alter table public.tags enable row level security;
alter table public.content_tags enable row level security; alter table public.course_tags enable row level security; alter table public.content_relationships enable row level security;

create policy courses_read on public.courses for select using (scope='global' or is_platform_admin() or school_id=current_school_id());
create policy courses_platform_write on public.courses for all using (is_platform_admin()) with check(is_platform_admin());
create policy courses_school_create on public.courses for insert with check(scope='school' and school_id=current_school_id() and current_profile_role() in ('school_admin','teacher') and status='draft');
create policy courses_school_admin_update on public.courses for update using(scope='school' and school_id=current_school_id() and current_profile_role()='school_admin') with check(scope='school' and school_id=current_school_id());
create policy nodes_read_staff on public.content_nodes for select using (is_platform_admin() or (current_profile_role() in ('school_admin','teacher') and (scope='global' or school_id=current_school_id())) or (current_profile_role()='student' and status='published' and approved_at is not null and (school_id=current_school_id() or (scope='global' and exists(select 1 from school_course_adoptions a where a.course_id=content_nodes.course_id and a.school_id=current_school_id() and a.active)))));
create policy nodes_platform_write on public.content_nodes for all using(is_platform_admin()) with check(is_platform_admin());
create policy nodes_school_insert on public.content_nodes for insert with check(scope='school' and school_id=current_school_id() and current_profile_role() in ('school_admin','teacher') and status='draft');
create policy nodes_school_admin_update on public.content_nodes for update using(scope='school' and school_id=current_school_id() and current_profile_role()='school_admin') with check(scope='school' and school_id=current_school_id());
create policy nodes_teacher_own_draft on public.content_nodes for update using(scope='school' and school_id=current_school_id() and current_profile_role()='teacher' and created_by=(select id from profiles where user_id=auth.uid()) and status in ('draft','in_review')) with check(status in ('draft','in_review'));
create policy versions_read on public.content_versions for select using(exists(select 1 from content_nodes n where n.id=content_node_id and (is_platform_admin() or n.scope='global' or n.school_id=current_school_id())));
create policy versions_insert on public.content_versions for insert with check(author_id=(select id from profiles where user_id=auth.uid()) and exists(select 1 from content_nodes n where n.id=content_node_id and (is_platform_admin() or n.school_id=current_school_id())));
create policy adoptions_read on public.school_course_adoptions for select using(is_platform_admin() or school_id=current_school_id());
create policy adoptions_admin_write on public.school_course_adoptions for all using(is_platform_admin() or (current_profile_role()='school_admin' and school_id=current_school_id())) with check(is_platform_admin() or (current_profile_role()='school_admin' and school_id=current_school_id()));
create policy reviews_read on public.content_reviews for select using(is_platform_admin() or school_id=current_school_id());
create policy reviews_submit on public.content_reviews for insert with check(submitted_by=(select id from profiles where user_id=auth.uid()) and (is_platform_admin() or school_id=current_school_id()));
create policy reviews_school_decide on public.content_reviews for update using(is_platform_admin() or (current_profile_role()='school_admin' and school_id=current_school_id()));
create policy audit_read on public.content_approval_actions for select using(is_platform_admin() or school_id=current_school_id() or school_id is null and current_profile_role() in ('school_admin','teacher'));
create policy audit_insert on public.content_approval_actions for insert with check(actor_id=(select id from profiles where user_id=auth.uid()) and (is_platform_admin() or school_id=current_school_id()));
create policy proposals_school_read on public.content_proposals for select using(is_platform_admin() or school_id=current_school_id());
create policy proposals_school_create on public.content_proposals for insert with check(current_profile_role()='school_admin' and school_id=current_school_id() and exists(select 1 from content_nodes n where n.id=source_content_id and n.school_id=current_school_id() and n.status in ('approved','published')));
create policy proposals_platform_update on public.content_proposals for update using(is_platform_admin()) with check(is_platform_admin());
create policy tags_read on public.tags for select using(auth.uid() is not null); create policy tags_platform_write on public.tags for all using(is_platform_admin()) with check(is_platform_admin());
create policy content_tags_read on public.content_tags for select using(auth.uid() is not null); create policy content_tags_write on public.content_tags for all using(is_platform_admin()) with check(is_platform_admin());
create policy course_tags_read on public.course_tags for select using(auth.uid() is not null); create policy course_tags_write on public.course_tags for all using(is_platform_admin()) with check(is_platform_admin());
create policy relationships_read on public.content_relationships for select using(auth.uid() is not null); create policy relationships_write on public.content_relationships for all using(is_platform_admin()) with check(is_platform_admin());

comment on function public.effective_course_nodes is 'Returns the adopted global tree with active school overrides substituted node-by-node; global rows are never copied.';
comment on function public.accept_content_proposal is 'Creates a distinct sanitized global draft while retaining school content and provenance.';
comment on view public.student_published_content is 'Safety boundary for learning surfaces: only human-approved, published course and node records.';
