-- ===========================================================================
-- Semilla: path de Frontend por niveles (Basic / Intermediate / Advanced)
-- ===========================================================================
--
-- Reemplaza los 3 tópicos planos de frontend por 3 niveles con 5 secciones
-- cada uno. Los niveles son tópicos padre: no hay columna de dificultad: la
-- jerarquía que ya existía (`parent_id`) alcanza, y el árbol, el orden y el
-- desbloqueo secuencial funcionan sin tocar dominio ni casos de uso.
--
-- 47 retos en total. La teoría es la mitad de Basic (8 de 16), cede en
-- Intermediate (5 de 16) y casi desaparece en Advanced (2 de 15): primero se
-- explica, después se practica, y al final sólo se resuelve. La selección de
-- temas apunta a lo que la industria internacional pide de un perfil junior
-- —HTML semántico, mobile-first, accesibilidad, consumo de APIs— y no a lo que
-- luce bien en un demo.
--
-- Sólo toca frontend. Backend e infrastructure conservan sus tópicos planos
-- actuales, así que ninguna usuaria de esos tracks nota el cambio.
--
-- Ojo: `topics` cascadea a `lab_challenges` y a `user_progress`. El progreso
-- de frontend previo a esta migración se pierde, porque los ids de los tópicos
-- se regeneran y no hay forma de mapear los viejos a los nuevos. Es asumible
-- mientras el currículum anterior eran 3 tópicos de prueba.

do $$
declare
  v_basic uuid;
  v_inter uuid;
  v_adv uuid;

  -- Basic
  v_b1 uuid; v_b2 uuid; v_b3 uuid; v_b4 uuid; v_b5 uuid;
  -- Intermediate
  v_i1 uuid; v_i2 uuid; v_i3 uuid; v_i4 uuid; v_i5 uuid;
  -- Advanced
  v_a1 uuid; v_a2 uuid; v_a3 uuid; v_a4 uuid; v_a5 uuid;
