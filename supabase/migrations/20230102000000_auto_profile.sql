-- ============================================================================
-- 012_auto_profile.sql
-- Crea el perfil automáticamente al registrar un usuario en auth.users,
-- mediante un trigger SECURITY DEFINER. Esto permite dejar activada la
-- confirmación de correo (el perfil se crea server-side, sin sesión).
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
      when new.raw_user_meta_data ->> 'role' in ('PLAYER', 'TEAM', 'ADMIN')
        then (new.raw_user_meta_data ->> 'role')::user_role
      else 'PLAYER'::user_role
    end
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
