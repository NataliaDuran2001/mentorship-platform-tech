-- ===========================================================================
-- Semilla: path de Backend por niveles (Basic / Intermediate / Advanced)
-- ===========================================================================
--
-- Mismo modelo que el path de Frontend (20260814000002): 3 niveles como
-- tópicos padre, 5 secciones por nivel, teoría dominante en Basic y casi
-- ausente en Advanced. 45 retos.
--
-- Ojo: borra los tópicos planos de backend, y con ellos el progreso previo de
-- ese track (cascada a user_progress).

do $$
declare
  v_basic uuid; v_inter uuid; v_adv uuid;
  v_b1 uuid; v_b2 uuid; v_b3 uuid; v_b4 uuid; v_b5 uuid;
  v_i1 uuid; v_i2 uuid; v_i3 uuid; v_i4 uuid; v_i5 uuid;
  v_a1 uuid; v_a2 uuid; v_a3 uuid; v_a4 uuid; v_a5 uuid;
begin

  delete from public.topics where track_id = 'backend';

  -- =========================================================================
  -- NIVELES
  -- =========================================================================
  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('backend', null, 'Basic',
    $q$What actually happens behind the screen: servers, data and the language every web app speaks. No prior experience needed.$q$, 1)
  returning id into v_basic;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('backend', null, 'Intermediate',
    $q$Design data that stays consistent and APIs that other developers enjoy using.$q$, 2)
  returning id into v_inter;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('backend', null, 'Advanced',
    $q$What a junior backend role is hired for: security, reliability and code you can prove works.$q$, 3)
  returning id into v_adv;

  -- =========================================================================
  -- BASIC
  -- =========================================================================
  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('backend', v_basic, 'What a Server Actually Does',
    $q$The other half of every app: where the rules live and the data survives.$q$, 1)
  returning id into v_b1;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('backend', v_basic, 'HTTP: How Machines Talk',
    $q$The request-and-response language that every web app speaks.$q$, 2)
  returning id into v_b2;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('backend', v_basic, 'Databases: Where Everything Lives',
    $q$Why apps remember things, and where they keep them.$q$, 3)
  returning id into v_b3;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('backend', v_basic, 'Your First SQL',
    $q$Ask a database questions and get exactly what you asked for.$q$, 4)
  returning id into v_b4;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('backend', v_basic, 'APIs and JSON',
    $q$How programs hand each other data without ever meeting.$q$, 5)
  returning id into v_b5;

  -- --- B1 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b1, 'theory', $q$The other half of every app$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "When you tap a button, your device rarely does the important work itself. It sends a request to a server — a computer that is always on — and waits for the answer. The backend is everything that runs on that server."},
    {"type": "list", "items": [
      "The client asks — a browser or an app sends a request.",
      "The server decides — applies the rules of the business.",
      "The database remembers — keeps the data safe between visits."
    ]},
    {"type": "paragraph", "text": "Every login, every purchase, every saved photo follows that same triangle."}
  ], "keyTakeaway": "The frontend asks; the backend decides and remembers."}
  $j$, 1),

  (v_b1, 'theory', $q$Why the rules cannot live in the browser$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Anyone can open their browser's developer tools and change what runs there. If the price check or the permission check lives only in the frontend, a curious user can simply switch it off."},
    {"type": "paragraph", "text": "That is why every rule that matters — prices, permissions, limits — is enforced on the server, where users cannot touch it. The frontend may repeat the check to be friendly, but the backend has the final word."}
  ], "keyTakeaway": "Never trust the client: every rule that matters runs on the server."}
  $j$, 2),

  (v_b1, 'multiple_choice',
   $q$Which of these jobs belongs to the backend?$q$,
   $q$Think about what must be protected from the user's own hands.$q$,
   $j${"options": {
      "a": "Checking that a user can only see their own orders",
      "b": "Choosing the color of the Buy button",
      "c": "Animating the menu when it opens",
      "d": "Rounding the corners of the product cards"
    }, "correctOptionId": "a"}$j$, 3);

  -- --- B2 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b2, 'theory', $q$Requests carry an intention$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Every message a client sends to a server uses HTTP, and every HTTP request starts with a verb that says what the client wants to do."},
    {"type": "list", "items": [
      "GET — read something, change nothing",
      "POST — create something new",
      "PUT / PATCH — update something that exists",
      "DELETE — remove it"
    ]},
    {"type": "code", "language": "http", "text": "GET /products/42\nPOST /users"},
    {"type": "paragraph", "text": "The server answers with a status code: a three-digit number that says how it went."}
  ], "keyTakeaway": "One verb, one intention."}
  $j$, 1),

  (v_b2, 'multiple_choice',
   $q$A mobile app needs to create a new account. Which request should it send?$q$,
   $q$Match the verb to the intention.$q$,
   $j${"options": {
      "a": "GET /users",
      "b": "POST /users",
      "c": "DELETE /users",
      "d": "PUT /users"
    }, "correctOptionId": "b"}$j$, 2),

  (v_b2, 'fill_blank',
   $q$Match each status code to what it tells the client.$q$,
   $q$2xx is good news, 4xx blames the request, 5xx blames the server.$q$,
   $j${"codeSnippet": "200 → {{0}}\n404 → {{1}}\n500 → {{2}}",
      "correctAnswers": {"0": "success", "1": "not found", "2": "server error"},
      "availableOptions": ["success", "not found", "server error", "redirect"]}$j$, 3);

  -- --- B3 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b3, 'theory', $q$Tables, rows and columns$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "A relational database organizes data like a very strict spreadsheet. A table holds one kind of thing — users, orders, products. Each row is one of them. Each column is one fact about it."},
    {"type": "code", "language": "text", "text": "users\n| id | name  | country |\n|----|-------|---------|\n| 1  | Ana   | BO      |\n| 2  | Luisa | BO      |"},
    {"type": "paragraph", "text": "That strictness is the point: because every row has the same shape, the database can answer questions about millions of them in milliseconds."}
  ], "keyTakeaway": "A table is one kind of thing; a row is one of them."}
  $j$, 1),

  (v_b3, 'theory', $q$Why not just save files?$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "You could store everything in text files. It works until two users save at the same time, or the app crashes halfway through writing, or you need to find one order among a million."},
    {"type": "list", "items": [
      "Concurrency — many users writing at once without corrupting each other",
      "Integrity — a half-finished save never leaves broken data behind",
      "Queries — questions answered fast, without reading everything"
    ]},
    {"type": "paragraph", "text": "Databases exist because those three problems appear in every real application, and solving them by hand is a career in itself."}
  ], "keyTakeaway": "A database is files plus every guarantee you would have to build yourself."}
  $j$, 2),

  (v_b3, 'multiple_choice',
   $q$Where should each user's saved progress live?$q$,
   $q$It has to survive closed tabs, new devices and app updates.$q$,
   $j${"options": {
      "a": "In the database, tied to the user's account",
      "b": "In the browser's memory",
      "c": "In a text file on the developer's laptop",
      "d": "Inside the frontend code"
    }, "correctOptionId": "a"}$j$, 3);

  -- --- B4 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b4, 'theory', $q$SELECT: say what you want$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "SQL is the language for asking a database questions. Its most important sentence is SELECT, and it reads almost like English."},
    {"type": "code", "language": "sql", "text": "SELECT name\nFROM users\nWHERE country = 'BO';"},
    {"type": "paragraph", "text": "SELECT names the columns you want, FROM names the table, WHERE filters the rows. You describe the result; the database figures out how to find it."}
  ], "keyTakeaway": "Say what you want, not how to find it."}
  $j$, 1),

  (v_b4, 'fill_blank',
   $q$Get the names of all users from Bolivia.$q$,
   $q$Three clauses: what, from where, under which condition.$q$,
   $j${"codeSnippet": "{{0}} name\n{{1}} users\n{{2}} country = 'BO';",
      "correctAnswers": {"0": "SELECT", "1": "FROM", "2": "WHERE"},
      "availableOptions": ["SELECT", "FROM", "WHERE", "ORDER BY"]}$j$, 2),

  (v_b4, 'order_logic',
   $q$Order the clauses of a standard SQL query.$q$,
   $q$What, from where, filtered how, sorted how.$q$,
   $j${"blocks": {
      "select": "SELECT title",
      "from": "FROM courses",
      "where": "WHERE level = 'basic'",
      "order": "ORDER BY title"
    }, "correctOrder": ["select", "from", "where", "order"]}$j$, 3);

  -- --- B5 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_b5, 'theory', $q$JSON: the common language$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "When two programs talk — your app and a server, or two servers — they need a format both understand. Today that format is JSON: plain text, readable by humans and machines alike."},
    {"type": "code", "language": "json", "text": "{\n  \"name\": \"Ana\",\n  \"skills\": [\"sql\", \"http\"]\n}"},
    {"type": "paragraph", "text": "Curly braces wrap one thing with named fields. Square brackets wrap a list. Text goes in double quotes, numbers do not. That is almost the entire language."}
  ], "keyTakeaway": "Curly braces for a thing, square brackets for a list."}
  $j$, 1),

  (v_b5, 'multiple_choice',
   $q$Your API returns a list of products. Which response shape is correct JSON?$q$,
   $q$A list of things: brackets outside, braces inside.$q$,
   $j${"options": {
      "a": "[{\"id\": 1}, {\"id\": 2}]",
      "b": "{1, 2}",
      "c": "\"id: 1, id: 2\"",
      "d": "(id=1)(id=2)"
    }, "correctOptionId": "a"}$j$, 2),

  (v_b5, 'fill_blank',
   $q$Complete the JSON so it is valid.$q$,
   $q$Field names and text values always take double quotes.$q$,
   $j${"codeSnippet": "{\n  {{0}}: \"Ana\",\n  \"age\": {{1}}\n}",
      "correctAnswers": {"0": "\"name\"", "1": "23"},
      "availableOptions": ["\"name\"", "name", "23", "\"23\""]}$j$, 3);

  -- =========================================================================
  -- INTERMEDIATE
  -- =========================================================================
  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('backend', v_inter, 'Modeling Data Well',
    $q$Keys and relationships: the difference between data and a mess.$q$, 1)
  returning id into v_i1;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('backend', v_inter, 'Queries That Answer Questions',
    $q$JOIN and GROUP BY: where SQL starts earning its keep.$q$, 2)
  returning id into v_i2;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('backend', v_inter, 'Designing a REST API',
    $q$Endpoints other developers can guess without reading the docs.$q$, 3)
  returning id into v_i3;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('backend', v_inter, 'Node.js on the Server',
    $q$The JavaScript you already know, now answering requests.$q$, 4)
  returning id into v_i4;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('backend', v_inter, 'Errors Are Part of the Job',
    $q$Real backends fail. Good ones fail clearly.$q$, 5)
  returning id into v_i5;

  -- --- I1 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i1, 'theory', $q$Primary and foreign keys$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Every row needs an identity: a primary key, usually an id column, unique in its table. And when one thing belongs to another — an order belongs to a user — the child row stores the parent's id. That stored reference is a foreign key."},
    {"type": "code", "language": "sql", "text": "orders\n| id | user_id | total |\n|----|---------|-------|\n| 7  | 1       | 120   |"},
    {"type": "paragraph", "text": "The database enforces it: you cannot create an order for a user that does not exist, and that single rule prevents entire categories of bugs."}
  ], "keyTakeaway": "Every row needs an identity; every relationship needs a key."}
  $j$, 1),

  (v_i1, 'fill_blank',
   $q$Declare that every order belongs to an existing user.$q$,
   $q$The foreign key points at the parent table and its key column.$q$,
   $j${"codeSnippet": "create table orders (\n  id uuid primary key,\n  user_id uuid references {{0}} ({{1}})\n);",
      "correctAnswers": {"0": "users", "1": "id"},
      "availableOptions": ["users", "orders", "id", "name"]}$j$, 2),

  (v_i1, 'order_logic',
   $q$Order the steps to model a new feature's data.$q$,
   $q$Things first, identity second, relationships third.$q$,
   $j${"blocks": {
      "entities": "Identify the things: users, courses, enrollments",
      "keys": "Give each table a primary key",
      "relations": "Link them with foreign keys",
      "constraints": "Add the rules the data must never break"
    }, "correctOrder": ["entities", "keys", "relations", "constraints"]}$j$, 3);

  -- --- I2 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i2, 'theory', $q$JOIN: two tables, one answer$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Data lives split across tables, but questions rarely respect that split. Show every order with the name of its buyer needs both tables at once. JOIN stitches them together through the foreign key."},
    {"type": "code", "language": "sql", "text": "SELECT o.total, u.name\nFROM orders o\nJOIN users u ON o.user_id = u.id;"},
    {"type": "paragraph", "text": "The ON clause says how the rows match. Get that condition wrong and you do not get an error — you get wrong data that looks right, which is worse."}
  ], "keyTakeaway": "JOIN reunites what good modeling split apart."}
  $j$, 1),

  (v_i2, 'fill_blank',
   $q$Show each order's total with the buyer's name.$q$,
   $q$One keyword stitches the tables, the other says how they match.$q$,
   $j${"codeSnippet": "SELECT o.total, u.name\nFROM orders o\n{{0}} users u {{1}} o.user_id = u.id;",
      "correctAnswers": {"0": "JOIN", "1": "ON"},
      "availableOptions": ["JOIN", "ON", "WHERE", "WITH"]}$j$, 2),

  (v_i2, 'multiple_choice',
   $q$You need the number of orders per user. Which clause groups the rows?$q$,
   $q$Counting per something is the giveaway.$q$,
   $j${"options": {
      "a": "GROUP BY user_id",
      "b": "WHERE user_id",
      "c": "ORDER BY user_id",
      "d": "LIMIT user_id"
    }, "correctOptionId": "a"}$j$, 3);

  -- --- I3 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i3, 'theory', $q$Resources, not actions$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "A REST API names things — resources — with URLs, and acts on them with HTTP verbs. The URL is a noun; the verb is the action. That is the entire convention, and following it is what makes an API guessable."},
    {"type": "code", "language": "http", "text": "GET    /products       → list them\nGET    /products/42    → one of them\nPOST   /products       → create one\nDELETE /products/42    → remove it"},
    {"type": "paragraph", "text": "The moment a URL contains a verb — /getProduct, /delete_user — the convention is broken and every consumer has to memorize your API instead of guessing it."}
  ], "keyTakeaway": "URLs name things; verbs act on them."}
  $j$, 1),

  (v_i3, 'multiple_choice',
   $q$Which endpoint follows REST conventions for reading one product?$q$,
   $q$Noun in the URL, intention in the verb.$q$,
   $j${"options": {
      "a": "GET /products/42",
      "b": "GET /getProduct?id=42",
      "c": "POST /products/fetch",
      "d": "GET /product_get/42"
    }, "correctOptionId": "a"}$j$, 2),

  (v_i3, 'order_logic',
   $q$Order what a well-built endpoint does with a request.$q$,
   $q$Never touch the database with data you have not checked.$q$,
   $j${"blocks": {
      "receive": "Receive the request",
      "validate": "Validate the input",
      "rules": "Apply the business rules",
      "db": "Read or write the database",
      "respond": "Respond with the right status code"
    }, "correctOrder": ["receive", "validate", "rules", "db", "respond"]}$j$, 3);

  -- --- I4 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i4, 'theory', $q$One language, both sides$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Node.js runs JavaScript outside the browser, which means the language you learned for the frontend also writes servers. With a small framework like Express, an endpoint is a few lines:"},
    {"type": "code", "language": "javascript", "text": "app.get('/products', (req, res) => {\n  res.json(products);\n});"},
    {"type": "paragraph", "text": "req carries everything about the request; res is how you answer. npm — Node's package manager — gives you thousands of libraries so you never start from zero."}
  ], "keyTakeaway": "A server is a function that turns requests into responses."}
  $j$, 1),

  (v_i4, 'fill_blank',
   $q$Answer GET requests to /courses with the list in JSON.$q$,
   $q$The verb picks the method; the response object does the answering.$q$,
   $j${"codeSnippet": "app.{{0}}('/courses', (req, {{1}}) => {\n  res.json(courses);\n});",
      "correctAnswers": {"0": "get", "1": "res"},
      "availableOptions": ["get", "post", "res", "req"]}$j$, 2),

  (v_i4, 'order_logic',
   $q$Order the steps to stand up a Node.js API from scratch.$q$,
   $q$Dependencies before code, code before listening.$q$,
   $j${"blocks": {
      "init": "npm init — create the project",
      "install": "npm install express",
      "write": "Write the endpoints",
      "listen": "app.listen(3000) — start answering"
    }, "correctOrder": ["init", "install", "write", "listen"]}$j$, 3);

  -- --- I5 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_i5, 'theory', $q$4xx or 5xx: whose fault is it?$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "When something goes wrong, the status code assigns the blame. A 4xx says the request was the problem: asked for something that does not exist (404), sent invalid data (400), lacked permission (403). A 5xx says the server failed: your code threw, the database was down."},
    {"type": "paragraph", "text": "The distinction is not cosmetic. Clients retry 5xx errors and fix-and-resend 4xx ones; monitoring pages you for 5xx spikes at 3 AM and ignores 4xx noise. Lie with your codes and both behaviors break."}
  ], "keyTakeaway": "A 4xx blames the request; a 5xx blames you."}
  $j$, 1),

  (v_i5, 'multiple_choice',
   $q$A user asks for an order id that does not exist. What should the API return?$q$,
   $q$Nothing crashed — the thing just is not there.$q$,
   $j${"options": {
      "a": "404 with a clear message",
      "b": "500, since the lookup failed",
      "c": "200 with an empty body",
      "d": "301 redirecting to the home page"
    }, "correctOptionId": "a"}$j$, 2),

  (v_i5, 'fill_blank',
   $q$Handle the failure without crashing the server.$q$,
   $q$Catch it, log it for yourselves, answer honestly to the client.$q$,
   $j${"codeSnippet": "try {\n  await saveOrder(order);\n} {{0}} (err) {\n  console.{{1}}(err);\n  res.status(500).json({ error: 'Could not save the order' });\n}",
      "correctAnswers": {"0": "catch", "1": "error"},
      "availableOptions": ["catch", "finally", "error", "print"]}$j$, 3);

  -- =========================================================================
  -- ADVANCED
  -- =========================================================================
  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('backend', v_adv, 'Passwords and Authentication',
    $q$The one thing you are never allowed to get wrong.$q$, 1)
  returning id into v_a1;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('backend', v_adv, 'Protecting Your API',
    $q$Injection and validation: the attacks every junior is tested on.$q$, 2)
  returning id into v_a2;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('backend', v_adv, 'Testing Your Backend',
    $q$Code you can prove works, and keep proving after every change.$q$, 3)
  returning id into v_a3;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('backend', v_adv, 'Performance and Indexes',
    $q$Why the query is slow, and the one-line fix that is usually right.$q$, 4)
  returning id into v_a4;

  insert into public.topics (track_id, parent_id, title, description, sort_order)
  values ('backend', v_adv, 'Deploying and Configuration',
    $q$Secrets, environments and getting code to production without leaking either.$q$, 5)
  returning id into v_a5;

  -- --- A1 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a1, 'theory', $q$Never store the password$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "If your database is ever leaked — and you must plan as if it will be — the passwords in it must be useless. That is why passwords are never stored, not even encrypted. They are hashed: run through a one-way function that cannot be reversed."},
    {"type": "paragraph", "text": "At login you hash what the user typed and compare hashes. You verify the password without ever keeping it. Use a slow, salted algorithm built for this — bcrypt is the classic choice — never a fast one like MD5 or SHA-1."},
    {"type": "paragraph", "text": "After login, the user carries a token that proves who they are on every request, so the password travels exactly once."}
  ], "keyTakeaway": "Store proof of the password, never the password."}
  $j$, 1),

  (v_a1, 'multiple_choice',
   $q$How should the password column in your users table look?$q$,
   $q$Assume the table leaks tomorrow. Which option stays harmless?$q$,
   $j${"options": {
      "a": "A bcrypt hash, salted, one per user",
      "b": "The password in plain text",
      "c": "The password encoded in base64",
      "d": "The password encrypted, with the key stored next to the table"
    }, "correctOptionId": "a"}$j$, 2),

  (v_a1, 'fill_blank',
   $q$Send the session token on an authenticated request.$q$,
   $q$The standard scheme name goes before the token.$q$,
   $j${"codeSnippet": "GET /orders\nAuthorization: {{0}} {{1}}",
      "correctAnswers": {"0": "Bearer", "1": "<token>"},
      "availableOptions": ["Bearer", "Basic", "<token>", "<password>"]}$j$, 3);

  -- --- A2 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a2, 'multiple_choice',
   $q$This code builds a query by gluing user text into the SQL. What attack does it invite?$q$,
   $q$db.query("SELECT * FROM users WHERE email = '" + email + "'")$q$,
   $j${"options": {
      "a": "SQL injection — the user's text becomes part of the query itself",
      "b": "A denial of service",
      "c": "Cross-site scripting",
      "d": "Nothing, as long as the column is indexed"
    }, "correctOptionId": "a"}$j$, 1),

  (v_a2, 'fill_blank',
   $q$Rewrite it so user input can never become SQL.$q$,
   $q$Parameters keep data as data.$q$,
   $j${"codeSnippet": "db.query(\n  'SELECT * FROM users WHERE email = {{0}}',\n  [{{1}}]\n);",
      "correctAnswers": {"0": "$1", "1": "email"},
      "availableOptions": ["$1", "' + email + '", "email", "query"]}$j$, 2),

  (v_a2, 'order_logic',
   $q$Order the defenses a request passes through before touching data.$q$,
   $q$Reject early, execute safely, expose the minimum.$q$,
   $j${"blocks": {
      "shape": "Validate the shape and types of the input",
      "reject": "Reject anything invalid with a 400",
      "params": "Query only with parameters, never concatenation",
      "least": "Run as a database user with the minimum permissions"
    }, "correctOrder": ["shape", "reject", "params", "least"]}$j$, 3);

  -- --- A3 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a3, 'order_logic',
   $q$Order the three moments of every test.$q$,
   $q$The pattern is called Arrange, Act, Assert.$q$,
   $j${"blocks": {
      "arrange": "Arrange — prepare the data and the scenario",
      "act": "Act — call the thing being tested",
      "assert": "Assert — check the result is exactly what you expected"
    }, "correctOrder": ["arrange", "act", "assert"]}$j$, 1),

  (v_a3, 'multiple_choice',
   $q$Which of these makes a test trustworthy?$q$,
   $q$Think about what lets a test run a thousand times in CI.$q$,
   $j${"options": {
      "a": "It tests one behavior and passes or fails the same way every run",
      "b": "It depends on the production database being up",
      "c": "It checks many unrelated things at once, to save files",
      "d": "It passes when run alone but not with the others"
    }, "correctOptionId": "a"}$j$, 2),

  (v_a3, 'fill_blank',
   $q$Assert that the calculated total is exactly 113.$q$,
   $q$State the expectation; the framework does the comparing.$q$,
   $j${"codeSnippet": "const total = addTax(100);\n{{0}}(total).{{1}}(113);",
      "correctAnswers": {"0": "expect", "1": "toBe"},
      "availableOptions": ["expect", "assert", "toBe", "isEqual"]}$j$, 3);

  -- --- A4 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a4, 'multiple_choice',
   $q$A query filtering users by email takes 3 seconds on a million rows. The usual first fix?$q$,
   $q$Without it, the database reads every single row to find one.$q$,
   $j${"options": {
      "a": "Add an index on the email column",
      "b": "Buy a bigger server",
      "c": "Cache every query in memory",
      "d": "Split the table in two"
    }, "correctOptionId": "a"}$j$, 1),

  (v_a4, 'fill_blank',
   $q$Create the index that makes the email lookup instant.$q$,
   $q$Name the structure, then the table and column it covers.$q$,
   $j${"codeSnippet": "create {{0}} users_email_idx on users ({{1}});",
      "correctAnswers": {"0": "index", "1": "email"},
      "availableOptions": ["index", "key", "email", "id"]}$j$, 2),

  (v_a4, 'order_logic',
   $q$Order a professional response to "the app is slow".$q$,
   $q$Measure before touching anything, and after touching it too.$q$,
   $j${"blocks": {
      "measure": "Measure — find where the time actually goes",
      "identify": "Identify the slowest query",
      "explain": "Read the query plan to see why it is slow",
      "fix": "Apply the fix, usually an index",
      "verify": "Measure again to prove it worked"
    }, "correctOrder": ["measure", "identify", "explain", "fix", "verify"]}$j$, 3);

  -- --- A5 -----------------------------------------------------------------
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_a5, 'theory', $q$Secrets are not code$q$, null, $j$
  {"blocks": [
    {"type": "paragraph", "text": "Your code is visible to your whole team and lives forever in git history. Database passwords and API keys must not — one leaked key can cost a company its data or its money."},
    {"type": "paragraph", "text": "The rule: configuration lives in environment variables, set on the server, read by the code, committed nowhere. The same code then runs in development, staging and production, each with its own values."},
    {"type": "code", "language": "javascript", "text": "const dbUrl = process.env.DATABASE_URL;"},
    {"type": "paragraph", "text": "If a secret ever lands in git, rotating it — generating a new one — is the only real fix. Deleting the commit does not un-leak it."}
  ], "keyTakeaway": "Code is shared; secrets are not code."}
  $j$, 1),

  (v_a5, 'multiple_choice',
   $q$Where does the production API key live?$q$,
   $q$It has to be readable by the app and by nothing else.$q$,
   $j${"options": {
      "a": "In an environment variable on the server",
      "b": "Committed in a config.js for convenience",
      "c": "In the frontend, so the app can use it directly",
      "d": "In the README, so the team can find it"
    }, "correctOptionId": "a"}$j$, 2),

  (v_a5, 'fill_blank',
   $q$Read the secret from the environment instead of hardcoding it.$q$,
   $q$Node exposes them on one well-known object.$q$,
   $j${"codeSnippet": "const apiKey = process.{{0}}.{{1}};",
      "correctAnswers": {"0": "env", "1": "API_KEY"},
      "availableOptions": ["env", "config", "API_KEY", "apiKey"]}$j$, 3);

end
$$;
