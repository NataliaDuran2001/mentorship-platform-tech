-- ===========================================================================
-- Esquema del Módulo 1: onboarding y selección de roadmap. Issue #7.
--
-- Cinco tablas: profiles, tracks, topics, user_progress, onboarding_answers.
-- Todas con RLS habilitado y al menos una política explícita.
--
-- El schema public tiene un event trigger `ensure_rls` -> `rls_auto_enable()`
-- que habilita RLS solo en cada CREATE TABLE. Igual escribimos el
-- `enable row level security` explícito: esta migración tiene que ser
-- reproducible sobre un proyecto que no tenga ese guardrail (AC7).
--
-- El modo de falla que importa acá NO es olvidar habilitar RLS —eso lo cubre
-- el trigger—, sino dejar una tabla con RLS activo y cero políticas, que queda
-- silenciosamente inaccesible sin ningún error visible.
--
-- Los valores de los enums y de `tracks.id` son los slugs de
-- lib/domain/entities/{experience_level,learning_goal,roadmap_track}.dart.
-- Si cambian de un lado, cambian del otro.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------

-- Espejo de ExperienceLevel (3 valores, decisión de producto cerrada).
create type public.experience_level as enum (
  'student',
  'junior_developer',
  'career_switcher'
);

-- Espejo de LearningGoal (4 valores).
create type public.learning_goal as enum (
  'first_job',
  'new_language',
  'interview_skills',
  'middle_level'
);

-- Avance de un tópico. Ojo: solo se guardan los estados que son un HECHO.
-- `available` y `locked` de TopicStatus no viven acá porque son DERIVADOS:
-- los calcula GetRoadmapTreeUseCase recorriendo el árbol en orden. Guardarlos
-- obligaría a reescribir filas cada vez que la usuaria completa un tópico, y
-- dos fuentes de verdad para la misma cosa se desincronizan.
create type public.topic_progress_status as enum (
  'in_progress',
  'completed'
);

-- ---------------------------------------------------------------------------
-- tracks — catálogo de rutas. Solo lectura desde el cliente.
-- ---------------------------------------------------------------------------

create table public.tracks (
  -- Slug del enum RoadmapTrack, no un uuid: hace el mapeo enum <-> base
  -- directo y deja las URLs y los datos legibles.
  id text primary key,
  name text not null,
  description text not null,
  -- Nombre del ícono de Material. Texto porque la capa domain no puede
  -- importar Flutter; presentation lo resuelve.
  icon_name text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

comment on table public.tracks is
  'Catálogo de rutas de aprendizaje. Agregar una fila acá NO alcanza: el enum '
  'RoadmapTrack de lib/domain/ tiene que aprender el slug o la app la ignora.';

-- ---------------------------------------------------------------------------
-- profiles — 1:1 con auth.users
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  display_name text,
  experience_level public.experience_level,
  track_id text references public.tracks (id) on delete restrict,
  learning_goal public.learning_goal,
  onboarding_completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- El CA 1.3 en la base: sin track no hay roadmap que mostrar, así que un
  -- perfil no puede quedar marcado como completo con track_id nulo. Es la
  -- misma regla que UserProfile.hasCompletedOnboarding y la política del #14,
  -- acá abajo, donde ningún camino de la UI la puede saltear.
  constraint profiles_completo_exige_track
    check (onboarding_completed_at is null or track_id is not null)
);

comment on column public.profiles.track_id is
  'Ruta elegida. on delete restrict: no se borra un track que alguien está '
  'cursando, porque dejaría el perfil completo sin ruta.';

-- ---------------------------------------------------------------------------
-- topics — árbol por track. Solo lectura desde el cliente.
-- ---------------------------------------------------------------------------

