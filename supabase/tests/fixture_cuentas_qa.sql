-- ===========================================================================
-- Fixture: 5 cuentas de QA, una por track
-- ===========================================================================
--
-- NO es una migración: no va en supabase/migrations/ y no cambia el esquema.
-- Crea usuarias reales para probar los 5 paths a mano y con la batería de QA.
--
-- CÓMO CORRERLO
--   Dashboard de Supabase → SQL Editor → pegar todo → Run.
--
-- ATENCIÓN: a diferencia de los otros scripts de supabase/tests/, este
-- **COMMITEA**. Deja 5 usuarias creadas en el proyecto. Es a propósito: son
-- cuentas para entrar por la app.
--
-- Es idempotente: borra las cuentas qa.*@aspire.dev antes de recrearlas, así
-- se puede correr las veces que haga falta para volver a fojas cero. El borrado
-- cascadea a profiles, onboarding_answers y user_progress.
--
-- QUÉ DEJA
--   qa.frontend@aspire.dev  → track frontend
--   qa.backend@aspire.dev   → track backend
--   qa.infra@aspire.dev     → track infrastructure
--   qa.uiux@aspire.dev      → track uiux
--   qa.pm@aspire.dev        → track project_management
--   Password de todas: QaAspire2026!
--
--   Todas nacen confirmadas (email_confirmed_at) y con el onboarding completo,
--   así entran directo al path sin pasar por el cuestionario ni por el correo.
--
-- POR QUÉ SE INSERTA TAMBIÉN EN auth.identities
--   GoTrue resuelve el login por email contra la identidad del proveedor. Sin
--   la fila en identities la cuenta existe pero no puede iniciar sesión, que es
--   justamente lo que se necesita acá.
--
-- POR QUÉ LAS COLUMNAS DE TOKEN VAN EN '' Y NO EN NULL
--   GoTrue las lee como cadenas, no como nullables. Dejarlas en NULL hace que
--   el login falle con 500 «Database error querying schema» antes incluso de
--   comparar la contraseña. Al registrarse por la app no se nota porque las
--   escribe GoTrue. Sus índices únicos son parciales
--   (`where <col> !~ '^[0-9 ]*$'`), así que la cadena vacía queda fuera del
--   filtro y varias filas pueden compartirla.
-- ===========================================================================

begin;

-- ---------------------------------------------------------------------------
-- Fojas cero
-- ---------------------------------------------------------------------------

delete from auth.users where email like 'qa.%@aspire.dev';

-- ---------------------------------------------------------------------------
-- Las 5 usuarias
--
-- Mismo INSERT que hace Supabase Auth al registrar, así el trigger
-- handle_new_user() crea los perfiles solo.
-- ---------------------------------------------------------------------------

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change,
  email_change_token_new, email_change_token_current
)
values
  ('00000000-0000-0000-0000-000000000000',
   'aa000001-0000-4000-8000-000000000001', 'authenticated', 'authenticated',
   'qa.frontend@aspire.dev', crypt('QaAspire2026!', gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"QA Frontend"}', now(), now(), '', '', '', '', ''),

  ('00000000-0000-0000-0000-000000000000',
   'aa000002-0000-4000-8000-000000000002', 'authenticated', 'authenticated',
   'qa.backend@aspire.dev', crypt('QaAspire2026!', gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"QA Backend"}', now(), now(), '', '', '', '', ''),

  ('00000000-0000-0000-0000-000000000000',
   'aa000003-0000-4000-8000-000000000003', 'authenticated', 'authenticated',
   'qa.infra@aspire.dev', crypt('QaAspire2026!', gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"QA Infra"}', now(), now(), '', '', '', '', ''),

  ('00000000-0000-0000-0000-000000000000',
   'aa000004-0000-4000-8000-000000000004', 'authenticated', 'authenticated',
   'qa.uiux@aspire.dev', crypt('QaAspire2026!', gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"QA UI/UX"}', now(), now(), '', '', '', '', ''),

  ('00000000-0000-0000-0000-000000000000',
   'aa000005-0000-4000-8000-000000000005', 'authenticated', 'authenticated',
   'qa.pm@aspire.dev', crypt('QaAspire2026!', gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}',
   '{"display_name":"QA PM"}', now(), now(), '', '', '', '', '');

-- ---------------------------------------------------------------------------
-- Identidades del proveedor email (lo que habilita el login)
-- ---------------------------------------------------------------------------

insert into auth.identities (
  provider_id, user_id, identity_data, provider,
  last_sign_in_at, created_at, updated_at
)
select
  u.id::text,
  u.id,
  jsonb_build_object(
    'sub', u.id::text,
    'email', u.email,
    'email_verified', true,
    'phone_verified', false
  ),
  'email',
  now(), now(), now()
from auth.users u
where u.email like 'qa.%@aspire.dev';

-- ---------------------------------------------------------------------------
-- Onboarding ya resuelto: cada cuenta parada en su track
--
-- El check profiles_completo_exige_track obliga a que track_id y
-- onboarding_completed_at viajen juntos.
-- ---------------------------------------------------------------------------

update public.profiles p set
  track_id = v.track,
  experience_level = v.nivel::public.experience_level,
  learning_goal = v.meta::public.learning_goal,
  onboarding_completed_at = now(),
  updated_at = now()
from (values
  ('qa.frontend@aspire.dev', 'frontend',           'student',          'first_job'),
  ('qa.backend@aspire.dev',  'backend',            'junior_developer', 'middle_level'),
  ('qa.infra@aspire.dev',    'infrastructure',     'career_switcher',  'new_language'),
  ('qa.uiux@aspire.dev',     'uiux',               'student',          'first_job'),
  ('qa.pm@aspire.dev',       'project_management', 'career_switcher',  'interview_skills')
) as v(email, track, nivel, meta)
where p.email = v.email;

commit;

-- ---------------------------------------------------------------------------
-- Verificación: 5 filas, todas OK
-- ---------------------------------------------------------------------------

select
  p.email,
  p.track_id,
  t.name as track,
  (select count(*) from public.topics
    where track_id = p.track_id and parent_id is null) as niveles,
  (select count(*) from public.topics
    where track_id = p.track_id and parent_id is not null) as secciones,
  case
    when u.email_confirmed_at is null then 'FALLA: sin confirmar'
    when i.id is null then 'FALLA: sin identidad, no podra entrar'
    when p.track_id is null then 'FALLA: sin track'
    when p.onboarding_completed_at is null then 'FALLA: onboarding incompleto'
    when (select count(*) from public.topics
           where track_id = p.track_id and parent_id is null) <> 3
      then 'FALLA: el track no tiene 3 niveles'
    else 'OK'
  end as ok
from public.profiles p
join auth.users u on u.id = p.id
left join auth.identities i on i.user_id = p.id and i.provider = 'email'
left join public.tracks t on t.id = p.track_id
where p.email like 'qa.%@aspire.dev'
order by p.email;
