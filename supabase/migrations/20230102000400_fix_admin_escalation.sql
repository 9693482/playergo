-- ============================================================================
-- fix_admin_escalation.sql
-- SEGURIDAD: El trigger handle_new_user aceptaba 'ADMIN' desde
-- raw_user_meta_data, permitiendo que cualquier usuario se auto-asigne
-- rol de administrador. Ahora solo acepta PLAYER y TEAM.
-- ============================================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    case
      when new.raw_user_meta_data ->> 'role' in ('PLAYER', 'TEAM')
        then (new.raw_user_meta_data ->> 'role')::user_role
      else 'PLAYER'::user_role
    end
  )
  on conflict (id) do nothing;

  return new;
end;
$$;
