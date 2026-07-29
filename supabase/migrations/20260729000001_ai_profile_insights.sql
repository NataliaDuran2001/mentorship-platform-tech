-- ===========================================================================
-- AI Profile Insights — Módulo AI-First
--
-- Almacena los insights generados por Kimi3 (kimi-k3 via Moonshot AI).
-- Cada fila es una respuesta cacheada de la IA para un usuario específico.
-- Los tipos soportados:
--   'track_recommendation' — análisis del perfil con razonamiento del track
--   'daily_brief'          — resumen diario personalizado del dashboard
--   'roadmap_coach'        — mensaje motivacional del header del roadmap
--   'topic_hint'           — pista de un lab challenge
-- ===========================================================================

create table public.ai_profile_insights (
  id           uuid        primary key default gen_random_uuid(),
  user_id      uuid        not null references auth.users (id) on delete cascade,
  insight_type text        not null,
  -- Contenido flexible según el tipo. Siempre tiene al menos { "text": "..." }.
  -- track_recommendation también lleva { "reasoning": "...", "confidence": 0.9 }.
  content      jsonb       not null,
  model        text        not null default 'kimi-k3',
  created_at   timestamptz not null default now()
);

comment on table public.ai_profile_insights is
  'Caché de respuestas generadas por Kimi3. Nunca contiene datos de otros '
  'usuarios: RLS lo garantiza. El cliente lee aquí antes de llamar a la '
  'Edge Function para evitar llamadas redundantes al LLM.';

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table public.ai_profile_insights enable row level security;

-- Cada usuario ve y gestiona solo sus propios insights.
create policy "insight owner read"
  on public.ai_profile_insights
  for select
  using (auth.uid() = user_id);

create policy "insight owner insert"
  on public.ai_profile_insights
  for insert
  with check (auth.uid() = user_id);

create policy "insight owner delete"
  on public.ai_profile_insights
  for delete
  using (auth.uid() = user_id);

-- Las Edge Functions escriben via service_role key: no tienen restricción RLS,
-- pero sí se les pasa explícitamente el user_id en el payload para que
-- la fila quede asociada al usuario correcto.

-- ---------------------------------------------------------------------------
-- Índices
-- ---------------------------------------------------------------------------

-- Patrón principal de lectura: "dame el insight más reciente de tipo X para
-- el usuario Y". El orden DESC en created_at permite limit 1 sin sort extra.
create index ai_insights_user_type_idx
  on public.ai_profile_insights (user_id, insight_type, created_at desc);
