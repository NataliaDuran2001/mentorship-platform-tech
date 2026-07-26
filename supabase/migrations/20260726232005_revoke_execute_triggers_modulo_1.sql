-- Cierra los WARN anon/authenticated_security_definer_function_executable que
-- el linter levantó por handle_new_user(), introducida en la migración del
-- esquema del Módulo 1 (#7). Mismo problema y misma solución que el #16 con
-- rls_auto_enable().
--
-- handle_new_user() tiene que seguir siendo SECURITY DEFINER: escribe en
-- public.profiles y la dispara supabase_auth_admin al insertar en auth.users,
-- que no tiene privilegios sobre public.profiles ni evade su RLS.
--
-- El ACL por defecto de una función incluye un grant a PUBLIC, así que revocar
-- solo anon/authenticated no eliminaría el acceso efectivo (lección del #16).
-- Y como se revoca PUBLIC, el rol que dispara el trigger necesita su grant
-- explícito o el registro de usuarias se rompe.
grant execute on function public.handle_new_user() to supabase_auth_admin, postgres;
revoke execute on function public.handle_new_user() from public, anon, authenticated;

-- touch_updated_at() no es SECURITY DEFINER, así que el linter no la marca,
-- pero tampoco tiene por qué estar expuesta en /rest/v1/rpc/.
grant execute on function public.touch_updated_at() to postgres;
revoke execute on function public.touch_updated_at() from public, anon, authenticated;
