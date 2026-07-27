-- ===========================================================================
-- Modelo de roles: estudiante y administradora. Issue #36.
--
-- Se adelanta a proposito, antes del #37 (knowledge base + IA): el esquema del
-- #7 esta vacio de datos productivos, asi que sumar el rol cuesta una
-- migracion corta. Despues, con perfiles reales adentro, seria rehacer el RLS
-- de las cinco tablas.
--
-- El riesgo que esta migracion cierra: la publishable key viaja en el bundle
-- de Flutter Web y la politica profiles_update_propio deja a cada usuaria
-- actualizar SU fila. Si el rol vive en esa fila y nada lo protege, cualquiera
-- se promueve a administradora con una llamada desde el navegador y el rol
-- pasa a ser decorativo. Eso lo cierra el trigger profiles_role_is_immutable.
--
-- OJO: esta migracion crea la funcion del trigger como SECURITY DEFINER, que
-- es un ERROR corregido en la migracion siguiente
-- (fix_role_trigger_debe_correr_como_invoker). Se deja tal cual y no se
-- reescribe porque ya esta aplicada: el historial de migraciones es
-- append-only. Las dos juntas dejan el estado correcto.
-- ===========================================================================

create type public.user_role as enum ('student', 'admin');

alter table public.profiles
  add column role public.user_role not null default 'student';

comment on column public.profiles.role is
  'Rol de la usuaria. Nace en student por defecto, tambien para las filas que '
  'crea el trigger handle_new_user. Solo se cambia fuera de la sesion del '
  'cliente: ver el trigger profiles_role_is_immutable.';

-- ---------------------------------------------------------------------------
-- El rol es inmutable desde el cliente
--
-- No alcanza con no exponerlo en la UI: PostgREST acepta un update sobre
-- cualquier columna que el grant permita, y la politica de RLS ya autoriza la
-- fila propia. Una politica no puede comparar OLD con NEW, asi que la regla va
-- en un trigger.
--
-- Se bloquea solo cuando el update viene de una sesion del cliente
-- (current_user es authenticated o anon). Desde el SQL editor, un job o
-- service_role, current_user es otro y el cambio pasa: es asi como se promueve
-- a una administradora, deliberadamente y fuera de la app.
-- ---------------------------------------------------------------------------

create or replace function public.prevent_client_role_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.role is distinct from old.role
     and current_user in ('authenticated', 'anon') then
    raise exception 'role cannot be changed from a client session'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

comment on function public.prevent_client_role_change() is
  'Impide que una usuaria cambie su propio rol desde la app. Promover a una '
  'administradora se hace fuera de la sesion del cliente, a proposito.';

create trigger profiles_role_is_immutable
  before update on public.profiles
  for each row execute function public.prevent_client_role_change();

-- Mismo cuidado que el #16 y la migracion de triggers del #7: el ACL por
-- defecto incluye un grant a PUBLIC, asi que revocar solo anon/authenticated
-- no eliminaria el acceso efectivo, y el linter marcaria la funcion como
-- SECURITY DEFINER invocable por /rest/v1/rpc/.
grant execute on function public.prevent_client_role_change() to postgres;
revoke execute on function public.prevent_client_role_change()
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- La administradora escribe el catalogo
--
-- Hasta ahora tracks y topics no tenian ninguna politica de escritura, asi que
-- NADIE podia cargar el curriculum desde el cliente: era justamente lo que
-- faltaba para que el #37 sea posible.
--
-- El EXISTS consulta public.profiles, que tiene su propio RLS: la subconsulta
-- solo ve la fila propia (profiles_select_propio), que es exactamente la que
-- hace falta. No hay recursion porque es otra tabla.
-- ---------------------------------------------------------------------------

create policy "tracks_write_admin"
  on public.tracks for all to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid()) and p.role = 'admin'
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid()) and p.role = 'admin'
    )
  );

create policy "topics_write_admin"
  on public.topics for all to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid()) and p.role = 'admin'
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid()) and p.role = 'admin'
    )
  );
