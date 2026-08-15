-- ===========================================================================
-- Intercalar concepto y práctica en las secciones que explicaban de corrido
-- ===========================================================================
--
-- De las 75 secciones del path, 8 presentaban dos explicaciones seguidas antes
-- de pedir nada: la persona leía el concepto 2 y recién después practicaba el
-- concepto 1. Eso es lo que rompe la retención, y es lo único que se toca acá.
-- Las otras 67 ya alternan y quedan intactas.
--
-- Siete de las ocho eran teoría-teoría-práctica: con un solo ejercicio no se
-- pueden intercalar reordenando, porque T-P-T termina en explicación y eso es
-- un cierre flojo. La octava (frontend, "Your First HTML Page") tenía dos
-- ejercicios pero los dos practicaban el segundo concepto, así que reordenar
-- habría emparejado mal. Las ocho reciben un ejercicio nuevo, escrito para el
-- concepto que lo precede y no para el que sea.
--
-- Los ejercicios nuevos se escribieron con situaciones de trabajo reales
-- —un comentario en un code review, un viernes que se rompe en producción, un
-- cliente que agrega alcance sin mover la fecha— y no con preguntas de
-- definición. El objetivo del path es que la persona sea empleable afuera, y
-- afuera nadie pregunta qué significa una sigla.
--
-- LAS SECCIONES SE RESUELVEN POR POSICIÓN, NO POR TÍTULO
--   (track, nivel 'Basic', sort_order) en vez del título de la sección: los
--   títulos son texto editorial y pueden cambiar; la posición es estructura.
--
-- POR QUÉ EL REORDEN PASA POR NEGATIVOS
--   lab_challenges tiene unique (topic_id, sort_order). Mover 3 a 4 mientras
--   existe un 4 falla. Se manda todo a negativo primero —dominio disjunto del
--   final— y desde ahí cada uno a su lugar definitivo.
--
-- IDEMPOTENTE
--   Cada bloque se saltea si su ejercicio nuevo ya existe. Correrla dos veces
--   no duplica nada ni vuelve a barajar el orden.
--
-- CÓMO CORRERLA
--   Dashboard de Supabase → SQL Editor → pegar todo → Run.
-- ===========================================================================

do $do$
declare
  v_sec uuid;