create table public.topics (
  id uuid primary key default gen_random_uuid(),
  track_id text not null references public.tracks (id) on delete cascade,
  -- Jerarquía. null = tópico de primer nivel.
  parent_id uuid references public.topics (id) on delete cascade,
  title text not null,
  description text,
  -- Orden entre hermanos: es lo que hace la ruta secuencial (CA 1.3).
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),

  constraint topics_sin_padre_propio check (parent_id is null or parent_id <> id),

  -- Dos hermanos con el mismo sort_order harían el orden ambiguo y la ruta
  -- dejaría de ser determinística. `nulls not distinct` (PG 15+) hace que la
  -- restricción también aplique entre los tópicos de primer nivel.
  constraint topics_orden_unico_entre_hermanos
    unique nulls not distinct (track_id, parent_id, sort_order)
);

-- No hay forma declarativa simple de exigir que el padre sea del mismo track;
-- queda como invariante de los datos sembrados.
comment on column public.topics.parent_id is
  'Padre del tópico, del mismo track. La coherencia de track entre padre e '
  'hijo no está forzada por constraint: cuidarla al sembrar.';

create index topics_track_parent_orden_idx
  on public.topics (track_id, parent_id, sort_order);

-- ---------------------------------------------------------------------------
-- user_progress — avance por tópico
-- ---------------------------------------------------------------------------

create table public.user_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  topic_id uuid not null references public.topics (id) on delete cascade,
  status public.topic_progress_status not null default 'in_progress',
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- Una fila por usuaria y tópico: habilita el upsert y evita contar dos veces.
  constraint user_progress_una_fila_por_topico unique (user_id, topic_id),

  -- `completed` y `completed_at` van juntos o no van.
  constraint user_progress_completado_con_fecha
    check ((status = 'completed') = (completed_at is not null))
);

create index user_progress_usuaria_idx on public.user_progress (user_id);

-- ---------------------------------------------------------------------------
-- onboarding_answers — una respuesta por paso, para la reanudación (#14)
-- ---------------------------------------------------------------------------

create table public.onboarding_answers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  -- Clave estable del paso o pregunta: OnboardingKeys de lib/domain/
  -- ('experience_level', 'track', 'goal', 'quiz_1', 'quiz_2', ...).
  step_key text not null,
  -- Slug de la opción elegida, como texto: el mismo par (paso, valor) sirve a
  -- los pasos directos y a las preguntas del cuestionario guía.
  value text not null,
  answered_at timestamptz not null default now(),

  -- Clave del upsert del #14: volver atrás y cambiar una respuesta actualiza
  -- la fila, no agrega otra. Sin esto, reanudar duplica.
  constraint onboarding_answers_una_por_paso unique (user_id, step_key)
);

create index onboarding_answers_usuaria_idx
  on public.onboarding_answers (user_id);

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

