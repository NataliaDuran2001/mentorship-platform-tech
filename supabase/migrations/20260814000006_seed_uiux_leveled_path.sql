-- ===========================================================================
-- Semilla: path de UI/UX Design por niveles
-- ===========================================================================
--
-- Track nuevo (20260814000003). Mismo modelo por niveles que los demás paths.
-- 45 retos. Los tipos de reto existentes funcionan sin código nuevo: la teoría
-- para conceptos, multiple_choice para criterio de diseño, fill_blank para
-- vocabulario y order_logic para procesos (design thinking, research, handoff).

do $$
declare
  v_basic uuid; v_inter uuid; v_adv uuid;
  v_b1 uuid; v_b2 uuid; v_b3 uuid; v_b4 uuid; v_b5 uuid;
  v_i1 uuid; v_i2 uuid; v_i3 uuid; v_i4 uuid; v_i5 uuid;
  v_a1 uuid; v_a2 uuid; v_a3 uuid; v_a4 uuid; v_a5 uuid;
begin

  delete from public.topics where track_id = 'uiux';

  -- =========================================================================
  -- NIVELES
  -- =========================================================================
  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('uiux', null, 'Basic',
    $q$How design decisions are made: understanding people first, then shaping what they see. No design background needed.$q$, 1)
  returning id into v_basic;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('uiux', null, 'Intermediate',
    $q$From idea to screen: wireframes, design systems and interfaces that respond to people.$q$, 2)
  returning id into v_inter;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('uiux', null, 'Advanced',
    $q$What design teams expect from a junior: research, usability testing and working hand in hand with developers.$q$, 3)
  returning id into v_adv;

  -- =========================================================================
  -- BASIC
  -- =========================================================================
  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('uiux', v_basic, 'What UX Actually Is',
    $q$Design is decisions, not decoration — and the difference between UX and UI.$q$, 1)
  returning id into v_b1;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('uiux', v_basic, 'Users First',
    $q$Understand the problem before touching a single pixel.$q$, 2)
  returning id into v_b2;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('uiux', v_basic, 'Visual Hierarchy',
    $q$Guide the eye: what people see first is a decision you make.$q$, 3)
  returning id into v_b3;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('uiux', v_basic, 'Color and Typography',
    $q$Two tools that carry most of the visual work — used with restraint.$q$, 4)
  returning id into v_b4;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('uiux', v_basic, 'Layout and Spacing',
    $q$Whitespace is not wasted space: grouping, alignment and room to breathe.$q$, 5)
  returning id into v_b5;

  -- --- B1 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b1, 'theory', $q$Design is decisions, not decoration$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "UI is what a person sees: the buttons, the colors, the type. UX is what a person goes through: finding what they came for, finishing what they started, and how that felt."},
    {"type": "paragraph", "text": "They are related but not the same. A gorgeous screen with a confusing flow is good UI and bad UX. A plain screen where everything works on the first try is the opposite — and users keep the second one."},
    {"type": "paragraph", "text": "That is why design is not decoration. Every screen is a chain of decisions about what matters most, what can wait and what should not be there at all."}
  ], "keyTakeaway": "UI is what you see; UX is what you go through."}
  $j$, 1),

  (v_b1, 'theory', $q$You are not the user$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "You know where every button is because you put it there. Your users did not. What is obvious to the person who designed a screen is invisible to the person meeting it for the first time — this gap is the single most common source of bad design."},
    {"type": "paragraph", "text": "The discipline of UX exists to close that gap with evidence: watching real people use real things, instead of assuming they think like us."}
  ], "keyTakeaway": "What is obvious to you is invisible to someone seeing it for the first time."}
  $j$, 2),

  (v_b1, 'multiple_choice',
   $q$A checkout looks beautiful, but it takes nine steps and half the users abandon it. What kind of problem is that?$q$,
   $q$Where does the failure live: on the surface, or in the journey?$q$,
   $j${"options": {
      "a": "A UX problem — the journey is broken, however good it looks",
      "b": "A UI problem — the colors need work",
      "c": "Not a design problem, users are just impatient",
      "d": "A backend problem"
    }, "correctOptionId": "a"}$j$, 3);

  -- --- B2 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b2, 'theory', $q$Problems before solutions$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "The fastest way to design the wrong thing is to start from a solution. \"We need a map with 3D buildings\" is a solution. \"I need to know when my bus arrives so I do not freeze at the stop\" is a need — and a simple arrival time solves it better than any 3D map."},
    {"type": "paragraph", "text": "Design processes — like design thinking — all share the same skeleton: understand people, define the real problem, explore several ideas, make one tangible, test it against reality. The order matters more than the names."}
  ], "keyTakeaway": "Fall in love with the problem, not with your solution."}
  $j$, 1),

  (v_b2, 'order_logic',
   $q$Order the stages of a design process.$q$,
   $q$Understanding always comes before inventing.$q$,
   $j${"blocks": {
      "understand": "Understand the people and their context",
      "define": "Define the real problem to solve",
      "ideate": "Sketch several possible ideas",
      "prototype": "Make the strongest one tangible",
      "test": "Test it with real users"
    }, "correctOrder": ["understand", "define", "ideate", "prototype", "test"]}$j$, 2),

  (v_b2, 'multiple_choice',
   $q$Which of these is a user need, rather than a feature?$q$,
   $q$Needs describe a person's situation; features describe a screen.$q$,
   $j${"options": {
      "a": "I need to know if I can afford this before payday",
      "b": "Add a pie chart to the dashboard",
      "c": "Add dark mode",
      "d": "Put a chatbot on the home screen"
    }, "correctOptionId": "a"}$j$, 3);

  -- --- B3 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b3, 'theory', $q$The eye follows size, contrast and position$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "People do not read screens; they scan them. In that scan, three forces decide what gets seen: bigger beats smaller, higher contrast beats lower, and top-left beats bottom-right (in cultures that read that way)."},
    {"type": "paragraph", "text": "Visual hierarchy is using those forces on purpose: one primary action per screen, clearly dominant; secondary things visibly quieter. When everything is big, bold and colorful, the screen has no hierarchy — and the user has no guide."}
  ], "keyTakeaway": "If everything shouts, nothing is heard."}
  $j$, 1),

  (v_b3, 'multiple_choice',
   $q$A screen has one action that matters: "Confirm payment". How should it look?$q$,
   $q$Hierarchy is relative: it needs to win over its neighbors.$q$,
   $j${"options": {
      "a": "The most visually dominant element: strong contrast, generous size, alone",
      "b": "The same as every other button, for consistency",
      "c": "Small and subtle, to look elegant",
      "d": "Hidden in a menu, to keep the screen clean"
    }, "correctOptionId": "a"}$j$, 2),

  (v_b3, 'fill_blank',
   $q$Complete the two facts every screen is designed around.$q$,
   $q$How people consume screens, and where the important thing goes.$q$,
   $j${"codeSnippet": "Users {{0}} screens instead of reading them,\nso the key message goes {{1}}.",
      "correctAnswers": {"0": "scan", "1": "first"},
      "availableOptions": ["scan", "read", "first", "last"]}$j$, 3);

  -- --- B4 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b4, 'theory', $q$Color and type have jobs$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Color is not decoration; it is information. One color for your brand and your primary actions, one for danger, one for success — and enough contrast that everyone can read the text, in the sun, on a cheap screen, with tired eyes."},
    {"type": "list", "items": [
      "Contrast: body text needs at least 4.5:1 against its background — it is a WCAG accessibility standard, not a taste",
      "Typography: one or two type families, used consistently, sized around 16px for body text",
      "Restraint: every extra color and font is a decision the user has to process"
    ]}
  ], "keyTakeaway": "Color is information; contrast is a requirement, not a taste."}
  $j$, 1),

  (v_b4, 'multiple_choice',
   $q$Light grey text on a white background looks elegant in the mockup. What is the problem?$q$,
   $q$Think about who cannot read it, and where.$q$,
   $j${"options": {
      "a": "It likely fails the 4.5:1 contrast ratio, so many people simply cannot read it",
      "b": "Grey is an outdated color",
      "c": "Nothing, elegance comes first",
      "d": "White backgrounds consume more battery"
    }, "correctOptionId": "a"}$j$, 2),

  (v_b4, 'fill_blank',
   $q$Complete the accessibility baseline for body text.$q$,
   $q$A ratio and a size.$q$,
   $j${"codeSnippet": "Contrast ratio: at least {{0}}:1\nBody text size: around {{1}}px",
      "correctAnswers": {"0": "4.5", "1": "16"},
      "availableOptions": ["4.5", "1.5", "16", "8"]}$j$, 3);

  -- --- B5 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b5, 'theory', $q$Space is information$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Empty space is doing work. Things placed close together read as related; things far apart read as separate — that is the proximity principle, and it organizes a screen before a single line or box is drawn."},
    {"type": "list", "items": [
      "Proximity — group what belongs together with closeness, not with borders",
      "Alignment — every element lines up with something; nothing floats",
      "Breathing room — cramped screens feel harder than they are"
    ]},
    {"type": "paragraph", "text": "A grid — consistent columns and spacing steps — is what keeps those decisions coherent across every screen of a product."}
  ], "keyTakeaway": "Space is information: closeness means relationship."}
  $j$, 1),

  (v_b5, 'order_logic',
   $q$Order the steps of laying out a screen.$q$,
   $q$Structure first, content second, refinement last.$q$,
   $j${"blocks": {
      "grid": "Define the grid and spacing steps",
      "primary": "Place the primary content and action",
      "group": "Group related elements by proximity",
      "breathe": "Add breathing room and check alignment"
    }, "correctOrder": ["grid", "primary", "group", "breathe"]}$j$, 2),

  (v_b5, 'multiple_choice',
   $q$The label "Email" and its input field should be…$q$,
   $q$Proximity says related things sit together.$q$,
   $j${"options": {
      "a": "Close to each other, clearly closer than to the next field",
      "b": "Separated by a decorative divider",
      "c": "At opposite ends of the row, for symmetry",
      "d": "On different screens, to reduce clutter"
    }, "correctOptionId": "a"}$j$, 3);

  -- =========================================================================
  -- INTERMEDIATE
  -- =========================================================================
  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('uiux', v_inter, 'Wireframes: Think Cheap, Fail Fast',
    $q$The cheaper the sketch, the cheaper the mistake.$q$, 1)
  returning id into v_i1;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('uiux', v_inter, 'Design Systems',
    $q$Design once, reuse everywhere: tokens, components and consistency.$q$, 2)
  returning id into v_i2;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('uiux', v_inter, 'States and Feedback',
    $q$A screen is many screens: empty, loading, error and success.$q$, 3)
  returning id into v_i3;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('uiux', v_inter, 'Forms People Finish',
    $q$Where products win or lose users, one field at a time.$q$, 4)
  returning id into v_i4;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('uiux', v_inter, 'Accessibility Is Design',
    $q$Design for one, extend to many — the constraint that improves everything.$q$, 5)
  returning id into v_i5;

  -- --- I1 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i1, 'theory', $q$The fidelity ladder$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Ideas get more expensive to change as they get more finished. A paper sketch costs a minute; a polished mockup costs a day; a built feature costs a sprint. So you climb the ladder deliberately:"},
    {"type": "list", "items": [
      "Sketch — boxes on paper, to think with your hands",
      "Wireframe — grey structure on screen: what goes where, no styling",
      "Mockup — the real look: color, type, imagery",
      "Prototype — clickable, to feel the flow before building it"
    ]},
    {"type": "paragraph", "text": "Every step exists to catch a different mistake while it is still cheap. Skipping to the pretty version early does not save time; it hides structural problems under paint."}
  ], "keyTakeaway": "The cheaper the sketch, the cheaper the mistake."}
  $j$, 1),

  (v_i1, 'order_logic',
   $q$Order the fidelity ladder from cheapest to most finished.$q$,
   $q$Paper first, pixels later, clicks last.$q$,
   $j${"blocks": {
      "sketch": "Paper sketch",
      "wireframe": "Wireframe",
      "mockup": "Mockup",
      "prototype": "Clickable prototype"
    }, "correctOrder": ["sketch", "wireframe", "mockup", "prototype"]}$j$, 2),

  (v_i1, 'multiple_choice',
   $q$In a wireframe review, a stakeholder wants to discuss button colors. What do you say?$q$,
   $q$Wireframes are grey on purpose.$q$,
   $j${"options": {
      "a": "Colors come later on purpose — right now the question is whether the structure works",
      "b": "Good catch, let us pick the palette now",
      "c": "Wireframes cannot have colors for technical reasons",
      "d": "Colors do not matter in design"
    }, "correctOptionId": "a"}$j$, 3);

  -- --- I2 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i2, 'theory', $q$Design once, reuse everywhere$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "By the tenth screen, deciding every color and spacing from scratch stops being creativity and becomes inconsistency. A design system captures the decisions once so every screen inherits them:"},
    {"type": "list", "items": [
      "Tokens — the raw decisions: this exact blue, these spacing steps, this type scale",
      "Components — reusable pieces built from tokens: buttons, cards, fields",
      "Patterns — how components combine to solve repeated situations"
    ]},
    {"type": "paragraph", "text": "Consistency is not an aesthetic preference. Users learn your interface once and expect that learning to keep working on every screen — every inconsistency is a small betrayal of that trust."}
  ], "keyTakeaway": "A design system turns decisions into defaults."}
  $j$, 1),

  (v_i2, 'multiple_choice',
   $q$What does a team gain from a design system?$q$,
   $q$Think about the tenth screen, not the first.$q$,
   $j${"options": {
      "a": "Consistent screens, faster work and decisions made once instead of every time",
      "b": "More creative freedom on every individual screen",
      "c": "It replaces the need for designers",
      "d": "Mainly a nicer-looking Figma file"
    }, "correctOptionId": "a"}$j$, 2),

  (v_i2, 'fill_blank',
   $q$Name the two building blocks of a design system.$q$,
   $q$One stores a decision; the other is a reusable piece.$q$,
   $j${"codeSnippet": "A {{0}} stores a decision like a color or a spacing step.\nA {{1}} is a reusable piece like a button or a card.",
      "correctAnswers": {"0": "token", "1": "component"},
      "availableOptions": ["token", "component", "pixel", "layer"]}$j$, 3);

  -- --- I3 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i3, 'theory', $q$A screen is many screens$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "The mockup with perfect data is the easiest state of a screen — and the one users see least. Before a screen is done, it needs an answer for:"},
    {"type": "list", "items": [
      "Empty — the first visit, before there is any data. What invites them in?",
      "Loading — the wait. What tells them the app is alive?",
      "Error — the failure. What went wrong and what can they do?",
      "Success — the confirmation. Did it actually work?"
    ]},
    {"type": "paragraph", "text": "Interfaces feel trustworthy when every action gets an immediate, honest response. Silence after a tap is how apps feel broken even when they are not."}
  ], "keyTakeaway": "Design the unhappy paths; users live there."}
  $j$, 1),

  (v_i3, 'multiple_choice',
   $q$A user opens their order list for the first time and sees a blank white area. What is missing?$q$,
   $q$First visit, no data yet.$q$,
   $j${"options": {
      "a": "An empty state that explains what will appear here and how to start",
      "b": "A bigger loading spinner",
      "c": "More orders",
      "d": "A decorative illustration with no text"
    }, "correctOptionId": "a"}$j$, 2),

  (v_i3, 'order_logic',
   $q$Order the feedback a user gets when saving a form.$q$,
   $q$Every action deserves an immediate, honest response.$q$,
   $j${"blocks": {
      "tap": "The user taps Save",
      "loading": "The button shows it is working",
      "result": "Success is confirmed — or the error is explained",
      "next": "The screen offers the natural next step"
    }, "correctOrder": ["tap", "loading", "result", "next"]}$j$, 3);

  -- --- I4 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i4, 'multiple_choice',
   $q$Which form layout helps people finish?$q$,
   $q$Eyes travel down faster than they zigzag.$q$,
   $j${"options": {
      "a": "One column, labels above their fields, only the essential questions",
      "b": "Two columns to make the form look shorter",
      "c": "Placeholder text instead of labels, for a cleaner look",
      "d": "All twenty questions on one screen to avoid steps"
    }, "correctOptionId": "a"}$j$, 1),

  (v_i4, 'fill_blank',
   $q$Complete the two jobs of a good error message.$q$,
   $q$Diagnosis and remedy, in the user's language.$q$,
   $j${"codeSnippet": "A good error message says {{0}} went wrong\nand {{1}} to fix it.",
      "correctAnswers": {"0": "what", "1": "how"},
      "availableOptions": ["what", "how", "who", "when"]}$j$, 2),

  (v_i4, 'order_logic',
   $q$Order the design of a form that people actually finish.$q$,
   $q$Every question you remove is a user you keep.$q$,
   $j${"blocks": {
      "trim": "Ask only what you truly need",
      "group": "Group the questions in logical steps",
      "validate": "Validate as they type, not only at the end",
      "confirm": "Confirm success clearly at the end"
    }, "correctOrder": ["trim", "group", "validate", "confirm"]}$j$, 3);

  -- --- I5 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i5, 'theory', $q$Design for one, extend to many$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Accessibility sounds like a special case until you look at who it covers: permanent conditions, yes — and also a broken arm, a bright sidewalk, a screen used while holding a baby. Everyone is situationally impaired sometimes."},
    {"type": "list", "items": [
      "Contrast 4.5:1 for text — readable eyes or not, sun or not",
      "Touch targets around 44px — tappable for every thumb",
      "Alt text on images — the screen reader's eyes",
      "Visible focus — keyboard users need to see where they are"
    ]},
    {"type": "paragraph", "text": "On international teams this is not a nice-to-have: it is reviewed, audited and in many markets legally required."}
  ], "keyTakeaway": "Accessible design is just good design under constraints."}
  $j$, 1),

  (v_i5, 'multiple_choice',
   $q$Why is a 44px minimum touch target a rule and not a taste?$q$,
   $q$Think of every thumb, not the designer's cursor.$q$,
   $j${"options": {
      "a": "Smaller targets cause constant mis-taps for a large share of real hands and situations",
      "b": "Smaller buttons load slower",
      "c": "It is only relevant for elderly users",
      "d": "App stores reject smaller buttons automatically"
    }, "correctOptionId": "a"}$j$, 2),

  (v_i5, 'fill_blank',
   $q$Complete the two accessibility basics every screen needs.$q$,
   $q$One for images, one for keyboards.$q$,
   $j${"codeSnippet": "Every meaningful image needs {{0}} text.\nEvery interactive control needs a visible {{1}} state.",
      "correctAnswers": {"0": "alt", "1": "focus"},
      "availableOptions": ["alt", "bold", "focus", "hover"]}$j$, 3);

  -- =========================================================================
  -- ADVANCED
  -- =========================================================================
  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('uiux', v_adv, 'Research That Finds Truth',
    $q$Ask about the past, not the future — and watch more than you ask.$q$, 1)
  returning id into v_a1;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('uiux', v_adv, 'Usability Testing',
    $q$Five users, real tasks, and the humility to watch in silence.$q$, 2)
  returning id into v_a2;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('uiux', v_adv, 'Prototypes That Answer Questions',
    $q$Build the cheapest thing that settles the argument.$q$, 3)
  returning id into v_a3;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('uiux', v_adv, 'Working With Developers',
    $q$Handoff is a conversation, not a delivery.$q$, 4)
  returning id into v_a4;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('uiux', v_adv, 'Measuring Design',
    $q$Opinions end where metrics begin.$q$, 5)
  returning id into v_a5;

  -- --- A1 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a1, 'theory', $q$Ask about the past, not the future$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "People are honest historians and terrible fortune tellers. \"Would you use this?\" invites politeness and imagination; \"tell me about the last time you tried to do this\" invites facts."},
    {"type": "list", "items": [
      "Ask about specific past behavior, not hypothetical future behavior",
      "Never ask leading questions — \"do you find this easier?\" already contains its answer",
      "When you can, watch what people do; it beats anything they say"
    ]},
    {"type": "paragraph", "text": "Research is not collecting compliments. It is hunting for the places where reality disagrees with your design."}
  ], "keyTakeaway": "Watch what they do; trust it over what they say."}
  $j$, 1),

  (v_a1, 'multiple_choice',
   $q$Which interview question will produce honest, usable data?$q$,
   $q$Past and specific beats future and hypothetical.$q$,
   $j${"options": {
      "a": "Tell me about the last time you paid a bill from your phone — what happened?",
      "b": "Would you use an app that pays your bills automatically?",
      "c": "Do you agree this design is easier than the old one?",
      "d": "How much would you love a faster checkout?"
    }, "correctOptionId": "a"}$j$, 2),

  (v_a1, 'order_logic',
   $q$Order a research effort that answers a real question.$q$,
   $q$Know what you need to learn before choosing how.$q$,
   $j${"blocks": {
      "question": "Define what you need to learn",
      "method": "Choose the method that answers it",
      "recruit": "Recruit people who match your real users",
      "observe": "Interview and observe",
      "synthesize": "Synthesize the patterns into findings"
    }, "correctOrder": ["question", "method", "recruit", "observe", "synthesize"]}$j$, 3);

  -- --- A2 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a2, 'order_logic',
   $q$Order a usability test that produces findings, not compliments.$q$,
   $q$Tasks, silence, notes — in that spirit.$q$,
   $j${"blocks": {
      "tasks": "Write realistic tasks, not instructions",
      "recruit": "Recruit around five representative users",
      "observe": "Let them try while you watch in silence",
      "notes": "Note where they hesitate and where they fail",
      "prioritize": "Prioritize the problems found and fix the worst"
    }, "correctOrder": ["tasks", "recruit", "observe", "notes", "prioritize"]}$j$, 1),

  (v_a2, 'multiple_choice',
   $q$Why do usability tests run with about five users per round?$q$,
   $q$It is about repetition of problems, not statistics.$q$,
   $j${"options": {
      "a": "Five users surface most recurring problems; more mostly repeats the same findings",
      "b": "Five is the legal minimum",
      "c": "Recruiting more is impossible",
      "d": "Statistics require exactly five"
    }, "correctOptionId": "a"}$j$, 2),

  (v_a2, 'fill_blank',
   $q$Complete the golden rule of moderating a test.$q$,
   $q$Your help contaminates the result.$q$,
   $j${"codeSnippet": "Give the user a {{0}}, not instructions —\nand when they get stuck, {{1}} instead of helping.",
      "correctAnswers": {"0": "task", "1": "watch"},
      "availableOptions": ["task", "tutorial", "watch", "intervene"]}$j$, 3);

  -- --- A3 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a3, 'multiple_choice',
   $q$You need to know if users understand the order of a 4-step flow. What do you build?$q$,
   $q$Match the fidelity to the question.$q$,
   $j${"options": {
      "a": "A quick clickable wireframe of the 4 steps — the question is about flow, not looks",
      "b": "The full visual design of every screen first",
      "c": "The developed feature, to test it for real",
      "d": "A survey asking if 4 steps sounds reasonable"
    }, "correctOptionId": "a"}$j$, 1),

  (v_a3, 'fill_blank',
   $q$Complete what a prototype is for.$q$,
   $q$It has one job, and it is not being pretty.$q$,
   $j${"codeSnippet": "A prototype exists to {{0}} a question,\nnot to {{1}} the final product.",
      "correctAnswers": {"0": "answer", "1": "imitate"},
      "availableOptions": ["answer", "imitate", "decorate", "delay"]}$j$, 2),

  (v_a3, 'order_logic',
   $q$Order the loop that keeps prototyping honest.$q$,
   $q$The question comes first; the build serves it.$q$,
   $j${"blocks": {
      "question": "Define the question this prototype must answer",
      "build": "Build the cheapest thing that can answer it",
      "test": "Test it with real users",
      "decide": "Decide with the evidence and move on"
    }, "correctOrder": ["question", "build", "test", "decide"]}$j$, 3);

  -- --- A4 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a4, 'theory', $q$Handoff is a conversation$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "A design is not done when it looks finished; it is done when a developer can build it without guessing. That means delivering the states — empty, loading, error — the edge cases (the 40-character name, the missing photo), and the spacing and tokens, named the way the design system names them."},
    {"type": "paragraph", "text": "The best designers involve developers before the design is final: an engineer looking at a wireframe for five minutes can save a week of building the wrong thing. And when the build is ready, reviewing it together is part of the design work, not an extra."}
  ], "keyTakeaway": "The best handoff happens before the design is finished."}
  $j$, 1),

  (v_a4, 'multiple_choice',
   $q$A developer asks: "what should this list show when it is empty?" — and the design has no answer. What does that reveal?$q$,
   $q$The mockup only showed perfect data.$q$,
   $j${"options": {
      "a": "The design is missing a state — the empty case was never designed",
      "b": "The developer should invent something reasonable",
      "c": "Lists are a backend concern",
      "d": "Nothing; empty lists never happen in production"
    }, "correctOptionId": "a"}$j$, 2),

  (v_a4, 'order_logic',
   $q$Order a handoff that will not come back to haunt you.$q$,
   $q$Involve early, specify fully, review together.$q$,
   $j${"blocks": {
      "early": "Involve developers while the design is still cheap to change",
      "states": "Deliver every state and edge case, not just the happy path",
      "specs": "Hand off tokens and spacing by their design-system names",
      "review": "Review the built result together and adjust"
    }, "correctOrder": ["early", "states", "specs", "review"]}$j$, 3);

  -- --- A5 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a5, 'multiple_choice',
   $q$The team redesigned the checkout. Which signal says whether it worked?$q$,
   $q$Success has a number.$q$,
   $j${"options": {
      "a": "The task completion rate: how many people who start the checkout finish it",
      "b": "The team agrees it looks much better",
      "c": "The CEO likes the new colors",
      "d": "It won an internal design award"
    }, "correctOptionId": "a"}$j$, 1),

  (v_a5, 'fill_blank',
   $q$Complete what gets measured after shipping a design.$q$,
   $q$Completion and failure, not applause.$q$,
   $j${"codeSnippet": "Measure {{0}} completion and {{1}} rate —\nopinions are not data.",
      "correctAnswers": {"0": "task", "1": "error"},
      "availableOptions": ["task", "error", "applause", "meeting"]}$j$, 2),

  (v_a5, 'order_logic',
   $q$Order the measurement loop of a shipped design.$q$,
   $q$Define success before shipping, or any number will look like success.$q$,
   $j${"blocks": {
      "define": "Define the success metric before shipping",
      "ship": "Ship the design",
      "compare": "Compare the metric against the baseline",
      "iterate": "Iterate on what the numbers reveal"
    }, "correctOrder": ["define", "ship", "compare", "iterate"]}$j$, 3);

end
$$;
