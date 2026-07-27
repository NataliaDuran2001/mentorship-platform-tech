-- Cierra un hueco del #36 que la primera version del guion de pruebas no
-- cubria: el trigger era BEFORE UPDATE, asi que protegia el camino de
-- "cambiar mi rol" pero no el de "crear mi perfil ya con rol admin".
--
-- La politica profiles_insert_propio existe para que la app pueda recrear su
-- propio perfil si el trigger handle_new_user no corrio (usuarias anteriores
-- al esquema, por ejemplo). Con RLS eso solo permite insertar la fila propia,
-- pero nada impedia elegir el rol en esa fila.
--
-- Hoy no es explotable —el trigger de auth.users crea el perfil al registrarse
-- y no hay politica de delete, asi que la fila siempre existe y un segundo
-- insert choca con la PK—, pero depende de una cadena de circunstancias en vez
-- de una regla. Se cierra explicitamente.
--
-- Un perfil creado desde el cliente nace estudiante, sin excepcion. Promover
-- sigue siendo un acto deliberado fuera de la sesion del cliente.

create or replace function public.prevent_client_role_change()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user not in ('authenticated', 'anon') then
    return new;
  end if;

  if tg_op = 'INSERT' and new.role <> 'student' then
    raise exception 'a profile created from a client session must be a student'
      using errcode = '42501';
  end if;

  if tg_op = 'UPDATE' and new.role is distinct from old.role then
    raise exception 'role cannot be changed from a client session'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

comment on function public.prevent_client_role_change() is
  'Mantiene el rol fuera del alcance del cliente en los dos caminos: un '
  'insert desde la app nace student y un update no puede cambiarlo. SECURITY '
  'INVOKER a proposito: necesita ver el rol real de la sesion en current_user.';

drop trigger if exists profiles_role_is_immutable on public.profiles;

create trigger profiles_role_is_immutable
  before insert or update on public.profiles
  for each row execute function public.prevent_client_role_change();
