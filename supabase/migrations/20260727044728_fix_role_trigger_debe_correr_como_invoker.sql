-- Corrige un defecto de la migracion anterior (#36), detectado por
-- supabase/tests/rls_roles.sql antes de que llegara a ningun lado: la
-- estudiante SI podia promoverse a admin.
--
-- Causa: prevent_client_role_change() se creo SECURITY DEFINER, y dentro de
-- una funcion SECURITY DEFINER `current_user` es el DUENO de la funcion
-- (postgres), no quien ejecuta la sentencia. La condicion
-- `current_user in ('authenticated','anon')` era entonces siempre falsa y el
-- trigger dejaba pasar todo.
--
-- El trigger no necesita privilegios elevados: solo compara OLD con NEW y
-- lanza excepcion. Como SECURITY INVOKER (el modo por defecto) `current_user`
-- vuelve a ser el rol de la sesion que hace el update, que es exactamente lo
-- que hay que mirar. De paso deja de ser SECURITY DEFINER en el schema
-- expuesto, asi que tampoco le aplica el lint que motivo el #16.

create or replace function public.prevent_client_role_change()
returns trigger
language plpgsql
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
  'Impide que una usuaria cambie su propio rol desde la app. SECURITY INVOKER '
  'a proposito: necesita ver el rol real de la sesion en current_user. '
  'Promover a una administradora se hace fuera de la sesion del cliente.';
