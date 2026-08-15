-- ===========================================================================
-- content_translations — caché compartido de traducciones generadas por IA
-- ===========================================================================
--
-- `topics` y `lab_challenges` viven sembrados en inglés únicamente (ver
-- 20260728000001, 20260814000002 y siguientes). No hay columna de idioma en
-- esas tablas ni catálogo bilingüe: agregar una obligaría a mantener a mano
-- 235 challenges en dos idiomas cada vez que cambia el currículo.
--
-- En vez de eso, el inglés sembrado sigue siendo la fuente de verdad y esta
-- tabla cachea la traducción al español generada por Kimi3, una sola vez por
-- fila de origen. A diferencia de `ai_profile_insights`, este caché es
-- compartido entre todas las usuarias (no por user_id): el contenido de un
-- tópico es el mismo para cualquiera que lo vea en el mismo idioma, así que
-- cachearlo por usuaria multiplicaría el costo de IA sin ninguna ganancia.
--
-- Los ejercicios (multiple_choice, fill_blank, order_logic) no pasan por acá:
-- su `content` valida respuestas y debe permanecer estable en el idioma
-- sembrado.

create table public.content_translations (
  id           uuid        primary key default gen_random_uuid(),
  source_table text        not null check (source_table in ('topics', 'lab_challenges')),
  source_id    uuid        not null,
  language     text        not null check (language in ('en', 'es')),
  -- Para 'topics': {"title": "...", "description": "..." | null}.
  -- Para 'lab_challenges' (solo challenge_type = 'theory'):
  --   {"question": "...", "blocks": [...], "keyTakeaway": "..." | null}
  --   (mismo shape que la columna `content` de lab_challenges).
  content      jsonb       not null,
  model        text        not null default 'kimi-k3',
  created_at   timestamptz not null default now(),

  constraint content_translations_unica
    unique (source_table, source_id, language)
);

comment on table public.content_translations is
  'Caché compartido (no por usuaria) de traducciones de topics/lab_challenges '
  'generadas por Kimi3. El inglés sembrado es la fuente de verdad; esta tabla '
  'solo guarda el resultado de traducirlo. Las Edge Functions escriben via '
  'service_role.';

create index content_translations_lookup_idx
  on public.content_translations (source_table, source_id, language);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table public.content_translations enable row level security;

-- Mismo criterio que topics/lab_challenges: material de estudio de solo
-- lectura para usuarias autenticadas. Sin políticas de insert/update/delete
-- para el cliente: solo la Edge Function (service_role) escribe acá.
create policy "content_translations_select_autenticadas"
  on public.content_translations for select to authenticated
  using (true);
