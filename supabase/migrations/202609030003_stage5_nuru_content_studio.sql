-- Stage 5: Nuru Content Studio. AI creates suggestions and reviewable drafts, never approvals/publications.
create type public.suggestion_scope as enum ('global','school');
create type public.suggestion_status as enum ('pending','accepted','dismissed','generated','completed');
create type public.suggestion_type as enum ('missing_content','content_improvement','practice_gap','quiz_gap','project_opportunity','student_interest','low_mastery','high_search_interest','next_level_opportunity');
create type public.suggestion_priority as enum ('low','medium','high');
create type public.ai_request_status as enum ('queued','processing','completed','failed');
create type public.ai_review_status as enum ('draft','duplicate_flagged','accepted','removed','submitted');
create type public.question_kind as enum ('multiple_choice','short_answer','numeric','true_false');

create table public.content_suggestions (
 id uuid primary key default gen_random_uuid(), scope suggestion_scope not null, school_id uuid references public.schools(id) on delete cascade,
 course_id uuid references public.courses(id) on delete cascade, content_node_id uuid references public.content_nodes(id) on delete cascade,
 suggestion_type suggestion_type not null, title text not null, description text not null, reason text not null check(length(trim(reason))>0),
 priority suggestion_priority not null default 'medium', evidence_json jsonb, status suggestion_status not null default 'pending',
 created_by uuid not null references public.profiles(id), created_at timestamptz not null default now(), reviewed_by uuid references public.profiles(id), reviewed_at timestamptz,
 constraint suggestion_scope_tenant check ((scope='global' and school_id is null) or (scope='school' and school_id is not null))
);
create index content_suggestions_scope_status on public.content_suggestions(scope,school_id,status,priority);

create table public.content_suggestion_feedback (
 id uuid primary key default gen_random_uuid(), suggestion_id uuid not null references public.content_suggestions(id) on delete cascade,
 reason text not null check(reason in ('not_relevant','already_covered','wrong_level','create_manually','other')), note text,
 created_by uuid not null references public.profiles(id), created_at timestamptz not null default now()
);

create table public.ai_generation_requests (
 id uuid primary key default gen_random_uuid(), requested_by uuid not null references public.profiles(id), school_id uuid references public.schools(id) on delete cascade,
 scope suggestion_scope not null, request_type text not null, context_json jsonb not null, prompt_summary text not null,
 provider text not null, model text, status ai_request_status not null default 'queued', created_at timestamptz not null default now(), completed_at timestamptz,
 constraint ai_request_scope_tenant check ((scope='global' and school_id is null) or (scope='school' and school_id is not null)),
 constraint controlled_context check (jsonb_typeof(context_json)='object')
);

create table public.ai_generated_items (
 id uuid primary key default gen_random_uuid(), generation_request_id uuid not null references public.ai_generation_requests(id) on delete cascade,
 content_id uuid references public.content_nodes(id) on delete set null, item_type text not null, review_status ai_review_status not null default 'draft',
 created_at timestamptz not null default now()
);