begin

  -- =========================================================================
  -- FRONTEND · Basic 1 · "What the Web Actually Is"
  -- El concepto 1 explica el viaje pedido-respuesta y nadie lo practicaba.
  -- =========================================================================
  select t.id into v_sec
  from public.topics t
  join public.topics lvl on lvl.id = t.parent_id
  where t.track_id = 'frontend' and lvl.title = 'Basic' and t.sort_order = 1;

  if v_sec is not null and not exists (
    select 1 from public.lab_challenges
    where topic_id = v_sec
      and question = $q$Order what happens between pressing Enter and seeing the page.$q$
  ) then
    update public.lab_challenges set sort_order = -sort_order where topic_id = v_sec;

    insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
    values (v_sec, 'order_logic',
      $q$Order what happens between pressing Enter and seeing the page.$q$,
      $q$Follow the message out to the server and back.$q$,
      $j${"blocks": {
        "type": "You type the address and press Enter",
        "request": "The browser sends a request to the server",
        "response": "The server answers with the files",
        "render": "The browser reads those files and draws the page"
      }, "correctOrder": ["type", "request", "response", "render"]}$j$, 2);

    update public.lab_challenges set sort_order = 1 where topic_id = v_sec
      and question = $q$What happens when you open a website$q$;
    update public.lab_challenges set sort_order = 3 where topic_id = v_sec
      and question = $q$The three languages of the web$q$;
    update public.lab_challenges set sort_order = 4 where topic_id = v_sec
      and question = $q$Your team asks you to change the color of every button on the site. Which language do you reach for?$q$;
  end if;

  -- =========================================================================
  -- FRONTEND · Basic 2 · "Your First HTML Page"
  -- Tenía dos ejercicios, pero los dos sobre el concepto 2 (los pares de
  -- etiquetas). El concepto 1 —significado, no apariencia— quedaba sin
  -- practicar, que es justo la idea que separa el HTML de junior del de
  -- principiante.
  -- =========================================================================
  select t.id into v_sec
  from public.topics t
  join public.topics lvl on lvl.id = t.parent_id
  where t.track_id = 'frontend' and lvl.title = 'Basic' and t.sort_order = 2;

  if v_sec is not null and not exists (
    select 1 from public.lab_challenges
    where topic_id = v_sec
      and question = $q$In a code review a teammate writes: "I used a heading tag because I wanted big bold text." What is wrong with that reasoning?$q$
  ) then
    update public.lab_challenges set sort_order = -sort_order where topic_id = v_sec;

    insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
    values (v_sec, 'multiple_choice',
      $q$In a code review a teammate writes: "I used a heading tag because I wanted big bold text." What is wrong with that reasoning?$q$,
      $q$Think about what the tag is actually deciding.$q$,
      $j${"options": {
        "size": "Nothing — making text big is what headings are for",
        "meaning": "A heading tag says the text IS a heading; how big it looks is CSS's job",
        "styling": "Heading tags cannot be styled with CSS",
        "never": "Heading tags should not be used at all"
      }, "correctOptionId": "meaning"}$j$, 2);

    update public.lab_challenges set sort_order = 1 where topic_id = v_sec
      and question = $q$What HTML is for$q$;
    update public.lab_challenges set sort_order = 3 where topic_id = v_sec
      and question = $q$Tags come in pairs$q$;
    update public.lab_challenges set sort_order = 4 where topic_id = v_sec
      and question = $q$Write a heading and a paragraph.$q$;
    update public.lab_challenges set sort_order = 5 where topic_id = v_sec
      and question = $q$Which line is written correctly?$q$;
  end if;

  -- =========================================================================
  -- FRONTEND · Basic 4 · "Giving It Style with CSS"
  -- El concepto 1 explica selector + declaración; el único ejercicio era de
  -- clases, que es el concepto 2.
  -- =========================================================================
  select t.id into v_sec
  from public.topics t
  join public.topics lvl on lvl.id = t.parent_id
  where t.track_id = 'frontend' and lvl.title = 'Basic' and t.sort_order = 4;

  if v_sec is not null and not exists (
    select 1 from public.lab_challenges
    where topic_id = v_sec
      and question = $q$Make every paragraph on the page dark grey.$q$
  ) then
    update public.lab_challenges set sort_order = -sort_order where topic_id = v_sec;

    insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
    values (v_sec, 'fill_blank',
      $q$Make every paragraph on the page dark grey.$q$,
      $q$One part picks the elements; the other describes them.$q$,
      $j${"codeSnippet": "{{0}} {\n  {{1}}: #333333;\n}",
        "correctAnswers": {"0": "p", "1": "color"},
        "availableOptions": ["p", ".p", "#p", "color", "background", "font-size"]}$j$, 2);

    update public.lab_challenges set sort_order = 1 where topic_id = v_sec
      and question = $q$How CSS finds your HTML$q$;
    update public.lab_challenges set sort_order = 3 where topic_id = v_sec
      and question = $q$Classes: styling some, not all$q$;
    update public.lab_challenges set sort_order = 4 where topic_id = v_sec
      and question = $q$Style only the elements marked as a card.$q$;
  end if;

  -- =========================================================================
  -- BACKEND · Basic 1
  -- El concepto 1 es el triángulo cliente-servidor-base; el ejercicio que
  -- había practicaba el concepto 2 (no confiar en el cliente).
  -- =========================================================================
  select t.id into v_sec
  from public.topics t
  join public.topics lvl on lvl.id = t.parent_id
  where t.track_id = 'backend' and lvl.title = 'Basic' and t.sort_order = 1;

  if v_sec is not null and not exists (
    select 1 from public.lab_challenges
    where topic_id = v_sec
      and question = $q$Order what happens when someone logs into an app.$q$
  ) then
    update public.lab_challenges set sort_order = -sort_order where topic_id = v_sec;

    insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
    values (v_sec, 'order_logic',
      $q$Order what happens when someone logs into an app.$q$,
      $q$Follow the triangle: who asks, who remembers, who decides.$q$,
      $j${"blocks": {
        "client": "The app sends the email and password to the server",
        "query": "The server asks the database for that account",
        "db": "The database returns what it has stored",
        "decide": "The server decides whether the password matches, and answers"
      }, "correctOrder": ["client", "query", "db", "decide"]}$j$, 2);

    update public.lab_challenges set sort_order = 1 where topic_id = v_sec
      and question = $q$The other half of every app$q$;
    update public.lab_challenges set sort_order = 3 where topic_id = v_sec
      and question = $q$Why the rules cannot live in the browser$q$;
    update public.lab_challenges set sort_order = 4 where topic_id = v_sec
      and question = $q$Which of these jobs belongs to the backend?$q$;
  end if;

  -- =========================================================================
  -- BACKEND · Basic 3
  -- El concepto 1 explica tabla, fila y columna; el ejercicio que había era
  -- del concepto 2 (por qué no guardar archivos).
  -- =========================================================================
  select t.id into v_sec
  from public.topics t
  join public.topics lvl on lvl.id = t.parent_id
  where t.track_id = 'backend' and lvl.title = 'Basic' and t.sort_order = 3;

  if v_sec is not null and not exists (
    select 1 from public.lab_challenges
    where topic_id = v_sec
      and question = $q$Your app has to store products, each with a name, a price and a stock count. How does that map onto a table?$q$
  ) then
    update public.lab_challenges set sort_order = -sort_order where topic_id = v_sec;

    insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
    values (v_sec, 'multiple_choice',
      $q$Your app has to store products, each with a name, a price and a stock count. How does that map onto a table?$q$,
      $q$One kind of thing, one of them, one fact about it.$q$,
      $j${"options": {
        "right": "One products table; each row is a product; name, price and stock are columns",
        "table_each": "One table per product, with a row for each of its facts",
        "one_big": "A single table called data, holding everything the app stores",
        "flipped": "One column per product, with a row for each shop"
      }, "correctOptionId": "right"}$j$, 2);

    update public.lab_challenges set sort_order = 1 where topic_id = v_sec
      and question = $q$Tables, rows and columns$q$;
    update public.lab_challenges set sort_order = 3 where topic_id = v_sec
      and question = $q$Why not just save files?$q$;
    update public.lab_challenges set sort_order = 4 where topic_id = v_sec
      and question = $q$Where should each user's saved progress live?$q$;
  end if;

  -- =========================================================================
  -- INFRASTRUCTURE · Basic 1
  -- El concepto 1 es "you build it, you run it"; el ejercicio que había era
  -- del concepto 2 (automatizar).
  -- =========================================================================
  select t.id into v_sec
  from public.topics t
  join public.topics lvl on lvl.id = t.parent_id
  where t.track_id = 'infrastructure' and lvl.title = 'Basic' and t.sort_order = 1;

  if v_sec is not null and not exists (
    select 1 from public.lab_challenges
    where topic_id = v_sec
      and question = $q$Your team ships a feature on Friday. It breaks in production on Saturday. Under DevOps, whose problem is it?$q$
  ) then
    update public.lab_challenges set sort_order = -sort_order where topic_id = v_sec;

    insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
    values (v_sec, 'multiple_choice',
      $q$Your team ships a feature on Friday. It breaks in production on Saturday. Under DevOps, whose problem is it?$q$,
      $q$Remember who is meant to run what they build.$q$,
      $j${"options": {
        "team": "The team that built it — building it and running it are the same job",
        "ops": "The operations team, because production is theirs",
        "monday": "Nobody's until Monday, when the office opens",
        "author": "Whoever wrote the failing line, on their own"
      }, "correctOptionId": "team"}$j$, 2);

    update public.lab_challenges set sort_order = 1 where topic_id = v_sec
      and question = $q$Dev plus Ops$q$;
    update public.lab_challenges set sort_order = 3 where topic_id = v_sec
      and question = $q$Automate the boring, repeat the safe$q$;
    update public.lab_challenges set sort_order = 4 where topic_id = v_sec
      and question = $q$Which of these is a DevOps practice?$q$;
  end if;

  -- =========================================================================
  -- UI/UX · Basic 1
  -- Acá el ejercicio que había SÍ practicaba el concepto 1 (UI vs UX), así
  -- que sube al segundo lugar y el ejercicio nuevo es para el concepto 2.
  -- =========================================================================
  select t.id into v_sec
  from public.topics t
  join public.topics lvl on lvl.id = t.parent_id
  where t.track_id = 'uiux' and lvl.title = 'Basic' and t.sort_order = 1;

  if v_sec is not null and not exists (
    select 1 from public.lab_challenges
    where topic_id = v_sec
      and question = $q$You designed a screen and every button seems obvious to you. How do you find out whether it is obvious to your users?$q$
  ) then
    update public.lab_challenges set sort_order = -sort_order where topic_id = v_sec;

    insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
    values (v_sec, 'multiple_choice',
      $q$You designed a screen and every button seems obvious to you. How do you find out whether it is obvious to your users?$q$,
      $q$This gap does not close by thinking harder about it.$q$,
      $j${"options": {
        "watch": "Watch real people use it, without helping them",
        "team": "Ask your teammates whether it looks clear to them",
        "instinct": "Trust your instinct — you are a user too",
        "tooltip": "Add a tooltip explaining what each button does"
      }, "correctOptionId": "watch"}$j$, 4);

    update public.lab_challenges set sort_order = 1 where topic_id = v_sec
      and question = $q$Design is decisions, not decoration$q$;
    update public.lab_challenges set sort_order = 2 where topic_id = v_sec
      and question = $q$A checkout looks beautiful, but it takes nine steps and half the users abandon it. What kind of problem is that?$q$;
    update public.lab_challenges set sort_order = 3 where topic_id = v_sec
      and question = $q$You are not the user$q$;
  end if;

  -- =========================================================================
  -- PROJECT MANAGEMENT · Basic 1
  -- Igual que UI/UX: el ejercicio que había practicaba el concepto 1
  -- (proyecto vs operación), y el nuevo es para la triple restricción.
  -- =========================================================================
  select t.id into v_sec
  from public.topics t
  join public.topics lvl on lvl.id = t.parent_id
  where t.track_id = 'project_management' and lvl.title = 'Basic' and t.sort_order = 1;

  if v_sec is not null and not exists (
    select 1 from public.lab_challenges
    where topic_id = v_sec
      and question = $q$Two weeks before launch the client adds a feature and will not move the date. What do you do?$q$
  ) then
    update public.lab_challenges set sort_order = -sort_order where topic_id = v_sec;

    insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
    values (v_sec, 'multiple_choice',
      $q$Two weeks before launch the client adds a feature and will not move the date. What do you do?$q$,
      $q$You cannot move one corner of the triangle without moving another.$q$,
      $j${"options": {
        "trade": "Name the trade out loud: something else leaves the scope, or the budget grows",
        "absorb": "Absorb it quietly — the team can put in a couple of weekends",
        "hope": "Accept it and hope the estimate had room in it",
        "refuse": "Refuse every change once the plan has been signed"
      }, "correctOptionId": "trade"}$j$, 4);

    update public.lab_challenges set sort_order = 1 where topic_id = v_sec
      and question = $q$Temporary and unique$q$;
    update public.lab_challenges set sort_order = 2 where topic_id = v_sec
      and question = $q$Which of these is a project?$q$;
    update public.lab_challenges set sort_order = 3 where topic_id = v_sec
      and question = $q$The triple constraint$q$;
  end if;

