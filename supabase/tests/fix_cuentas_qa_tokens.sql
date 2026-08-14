-- ===========================================================================
-- Arreglo: columnas de token en NULL en las cuentas QA
-- ===========================================================================
--
-- Síntoma: el login devuelve 500 con
--   {"error_code":"unexpected_failure","msg":"Database error querying schema"}
--
-- Causa: GoTrue lee esas columnas como cadenas, no como nullables. Cuando se
-- inserta en auth.users a mano quedan en NULL y el scan del backend explota
-- antes de comparar la contraseña. Al registrarse por la app nunca pasa porque
-- GoTrue las escribe en '' él mismo.
--
-- Por qué '' es seguro: los índices únicos de esas columnas son parciales
-- (`where <col> !~ '^[0-9 ]*$'`), y la cadena vacía cae fuera del filtro. Por
-- eso varias filas pueden tener '' sin chocar entre sí.
--
-- El nombre de las columnas cambió entre versiones de GoTrue, así que cada una
-- se toca solo si existe en este proyecto.
--
-- CÓMO CORRERLO
--   Dashboard de Supabase → SQL Editor → pegar todo → Run.
--   Idempotente: correrlo de nuevo no hace nada.
-- ===========================================================================

do $$
declare
  v_col text;
  v_tocadas text[] := '{}';
begin
  foreach v_col in array array[
    'confirmation_token',
    'recovery_token',
    'email_change',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change',
    'phone_change_token',
    'reauthentication_token'
  ]
  loop
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'auth'
        and table_name = 'users'
        and column_name = v_col
    ) then
      execute format(
        'update auth.users set %I = '''' where email like ''qa.%%@aspire.dev'' and %I is null',
        v_col, v_col
      );
      v_tocadas := v_tocadas || v_col;
    end if;
  end loop;

  raise notice 'Columnas normalizadas: %', array_to_string(v_tocadas, ', ');
end
$$;

-- ---------------------------------------------------------------------------
-- Verificación: ninguna columna de token puede quedar en NULL
-- ---------------------------------------------------------------------------

select
  email,
  case
    when num_nulls(
      confirmation_token, recovery_token, email_change,
      email_change_token_new, email_change_token_current,
      phone_change, phone_change_token, reauthentication_token
    ) > 0 then 'FALLA: quedan tokens en NULL'
    when encrypted_password is null then 'FALLA: sin contrasena'
    when email_confirmed_at is null then 'FALLA: sin confirmar'
    else 'OK'
  end as ok
from auth.users
where email like 'qa.%@aspire.dev'
order by email;
