-- ===========================================================================
-- Verificación de las políticas RLS del Módulo 1. Issue #7, AC3 y AC4.
--
-- NO es una migración: no va en supabase/migrations/ y no cambia el esquema.
-- Es el guion reproducible de la verificación, para poder repetirla después de
-- cada cambio de políticas.
--
-- Cómo correrlo: pegarlo completo en el SQL editor del dashboard, o
--   psql "$DATABASE_URL" -f supabase/tests/rls_modulo_1.sql
--
-- Todo va dentro de una transacción que termina en ROLLBACK: crea dos usuarias
-- de prueba, corre las pruebas y no deja rastro. Se puede correr sobre el
-- proyecto de desarrollo sin ensuciarlo.
--
-- Qué se verifica:
--   AC3 — la usuaria A no lee ni escribe filas de B en profiles,
--         user_progress ni onboarding_answers.
--   AC4 — una usuaria autenticada no puede escribir en tracks ni topics.
--   AC5 — insertar en auth.users crea el perfil por trigger.
--
-- Cada bloque imprime el resultado esperado en su comentario. Si alguno no
-- coincide, hay un agujero en las políticas.
-- ===========================================================================

begin;

-- ---------------------------------------------------------------------------
-- Fixture: dos usuarias. Es el mismo INSERT que hace Supabase Auth al
-- registrar, así que el trigger AFTER INSERT se ejercita igual, y no se
-- consume la cuota de correos del proyecto.
-- ---------------------------------------------------------------------------

insert into auth.users (
  id, aud, role, email, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    'aaaaaaaa-0000-4000-8000-000000000001', 'authenticated', 'authenticated',
    'rls-test-a@aspire.test', now(),
    '{"provider":"email","providers":["email"]}', '{"display_name":"Usuaria A"}',
    now(), now()
  ),
  (
    'bbbbbbbb-0000-4000-8000-000000000002', 'authenticated', 'authenticated',
    'rls-test-b@aspire.test', now(),
    '{"provider":"email","providers":["email"]}', '{"display_name":"Usuaria B"}',
    now(), now()
  );

-- AC5. Esperado: dos filas, ambas con perfil_creado_por_trigger = true,
-- display_name tomado de raw_user_meta_data, y todo lo del onboarding en null.
select
  u.email,
  p.id is not null as perfil_creado_por_trigger,
  p.display_name,
  p.experience_level,
  p.track_id,
  p.learning_goal,
  p.onboarding_completed_at
from auth.users u
left join public.profiles p on p.id = u.id
where u.id in (
  'aaaaaaaa-0000-4000-8000-000000000001',
  'bbbbbbbb-0000-4000-8000-000000000002'
)
order by u.email;

-- Datos de B, cargados como owner (sin RLS) para tener algo que A intente ver.
insert into public.onboarding_answers (user_id, step_key, value)
values ('bbbbbbbb-0000-4000-8000-000000000002', 'experience_level', 'junior_developer');

insert into public.user_progress (user_id, topic_id, status, completed_at)
select 'bbbbbbbb-0000-4000-8000-000000000002', id, 'completed', now()
from public.topics
where parent_id is not null
order by sort_order
limit 1;

-- ---------------------------------------------------------------------------
-- AC3 · lectura. Todo lo que sigue corre como la usuaria A.
-- ---------------------------------------------------------------------------

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

-- Esperado: 1 / 1 / 0 en profiles (ve el propio, no el de B), y 0 / 0 en las
-- tablas de B, que tienen una fila cada una.
select
  (select count(*) from public.profiles) as profiles_visibles,
  (select count(*) from public.profiles
    where id = 'aaaaaaaa-0000-4000-8000-000000000001') as ve_su_perfil,
  (select count(*) from public.profiles
    where id = 'bbbbbbbb-0000-4000-8000-000000000002') as ve_el_perfil_de_b,
  (select count(*) from public.onboarding_answers) as respuestas_visibles,
  (select count(*) from public.user_progress) as progreso_visible,
  (select count(*) from public.tracks) as tracks_visibles,
  (select count(*) from public.topics) as topics_visibles;

-- ---------------------------------------------------------------------------
-- AC3 · escritura sobre filas ajenas.
--
-- Los UPDATE y DELETE no lanzan error: sin política que las alcance, la
-- cláusula USING filtra las filas y afectan 0. Esa es la denegación. Los
-- INSERT sí lanzan 42501, porque el WITH CHECK se evalúa sobre la fila nueva.
-- ---------------------------------------------------------------------------

-- Esperado: los tres en 0.
with toca_perfil as (
  update public.profiles set display_name = 'Secuestrada'
  where id = 'bbbbbbbb-0000-4000-8000-000000000002' returning 1
),
toca_respuesta as (
  update public.onboarding_answers set value = 'career_switcher'
  where user_id = 'bbbbbbbb-0000-4000-8000-000000000002' returning 1
),
borra_progreso as (
  delete from public.user_progress
  where user_id = 'bbbbbbbb-0000-4000-8000-000000000002' returning 1
)
select
  (select count(*) from toca_perfil) as perfiles_de_b_modificados,
  (select count(*) from toca_respuesta) as respuestas_de_b_modificadas,
  (select count(*) from borra_progreso) as progreso_de_b_borrado;

-- Esperado: 42501 «new row violates row-level security policy».
-- Descomentar de a uno; cada uno aborta la transacción.
--
-- insert into public.onboarding_answers (user_id, step_key, value)
-- values ('bbbbbbbb-0000-4000-8000-000000000002', 'goal', 'first_job');
--
-- insert into public.user_progress (user_id, topic_id)
-- select 'bbbbbbbb-0000-4000-8000-000000000002', id from public.topics limit 1;

-- Esperado: 1 fila insertada. La usuaria sí puede escribir lo propio.
insert into public.onboarding_answers (user_id, step_key, value)
values ('aaaaaaaa-0000-4000-8000-000000000001', 'experience_level', 'student')
on conflict (user_id, step_key) do update set value = excluded.value;

-- Esperado: 1 — solo la propia, aunque B también tenga una.
select count(*) as respuestas_propias from public.onboarding_answers;

-- ---------------------------------------------------------------------------
-- AC4 · el catálogo es de solo lectura para el cliente.
-- ---------------------------------------------------------------------------

-- Esperado: los tres en 0.
with borra_track as (delete from public.tracks where id = 'frontend' returning 1),
borra_topic as (delete from public.topics returning 1),
mueve_topic as (update public.topics set sort_order = 999 returning 1)
select
  (select count(*) from borra_track) as tracks_borrados,
  (select count(*) from borra_topic) as topics_borrados,
  (select count(*) from mueve_topic) as topics_modificados;

-- Esperado: 42501 en los dos. Descomentar de a uno.
--
-- insert into public.tracks (id, name, description)
-- values ('mobile', 'Mobile', 'Track que el cliente no deberia poder crear');
--
-- insert into public.topics (track_id, title, sort_order)
-- values ('frontend', 'Topico inyectado por el cliente', 99);

-- ---------------------------------------------------------------------------
-- Fin: deshace todo, incluidas las dos usuarias de prueba.
-- ---------------------------------------------------------------------------

reset role;
rollback;