end
$do$;

-- ---------------------------------------------------------------------------
-- Verificación: ninguna sección del path puede tener dos teorías seguidas
--
-- No mira solo las 8 tocadas: recorre las 75. Si una migración futura vuelve a
-- explicar de corrido, esta consulta lo dice.
-- ---------------------------------------------------------------------------

with seguidas as (
  select
    c.topic_id,
    c.question,
    c.challenge_type,
    lag(c.challenge_type) over (
      partition by c.topic_id order by c.sort_order
    ) as anterior
  from public.lab_challenges c
)
select
  t.track_id,
  lvl.title as nivel,
  t.title as seccion,
  count(*) filter (where s.challenge_type = 'theory' and s.anterior = 'theory')
    as teorias_seguidas,
  case
    when count(*) filter (
      where s.challenge_type = 'theory' and s.anterior = 'theory'
    ) > 0 then 'FALLA: explica dos veces antes de pedir nada'
    else 'OK'
  end as ok
from seguidas s
join public.topics t on t.id = s.topic_id
left join public.topics lvl on lvl.id = t.parent_id
group by t.track_id, lvl.title, t.title, t.sort_order
having count(*) filter (
  where s.challenge_type = 'theory' and s.anterior = 'theory'
) > 0
order by t.track_id, lvl.title, t.sort_order;

-- Si la consulta de arriba devuelve CERO filas, las 75 secciones alternan.
-- Este resumen confirma además que los retos nuevos entraron.

select
  track_id,
  count(*) as retos,
  count(*) filter (where challenge_type = 'theory') as teoria,
  count(*) filter (where challenge_type <> 'theory') as ejercicios
from public.lab_challenges c
join public.topics t on t.id = c.topic_id
group by track_id
order by track_id;