-- Perfil automático al registrarse: no puede haber usuarias sin perfil, ni un
-- registro que dependa de que el cliente se acuerde de crear la fila.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    new.email,
    nullif(new.raw_user_meta_data ->> 'display_name', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

comment on function public.handle_new_user() is
  'Crea public.profiles al insertarse en auth.users. SECURITY DEFINER con '
  'search_path vacío: corre como owner (por eso no la frena RLS) y no puede '
  'ser secuestrada por un search_path del invocador.';

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Mantiene updated_at honesto sin depender del cliente.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.touch_updated_at();

create trigger user_progress_touch_updated_at
  before update on public.user_progress
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
--
-- La publishable key viaja en el bundle de Flutter Web, así que todo lo que no
-- esté explícitamente permitido acá es lo único que protege los datos.
--
-- Ninguna política menciona el rol `anon`: sin sesión no se lee nada, ni el
-- catálogo. Todo el Módulo 1 pasa por login.
-- ---------------------------------------------------------------------------

alter table public.tracks enable row level security;
alter table public.profiles enable row level security;
alter table public.topics enable row level security;
alter table public.user_progress enable row level security;
alter table public.onboarding_answers enable row level security;

-- tracks y topics: catálogo, solo lectura. Sin políticas de insert/update/
-- delete, así que el cliente no puede escribirlos (AC4). El contenido entra
-- por migración.
create policy "tracks_select_autenticadas"
  on public.tracks for select to authenticated
  using (true);

create policy "topics_select_autenticadas"
  on public.topics for select to authenticated
  using (true);

-- profiles: cada usuaria, su fila y nada más.
create policy "profiles_select_propio"
  on public.profiles for select to authenticated
  using (auth.uid() = id);

create policy "profiles_update_propio"
  on public.profiles for update to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- El insert normal lo hace el trigger. Esta política existe solo para que la
-- app pueda recrear su propio perfil si el trigger no corrió (usuarias
-- anteriores a esta migración, por ejemplo), y solo el propio.
create policy "profiles_insert_propio"
  on public.profiles for insert to authenticated
  with check (auth.uid() = id);

-- Sin política de delete: el perfil se va por cascada al borrarse la usuaria.

-- user_progress: propio, con insert y update para el upsert del avance.
create policy "user_progress_select_propio"
  on public.user_progress for select to authenticated
  using (auth.uid() = user_id);

create policy "user_progress_insert_propio"
  on public.user_progress for insert to authenticated
  with check (auth.uid() = user_id);

create policy "user_progress_update_propio"
  on public.user_progress for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- onboarding_answers: propio. insert + update son los dos lados del upsert por
-- (user_id, step_key) que necesita la reanudación del #14.
create policy "onboarding_answers_select_propio"
  on public.onboarding_answers for select to authenticated
  using (auth.uid() = user_id);

create policy "onboarding_answers_insert_propio"
  on public.onboarding_answers for insert to authenticated
  with check (auth.uid() = user_id);

create policy "onboarding_answers_update_propio"
  on public.onboarding_answers for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Semilla: los 3 tracks
--
-- Textos exactos del prototipo `orientaci_n_de_ruta_test`, que es el que trae
-- las descripciones. Íconos de Material, los mismos del prototipo.
-- ---------------------------------------------------------------------------

insert into public.tracks (id, name, description, icon_name, sort_order)
values
  (
    'frontend',
    'Front-end',
    'Crear interfaces visuales y experiencias de usuario que cautiven a primera vista.',
    'brush',
    1
  ),
  (
    'backend',
    'Back-end',
    'Diseñar la lógica detrás de escena y bases de datos robustas para escalar sistemas.',
    'database',
    2
  ),
  (
    'infrastructure',
    'Infraestructura',
    'Organizar procesos, automatizar tareas y optimizar flujos de trabajo masivos.',
    'settings_suggest',
    3
  )
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Semilla: tópicos PLACEHOLDER
--
-- El currículum real es una decisión abierta del Módulo 2 y no se inventa acá.
-- Estos títulos dicen «placeholder» a propósito: si alguno llega a una captura
-- de pantalla, se ve que es andamio.
--
-- Se siembra SOLO el track frontend, a propósito. El #13 tiene que manejar dos
-- casos y así puede probar los dos contra datos reales: un árbol con jerarquía
-- (frontend) y el estado vacío (backend e infrastructure), que hoy es el caso
-- normal porque el currículum no está escrito.
-- ---------------------------------------------------------------------------

do $$
declare
  v_modulo_a uuid;
  v_modulo_b uuid;
  v_placeholder text :=
    'Contenido pendiente. El currículum real es una decisión abierta del Módulo 2.';
begin
  -- Idempotente: no re-siembra si ya hay tópicos.
  if exists (select 1 from public.topics) then
    return;
  end if;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', null, 'Módulo de ejemplo A (placeholder)', v_placeholder, 1)
  returning id into v_modulo_a;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values
    ('frontend', v_modulo_a, 'Tópico A1 (placeholder)', v_placeholder, 1),
    ('frontend', v_modulo_a, 'Tópico A2 (placeholder)', v_placeholder, 2);

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', null, 'Módulo de ejemplo B (placeholder)', v_placeholder, 2)
  returning id into v_modulo_b;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', v_modulo_b, 'Tópico B1 (placeholder)', v_placeholder, 1);
end
$$;
