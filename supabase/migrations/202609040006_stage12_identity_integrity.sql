-- Stage 12: identity authority is immutable from browser-issued school-admin updates.
-- School admins may maintain non-authoritative profile details, while only trusted
-- platform operations may rebind an Auth user, tenant, or role.

create or replace function public.protect_profile_authority()
returns trigger
language plpgsql
set search_path=public
as $$
begin
  if (new.user_id, new.school_id, new.role) is distinct from
     (old.user_id, old.school_id, old.role)
     and not public.is_platform_admin() then
    raise exception using
      errcode='42501',
      message='Profile authority fields require a platform administrator';
  end if;
  return new;
end
$$;

drop trigger if exists protect_profile_authority_before_update on public.profiles;
create trigger protect_profile_authority_before_update
before update on public.profiles
for each row execute function public.protect_profile_authority();

revoke execute on function public.protect_profile_authority() from public, anon, authenticated;

