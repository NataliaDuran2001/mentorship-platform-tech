-- ===========================================================================
-- Verificación del modelo de roles. Issue #36, AC1, AC2 y AC4.
--
-- Complementa a rls_modulo_1.sql, que sigue siendo el guion del aislamiento
-- por usuaria (#7). Este cubre lo que agrega el rol: quién escribe el
-- catálogo y por qué nadie se promueve solo.
--
-- Este guion ya encontró un defecto real: la primera versión del trigger se
-- creó SECURITY DEFINER, y dentro de una función así `current_user` es el
-- dueño de la función y no quien ejecuta la sentencia, de modo que la
-- estudiante SÍ podía promoverse. Correrlo no es ceremonia.
--
-- NO es una migración: no va en supabase/migrations/ y no cambia el esquema.
--
-- CÓMO CORRERLO
--   Dashboard de Supabase → SQL Editor → pegar todo → Run.
--   O bien:  psql "$DATABASE_URL" -f supabase/tests/rls_roles.sql
--
--   Va todo de una sola vez. No correrlo por partes: es una única transacción.
--
-- QUÉ DEVUELVE
--   Una fila por prueba y una columna `ok`. **Todas tienen que decir OK.**
--
-- QUÉ DEJA
--   Nada: termina en ROLLBACK. Las usuarias de prueba y lo que crea la
--   administradora se deshacen al terminar. Tampoco manda correos.
-- ===========================================================================

begin;

create temp table _r (
  orden integer,
  prueba text,
  esperado text,
  obtenido text
) on commit drop;

grant all on _r to authenticated;

-- ---------------------------------------------------------------------------
-- Fixture: dos usuarias. Mismo INSERT que hace Supabase Auth al registrar, así
-- que el trigger handle_new_user se ejercita igual.
-- ---------------------------------------------------------------------------

insert into auth.users (
  id, aud, role, email, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    'cccccccc-0000-4000-8000-000000000003'::uuid, 'authenticated',
    'authenticated', 'roles-test-student@aspire.test', now(),
    '{"provider":"email","providers":["email"]}',
    '{"display_name":"Estudiante"}', now(), now()
  ),
  (
    'ddddddd0-0000-4000-8000-000000000004'::uuid, 'authenticated',
    'authenticated', 'roles-test-admin@aspire.test', now(),
    '{"provider":"email","providers":["email"]}',
    '{"display_name":"Administradora"}', now(), now()
  );

-- AC1 · el rol por defecto ---------------------------------------------------

insert into _r
select
  1,
  'AC1 - registrarse crea el perfil con rol student',
  '2 student',
  count(*)::text || ' ' || coalesce(min(role::text), '(sin rol)')
from public.profiles
where id in (
  'cccccccc-0000-4000-8000-000000000003'::uuid,
  'ddddddd0-0000-4000-8000-000000000004'::uuid
);

-- Promoción: fuera de la sesión del cliente, que es el único camino
-- permitido. Acá corre como owner, igual que lo haría el SQL editor.
update public.profiles
set role = 'admin'
where id = 'ddddddd0-0000-4000-8000-000000000004'::uuid;

insert into _r
select
  2,
  'AC1 - la promocion fuera del cliente funciona',
  'admin',
  role::text
from public.profiles
where id = 'ddddddd0-0000-4000-8000-000000000004'::uuid;

-- Se borra el perfil de la estudiante como owner para poder ejercitar el
-- camino del INSERT desde el cliente. En la vida real la fila siempre existe
-- (la crea el trigger y no hay política de delete), pero la regla no puede
-- depender de esa circunstancia.
delete from public.profiles
where id = 'cccccccc-0000-4000-8000-000000000003'::uuid;

-- ---------------------------------------------------------------------------
-- Como la ESTUDIANTE
-- ---------------------------------------------------------------------------

set local role authenticated;

select set_config(
  'request.jwt.claims',
  '{"sub":"cccccccc-0000-4000-8000-000000000003","role":"authenticated"}',
  true
);

do $$
begin
  -- AC4 · el camino del insert: crear el perfil propio ya con rol admin
  begin
    insert into public.profiles (id, email, role)
    values (
      'cccccccc-0000-4000-8000-000000000003'::uuid,
      'roles-test-student@aspire.test',
      'admin'
    );
    insert into _r values (5,
      'AC4 - no se crea un perfil propio con rol admin',
      'DENEGADO', 'PERMITIDO');
  exception when others then
    insert into _r values (5,
      'AC4 - no se crea un perfil propio con rol admin',
      'DENEGADO', 'DENEGADO (' || sqlstate || ')');
  end;

  -- El bloqueo no puede romper la recuperación legítima del perfil.
  begin
    insert into public.profiles (id, email)
    values (
      'cccccccc-0000-4000-8000-000000000003'::uuid,
      'roles-test-student@aspire.test'
    );
    insert into _r values (6,
      'AC4 - si se recrea el perfil propio como estudiante',
      'PERMITIDO', 'PERMITIDO');
  exception when others then
    insert into _r values (6,
      'AC4 - si se recrea el perfil propio como estudiante',
      'PERMITIDO', 'DENEGADO (' || sqlstate || ')');
  end;

  -- AC2 · la estudiante no escribe el catálogo
  begin
    insert into public.tracks (id, name, description, sort_order)
    values ('pirata', 'Track pirata', 'No deberia entrar', 99);
    insert into _r values (10,
      'AC2 - la estudiante no inserta en tracks', 'DENEGADO', 'PERMITIDO');
  exception when others then
    insert into _r values (10,
      'AC2 - la estudiante no inserta en tracks',
      'DENEGADO', 'DENEGADO (' || sqlstate || ')');
  end;

  begin
    insert into public.topics (track_id, title, sort_order)
    values ('frontend', 'Topico pirata', 98);
    insert into _r values (11,
      'AC2 - la estudiante no inserta en topics', 'DENEGADO', 'PERMITIDO');
  exception when others then
    insert into _r values (11,
      'AC2 - la estudiante no inserta en topics',
      'DENEGADO', 'DENEGADO (' || sqlstate || ')');
  end;

  -- AC4 · el corazón del issue: nadie se promueve solo
  begin
    update public.profiles
    set role = 'admin'
    where id = 'cccccccc-0000-4000-8000-000000000003'::uuid;
    insert into _r values (12,
      'AC4 - la estudiante no se promueve a admin', 'DENEGADO', 'PERMITIDO');
  exception when others then
    insert into _r values (12,
      'AC4 - la estudiante no se promueve a admin',
      'DENEGADO', 'DENEGADO (' || sqlstate || ')');
  end;

  -- El bloqueo tiene que ser quirúrgico: el resto del perfil se sigue
  -- actualizando, o el onboarding dejaría de funcionar.
  begin
    update public.profiles
    set display_name = 'Nombre nuevo'
    where id = 'cccccccc-0000-4000-8000-000000000003'::uuid;
    insert into _r values (13,
      'AC4 - la estudiante si actualiza el resto de su perfil',
      'PERMITIDO', 'PERMITIDO');
  exception when others then
    insert into _r values (13,
      'AC4 - la estudiante si actualiza el resto de su perfil',
      'PERMITIDO', 'DENEGADO (' || sqlstate || ')');
  end;
end
$$;

reset role;

-- ---------------------------------------------------------------------------
-- Como la ADMINISTRADORA
-- ---------------------------------------------------------------------------

set local role authenticated;

select set_config(
  'request.jwt.claims',
  '{"sub":"ddddddd0-0000-4000-8000-000000000004","role":"authenticated"}',
  true
);

do $$
begin
  -- AC2 · la administradora sí escribe el catálogo. Es lo que habilita el #37.
  begin
    insert into public.tracks (id, name, description, sort_order)
    values ('qa', 'QA', 'Track cargado por la administradora', 90);
    insert into _r values (20,
      'AC2 - la admin inserta en tracks', 'PERMITIDO', 'PERMITIDO');
  exception when others then
    insert into _r values (20,
      'AC2 - la admin inserta en tracks',
      'PERMITIDO', 'DENEGADO (' || sqlstate || ')');
  end;

  begin
    insert into public.topics (track_id, title, sort_order)
    values ('qa', 'Topico de la admin', 1);
    insert into _r values (21,
      'AC2 - la admin inserta en topics', 'PERMITIDO', 'PERMITIDO');
  exception when others then
    insert into _r values (21,
      'AC2 - la admin inserta en topics',
      'PERMITIDO', 'DENEGADO (' || sqlstate || ')');
  end;

  begin
    update public.tracks set description = 'Descripcion corregida'
    where id = 'qa';
    insert into _r values (22,
      'AC2 - la admin actualiza tracks', 'PERMITIDO', 'PERMITIDO');
  exception when others then
    insert into _r values (22,
      'AC2 - la admin actualiza tracks',
      'PERMITIDO', 'DENEGADO (' || sqlstate || ')');
  end;

  -- AC4 · ni siquiera la administradora cambia roles desde el cliente. El
  -- trigger mira la sesión, no el rol: si mirara el rol, una admin
  -- comprometida podría repartir permisos desde el navegador.
  begin
    update public.profiles
    set role = 'student'
    where id = 'ddddddd0-0000-4000-8000-000000000004'::uuid;
    insert into _r values (23,
      'AC4 - ni la admin cambia roles desde el cliente',
      'DENEGADO', 'PERMITIDO');
  exception when others then
    insert into _r values (23,
      'AC4 - ni la admin cambia roles desde el cliente',
      'DENEGADO', 'DENEGADO (' || sqlstate || ')');
  end;

  -- El aislamiento entre usuarias no se afloja por ser administradora: el rol
  -- da acceso al catálogo, no a los datos de las demás.
  insert into _r
  select
    24,
    'AC4 - la admin no ve perfiles ajenos',
    '0',
    count(*)::text
  from public.profiles
  where id = 'cccccccc-0000-4000-8000-000000000003'::uuid;
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
from _r
order by orden;

rollback;
