-- ===========================================================================
-- Esquema para los retos interactivos (Micro-Labs) del Módulo 2
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Tipo enum para los tipos de reto
-- ---------------------------------------------------------------------------
create type public.challenge_type as enum (
  'multiple_choice',
  'fill_blank',
  'order_logic'
);

-- ---------------------------------------------------------------------------
-- lab_challenges — catálogo de retos por tópico. Solo lectura desde el cliente.
-- ---------------------------------------------------------------------------

create table public.lab_challenges (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references public.topics (id) on delete cascade,
  challenge_type public.challenge_type not null,
  question text not null,
  description text,
  -- El contenido dinámico específico de cada reto (opciones, código, respuestas).
  -- Se valida y tipa en la capa de datos de Flutter, permitiendo escalar a
  -- nuevos tipos de reto sin alterar el esquema relacional.
  content jsonb not null,
  -- Orden en el que se presentan dentro de un mismo tópico
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),

  constraint lab_challenges_orden_unico_por_topico
    unique (topic_id, sort_order)
);

create index lab_challenges_topic_idx on public.lab_challenges (topic_id);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table public.lab_challenges enable row level security;

-- Al igual que tracks y topics, los retos son material de estudio de solo lectura
-- para las usuarias autenticadas.
create policy "lab_challenges_select_autenticadas"
  on public.lab_challenges for select to authenticated
  using (true);
