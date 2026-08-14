-- ===========================================================================
-- Semilla: path de Project Management por niveles
-- ===========================================================================
--
-- Track nuevo (20260814000003). El marco de referencia es el PMBOK (grupos de
-- procesos, charter, WBS, riesgos, tailoring ágil/predictivo), y el nivel
-- Advanced se dedica deliberadamente a las habilidades blandas —comunicación,
-- liderazgo, negociación— porque son lo que de verdad entrega proyectos y lo
-- que la dueña pidió enfatizar. 45 retos.

do $$
declare
  v_basic uuid; v_inter uuid; v_adv uuid;
  v_b1 uuid; v_b2 uuid; v_b3 uuid; v_b4 uuid; v_b5 uuid;
  v_i1 uuid; v_i2 uuid; v_i3 uuid; v_i4 uuid; v_i5 uuid;
  v_a1 uuid; v_a2 uuid; v_a3 uuid; v_a4 uuid; v_a5 uuid;
begin

  delete from public.topics where track_id = 'project_management';

  -- =========================================================================
  -- NIVELES
  -- =========================================================================
  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('project_management', null, 'Basic',
    $q$What a project really is, who is in it and how it starts — the foundations every PM shares, straight from the PMBOK.$q$, 1)
  returning id into v_basic;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('project_management', null, 'Intermediate',
    $q$Planning that survives reality: scope, time, risk and choosing the right way of working.$q$, 2)
  returning id into v_inter;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('project_management', null, 'Advanced',
    $q$The human side that actually delivers projects: communication, leadership, negotiation and closing well.$q$, 3)
  returning id into v_adv;

  -- =========================================================================
  -- BASIC
  -- =========================================================================
  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('project_management', v_basic, 'What a Project Is (and Is Not)',
    $q$Temporary, unique, and always pulled by three forces.$q$, 1)
  returning id into v_b1;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('project_management', v_basic, 'The Life of a Project',
    $q$The five process groups: how every project moves from idea to done.$q$, 2)
  returning id into v_b2;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('project_management', v_basic, 'People in a Project',
    $q$Sponsor, PM, team: who owns the why, the how and the doing.$q$, 3)
  returning id into v_b3;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('project_management', v_basic, 'Stakeholders: Map Them Early',
    $q$Anyone the project touches can help it or sink it.$q$, 4)
  returning id into v_b4;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('project_management', v_basic, 'The Project Charter',
    $q$The document that gives the project — and you — the right to exist.$q$, 5)
  returning id into v_b5;

  -- --- B1 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b1, 'theory', $q$Temporary and unique$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "The PMBOK defines a project as a temporary endeavor undertaken to create a unique result. Two words carry all the weight: temporary — it has a beginning and an end — and unique — it produces something that did not exist before."},
    {"type": "paragraph", "text": "That separates projects from operations. Migrating the company to a new billing system is a project. Sending the invoices every month is operations: repetitive, ongoing, no end date. They are managed completely differently, and confusing them is how endless projects are born."}
  ], "keyTakeaway": "If it never ends, it is not a project — it is operations."}
  $j$, 1),

  (v_b1, 'theory', $q$The triple constraint$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Every project is pulled by three forces at once: scope (how much gets done), time (by when) and cost (with what resources). Quality sits in the middle, shaped by all three."},
    {"type": "paragraph", "text": "The law of the triangle: you cannot move one corner without moving another. More scope needs more time or more people. A tighter deadline needs less scope or more budget. A PM's daily job is making those trades visible before they are made silently — because they always get made."}
  ], "keyTakeaway": "Scope, time, cost: you can fix two; the third one moves."}
  $j$, 2),

  (v_b1, 'multiple_choice',
   $q$Which of these is a project?$q$,
   $q$Look for a beginning, an end and a unique result.$q$,
   $j${"options": {
      "a": "Migrating the company to a new billing system by June",
      "b": "Answering support tickets every day",
      "c": "Running payroll every month",
      "d": "Keeping the servers patched, forever"
    }, "correctOptionId": "a"}$j$, 3);

  -- --- B2 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b2, 'theory', $q$The five process groups$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "The PMBOK organizes every project's work into five process groups: Initiating (authorize it and name what success means), Planning (decide the route), Executing (do the work), Monitoring & Controlling (compare reality against the plan and correct), and Closing (finish formally and learn)."},
    {"type": "paragraph", "text": "The trap is reading them as a straight line. Monitoring is not a phase at the end — it runs alongside everything, from the first week to the last. And in agile projects the middle groups repeat in every cycle."}
  ], "keyTakeaway": "Monitoring is not a phase at the end; it runs alongside everything."}
  $j$, 1),

  (v_b2, 'order_logic',
   $q$Order the five PMBOK process groups.$q$,
   $q$From the birth of the project to its lessons.$q$,
   $j${"blocks": {
      "init": "Initiating",
      "plan": "Planning",
      "exec": "Executing",
      "monitor": "Monitoring & Controlling",
      "close": "Closing"
    }, "correctOrder": ["init", "plan", "exec", "monitor", "close"]}$j$, 2),

  (v_b2, 'multiple_choice',
   $q$The team is building, and you are comparing actual progress against the plan and correcting course. Which process group is that?$q$,
   $q$It happens during the work, not after it.$q$,
   $j${"options": {
      "a": "Monitoring & Controlling",
      "b": "Initiating",
      "c": "Closing",
      "d": "Planning"
    }, "correctOptionId": "a"}$j$, 3);

  -- --- B3 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b3, 'theory', $q$Who owns what$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Projects fail over unclear roles more often than over hard problems. The core cast:"},
    {"type": "list", "items": [
      "Sponsor — funds and authorizes the project; owns the why; unblocks at the top",
      "Project manager — orchestrates plan, people and risks; owns the how",
      "Team — builds the result; owns the doing and the estimates",
      "Stakeholders — everyone affected; they do not build, but they can bless or block"
    ]},
    {"type": "paragraph", "text": "A useful test for any decision: is this a why decision (sponsor), a how decision (PM) or a doing decision (team)? Escalate or delegate accordingly."}
  ], "keyTakeaway": "The sponsor owns the why; the PM owns the how; the team owns the doing."}
  $j$, 1),

  (v_b3, 'multiple_choice',
   $q$The project needs 20% more budget. Who decides?$q$,
   $q$Money and mandate live in the same place.$q$,
   $j${"options": {
      "a": "The sponsor — funding is a why-level decision",
      "b": "The PM, quietly, to avoid worrying anyone",
      "c": "The team, by majority vote",
      "d": "Nobody; budgets never change"
    }, "correctOptionId": "a"}$j$, 2),

  (v_b3, 'fill_blank',
   $q$Complete who authorizes and who delivers.$q$,
   $q$One signs the birth certificate; the other does the daily work.$q$,
   $j${"codeSnippet": "The {{0}} authorizes the project and owns the why.\nThe {{1}} builds the result day by day.",
      "correctAnswers": {"0": "sponsor", "1": "team"},
      "availableOptions": ["sponsor", "team", "client", "vendor"]}$j$, 3);

  -- --- B4 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b4, 'theory', $q$Anyone the project touches$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "A stakeholder is anyone affected by the project or able to affect it: users, bosses, legal, the team next door whose system you integrate with. The dangerous ones are the ones you have not identified — they show up late, surprised and opposed."},
    {"type": "paragraph", "text": "The classic tool is the power/interest grid: how much influence does each one have, how much do they care. High power and high interest → manage closely. High power, low interest → keep satisfied, do not flood with detail. Low power, high interest → keep informed. Low both → monitor."}
  ], "keyTakeaway": "A stakeholder you ignore becomes a risk you meet later."}
  $j$, 1),

  (v_b4, 'order_logic',
   $q$Order the stakeholder management cycle.$q$,
   $q$You cannot engage who you have not analyzed.$q$,
   $j${"blocks": {
      "identify": "Identify everyone the project touches",
      "analyze": "Analyze their power and their interest",
      "plan": "Plan how to engage each group",
      "monitor": "Keep monitoring — stakeholders change"
    }, "correctOrder": ["identify", "analyze", "plan", "monitor"]}$j$, 2),

  (v_b4, 'multiple_choice',
   $q$A director has high power over your project but little day-to-day interest. How do you engage them?$q$,
   $q$Enough to keep their support; not so much that they tune out.$q$,
   $j${"options": {
      "a": "Keep them satisfied: short executive updates at the right moments",
      "b": "Add them to every working meeting",
      "c": "Ignore them until there is a crisis",
      "d": "Send them the full task board daily"
    }, "correctOptionId": "a"}$j$, 3);

  -- --- B5 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b5, 'theory', $q$The birth certificate$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "The project charter is the document that makes a project official. It names why the project exists, what success looks like at a high level, who the sponsor is — and it formally authorizes the project manager to use the organization's resources."},
    {"type": "paragraph", "text": "That last part is the one juniors underestimate. Without a charter, a PM is someone asking colleagues for favors. With it, coordinating people and budget is not a favor — it is the mandate. When a project feels impossible to move, the missing charter is often the reason."}
  ], "keyTakeaway": "No charter, no authority."}
  $j$, 1),

  (v_b5, 'multiple_choice',
   $q$What does the charter give the project manager?$q$,
   $q$It is about mandate, not about task lists.$q$,
   $j${"options": {
      "a": "Formal authority to use resources for the project",
      "b": "The detailed task list for the whole project",
      "c": "A guarantee that the project cannot fail",
      "d": "The final architecture of the solution"
    }, "correctOptionId": "a"}$j$, 2),

  (v_b5, 'fill_blank',
   $q$Complete what the charter states.$q$,
   $q$Purpose and definition of done, at the highest level.$q$,
   $j${"codeSnippet": "The charter states {{0}} the project exists\nand {{1}} success looks like.",
      "correctAnswers": {"0": "why", "1": "what"},
      "availableOptions": ["why", "what", "where", "who"]}$j$, 3);

  -- =========================================================================
  -- INTERMEDIATE
  -- =========================================================================
  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('project_management', v_inter, 'Scope and the WBS',
    $q$Say what is in, write what is out, break the rest into pieces.$q$, 1)
  returning id into v_i1;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('project_management', v_inter, 'Scheduling',
    $q$Dependencies before dates: the critical path decides your deadline.$q$, 2)
  returning id into v_i2;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('project_management', v_inter, 'Risk Management',
    $q$A risk written down is a plan; a risk in your head is a surprise.$q$, 3)
  returning id into v_i3;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('project_management', v_inter, 'Agile and Predictive',
    $q$Two honest answers to uncertainty — and how to choose.$q$, 4)
  returning id into v_i4;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('project_management', v_inter, 'Tracking Real Progress',
    $q$Time spent is not work done. Measure what actually moved.$q$, 5)
  returning id into v_i5;

  -- --- I1 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i1, 'theory', $q$Scope: say what is out$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "The scope statement says what the project will deliver — and, just as loudly, what it will not. The exclusions are not pessimism; they are the only defense against the slow, smiling death of projects: scope creep, one small extra at a time."},
    {"type": "paragraph", "text": "The WBS — work breakdown structure — turns the scope into pieces: deliverables decomposed into work packages small enough to estimate and assign. Its golden rule: if work is not in the WBS, it is not in the project."}
  ], "keyTakeaway": "Scope not written down is scope you already lost."}
  $j$, 1),

  (v_i1, 'order_logic',
   $q$Order the construction of a WBS.$q$,
   $q$From deliverables to owned, estimated pieces.$q$,
   $j${"blocks": {
      "deliverables": "List the major deliverables",
      "decompose": "Decompose each into work packages",
      "assign": "Assign an owner to every package",
      "estimate": "Estimate each package"
    }, "correctOrder": ["deliverables", "decompose", "assign", "estimate"]}$j$, 2),

  (v_i1, 'multiple_choice',
   $q$Every week the client adds "one small extra screen, since you are at it". What is happening?$q$,
   $q$It has a name, and it kills projects politely.$q$,
   $j${"options": {
      "a": "Scope creep — uncontrolled growth, one small yes at a time",
      "b": "Healthy flexibility, always say yes",
      "c": "A scheduling problem",
      "d": "Normal monitoring and controlling"
    }, "correctOptionId": "a"}$j$, 3);

  -- --- I2 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i2, 'theory', $q$Dependencies before dates$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "A schedule is not a list of dates; it is a chain of dependencies with dates at the end. First: what depends on what — you cannot test what is not built. Then: how long each piece takes. Only then do dates exist."},
    {"type": "paragraph", "text": "The longest chain of dependent tasks is the critical path, and it defines the project's minimum duration. Tasks on it have zero slack: a day lost there is a day lost at the end. Tasks off it can slip quietly. Knowing which is which is the difference between managing a schedule and being surprised by it."}
  ], "keyTakeaway": "The critical path is where a delay costs you the deadline."}
  $j$, 1),

  (v_i2, 'order_logic',
   $q$Order the construction of a schedule.$q$,
   $q$Sequence first, durations second, path last.$q$,
   $j${"blocks": {
      "list": "List the activities from the WBS",
      "sequence": "Sequence their dependencies",
      "estimate": "Estimate each duration",
      "path": "Find the critical path"
    }, "correctOrder": ["list", "sequence", "estimate", "path"]}$j$, 2),

  (v_i2, 'multiple_choice',
   $q$A task on the critical path slips two days. What happens to the project?$q$,
   $q$Zero slack means zero forgiveness.$q$,
   $j${"options": {
      "a": "The end date moves two days, unless you change something else",
      "b": "Nothing, other tasks absorb it automatically",
      "c": "Only that task's owner is affected",
      "d": "The budget shrinks"
    }, "correctOptionId": "a"}$j$, 3);

  -- --- I3 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i3, 'theory', $q$Risks are not problems yet$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "A risk is a problem that has not happened: the key developer might leave, the vendor might deliver late. Managing risks means finding them early, sizing them by probability and impact, and deciding the response before they fire:"},
    {"type": "list", "items": [
      "Avoid — change the plan so the risk cannot happen",
      "Mitigate — reduce its probability or its impact",
      "Transfer — hand it to someone built for it (insurance, a contract)",
      "Accept — decide it is small enough to live with, and watch it"
    ]},
    {"type": "paragraph", "text": "The risk register is where they live: each with an owner and a trigger. A risk without an owner is a risk nobody is watching."}
  ], "keyTakeaway": "A risk written down is a plan; a risk in your head is a surprise."}
  $j$, 1),

  (v_i3, 'multiple_choice',
   $q$You buy insurance against the vendor failing to deliver. Which risk response is that?$q$,
   $q$Someone else absorbs the impact, for a price.$q$,
   $j${"options": {
      "a": "Transfer",
      "b": "Avoid",
      "c": "Mitigate",
      "d": "Accept"
    }, "correctOptionId": "a"}$j$, 2),

  (v_i3, 'order_logic',
   $q$Order the risk management cycle.$q$,
   $q$Find, size, plan, watch.$q$,
   $j${"blocks": {
      "identify": "Identify the risks",
      "analyze": "Analyze probability and impact",
      "respond": "Plan the response for the big ones",
      "watch": "Watch the triggers throughout the project"
    }, "correctOrder": ["identify", "analyze", "respond", "watch"]}$j$, 3);

  -- --- I4 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i4, 'theory', $q$Two honest answers to uncertainty$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Predictive (waterfall) plans the whole route up front. It shines when requirements are stable and known — a regulatory migration, a building. Agile plans in short cycles, shipping something usable each time and adjusting with what it learns. It shines when you are discovering what users need as you go — most software."},
    {"type": "paragraph", "text": "The PMBOK stopped treating this as a war years ago: it calls it tailoring. The method is chosen per project — and hybrids are normal: predictive skeleton, agile delivery inside."}
  ], "keyTakeaway": "The method serves the project, not the other way around."}
  $j$, 1),

  (v_i4, 'multiple_choice',
   $q$Requirements are fuzzy and users can give feedback every two weeks. Which approach fits?$q$,
   $q$Uncertainty plus fast feedback points one way.$q$,
   $j${"options": {
      "a": "Agile — short cycles that turn feedback into direction",
      "b": "Predictive — freeze the requirements now",
      "c": "No method, just start typing",
      "d": "Wait until requirements stabilize on their own"
    }, "correctOptionId": "a"}$j$, 2),

  (v_i4, 'order_logic',
   $q$Order one agile cycle (a sprint).$q$,
   $q$Plan, build, show, learn — then again.$q$,
   $j${"blocks": {
      "plan": "Plan the sprint: what fits and what matters most",
      "build": "Build it",
      "review": "Review the result with users and stakeholders",
      "retro": "Retrospective: how the team itself can improve"
    }, "correctOrder": ["plan", "build", "review", "retro"]}$j$, 3);

  -- --- I5 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i5, 'multiple_choice',
   $q$Half the time has passed. What tells you whether the project is actually on track?$q$,
   $q$The calendar moves on its own; the work does not.$q$,
   $j${"options": {
      "a": "Comparing the work completed against the work planned for this point",
      "b": "Half the time passed, so it must be half done",
      "c": "The team looks busy",
      "d": "The budget is half spent"
    }, "correctOptionId": "a"}$j$, 1),

  (v_i5, 'fill_blank',
   $q$Complete the tracking principle.$q$,
   $q$One is evidence; the other just passes.$q$,
   $j${"codeSnippet": "Track {{0}} completed, not {{1}} spent.",
      "correctAnswers": {"0": "work", "1": "time"},
      "availableOptions": ["work", "time", "money", "meetings"]}$j$, 2),

  (v_i5, 'order_logic',
   $q$Order the monitoring loop that keeps a project honest.$q$,
   $q$Without a baseline there is nothing to compare against.$q$,
   $j${"blocks": {
      "baseline": "Baseline the plan: scope, schedule, cost",
      "record": "Record actual progress regularly",
      "compare": "Compare actuals against the baseline",
      "correct": "Correct course while it is still cheap"
    }, "correctOrder": ["baseline", "record", "compare", "correct"]}$j$, 3);

  -- =========================================================================
  -- ADVANCED — habilidades blandas
  -- =========================================================================
  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('project_management', v_adv, 'Communication: the Real Job',
    $q$A PM spends most of the day communicating. Do it on purpose.$q$, 1)
  returning id into v_a1;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('project_management', v_adv, 'Leading Without Authority',
    $q$Influence, trust and removing blockers — nobody has to obey you.$q$, 2)
  returning id into v_a2;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('project_management', v_adv, 'Negotiation and Conflict',
    $q$Conflict is information. Argue interests, not positions.$q$, 3)
  returning id into v_a3;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('project_management', v_adv, 'Meetings That Deserve to Exist',
    $q$Purpose, the right people, decisions written down — or a message instead.$q$, 4)
  returning id into v_a4;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('project_management', v_adv, 'Closing and Lessons Learned',
    $q$Projects end on purpose — and teach on purpose.$q$, 5)
  returning id into v_a5;

  -- --- A1 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a1, 'theory', $q$Ninety percent communication$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "The PMBOK's most quoted statistic: project managers spend about 90% of their time communicating. Not because they talk a lot — because alignment is the actual product of their work. The plan only exists if everyone holds the same version of it."},
    {"type": "list", "items": [
      "Audience first — the sponsor needs impact and options; the team needs specifics",
      "Channel matters — urgent and serious deserves a call, not a paragraph in a thread",
      "Confirmation closes the loop — communication is what they understood, not what you sent"
    ]}
  ], "keyTakeaway": "If they did not understand it, you did not communicate it."}
  $j$, 1),

  (v_a1, 'multiple_choice',
   $q$Production broke and the client is affected. How do you tell the sponsor?$q$,
   $q$Urgency and severity choose the channel.$q$,
   $j${"options": {
      "a": "Immediately and briefly: what happened, the impact, what is being done",
      "b": "A detailed slide deck at next week's steering meeting",
      "c": "Nothing until it is fully fixed, to avoid alarm",
      "d": "A long email with the complete technical log"
    }, "correctOptionId": "a"}$j$, 2),

  (v_a1, 'order_logic',
   $q$Order a status update people actually read.$q$,
   $q$Progress, blockers, needs, next — in that order.$q$,
   $j${"blocks": {
      "progress": "What moved forward since last time",
      "blockers": "What is blocked and why",
      "needs": "What you need from whom",
      "next": "What comes next"
    }, "correctOrder": ["progress", "blockers", "needs", "next"]}$j$, 3);

  -- --- A2 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a2, 'theory', $q$Influence over orders$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "A PM usually leads people who do not report to them. Orders are not available; influence is. It is built the unglamorous way: keeping promises, removing the blockers in the team's path, giving credit away and absorbing pressure instead of passing it down."},
    {"type": "paragraph", "text": "This is servant leadership, and it is not softness. A team that trusts its PM raises problems while they are small. A team that fears its PM hides them until they are catastrophic. The trust is the early-warning system."}
  ], "keyTakeaway": "Authority gets compliance; trust gets commitment."}
  $j$, 1),

  (v_a2, 'multiple_choice',
   $q$A strong developer has started missing deadlines. Your first move?$q$,
   $q$Diagnose before judging.$q$,
   $j${"options": {
      "a": "A private conversation to understand what changed — blockers, workload, something personal",
      "b": "Mention it in the team meeting so everyone learns",
      "c": "Escalate to their manager immediately",
      "d": "Silently reassign their work"
    }, "correctOptionId": "a"}$j$, 2),

  (v_a2, 'fill_blank',
   $q$Complete what a servant leader does.$q$,
   $q$One thing they clear away; one thing they give away.$q$,
   $j${"codeSnippet": "A servant leader removes {{0}}\nand gives away {{1}}.",
      "correctAnswers": {"0": "blockers", "1": "credit"},
      "availableOptions": ["blockers", "credit", "deadlines", "blame"]}$j$, 3);

  -- --- A3 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a3, 'theory', $q$Positions and interests$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "A position is what someone demands: \"we must use my framework\". An interest is why they demand it: \"I do not want to maintain code nobody else understands\". Positions collide head-on; interests often turn out to be compatible."},
    {"type": "paragraph", "text": "The negotiator's craft is digging from positions down to interests, separating the people from the problem, and agreeing on objective criteria before choosing. Conflict handled this way is not a threat to the project — it is information about what matters to whom, surfacing early enough to use."}
  ], "keyTakeaway": "Argue interests, not positions."}
  $j$, 1),

  (v_a3, 'order_logic',
   $q$Order a principled resolution of a conflict.$q$,
   $q$Listen, separate, dig, agree on the rules, then decide.$q$,
   $j${"blocks": {
      "listen": "Listen to both sides completely",
      "separate": "Separate the people from the problem",
      "interests": "Dig for the interests behind the positions",
      "criteria": "Agree on objective criteria",
      "decide": "Decide with the criteria, not with the loudest voice"
    }, "correctOrder": ["listen", "separate", "interests", "criteria", "decide"]}$j$, 2),

  (v_a3, 'multiple_choice',
   $q$Two senior developers are locked in a public fight over a technology choice. What does a good PM do?$q$,
   $q$The project needs a decision, not a winner.$q$,
   $j${"options": {
      "a": "Get the criteria on the table — needs, constraints — and drive the decision through them",
      "b": "Side with the more senior one",
      "c": "Let them fight it out; the best idea wins",
      "d": "Postpone the decision until the tension fades"
    }, "correctOptionId": "a"}$j$, 3);

  -- --- A4 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a4, 'multiple_choice',
   $q$A recurring meeting has no agenda, no decisions and the same monologue every week. What should it be?$q$,
   $q$Respect for people's hours is a PM skill.$q$,
   $j${"options": {
      "a": "A written status message — it stopped deserving a meeting",
      "b": "Longer, to cover more ground",
      "c": "Mandatory, to improve attendance",
      "d": "Moved to Fridays"
    }, "correctOptionId": "a"}$j$, 1),

  (v_a4, 'order_logic',
   $q$Order a meeting that earns its slot on the calendar.$q$,
   $q$Purpose before people, decisions before goodbye.$q$,
   $j${"blocks": {
      "purpose": "Define the purpose: what gets decided here",
      "invite": "Invite only the people needed for that",
      "agenda": "Share the agenda beforehand",
      "decide": "Decide, and write the decisions down",
      "actions": "Send the action items with owners and dates"
    }, "correctOrder": ["purpose", "invite", "agenda", "decide", "actions"]}$j$, 2),

  (v_a4, 'fill_blank',
   $q$Complete how every meeting must end.$q$,
   $q$Otherwise it was a conversation, not a meeting.$q$,
   $j${"codeSnippet": "Every meeting ends with {{0}},\neach with an owner and a {{1}}.",
      "correctAnswers": {"0": "action items", "1": "deadline"},
      "availableOptions": ["action items", "applause", "deadline", "recording"]}$j$, 3);

  -- --- A5 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a5, 'theory', $q$Projects end on purpose$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Closing is a process, not an event: the sponsor formally accepts the result, the product is handed to whoever operates it from now on, the team is released with recognition, and the archive is left in order for whoever comes later."},
    {"type": "paragraph", "text": "And the lessons learned session — while memories are fresh, and about the work, never about the guilty. Its only question is: what do we now know that we wish we had known at the start? A project that skips it donates its mistakes to the next project."}
  ], "keyTakeaway": "A project without lessons learned will be repeated — mistakes included."}
  $j$, 1),

  (v_a5, 'order_logic',
   $q$Order the closing of a project.$q$,
   $q$Acceptance first, learning before goodbye.$q$,
   $j${"blocks": {
      "accept": "Obtain formal acceptance from the sponsor",
      "handover": "Hand the product over to operations",
      "lessons": "Run the lessons learned session",
      "release": "Release the team, with recognition",
      "archive": "Archive the documentation"
    }, "correctOrder": ["accept", "handover", "lessons", "release", "archive"]}$j$, 2),

  (v_a5, 'multiple_choice',
   $q$What is the purpose of the lessons learned session?$q$,
   $q$It looks backward to serve what comes next.$q$,
   $j${"options": {
      "a": "Making the next project better with what this one taught",
      "b": "Establishing who was to blame for the delays",
      "c": "A ceremony required to unlock the final invoice",
      "d": "Celebrating, with no written output"
    }, "correctOptionId": "a"}$j$, 3);

end
$$;
