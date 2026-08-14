-- ===========================================================================
-- Semilla: path de Infrastructure & DevOps por niveles
-- ===========================================================================
--
-- Mismo modelo que Frontend (20260814000002) y Backend (20260814000004).
-- 45 retos. Borra los tópicos planos de infrastructure, y con ellos el
-- progreso previo de ese track (cascada a user_progress) — incluido el lab de
-- Docker jugado durante la validación del Módulo 2.

do $$
declare
  v_basic uuid; v_inter uuid; v_adv uuid;
  v_b1 uuid; v_b2 uuid; v_b3 uuid; v_b4 uuid; v_b5 uuid;
  v_i1 uuid; v_i2 uuid; v_i3 uuid; v_i4 uuid; v_i5 uuid;
  v_a1 uuid; v_a2 uuid; v_a3 uuid; v_a4 uuid; v_a5 uuid;
begin

  delete from public.topics where track_id = 'infrastructure';

  -- =========================================================================
  -- NIVELES
  -- =========================================================================
  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('infrastructure', null, 'Basic',
    $q$The craft of keeping software alive: terminals, version control and how an app travels from a laptop to the internet.$q$, 1)
  returning id into v_basic;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('infrastructure', null, 'Intermediate',
    $q$Containers and pipelines: package the app once and let machines test and ship it.$q$, 2)
  returning id into v_inter;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('infrastructure', null, 'Advanced',
    $q$What keeps production calm: monitoring, scaling and recovering fast when things break.$q$, 3)
  returning id into v_adv;

  -- =========================================================================
  -- BASIC
  -- =========================================================================
  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('infrastructure', v_basic, 'What DevOps Actually Means',
    $q$Why building software and running it stopped being separate jobs.$q$, 1)
  returning id into v_b1;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('infrastructure', v_basic, 'The Terminal: Your Home Base',
    $q$Servers have no buttons. The terminal is how you talk to them.$q$, 2)
  returning id into v_b2;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('infrastructure', v_basic, 'Git: the Safety Net',
    $q$Version control: the tool every single tech role shares.$q$, 3)
  returning id into v_b3;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('infrastructure', v_basic, 'Servers and the Cloud',
    $q$Whose computer is it, and what are you actually paying for.$q$, 4)
  returning id into v_b4;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('infrastructure', v_basic, 'From Laptop to Internet',
    $q$What deploying really means, and the journey of a request.$q$, 5)
  returning id into v_b5;

  -- --- B1 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b1, 'theory', $q$Dev plus Ops$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "For years, the people who wrote software and the people who ran it were different teams with different goals: one wanted to ship changes, the other wanted nothing to change. Software got stuck in the middle."},
    {"type": "paragraph", "text": "DevOps is the practice of tearing that wall down: the same team builds, ships and operates its software, sharing the responsibility for it working in the real world."},
    {"type": "list", "items": [
      "Shared ownership — whoever builds it also cares that it runs",
      "Automation — machines do the repetitive steps, always the same way",
      "Fast feedback — problems surface in minutes, not at the end"
    ]}
  ], "keyTakeaway": "You build it, you run it."}
  $j$, 1),

  (v_b1, 'theory', $q$Automate the boring, repeat the safe$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "A person deploying by hand at the end of a long day will eventually skip a step, and that day the site goes down. A script never forgets a step, never improvises, and leaves a record of what it did."},
    {"type": "paragraph", "text": "That is why the core DevOps habit is: if you did it twice by hand, automate it before the third time. Not because typing is expensive — because human memory under pressure is."}
  ], "keyTakeaway": "If you did it twice by hand, automate it before the third time."}
  $j$, 2),

  (v_b1, 'multiple_choice',
   $q$Which of these is a DevOps practice?$q$,
   $q$Look for the one that removes human improvisation.$q$,
   $j${"options": {
      "a": "A deploy script that runs the same steps every time",
      "b": "Deploying by hand every Friday afternoon",
      "c": "Sending the code to the ops team by email as a zip",
      "d": "Testing new changes directly in production"
    }, "correctOptionId": "a"}$j$, 3);

  -- --- B2 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b2, 'theory', $q$Why the terminal$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "The servers your apps run on have no screen, no mouse and no desktop. The only way in is a text conversation: you type a command, the machine answers. That conversation is the terminal."},
    {"type": "code", "language": "bash", "text": "cd /var/www     # move into a folder\nls              # list what is here\ntail app.log    # read the end of a file"},
    {"type": "paragraph", "text": "It looks austere, but it has a superpower the mouse never will: anything you can type, you can save as a script and repeat perfectly, forever."}
  ], "keyTakeaway": "If you can type it, you can script it."}
  $j$, 1),

  (v_b2, 'fill_blank',
   $q$Move into the app folder and see what is inside.$q$,
   $q$One command changes where you are, another lists what is there.$q$,
   $j${"codeSnippet": "{{0}} /var/www/app\n{{1}}",
      "correctAnswers": {"0": "cd", "1": "ls"},
      "availableOptions": ["cd", "ls", "go", "open"]}$j$, 2),

  (v_b2, 'multiple_choice',
   $q$The app is failing right now and you want to watch the log as it grows. Which command?$q$,
   $q$You want the end of the file, following along live.$q$,
   $j${"options": {
      "a": "tail -f app.log",
      "b": "rm app.log",
      "c": "mv app.log",
      "d": "touch app.log"
    }, "correctOptionId": "a"}$j$, 3);

  -- --- B3 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b3, 'theory', $q$A time machine for code$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Git records snapshots of your project — commits — so any change can be inspected, compared or undone. It is the safety net that makes experimenting cheap: nothing committed is ever truly lost."},
    {"type": "code", "language": "bash", "text": "git add .\ngit commit -m \"fix: correct the price rounding\"\ngit push"},
    {"type": "paragraph", "text": "Branches let several people work in parallel without stepping on each other, and a pull request is how a branch asks to be reviewed and merged. Every tech role you will work with — dev, design handoff files, infrastructure definitions — lives in git."}
  ], "keyTakeaway": "Commit small, commit often — every commit is a point you can return to."}
  $j$, 1),

  (v_b3, 'fill_blank',
   $q$Save your change with a message that explains it.$q$,
   $q$Stage first, then commit.$q$,
   $j${"codeSnippet": "git {{0}} .\ngit {{1}} -m \"fix: correct the price rounding\"",
      "correctAnswers": {"0": "add", "1": "commit"},
      "availableOptions": ["add", "commit", "save", "push"]}$j$, 2),

  (v_b3, 'order_logic',
   $q$Order the everyday flow of contributing a change.$q$,
   $q$From getting the code to asking for review.$q$,
   $j${"blocks": {
      "clone": "Clone the repository",
      "branch": "Create a branch for your change",
      "commit": "Commit your work",
      "push": "Push the branch",
      "pr": "Open a pull request for review"
    }, "correctOrder": ["clone", "branch", "commit", "push", "pr"]}$j$, 3);

  -- --- B4 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b4, 'theory', $q$Someone else's computer, your responsibility$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "The cloud is renting computers by the minute instead of buying them. You click, and seconds later a machine exists in a data center; you stop paying, and it is gone. What changes is not the nature of servers — it is how fast you can have one, and how many."},
    {"type": "list", "items": [
      "IaaS — you rent the machine and install everything yourself",
      "PaaS — you hand over your code and the platform runs it",
      "SaaS — you just use finished software, like Gmail"
    ]},
    {"type": "paragraph", "text": "The trade is always the same: the more the provider manages, the less you control — and the less you can break."}
  ], "keyTakeaway": "The cloud sells speed and elasticity, not magic."}
  $j$, 1),

  (v_b4, 'multiple_choice',
   $q$You rent a virtual machine and install the runtime, the app and the database yourself. Which model is that?$q$,
   $q$You got the infrastructure; everything above it is on you.$q$,
   $j${"options": {
      "a": "IaaS — Infrastructure as a Service",
      "b": "PaaS — Platform as a Service",
      "c": "SaaS — Software as a Service",
      "d": "Serverless"
    }, "correctOptionId": "a"}$j$, 2),

  (v_b4, 'multiple_choice',
   $q$Your app went viral overnight. What does the cloud let you do that your own server would not?$q$,
   $q$Think in minutes, not in shopping trips.$q$,
   $j${"options": {
      "a": "Add more machines in minutes and remove them when the wave passes",
      "b": "Make the code run faster automatically",
      "c": "Skip paying for the traffic",
      "d": "Avoid failures entirely"
    }, "correctOptionId": "a"}$j$, 3);

  -- --- B5 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b5, 'theory', $q$What deploying means$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Your app on your laptop only exists for you. Deploying is putting it on a machine that never sleeps, reachable by anyone, under a name people can type."},
    {"type": "paragraph", "text": "That name is where DNS comes in: the internet's phone book, translating aspire.app into the numeric address of the server that answers. When a user hits Enter, the name is resolved, the request crosses the network, your server answers, and the browser paints it — the same request-response loop, now with your machine on the answering side."}
  ], "keyTakeaway": "Deploying is copying code to a machine that never sleeps."}
  $j$, 1),

  (v_b5, 'order_logic',
   $q$Order the journey of a request from a user to your app.$q$,
   $q$The name has to become an address before anything can travel.$q$,
   $j${"blocks": {
      "type": "The user types your domain and presses Enter",
      "dns": "DNS translates the name into the server's address",
      "request": "The request travels to that server",
      "respond": "Your app processes it and responds"
    }, "correctOrder": ["type", "dns", "request", "respond"]}$j$, 2),

  (v_b5, 'multiple_choice',
   $q$What does DNS actually do?$q$,
   $q$It is a translation service.$q$,
   $j${"options": {
      "a": "Translates domain names into server addresses",
      "b": "Encrypts the traffic between browser and server",
      "c": "Stores the website's files",
      "d": "Blocks malicious visitors"
    }, "correctOptionId": "a"}$j$, 3);

  -- =========================================================================
  -- INTERMEDIATE
  -- =========================================================================
  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('infrastructure', v_inter, 'Containers: Package Once, Run Anywhere',
    $q$The end of "it works on my machine".$q$, 1)
  returning id into v_i1;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('infrastructure', v_inter, 'Docker in Practice',
    $q$Build the image, run the container, publish the port.$q$, 2)
  returning id into v_i2;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('infrastructure', v_inter, 'CI: Test Every Change',
    $q$A robot that checks every push before it can hurt anyone.$q$, 3)
  returning id into v_i3;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('infrastructure', v_inter, 'CD: Ship Without Fear',
    $q$From merged to live, through the same tested pipeline every time.$q$, 4)
  returning id into v_i4;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('infrastructure', v_inter, 'Configuration and Secrets',
    $q$Same code everywhere; different settings, safely.$q$, 5)
  returning id into v_i5;

  -- --- I1 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i1, 'theory', $q$The recipe and the dish$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "\"It works on my machine\" dies the day you package the machine along with the app. A container bundles your code with everything it needs — runtime, libraries, settings — so it runs identically on your laptop, a teammate's, and production."},
    {"type": "list", "items": [
      "Image — the frozen recipe: what to install, what to copy, what to run",
      "Container — a running instance of that recipe; start ten if you want",
      "Registry — where images are stored and shared, like git for images"
    ]},
    {"type": "paragraph", "text": "Docker is the tool that made this everyday practice; the idea is bigger than the brand."}
  ], "keyTakeaway": "The image is the recipe; the container is the dish."}
  $j$, 1),

  (v_i1, 'multiple_choice',
   $q$What is the difference between an image and a container?$q$,
   $q$One is frozen, one is alive.$q$,
   $j${"options": {
      "a": "The image is the template; a container is one running instance of it",
      "b": "They are two names for the same thing",
      "c": "The container is the file, the image is what runs",
      "d": "Images run on Linux, containers on Windows"
    }, "correctOptionId": "a"}$j$, 2),

  (v_i1, 'fill_blank',
   $q$Start the Dockerfile: base image first, then install dependencies.$q$,
   $q$One instruction picks the starting point, another executes a command.$q$,
   $j${"codeSnippet": "{{0}} node:18-alpine\nCOPY . .\n{{1}} npm install",
      "correctAnswers": {"0": "FROM", "1": "RUN"},
      "availableOptions": ["FROM", "RUN", "START", "EXEC"]}$j$, 3);

  -- --- I2 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i2, 'order_logic',
   $q$Order the instructions of a typical Node.js Dockerfile.$q$,
   $q$Base, then files, then dependencies, then the start command.$q$,
   $j${"blocks": {
      "from": "FROM node:18-alpine",
      "copy": "COPY . .",
      "run": "RUN npm install",
      "cmd": "CMD [\"npm\", \"start\"]"
    }, "correctOrder": ["from", "copy", "run", "cmd"]}$j$, 1),

  (v_i2, 'fill_blank',
   $q$Run the container and expose it on port 8080 of your machine.$q$,
   $q$The flag maps your port to the container's port.$q$,
   $j${"codeSnippet": "docker run {{0}} 8080:80 {{1}}",
      "correctAnswers": {"0": "-p", "1": "nginx"},
      "availableOptions": ["-p", "-v", "nginx", "port"]}$j$, 2),

  (v_i2, 'multiple_choice',
   $q$Your container starts and exits immediately. The most common reason?$q$,
   $q$A container lives exactly as long as one thing.$q$,
   $j${"options": {
      "a": "Its main process finished, so the container is done",
      "b": "Containers always need a restart to warm up",
      "c": "The image was too small",
      "d": "Docker only runs containers for a few seconds by default"
    }, "correctOptionId": "a"}$j$, 3);

  -- --- I3 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i3, 'theory', $q$A robot that never skips the tests$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Continuous Integration means: every time anyone pushes code, a machine builds the project and runs every test, automatically, before the change can be merged."},
    {"type": "paragraph", "text": "The value is in the timing. A bug caught on the pull request costs minutes; the same bug caught in production costs a night and some trust. CI moves the discovery as early as it can go."},
    {"type": "paragraph", "text": "The pipeline is defined in a file inside the repo — reviewed like code, versioned like code — so the checks themselves cannot be silently skipped."}
  ], "keyTakeaway": "If it is not tested automatically, it is broken and you do not know it yet."}
  $j$, 1),

  (v_i3, 'order_logic',
   $q$Order what happens when you push a branch with CI configured.$q$,
   $q$From your push to the green check on the PR.$q$,
   $j${"blocks": {
      "push": "You push your branch",
      "install": "The pipeline installs dependencies on a clean machine",
      "test": "It runs the full test suite",
      "report": "It reports pass or fail on the pull request"
    }, "correctOrder": ["push", "install", "test", "report"]}$j$, 2),

  (v_i3, 'multiple_choice',
   $q$What is the main value of CI for a team?$q$,
   $q$Think about when problems are found.$q$,
   $j${"options": {
      "a": "Breakage is caught before merging, while it is still cheap to fix",
      "b": "It makes the code run faster in production",
      "c": "It removes the need to write tests",
      "d": "It deploys the app automatically to users"
    }, "correctOptionId": "a"}$j$, 3);

  -- --- I4 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i4, 'theory', $q$From merged to live$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Continuous Delivery picks up where CI ends: once a change is merged and green, the pipeline packages it and moves it toward production through environments — usually staging first, a production-like copy where the change is tried safely."},
    {"type": "paragraph", "text": "Teams that ship small changes often have calmer productions than teams that ship big releases rarely. A small release that fails is a small problem with an obvious cause; a giant release that fails is an investigation."}
  ], "keyTakeaway": "Small releases fail small."}
  $j$, 1),

  (v_i4, 'multiple_choice',
   $q$Why deploy to staging before production?$q$,
   $q$It is a dress rehearsal on a production-like stage.$q$,
   $j${"options": {
      "a": "To try the change on a copy that behaves like production, without users at risk",
      "b": "Because production only accepts deploys at night",
      "c": "To make the release take longer on purpose",
      "d": "Staging is where users test the app"
    }, "correctOptionId": "a"}$j$, 2),

  (v_i4, 'order_logic',
   $q$Order a healthy path from merge to production.$q$,
   $q$Build once, verify, then promote.$q$,
   $j${"blocks": {
      "merge": "The change is merged to main",
      "build": "The pipeline builds the artifact",
      "staging": "It deploys to staging",
      "smoke": "Quick checks confirm staging works",
      "prod": "The same artifact is promoted to production"
    }, "correctOrder": ["merge", "build", "staging", "smoke", "prod"]}$j$, 3);

  -- --- I5 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i5, 'theory', $q$Same code, different settings$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "The app in staging and the app in production are the same code pointed at different databases, keys and limits. Those differences live in environment variables — named values the machine provides and the code reads."},
    {"type": "code", "language": "bash", "text": "export APP_ENV=production\nexport DATABASE_URL=postgres://..."},
    {"type": "paragraph", "text": "Secrets — passwords, API keys — are environment configuration too, with one extra rule: they never, under any excuse, get committed to the repository. Git history is forever, and so is a leaked key."}
  ], "keyTakeaway": "Configuration changes per environment; code does not."}
  $j$, 1),

  (v_i5, 'fill_blank',
   $q$Point the app at the production database through the environment.$q$,
   $q$Set the variable, then read it by name.$q$,
   $j${"codeSnippet": "export {{0}}=postgres://user:pass@host/app\n\n// in the code\nconst url = process.env.{{1}};",
      "correctAnswers": {"0": "DATABASE_URL", "1": "DATABASE_URL"},
      "availableOptions": ["DATABASE_URL", "database", "config", "URL"]}$j$, 2),

  (v_i5, 'multiple_choice',
   $q$Which of these places is NOT safe for the database password?$q$,
   $q$One of them is forever.$q$,
   $j${"options": {
      "a": "Committed to the repository",
      "b": "An environment variable on the server",
      "c": "The cloud provider's secret manager",
      "d": "The CI system's protected secrets store"
    }, "correctOptionId": "a"}$j$, 3);

  -- =========================================================================
  -- ADVANCED
  -- =========================================================================
  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('infrastructure', v_adv, 'Monitoring and Logs',
    $q$You cannot fix what you cannot see.$q$, 1)
  returning id into v_a1;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('infrastructure', v_adv, 'Infrastructure as Code',
    $q$Servers described in files: reviewable, repeatable, recoverable.$q$, 2)
  returning id into v_a2;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('infrastructure', v_adv, 'Scaling Basics',
    $q$What to do when success arrives and the server does not keep up.$q$, 3)
  returning id into v_a3;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('infrastructure', v_adv, 'Reliability and Backups',
    $q$Everything fails. The difference is how fast you recover.$q$, 4)
  returning id into v_a4;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('infrastructure', v_adv, 'Security in Operations',
    $q$Least privilege, encrypted traffic and patches on time.$q$, 5)
  returning id into v_a5;

  -- --- A1 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a1, 'theory', $q$Silence is not health$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "A production system with no monitoring is not \"fine\" — it is failing quietly until a user tells you. Observability is built from three materials:"},
    {"type": "list", "items": [
      "Logs — a record of events: what happened, when, to whom",
      "Metrics — numbers over time: CPU, requests per second, error rate",
      "Alerts — a rule that wakes a human when a metric crosses a line"
    ]},
    {"type": "paragraph", "text": "The craft is in the alerts: alert on what users feel (errors, slowness), not on everything that moves, or the team learns to ignore the pager — and then misses the real one."}
  ], "keyTakeaway": "Silence is not health; it is the absence of measurement."}
  $j$, 1),

  (v_a1, 'multiple_choice',
   $q$"CPU has been at 92% for five minutes" — what is that?$q$,
   $q$A number tracked over time.$q$,
   $j${"options": {
      "a": "A metric",
      "b": "A log line",
      "c": "A backup",
      "d": "A deployment"
    }, "correctOptionId": "a"}$j$, 2),

  (v_a1, 'order_logic',
   $q$Order a professional incident response.$q$,
   $q$Users first, root cause later, learning always.$q$,
   $j${"blocks": {
      "alert": "The alert fires",
      "confirm": "Confirm the impact on users",
      "mitigate": "Mitigate first — restore service, even with a workaround",
      "cause": "Then find the root cause",
      "postmortem": "Write the postmortem so it cannot repeat"
    }, "correctOrder": ["alert", "confirm", "mitigate", "cause", "postmortem"]}$j$, 3);

  -- --- A2 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a2, 'multiple_choice',
   $q$Why do teams describe their servers in code instead of clicking consoles?$q$,
   $q$Think about what code gives you that clicks do not.$q$,
   $j${"options": {
      "a": "The setup becomes reviewable, repeatable and recoverable after a disaster",
      "b": "Code makes the servers physically faster",
      "c": "Cloud consoles are being discontinued",
      "d": "It is required by law"
    }, "correctOptionId": "a"}$j$, 1),

  (v_a2, 'fill_blank',
   $q$Complete the idea behind Infrastructure as Code.$q$,
   $q$What it becomes, and what you can do with it.$q$,
   $j${"codeSnippet": "Infrastructure written as {{0}} can be {{1}} like any other change.",
      "correctAnswers": {"0": "code", "1": "reviewed"},
      "availableOptions": ["code", "reviewed", "clicked", "guessed"]}$j$, 2),

  (v_a2, 'order_logic',
   $q$Order the workflow of an infrastructure change done as code.$q$,
   $q$Preview before apply — always.$q$,
   $j${"blocks": {
      "write": "Write the change in the definition files",
      "review": "Get it reviewed like any code change",
      "plan": "Preview exactly what will be created or destroyed",
      "apply": "Apply it"
    }, "correctOrder": ["write", "review", "plan", "apply"]}$j$, 3);

  -- --- A3 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a3, 'multiple_choice',
   $q$Traffic doubled and one server cannot cope. Which is the horizontal option?$q$,
   $q$Horizontal means more, not bigger.$q$,
   $j${"options": {
      "a": "Add more copies of the server behind a load balancer",
      "b": "Buy a much bigger single server",
      "c": "Ask users to visit at different hours",
      "d": "Remove features until it fits"
    }, "correctOptionId": "a"}$j$, 1),

  (v_a3, 'fill_blank',
   $q$Name the piece that spreads the traffic.$q$,
   $q$It stands in front and deals the requests out.$q$,
   $j${"codeSnippet": "A {{0}} distributes incoming requests across several identical {{1}}.",
      "correctAnswers": {"0": "load balancer", "1": "servers"},
      "availableOptions": ["load balancer", "firewall", "servers", "domains"]}$j$, 2),

  (v_a3, 'order_logic',
   $q$Order a sane response to a system that stopped keeping up.$q$,
   $q$Find the bottleneck before spending money on the wrong layer.$q$,
   $j${"blocks": {
      "measure": "Measure to find the actual bottleneck",
      "cheap": "Apply the cheap wins first — caching what repeats",
      "scale": "Scale the layer that is actually saturated",
      "verify": "Measure again to confirm it held"
    }, "correctOrder": ["measure", "cheap", "scale", "verify"]}$j$, 3);

  -- --- A4 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a4, 'theory', $q$Plan for failure, because it is coming$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Disks die, regions go down, someone runs the wrong command on the wrong database. Reliability is not preventing all of that — it is making sure none of it is fatal."},
    {"type": "list", "items": [
      "Redundancy — no single machine whose death takes you down",
      "Backups — automatic, frequent, stored somewhere else",
      "Recovery drills — actually restoring a backup, on a schedule"
    ]},
    {"type": "paragraph", "text": "The drill is the part teams skip, and it is the part that matters: the day you need the backup is the worst possible day to discover it does not restore."}
  ], "keyTakeaway": "A backup you never restored is a hope, not a backup."}
  $j$, 1),

  (v_a4, 'multiple_choice',
   $q$What proves that your backup strategy works?$q$,
   $q$Not the schedule. Not the file size.$q$,
   $j${"options": {
      "a": "Successfully restoring from a backup, as a drill",
      "b": "The backup job reporting green every night",
      "c": "The backup files growing in size",
      "d": "Having backups in two formats"
    }, "correctOptionId": "a"}$j$, 2),

  (v_a4, 'order_logic',
   $q$Order a backup strategy that will actually save you.$q$,
   $q$Automatic, elsewhere, rehearsed, written down.$q$,
   $j${"blocks": {
      "schedule": "Schedule automatic backups",
      "offsite": "Store a copy away from the system it protects",
      "drill": "Restore one regularly, as a drill",
      "document": "Document the restore steps for the worst day"
    }, "correctOrder": ["schedule", "offsite", "drill", "document"]}$j$, 3);

  -- --- A5 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a5, 'multiple_choice',
   $q$What does the principle of least privilege say?$q$,
   $q$It applies to people, apps and API keys alike.$q$,
   $j${"options": {
      "a": "Every account gets only the permissions its job requires, nothing more",
      "b": "Only one person should hold all the credentials",
      "c": "Passwords should be as short as possible",
      "d": "Admins should share one account to simplify auditing"
    }, "correctOptionId": "a"}$j$, 1),

  (v_a5, 'fill_blank',
   $q$Complete the two operational security basics.$q$,
   $q$One protects data in transit; the other expires.$q$,
   $j${"codeSnippet": "{{0}} encrypts the traffic between the browser and the server.\nCertificates expire: {{1}} them before they do.",
      "correctAnswers": {"0": "HTTPS", "1": "renew"},
      "availableOptions": ["HTTPS", "FTP", "renew", "delete"]}$j$, 2),

  (v_a5, 'order_logic',
   $q$Order a responsible patching workflow.$q$,
   $q$You cannot patch what you do not know you run.$q$,
   $j${"blocks": {
      "inventory": "Keep an inventory of what you run and its versions",
      "watch": "Subscribe to security advisories for those things",
      "staging": "Apply the patch in staging first",
      "rollout": "Roll it out to production"
    }, "correctOrder": ["inventory", "watch", "staging", "rollout"]}$j$, 3);

end
$$;
