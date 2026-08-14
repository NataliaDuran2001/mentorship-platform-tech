-- ===========================================================================
-- Catálogo de tracks: ciclo completo de desarrollo de software
-- ===========================================================================
--
-- Decisión de producto del 2026-08-14: la dueña reabre el alcance original de
-- "solo 3 tracks técnicos" y suma UI/UX Design y Project Management, para que
-- el catálogo cubra el ciclo completo de entrega de software. Infrastructure
-- pasa a llamarse "Infrastructure & DevOps": el contenido nuevo mezcla ambas
-- disciplinas y así se pide en la industria.
--
-- Los ids son las claves del enum RoadmapTrack en Flutter: nunca se renombran,
-- solo se agregan. El estilo de las descripciones sigue el del catálogo
-- traducido en 20260727042317.

update public.tracks set
  name = 'Infrastructure & DevOps',
  description = 'Set up the tools that keep everything running smoothly and help apps reach more people without breaking.'
where id = 'infrastructure';

insert into public.tracks (id, name, description, icon_name, sort_order)
values
  (
    'uiux',
    'UI/UX Design',
    'Understand people and design the screens they will love — from the first sketch to the final look and feel.',
    'palette',
    4
  ),
  (
    'project_management',
    'Project Management',
    'Guide teams and projects from idea to delivery — plan the work, manage risks and keep everyone moving together.',
    'fact_check',
    5
  )
on conflict (id) do nothing;
