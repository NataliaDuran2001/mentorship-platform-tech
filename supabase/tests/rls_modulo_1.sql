-- ===========================================================================
-- Verificación de las políticas RLS del Módulo 1. Issue #7, AC3, AC4 y AC5.
--
-- NO es una migración: no va en supabase/migrations/ y no cambia el esquema.
-- Es el guion reproducible de la verificación, para repetirla cada vez que
-- cambien las políticas.
--
-- CÓMO CORRERLO
--   Dashboard de Supabase → SQL Editor → pegar todo → Run.
--   O bien:  psql "$DATABASE_URL" -f supabase/tests/rls_modulo_1.sql
--
--   Va todo de una sola vez. No correrlo por partes: es una única transacción.
--
-- QUÉ DEVUELVE
--   Una tabla con una fila por prueba y una columna `ok`. **Todas las filas
--   tienen que decir OK.** Cualquier `FALLA` es un agujero en las políticas.
--
-- QUÉ DEJA
--   Nada. Todo corre dentro de una transacción que termina en ROLLBACK: las
--   dos usuarias de prueba y sus datos se deshacen al terminar. Tampoco manda
--   correos, así que no consume la cuota SMTP del proyecto.
--
--   Si alguna sentencia falla y aborta la transacción, tampoco queda nada:
--   ese es justamente el motivo de envolverlo así.
--
-- POR QUÉ LOS RESULTADOS SE ACUMULAN EN UNA TABLA TEMPORAL
--   El editor SQL del dashboard muestra solo el resultado de la última
--   sentencia. Con un `select` por prueba no se vería ninguno.
-- ===========================================================================

begin;

-- ---------------------------------------------------------------------------
-- Acumulador de resultados
-- ---------------------------------------------------------------------------

create temp table _rls_resultado (
  orden integer,
  prueba text,
  esperado text,
  obtenido text
) on commit drop;

-- El rol `authenticated` también escribe acá cuando se lo impersona.
grant all on _rls_resultado to authenticated;

-- ---------------------------------------------------------------------------
-- Fixture: dos usuarias
--
-- Es el mismo INSERT que hace Supabase Auth al registrar, así que el trigger
-- AFTER INSERT sobre auth.users se ejercita igual.
-- ---------------------------------------------------------------------------

insert into auth.users (
  id, aud, role, email, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    'aaaaaaaa-0000-4000-8000-000000000001', 'authenticated', 'authenticated',
    'rls-test-a@aspire.test', now(),
    '{"provider":"email","providers":["email"]}',
    '{"display_name":"Usuaria A"}', now(), now()
  ),
  (
    'bbbbbbbb-0000-4000-8000-000000000002', 'authenticated', 'authenticated',
    'rls-test-b@aspire.test', now(),
    '{"provider":"email","providers":["email"]}',
    '{"display_name":"Usuaria B"}', now(), now()
  );

-- AC5: el trigger tiene que haber creado los dos perfiles, sin que nadie los
-- pida, con el display_name tomado de raw_user_meta_data.
insert into _rls_resultado
select
  1,
  'AC5 · el registro crea el perfil por trigger',
  '2',
  count(*)::text
from public.profiles
where id in (
  'aaaaaaaa-0000-4000-8000-000000000001',
  'bbbbbbbb-0000-4000-8000-000000000002'
);

insert into _rls_resultado
select
  2,
  'AC5 · el perfil copia el nombre y nace sin onboarding',
  'Usuaria A / sin completar',
  coalesce(display_name, '(sin nombre)')
    || ' / '
    || case
         when onboarding_completed_at is null then 'sin completar'
         else 'completo'
       end
from public.profiles
where id = 'aaaaaaaa-0000-4000-8000-000000000001';

-- Datos de B, cargados como owner para que A tenga algo ajeno que intentar ver.
insert into public.onboarding_answers (user_id, step_key, value)
values (
  'bbbbbbbb-0000-4000-8000-000000000002', 'experience_level', 'junior_developer'
);

insert into public.user_progress (user_id, topic_id, status, completed_at)
select
  'bbbbbbbb-0000-4000-8000-000000000002', id, 'completed', now()
from public.topics
where parent_id is not null
order by sort_order
limit 1;

-- ---------------------------------------------------------------------------
-- A partir de acá todo corre como la usuaria A
-- ---------------------------------------------------------------------------

set local role authenticated;

