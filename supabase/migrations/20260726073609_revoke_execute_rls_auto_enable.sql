-- Cierra los WARN anon/authenticated_security_definer_function_executable del linter:
-- rls_auto_enable() es un event trigger SECURITY DEFINER que el sistema invoca en DDL;
-- no debe ser ejecutable via /rest/v1/rpc/. El ACL incluia un grant a PUBLIC (=X/postgres),
-- por lo que revocar solo anon/authenticated no eliminaria el acceso efectivo.
-- El grant explicito de service_role se conserva. Issue #16.
revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
