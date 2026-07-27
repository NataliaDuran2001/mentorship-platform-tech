-- Issue #35: la UI pasa a ingles, y el catalogo sembrado se muestra tal cual.
-- RoadmapTree renderiza topics.title y topics.description, y las descripciones
-- de tracks alimentan las tarjetas del onboarding: dejarlos en espanol romperia
-- el AC1 ("ningun texto visible de la UI queda en espanol") por mas que lib/
-- este traducido.
--
-- Lo que NO se toca: tracks.id (frontend, backend, infrastructure). Es la clave
-- por la que el enum RoadmapTrack mapea contra la base; es dato, no interfaz.

update public.tracks set
  name = 'Front-end',
  description = 'Build visual interfaces and user experiences that win people over at first sight.'
where id = 'frontend';

update public.tracks set
  name = 'Back-end',
  description = 'Design the logic behind the scenes and solid databases to scale systems.'
where id = 'backend';

update public.tracks set
  name = 'Infrastructure',
  description = 'Organize processes, automate tasks and smooth out huge workflows.'
where id = 'infrastructure';

-- Los topicos son placeholders del #7: el curriculum real es decision abierta
-- del Modulo 2 (ver #37). Se traduce el andamio, no se inventa contenido.
update public.topics set
  title = replace(replace(title, 'Modulo de ejemplo', 'Sample module'), 'Topico', 'Topic');

update public.topics set
  title = replace(replace(title, 'Módulo de ejemplo', 'Sample module'), 'Tópico', 'Topic');

update public.topics set
  description = 'Content pending. The real curriculum is an open decision for Module 2.'
where description like 'Contenido pendiente%';