select set_config(
  'request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

-- AC3 · lectura -------------------------------------------------------------

insert into _rls_resultado
select
  10,
  'AC3 · A ve su perfil y ningún otro',
  '1 propio / 0 de B',
  (
    select count(*) from public.profiles
    where id = 'aaaaaaaa-0000-4000-8000-000000000001'
  )::text
  || ' propio / '
  || (
    select count(*) from public.profiles
    where id = 'bbbbbbbb-0000-4000-8000-000000000002'
  )::text
  || ' de B';

insert into _rls_resultado
select
  11,
  'AC3 · A no ve las respuestas de onboarding de B',
  '0',
  (select count(*) from public.onboarding_answers)::text;

insert into _rls_resultado
select
  12,
  'AC3 · A no ve el progreso de B',
  '0',
  (select count(*) from public.user_progress)::text;

insert into _rls_resultado
select
  13,
  'AC3 · el catálogo sí se lee: 3 tracks',
  '3',
  (select count(*) from public.tracks)::text;

-- AC3 · escritura sobre filas ajenas ----------------------------------------
--
-- Los UPDATE y DELETE no lanzan error: sin política que las alcance, la
-- cláusula USING filtra las filas y afectan 0. Esa es la denegación.

with toca_perfil as (
  update public.profiles set display_name = 'Secuestrada'
  where id = 'bbbbbbbb-0000-4000-8000-000000000002'
  returning 1
),
toca_respuesta as (
  update public.onboarding_answers set value = 'career_switcher'
  where user_id = 'bbbbbbbb-0000-4000-8000-000000000002'
  returning 1
),
borra_progreso as (
  delete from public.user_progress
  where user_id = 'bbbbbbbb-0000-4000-8000-000000000002'
  returning 1
)
insert into _rls_resultado
select
  20,
  'AC3 · A no modifica ni borra filas de B',
  '0 / 0 / 0',
  (select count(*) from toca_perfil)::text
    || ' / ' || (select count(*) from toca_respuesta)::text
    || ' / ' || (select count(*) from borra_progreso)::text;

-- Los INSERT sí lanzan 42501, porque el WITH CHECK evalúa la fila nueva. Cada
-- uno va en su propio bloque con manejo de excepción: así el fallo aborta solo
-- ese bloque y la transacción sigue viva.
do $$
begin
  begin
    insert into public.onboarding_answers (user_id, step_key, value)
    values ('bbbbbbbb-0000-4000-8000-000000000002', 'goal', 'first_job');
    insert into _rls_resultado
      values (21, 'AC3 · A no inserta respuestas a nombre de B',
              'DENEGADO', 'PERMITIDO');
  exception when others then
    insert into _rls_resultado
      values (21, 'AC3 · A no inserta respuestas a nombre de B',
              'DENEGADO', 'DENEGADO (' || sqlstate || ')');
  end;

  begin
    insert into public.user_progress (user_id, topic_id)
    select 'bbbbbbbb-0000-4000-8000-000000000002', id
    from public.topics limit 1;
    insert into _rls_resultado
      values (22, 'AC3 · A no inserta progreso a nombre de B',
              'DENEGADO', 'PERMITIDO');
  exception when others then
    insert into _rls_resultado
      values (22, 'AC3 · A no inserta progreso a nombre de B',
              'DENEGADO', 'DENEGADO (' || sqlstate || ')');
  end;
end
$$;

-- Lo propio sí se puede escribir: si esto fallara, la tabla estaría
-- silenciosamente inaccesible, que es el otro modo de falla del AC2.
insert into public.onboarding_answers (user_id, step_key, value)
values ('aaaaaaaa-0000-4000-8000-000000000001', 'experience_level', 'student')
on conflict (user_id, step_key) do update set value = excluded.value;

insert into _rls_resultado
select
  23,
  'AC3 · A sí escribe y lee lo propio',
  '1',
  (select count(*) from public.onboarding_answers)::text;

-- AC4 · el catálogo es de solo lectura para el cliente -----------------------

with borra_track as (
  delete from public.tracks where id = 'frontend' returning 1
),
borra_topic as (
  delete from public.topics returning 1
),
mueve_topic as (
  update public.topics set sort_order = 999 returning 1
)
insert into _rls_resultado
select
  30,
  'AC4 · el cliente no borra ni modifica el catálogo',
  '0 / 0 / 0',
  (select count(*) from borra_track)::text
    || ' / ' || (select count(*) from borra_topic)::text
    || ' / ' || (select count(*) from mueve_topic)::text;

do $$
begin
  begin
    insert into public.tracks (id, name, description)
    values ('mobile', 'Mobile', 'Track que el cliente no deberia poder crear');
    insert into _rls_resultado
      values (31, 'AC4 · el cliente no inserta en tracks',
              'DENEGADO', 'PERMITIDO');
  exception when others then
    insert into _rls_resultado
      values (31, 'AC4 · el cliente no inserta en tracks',
              'DENEGADO', 'DENEGADO (' || sqlstate || ')');
  end;

  begin
    insert into public.topics (track_id, title, sort_order)
    values ('frontend', 'Topico inyectado por el cliente', 99);
    insert into _rls_resultado
      values (32, 'AC4 · el cliente no inserta en topics',
              'DENEGADO', 'PERMITIDO');
  exception when others then
    insert into _rls_resultado
      values (32, 'AC4 · el cliente no inserta en topics',
              'DENEGADO', 'DENEGADO (' || sqlstate || ')');
  end;
end
$$;

reset role;

-- ---------------------------------------------------------------------------
-- Resultado
-- ---------------------------------------------------------------------------

select
  prueba,
  esperado,
  obtenido,
  case
    when obtenido = esperado then 'OK'
    when esperado = 'DENEGADO' and obtenido like 'DENEGADO%' then 'OK'
    else 'FALLA'
  end as ok
from _rls_resultado
order by orden;

rollback;