create table public.content_questions (
 id uuid primary key default gen_random_uuid(), content_node_id uuid not null references public.content_nodes(id) on delete cascade,
 question text not null, question_type question_kind not null, answer jsonb not null, explanation text not null default '', difficulty text,
 topic text, subtopic text, source text not null default 'human', created_by_ai boolean not null default false,
 status content_status not null default 'draft', normalized_question text not null, question_fingerprint text not null,
 duplicate_of uuid references public.content_questions(id) on delete set null, duplicate_reviewed_by uuid references public.profiles(id),
 created_by uuid not null references public.profiles(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 constraint ai_questions_start_draft check(not created_by_ai or status='draft')
);
create index questions_duplicate_lookup on public.content_questions(content_node_id,question_fingerprint);
create trigger content_questions_updated before update on public.content_questions for each row execute function public.touch_updated_at();

create extension if not exists pgcrypto;
create function public.normalize_question_text(input text) returns text language sql immutable strict as $$
 select trim(regexp_replace(regexp_replace(lower(input),'[^[:alnum:] =+*/.\-]+',' ','g'),'\s+',' ','g'))
$$;
create function public.prepare_question() returns trigger language plpgsql set search_path=public as $$
begin
 new.normalized_question:=normalize_question_text(new.question);
 new.question_fingerprint:=encode(digest(new.normalized_question,'sha256'),'hex');
 if new.created_by_ai then
  new.status:='draft';
  select q.id into new.duplicate_of from content_questions q where q.content_node_id=new.content_node_id and q.question_fingerprint=new.question_fingerprint and q.id<>new.id limit 1;
 end if;
 return new;
end $$;
create trigger prepare_content_question before insert or update of question on public.content_questions for each row execute function public.prepare_question();

-- Explicit generation authorization: this RPC records provenance only. A trusted server worker may later claim queued requests.
create function public.authorize_nuru_generation(request_scope suggestion_scope, request_school_id uuid, request_type text, controlled_context jsonb, summary text, provider_name text default 'mock')
returns uuid language plpgsql security definer set search_path=public as $$
declare actor profiles; request_id uuid;
begin
 select * into actor from profiles where user_id=auth.uid();
 if actor.id is null or actor.role not in ('teacher','school_admin','platform_admin') then raise exception 'Content author role required'; end if;
 if request_scope='global' and actor.role<>'platform_admin' then raise exception 'Only platform administrators may generate global drafts'; end if;
 if request_scope='school' and (request_school_id is null or actor.school_id<>request_school_id) then raise exception 'School scope mismatch'; end if;
 if controlled_context ?| array['student_id','student_ids','student_email'] then raise exception 'Student-level context is not permitted'; end if;
 if (select count(*) from ai_generation_requests where requested_by=actor.id and created_at>now()-interval '1 hour')>=30 then raise exception 'Nuru generation rate limit reached'; end if;
 insert into ai_generation_requests(requested_by,school_id,scope,request_type,context_json,prompt_summary,provider,status)
 values(actor.id,request_school_id,request_scope,request_type,controlled_context,summary,provider_name,'queued') returning id into request_id;
 return request_id;
end $$;

alter table public.content_suggestions enable row level security;
alter table public.content_suggestion_feedback enable row level security;
alter table public.ai_generation_requests enable row level security;
alter table public.ai_generated_items enable row level security;
alter table public.content_questions enable row level security;

create policy suggestions_read on public.content_suggestions for select using(is_platform_admin() or (scope='school' and school_id=current_school_id() and current_profile_role() in ('teacher','school_admin')));
create policy suggestions_platform_write on public.content_suggestions for all using(is_platform_admin()) with check(is_platform_admin());
create policy suggestions_school_create on public.content_suggestions for insert with check(scope='school' and school_id=current_school_id() and current_profile_role() in ('teacher','school_admin'));
create policy suggestions_school_review on public.content_suggestions for update using(scope='school' and school_id=current_school_id() and current_profile_role() in ('teacher','school_admin')) with check(scope='school' and school_id=current_school_id());
create policy suggestion_feedback_read on public.content_suggestion_feedback for select using(exists(select 1 from content_suggestions s where s.id=suggestion_id and (is_platform_admin() or s.school_id=current_school_id())));
create policy suggestion_feedback_create on public.content_suggestion_feedback for insert with check(created_by=(select id from profiles where user_id=auth.uid()) and exists(select 1 from content_suggestions s where s.id=suggestion_id and (is_platform_admin() or s.school_id=current_school_id())));
create policy ai_requests_read on public.ai_generation_requests for select using(is_platform_admin() or school_id=current_school_id() and requested_by=(select id from profiles where user_id=auth.uid()) or current_profile_role()='school_admin' and school_id=current_school_id());
create policy ai_items_read on public.ai_generated_items for select using(exists(select 1 from ai_generation_requests r where r.id=generation_request_id and (is_platform_admin() or r.school_id=current_school_id())));
create policy questions_read on public.content_questions for select using(exists(select 1 from content_nodes n where n.id=content_node_id and (is_platform_admin() or n.scope='global' or n.school_id=current_school_id())));
create policy questions_school_insert on public.content_questions for insert with check(created_by=(select id from profiles where user_id=auth.uid()) and exists(select 1 from content_nodes n where n.id=content_node_id and n.scope='school' and n.school_id=current_school_id() and n.status='draft'));
create policy questions_platform_write on public.content_questions for all using(is_platform_admin()) with check(is_platform_admin());
create policy questions_school_update on public.content_questions for update using(exists(select 1 from content_nodes n where n.id=content_node_id and n.school_id=current_school_id() and (current_profile_role()='school_admin' or created_by=(select id from profiles where user_id=auth.uid()))));

comment on table public.ai_generation_requests is 'Auditable user authorization and useful provider metadata; hidden chain-of-thought is never stored.';
comment on function public.authorize_nuru_generation is 'Validates auth, role, tenant, controlled context, and rate limits before queuing AI work.';
comment on column public.content_questions.duplicate_of is 'First-level exact-normalized duplicate warning; future semantic similarity can be added without changing review behavior.';