begin

  delete from public.topics where track_id = 'frontend';

  -- =========================================================================
  -- NIVELES
  -- =========================================================================
  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', null, 'Basic',
    $q$How the web works, and how to build a page that says what it means. Start here even if you have never written a line of code.$q$, 1)
  returning id into v_basic;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', null, 'Intermediate',
    $q$Layouts that hold up on any screen, and the language that makes a page react. This is where you start building things people can actually use.$q$, 2)
  returning id into v_inter;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', null, 'Advanced',
    $q$What a junior frontend role is really hired for: making the page respond, handling real data, and building interfaces that work for everyone.$q$, 3)
  returning id into v_adv;

  -- =========================================================================
  -- BASIC
  -- =========================================================================
  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', v_basic, 'What the Web Actually Is',
    $q$Before writing code, understand what happens between clicking a link and seeing a page.$q$, 1)
  returning id into v_b1;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', v_basic, 'Your First HTML Page',
    $q$Write real HTML and understand what every piece of it does.$q$, 2)
  returning id into v_b2;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', v_basic, 'Structuring Content',
    $q$Use the right tag for the right job — the habit that separates junior code from beginner code.$q$, 3)
  returning id into v_b3;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', v_basic, 'Giving It Style with CSS',
    $q$Control how your page looks without touching what it says.$q$, 4)
  returning id into v_b4;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', v_basic, 'Boxes, Space and Layout',
    $q$Every element is a box. Once you see that, spacing stops being guesswork.$q$, 5)
  returning id into v_b5;

  -- --- B1 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b1, 'theory', $q$What happens when you open a website$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "When you type an address and press Enter, your browser sends a request to another computer — a server — asking for a page. The server answers with plain text files. Your browser reads those files and draws what you see."},
    {"type": "paragraph", "text": "That is the whole loop: request, response, render. Everything you will learn as a frontend developer happens on your side of that loop, inside the browser."},
    {"type": "list", "items": [
      "Client — the browser on your device. This is where frontend code runs.",
      "Server — the computer that stores the files and sends them back.",
      "Request and response — the message you send, and the answer you get."
    ]}
  ], "keyTakeaway": "Frontend is everything that runs in the browser, after the response arrives."}
  $j$, 1),

  (v_b1, 'theory', $q$The three languages of the web$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "A web page is built from three languages, and each one has a single job. Mixing up those jobs is the most common source of messy code in real projects."},
    {"type": "list", "items": [
      "HTML gives content its meaning: this is a heading, this is a paragraph, this is a button.",
      "CSS decides how that content looks: color, spacing, size, layout.",
      "JavaScript decides how the page behaves: what happens when someone clicks, types or scrolls."
    ]},
    {"type": "paragraph", "text": "You will learn them in that order, because that is the order in which they depend on each other. A page with only HTML still works. A page with only CSS is nothing at all."}
  ], "keyTakeaway": "HTML means. CSS looks. JavaScript does."}
  $j$, 2),

  (v_b1, 'multiple_choice',
   $q$Your team asks you to change the color of every button on the site. Which language do you reach for?$q$,
   $q$Think about which of the three owns appearance.$q$,
   $j${"options": {
      "html": "HTML, because the buttons are written there",
      "css": "CSS, because color is presentation",
      "js": "JavaScript, because it changes the page",
      "server": "The server, because it sends the files"
    }, "correctOptionId": "css"}$j$, 3);

  -- --- B2 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b2, 'theory', $q$What HTML is for$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "A web page is just a text file. What makes a browser show it as a page — with headings, paragraphs and images — is HTML: a set of labels you wrap around your content to say what each piece is."},
    {"type": "paragraph", "text": "HTML does not decide how things look. It decides what things are. A heading is a heading whether it ends up large and blue or small and grey; that part comes later, with CSS."}
  ], "keyTakeaway": "HTML describes meaning, not appearance."}
  $j$, 1),

  (v_b2, 'theory', $q$Tags come in pairs$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "A label in HTML is called a tag, and most tags come in pairs: one to open and one to close. The closing one carries a slash."},
    {"type": "code", "language": "html", "text": "<p>This is a paragraph.</p>"},
    {"type": "paragraph", "text": "The opening tag starts it, the closing tag ends it, and whatever sits between them is the content. Forgetting to close a tag is the single most common beginner mistake — and the browser will not warn you about it."}
  ], "keyTakeaway": "Open, write, close."}
  $j$, 2),

  (v_b2, 'fill_blank',
   $q$Write a heading and a paragraph.$q$,
   $q$Remember that each tag needs its closing pair.$q$,
   $j${"codeSnippet": "{{0}}My first page{{1}}\n{{2}}I built this myself.{{3}}",
      "correctAnswers": {"0": "<h1>", "1": "</h1>", "2": "<p>", "3": "</p>"},
      "availableOptions": ["<h1>", "</h1>", "<p>", "</p>", "<title>", "</title>"]}$j$, 3),

  (v_b2, 'multiple_choice',
   $q$Which line is written correctly?$q$,
   $q$Look closely at the closing tags.$q$,
   $j${"options": {
      "a": "<p>Hello<p>",
      "b": "<p>Hello</p>",
      "c": "p>Hello</p",
      "d": "<paragraph>Hello</paragraph>"
    }, "correctOptionId": "b"}$j$, 4);

  -- --- B3 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b3, 'theory', $q$Semantic HTML, and why interviewers ask about it$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "You could build an entire page out of generic boxes. It would look identical to a well-built one. And it would still be a problem."},
    {"type": "paragraph", "text": "A <div> means nothing. A <nav> means this is the navigation, a <header> means this is the top of the page, a <button> means this does something when pressed. Choosing tags that carry meaning is called semantic HTML."},
    {"type": "paragraph", "text": "It matters for three reasons that come up in every real job: screen readers use those tags to describe the page to people who cannot see it, search engines use them to understand your content, and your teammates read them to understand your code."},
    {"type": "list", "items": [
      "<header> — introductory content at the top",
      "<nav> — a set of navigation links",
      "<main> — the main content, used once per page",
      "<footer> — closing content at the bottom",
      "<div> — a generic box, for when nothing else fits"
    ]}
  ], "keyTakeaway": "Reach for <div> last, not first."}
  $j$, 1),

  (v_b3, 'order_logic',
   $q$Order these sections as they appear in a typical page, from top to bottom.$q$,
   $q$Think about how a page reads on screen.$q$,
   $j${"blocks": {
      "header": "<header> — site title",
      "nav": "<nav> — the menu",
      "main": "<main> — the page content",
      "footer": "<footer> — contact and credits"
    }, "correctOrder": ["header", "nav", "main", "footer"]}$j$, 2),

  (v_b3, 'fill_blank',
   $q$Replace the generic boxes with tags that carry meaning.$q$,
   $q$One section introduces the page, the other holds its content.$q$,
   $j${"codeSnippet": "{{0}}\n  <h1>My portfolio</h1>\n{{1}}\n\n{{2}}\n  <p>Projects I have built.</p>\n{{3}}",
      "correctAnswers": {"0": "<header>", "1": "</header>", "2": "<main>", "3": "</main>"},
      "availableOptions": ["<header>", "</header>", "<main>", "</main>", "<div>", "</div>"]}$j$, 3);

  -- --- B4 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b4, 'theory', $q$How CSS finds your HTML$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "CSS does not live inside your content. It sits apart and points at it. A CSS rule has two parts: a selector that says what to style, and a block that says how."},
    {"type": "code", "language": "css", "text": "p {\n  color: #333333;\n  font-size: 16px;\n}"},
    {"type": "paragraph", "text": "This says: every paragraph on the page gets dark grey text at 16 pixels. The selector is p. Each line inside is a declaration — a property and a value."}
  ], "keyTakeaway": "The selector picks the element; the declarations describe it."}
  $j$, 1),

  (v_b4, 'theory', $q$Classes: styling some, not all$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Styling every paragraph on a page is rarely what you want. A class lets you tag specific elements and style only those."},
    {"type": "code", "language": "html", "text": "<p class=\"intro\">Welcome.</p>\n<p>Everything else.</p>"},
    {"type": "code", "language": "css", "text": ".intro {\n  font-weight: bold;\n}"},
    {"type": "paragraph", "text": "In CSS, a class selector starts with a dot. Only the first paragraph turns bold. Classes are how real projects stay manageable: you name a piece of your interface once and reuse that style everywhere it appears."}
  ], "keyTakeaway": "A dot in CSS means: the elements carrying this class."}
  $j$, 2),

  (v_b4, 'fill_blank',
   $q$Style only the elements marked as a card.$q$,
   $q$Class selectors need one character in front of the name.$q$,
   $j${"codeSnippet": "<div class=\"card\">Content</div>\n\n{{0}}card {\n  {{1}}: white;\n}",
      "correctAnswers": {"0": ".", "1": "background"},
      "availableOptions": [".", "#", "background", "color", "fill"]}$j$, 3);

  -- --- B5 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b5, 'theory', $q$The box model$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Every single element on a page is a rectangle, even when it does not look like one. That rectangle has four layers, counted from the inside out."},
    {"type": "list", "items": [
      "Content — the text or image itself",
      "Padding — space inside the box, between the content and the edge",
      "Border — the edge itself",
      "Margin — space outside the box, pushing other elements away"
    ]},
    {"type": "paragraph", "text": "Almost every why is this not lining up moment in your first months comes down to confusing padding with margin. Padding grows the box. Margin pushes other boxes away from it."}
  ], "keyTakeaway": "Padding is space inside. Margin is space outside."}
  $j$, 1),

  (v_b5, 'order_logic',
   $q$Order the box model layers from the inside out.$q$,
   $q$Start at the text itself and work outwards.$q$,
   $j${"blocks": {
      "content": "Content",
      "padding": "Padding",
      "border": "Border",
      "margin": "Margin"
    }, "correctOrder": ["content", "padding", "border", "margin"]}$j$, 2),

  (v_b5, 'fill_blank',
   $q$Give the card breathing room inside, and separation from the next one.$q$,
   $q$One property works inside the box, the other outside it.$q$,
   $j${"codeSnippet": ".card {\n  {{0}}: 24px;\n  {{1}}-bottom: 16px;\n}",
      "correctAnswers": {"0": "padding", "1": "margin"},
      "availableOptions": ["padding", "margin", "border", "spacing"]}$j$, 3);

  -- =========================================================================
  -- INTERMEDIATE
  -- =========================================================================
  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', v_inter, 'Layouts That Adapt',
    $q$Most of your users are on a phone. Build for that first.$q$, 1)
  returning id into v_i1;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', v_inter, 'Flexbox in Practice',
    $q$The layout tool you will reach for every single day.$q$, 2)
  returning id into v_i2;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', v_inter, 'JavaScript: Storing Values',
    $q$Variables and the habits that keep bugs out from day one.$q$, 3)
  returning id into v_i3;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', v_inter, 'JavaScript: Making Decisions',
    $q$Conditions and loops: making your code choose and repeat.$q$, 4)
  returning id into v_i4;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', v_inter, 'Functions: Reusing Your Work',
    $q$Wrap logic in a name so you write it once and use it everywhere.$q$, 5)
  returning id into v_i5;

  -- --- I1 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i1, 'theory', $q$Responsive design is not optional$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "More than half of all web traffic comes from phones. A layout that only works on a laptop is, for most of your users, simply broken."},
    {"type": "paragraph", "text": "The tool for this is the media query: a block of CSS that only applies when the screen meets a condition."},
    {"type": "code", "language": "css", "text": ".sidebar {\n  display: none;\n}\n\n@media (min-width: 768px) {\n  .sidebar {\n    display: block;\n  }\n}"},
    {"type": "paragraph", "text": "Read it in order: the sidebar is hidden by default, and appears only from 768 pixels wide upwards. Starting from the small screen and adding for larger ones is called mobile-first, and on most teams it is the default expectation rather than a preference."}
  ], "keyTakeaway": "Design for the smallest screen first, then add."}
  $j$, 1),

  (v_i1, 'multiple_choice',
   $q$Why do teams write mobile-first CSS instead of desktop-first?$q$,
   $q$Think about which set of styles ends up being the base.$q$,
   $j${"options": {
      "a": "The base styles cover the most common case, and larger screens only add to them",
      "b": "Phones cannot read media queries",
      "c": "It makes the CSS file smaller on desktop",
      "d": "Desktop browsers do not support modern CSS"
    }, "correctOptionId": "a"}$j$, 2),

  (v_i1, 'fill_blank',
   $q$Apply the two-column layout only from tablet width upwards.$q$,
   $q$Conditional blocks in CSS start with an at-rule.$q$,
   $j${"codeSnippet": "{{0}} (min-width: 768px) {\n  .layout {\n    display: grid;\n    grid-template-columns: 1fr 1fr;\n  }\n}",
      "correctAnswers": {"0": "@media"},
      "availableOptions": ["@media", "@screen", "@if", "@responsive"]}$j$, 3);

  -- --- I2 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i2, 'theory', $q$Flexbox in one idea$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Flexbox arranges a set of items along one line — a row or a column — and decides how the leftover space is shared between them."},
    {"type": "paragraph", "text": "You apply it to the container, not to the items. The container becomes a flex container, and its direct children become flex items."},
    {"type": "code", "language": "css", "text": ".toolbar {\n  display: flex;\n  justify-content: space-between;\n  align-items: center;\n}"},
    {"type": "paragraph", "text": "justify-content controls spacing along the line. align-items controls the cross direction. Those two properties alone solve a large share of everyday layout work, including the classic logo on the left, buttons on the right, both vertically centered."}
  ], "keyTakeaway": "Flex the container; the children follow."}
  $j$, 1),

  (v_i2, 'order_logic',
   $q$Order the steps to build a navigation bar with Flexbox.$q$,
   $q$Nothing can be flexed before there is a container to flex.$q$,
   $j${"blocks": {
      "wrap": "Wrap the links in a <nav> element",
      "display": "Set display: flex on the <nav>",
      "justify": "Use justify-content to spread the links out",
      "align": "Use align-items to line them up vertically"
    }, "correctOrder": ["wrap", "display", "justify", "align"]}$j$, 2),

  (v_i2, 'fill_blank',
   $q$Push the logo and the menu to opposite ends of the bar.$q$,
   $q$One property turns on the layout, the other distributes the space.$q$,
   $j${"codeSnippet": ".navbar {\n  display: {{0}};\n  {{1}}: space-between;\n}",
      "correctAnswers": {"0": "flex", "1": "justify-content"},
      "availableOptions": ["flex", "block", "justify-content", "align-items"]}$j$, 3),

  (v_i2, 'multiple_choice',
   $q$You set display: flex on a container and nothing changes visually. What is the most likely reason?$q$,
   $q$Flexbox distributes space between items.$q$,
   $j${"options": {
      "a": "The container has only one child, so there is nothing to distribute",
      "b": "Flexbox needs JavaScript to work",
      "c": "display: flex only works on <div> elements",
      "d": "You must also set position: relative"
    }, "correctOptionId": "a"}$j$, 4);

  -- --- I3 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i3, 'theory', $q$Variables, and why const comes first$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "A variable is a name for a value. In modern JavaScript you declare one with const or with let."},
    {"type": "code", "language": "javascript", "text": "const name = 'Ana';\nlet score = 0;\n\nscore = 10;    // fine\nname = 'Luis'; // error"},
    {"type": "paragraph", "text": "const means the name will never point at a different value. let means it will. The convention on most teams is to reach for const by default and switch to let only when you genuinely need to reassign — it makes code easier to read, because const tells whoever reads it that this will not move."},
    {"type": "paragraph", "text": "You may still meet var in older code. It behaves differently in ways that cause real bugs; treat it as legacy and do not write new code with it."}
  ], "keyTakeaway": "const by default, let when it changes, var never."}
  $j$, 1),

  (v_i3, 'fill_blank',
   $q$Declare a value that never changes, and one that does.$q$,
   $q$The tax rate is fixed. The total is recalculated.$q$,
   $j${"codeSnippet": "{{0}} TAX_RATE = 0.13;\n{{1}} total = 0;\n\ntotal = 100 * (1 + TAX_RATE);",
      "correctAnswers": {"0": "const", "1": "let"},
      "availableOptions": ["const", "let", "var", "final"]}$j$, 2),

  (v_i3, 'multiple_choice',
   $q$Which of these lines will cause an error?$q$,
   $q$Careful with the third one: const locks the name, not the contents.$q$,
   $j${"options": {
      "a": "const total = 5; total = 6;",
      "b": "let total = 5; total = 6;",
      "c": "const items = []; items.push('a');",
      "d": "let name; name = 'Ana';"
    }, "correctOptionId": "a"}$j$, 3);

  -- --- I4 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i4, 'theory', $q$if, else, and comparing safely$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "An if statement runs a block of code only when a condition is true, and an else block covers everything else."},
    {"type": "code", "language": "javascript", "text": "if (score >= 60) {\n  message = 'Passed';\n} else {\n  message = 'Keep going';\n}"},
    {"type": "paragraph", "text": "To compare values, use === and !==, with three characters. The two-character == also exists, but it quietly converts types before comparing, so the string 5 and the number 5 come out equal. That is a classic source of bugs and a very common interview question."}
  ], "keyTakeaway": "Always compare with ===."}
  $j$, 1),

  (v_i4, 'order_logic',
   $q$Order the lines so the loop prints each name once.$q$,
   $q$You cannot loop over a list before it exists.$q$,
   $j${"blocks": {
      "list": "const names = ['Ana', 'Luis', 'Sofia'];",
      "open": "for (const name of names) {",
      "body": "  console.log(name);",
      "close": "}"
    }, "correctOrder": ["list", "open", "body", "close"]}$j$, 2),

  (v_i4, 'fill_blank',
   $q$Complete the comparison so it does not convert types.$q$,
   $q$Three characters, not two.$q$,
   $j${"codeSnippet": "if (userInput {{0}} 5) {\n  console.log('Exactly five');\n}",
      "correctAnswers": {"0": "==="},
      "availableOptions": ["===", "==", "=", "!=="]}$j$, 3);

  -- --- I5 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i5, 'theory', $q$A function is a named job$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "A function takes input, does something with it, and usually hands a value back. Writing one is how you stop repeating yourself."},
    {"type": "code", "language": "javascript", "text": "function formatPrice(amount) {\n  return 'Bs ' + amount.toFixed(2);\n}\n\nformatPrice(12.5); // 'Bs 12.50'"},
    {"type": "paragraph", "text": "amount is a parameter — the input the function expects. return is what it hands back. A function without a return still runs; it just gives nothing back."},
    {"type": "paragraph", "text": "You will also meet the arrow form. It is the same idea written shorter, and it is what most modern codebases use, so you need to be able to read both."},
    {"type": "code", "language": "javascript", "text": "const formatPrice = (amount) => 'Bs ' + amount.toFixed(2);"}
  ], "keyTakeaway": "Name the job once, call it everywhere."}
  $j$, 1),

  (v_i5, 'fill_blank',
   $q$Complete the function so it hands the total back to whoever called it.$q$,
   $q$Printing a value and returning it are not the same thing.$q$,
   $j${"codeSnippet": "function addTax(price) {\n  {{0}} price * 1.13;\n}",
      "correctAnswers": {"0": "return"},
      "availableOptions": ["return", "print", "console.log", "yield"]}$j$, 2),

  (v_i5, 'order_logic',
   $q$Order the parts of a function declaration.$q$,
   $q$Read it the way you would say it out loud.$q$,
   $j${"blocks": {
      "kw": "function",
      "name": "greet",
      "params": "(userName)",
      "body": "{ return 'Hi ' + userName; }"
    }, "correctOrder": ["kw", "name", "params", "body"]}$j$, 3);

  -- =========================================================================
  -- ADVANCED
  -- =========================================================================
  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', v_adv, 'Changing the Page with the DOM',
    $q$Reach into the live page from JavaScript and change what is on screen.$q$, 1)
  returning id into v_a1;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', v_adv, 'Reacting to the User',
    $q$Events: the difference between a page and an application.$q$, 2)
  returning id into v_a2;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', v_adv, 'Working with Lists of Data',
    $q$Real interfaces render lists. Learn the methods you will use constantly.$q$, 3)
  returning id into v_a3;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', v_adv, 'Getting Data from an API',
    $q$Almost every frontend job is, at some point, showing data that came from somewhere else.$q$, 4)
  returning id into v_a4;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('frontend', v_adv, 'Accessible by Default',
    $q$Accessibility is a hiring requirement on most international teams, not a nice-to-have.$q$, 5)
  returning id into v_a5;

  -- --- A1 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a1, 'theory', $q$The DOM: your page as objects$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "When the browser reads your HTML, it builds a live model of it in memory called the DOM. JavaScript can read and change that model, and the page updates instantly."},
    {"type": "code", "language": "javascript", "text": "const title = document.querySelector('#page-title');\ntitle.textContent = 'Updated';"},
    {"type": "paragraph", "text": "querySelector finds the first element matching a CSS selector — the same selectors you already know from styling. textContent replaces its text."},
    {"type": "paragraph", "text": "Changing the DOM does not change your HTML file. It changes what is currently on screen, which is why a refresh brings the original back."}
  ], "keyTakeaway": "The DOM is the live page. Your HTML file is only its starting point."}
  $j$, 1),

  (v_a1, 'fill_blank',
   $q$Find the element with id total and put the amount inside it.$q$,
   $q$The selector syntax is the same one you use in CSS.$q$,
   $j${"codeSnippet": "const el = document.{{0}}('#total');\nel.{{1}} = 'Bs 120.00';",
      "correctAnswers": {"0": "querySelector", "1": "textContent"},
      "availableOptions": ["querySelector", "getElement", "textContent", "innerValue"]}$j$, 2),

  (v_a1, 'order_logic',
   $q$Order the steps to safely update a price on screen.$q$,
   $q$querySelector returns nothing when it finds nothing.$q$,
   $j${"blocks": {
      "find": "Find the element in the DOM",
      "check": "Check that it was actually found",
      "set": "Set its text to the new price"
    }, "correctOrder": ["find", "check", "set"]}$j$, 3);

  -- --- A2 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a2, 'fill_blank',
   $q$Run the function when the button is clicked.$q$,
   $q$The first argument is the name of the event, the second is what to run.$q$,
   $j${"codeSnippet": "const btn = document.querySelector('#save');\nbtn.{{0}}('{{1}}', handleSave);",
      "correctAnswers": {"0": "addEventListener", "1": "click"},
      "availableOptions": ["addEventListener", "onEvent", "click", "press"]}$j$, 1),

  (v_a2, 'order_logic',
   $q$Order the steps of a handler that saves a form.$q$,
   $q$Something has to stop the browser doing its own thing first.$q$,
   $j${"blocks": {
      "listen": "Listen for the submit event on the form",
      "prevent": "Stop the browser from reloading the page",
      "read": "Read the values the user typed",
      "send": "Send them to the server"
    }, "correctOrder": ["listen", "prevent", "read", "send"]}$j$, 2),

  (v_a2, 'multiple_choice',
   $q$Why does a form handler usually call event.preventDefault() first?$q$,
   $q$Think about what a form does on its own, without any JavaScript.$q$,
   $j${"options": {
      "a": "Because by default the browser reloads the page and your JavaScript never finishes",
      "b": "Because it makes the form submit faster",
      "c": "Because form values cannot be read without it",
      "d": "Because every browser requires it before reading an event"
    }, "correctOptionId": "a"}$j$, 3);

  -- --- A3 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a3, 'fill_blank',
   $q$Turn a list of products into a list of just their names.$q$,
   $q$You need the method that builds a new array from an old one.$q$,
   $j${"codeSnippet": "const names = products.{{0}}((product) => product.name);",
      "correctAnswers": {"0": "map"},
      "availableOptions": ["map", "filter", "forEach", "find"]}$j$, 1),

  (v_a3, 'order_logic',
   $q$Order the steps to show only the products in stock, cheapest first.$q$,
   $q$Narrow the list before you sort it, and reshape it last.$q$,
   $j${"blocks": {
      "filter": ".filter((p) => p.inStock)",
      "sort": ".sort((a, b) => a.price - b.price)",
      "map": ".map((p) => p.name)"
    }, "correctOrder": ["filter", "sort", "map"]}$j$, 2),

  (v_a3, 'multiple_choice',
   $q$What is the difference between map and forEach?$q$,
   $q$One of them gives you something back.$q$,
   $j${"options": {
      "a": "map returns a new array; forEach returns nothing",
      "b": "map is faster on large lists",
      "c": "forEach can only be used on numbers",
      "d": "There is no real difference between them"
    }, "correctOptionId": "a"}$j$, 3);

  -- --- A4 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a4, 'theory', $q$Requests take time, and your code has to expect that$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "When your page asks a server for data, the answer does not arrive instantly. JavaScript does not freeze while it waits — it carries on, and deals with the answer when it shows up. That is what asynchronous means."},
    {"type": "code", "language": "javascript", "text": "async function loadProducts() {\n  const response = await fetch('/api/products');\n  const products = await response.json();\n  return products;\n}"},
    {"type": "paragraph", "text": "await pauses inside this function until the answer arrives, and it only works inside a function marked async. There are two awaits here because the response arrives first, and turning it into usable data is a second step that also takes time."},
    {"type": "paragraph", "text": "Real code also handles the case where the request fails. A frontend that assumes the network always works is a frontend that breaks in production — and handling that is one of the first things a reviewer looks for."}
  ], "keyTakeaway": "Ask, wait, then use — and always plan for the failure."}
  $j$, 1),

  (v_a4, 'order_logic',
   $q$Order the steps of loading and displaying remote data.$q$,
   $q$The user should never stare at an empty screen wondering what happened.$q$,
   $j${"blocks": {
      "loading": "Show a loading state",
      "request": "Request the data",
      "check": "Check whether the request succeeded",
      "render": "Render the data, or an error message"
    }, "correctOrder": ["loading", "request", "check", "render"]}$j$, 2),

  (v_a4, 'fill_blank',
   $q$Wait for the response and turn it into usable data.$q$,
   $q$One keyword marks the function, the other marks the wait.$q$,
   $j${"codeSnippet": "{{0}} function load() {\n  const res = {{1}} fetch(url);\n  const data = await res.json();\n}",
      "correctAnswers": {"0": "async", "1": "await"},
      "availableOptions": ["async", "await", "function", "return"]}$j$, 3);

  -- --- A5 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a5, 'multiple_choice',
   $q$What does the alt attribute on an image actually do?$q$,
   $q$It has two jobs, and both matter.$q$,
   $j${"options": {
      "a": "Describes the image for people using a screen reader, and shows if the image fails to load",
      "b": "Sets the tooltip that appears when you hover over the image",
      "c": "Makes the image load faster",
      "d": "Is only needed on decorative images"
    }, "correctOptionId": "a"}$j$, 1),

  (v_a5, 'fill_blank',
   $q$Make this control reachable by keyboard and understandable to a screen reader.$q$,
   $q$A generic box with a click handler cannot be focused with the Tab key. The right element gives you focus, Enter and screen reader support for free.$q$,
   $j${"codeSnippet": "<{{0}} type=\"submit\">Save</{{1}}>",
      "correctAnswers": {"0": "button", "1": "button"},
      "availableOptions": ["button", "div", "span", "a"]}$j$, 2),

  (v_a5, 'multiple_choice',
   $q$A designer asks you to build a clickable card. What do you reach for?$q$,
   $q$Styling can make anything look like a card. Only some elements behave like a control.$q$,
   $j${"options": {
      "a": "A <div> with a click handler on it",
      "b": "A semantic element — a <button> or an <a> — styled to look like a card",
      "c": "A <span> with cursor: pointer",
      "d": "An <img> with a click handler"
    }, "correctOptionId": "b"}$j$, 3);

end
$$;
