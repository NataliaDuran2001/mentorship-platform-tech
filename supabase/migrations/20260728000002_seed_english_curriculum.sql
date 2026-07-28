-- ===========================================================================
-- Semilla: Currículum real en inglés (Topics + Labs)
-- ===========================================================================

do $$
declare
  -- Frontend
  v_fe_html uuid;
  v_fe_css uuid;
  v_fe_js uuid;
  -- Backend
  v_be_node uuid;
  v_be_sql uuid;
  v_be_rest uuid;
  -- Infra
  v_in_docker uuid;
  v_in_cicd uuid;
  v_in_cloud uuid;
begin
  -- Limpiar la tabla topics (y por cascada lab_challenges) de placeholders
  delete from public.topics;

  -- =========================================================================
  -- FRONTEND TRACK
  -- =========================================================================
  insert into public.topics (track_id, title, description, sort_order)
  values ('frontend', 'HTML Fundamentals', 'Learn the standard markup language for documents designed to be displayed in a web browser.', 1)
  returning id into v_fe_html;

  insert into public.topics (track_id, title, description, sort_order)
  values ('frontend', 'CSS Styling', 'Master the style sheet language used for describing the presentation of a document written in HTML.', 2)
  returning id into v_fe_css;

  insert into public.topics (track_id, title, description, sort_order)
  values ('frontend', 'JavaScript Basics', 'Understand the programming language that enables interactive web pages.', 3)
  returning id into v_fe_js;

  -- Labs para Frontend
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_fe_html, 'multiple_choice', 'Which HTML tag is used for the largest heading?', 'HTML provides six levels of headings.', 
   '{"options": {"h1": "<h1>", "head": "<heading>", "h6": "<h6>", "title": "<title>"}, "correctOptionId": "h1"}', 1),
  (v_fe_html, 'fill_blank', 'Complete the syntax to create a paragraph.', 'Use the standard paragraph tag.',
   '{"codeSnippet": "{{0}}Hello World{{1}}", "correctAnswers": {"0": "<p>", "1": "</p>"}, "availableOptions": ["<p>", "</p>", "<div>", "</div>"]}', 2);

  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_fe_css, 'fill_blank', 'Set the text color to red.', 'Use the color property.',
   '{"codeSnippet": "p {\n  {{0}}: red;\n}", "correctAnswers": {"0": "color"}, "availableOptions": ["color", "text-color", "background", "paint"]}', 1),
  (v_fe_css, 'order_logic', 'Order the CSS Box Model layers from inside out.', 'Think about how space is distributed around an element.',
   '{"blocks": {"content": "Content", "padding": "Padding", "border": "Border", "margin": "Margin"}, "correctOrder": ["content", "padding", "border", "margin"]}', 2);

  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_fe_js, 'multiple_choice', 'Which keyword is used to declare a variable that cannot be reassigned?', 'Choose the correct declaration keyword introduced in ES6.',
   '{"options": {"var": "var", "let": "let", "const": "const", "static": "static"}, "correctOptionId": "const"}', 1);

  -- =========================================================================
  -- BACKEND TRACK
  -- =========================================================================
  insert into public.topics (track_id, title, description, sort_order)
  values ('backend', 'Node.js Basics', 'Introduction to the V8 JavaScript runtime built for server-side programming.', 1)
  returning id into v_be_node;

  insert into public.topics (track_id, title, description, sort_order)
  values ('backend', 'SQL Databases', 'Learn how to store, manipulate and retrieve data in databases using SQL.', 2)
  returning id into v_be_sql;

  insert into public.topics (track_id, title, description, sort_order)
  values ('backend', 'REST APIs', 'Design and implement Representational State Transfer APIs.', 3)
  returning id into v_be_rest;

  -- Labs para Backend
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_be_node, 'fill_blank', 'Import the HTTP module in Node.js using CommonJS.', 'Use the built-in require function.',
   '{"codeSnippet": "const http = {{0}}({{1}});", "correctAnswers": {"0": "require", "1": "''http''"}, "availableOptions": ["require", "import", "''http''", "\"http\""]}', 1);

  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_be_sql, 'multiple_choice', 'Which SQL statement is used to extract data from a database?', 'Choose the fundamental query command.',
   '{"options": {"get": "GET", "extract": "EXTRACT", "select": "SELECT", "fetch": "FETCH"}, "correctOptionId": "select"}', 1),
  (v_be_sql, 'order_logic', 'Order the components of a standard SQL SELECT query.', 'Think about the logical order of clauses.',
   '{"blocks": {"select": "SELECT column_name", "from": "FROM table_name", "where": "WHERE condition", "orderby": "ORDER BY column_name"}, "correctOrder": ["select", "from", "where", "orderby"]}', 2);

  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_be_rest, 'multiple_choice', 'Which HTTP method is typically used to create a new resource?', 'REST relies on standard HTTP methods.',
   '{"options": {"get": "GET", "post": "POST", "put": "PUT", "delete": "DELETE"}, "correctOptionId": "post"}', 1);

  -- =========================================================================
  -- INFRASTRUCTURE TRACK
  -- =========================================================================
  insert into public.topics (track_id, title, description, sort_order)
  values ('infrastructure', 'Docker Containers', 'Learn how to package applications and their dependencies into standardized units.', 1)
  returning id into v_in_docker;

  insert into public.topics (track_id, title, description, sort_order)
  values ('infrastructure', 'CI/CD Pipelines', 'Automate the integration and deployment of code changes.', 2)
  returning id into v_in_cicd;

  insert into public.topics (track_id, title, description, sort_order)
  values ('infrastructure', 'Cloud Basics', 'Introduction to core cloud computing concepts and providers.', 3)
  returning id into v_in_cloud;

  -- Labs para Infrastructure
  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_in_docker, 'order_logic', 'Order the commands for a basic Node.js Dockerfile.', 'Follow the typical steps to containerize an app.',
   '{"blocks": {"from": "FROM node:18-alpine", "copy": "COPY . .", "run": "RUN npm install", "cmd": "CMD [\"npm\", \"start\"]"}, "correctOrder": ["from", "copy", "run", "cmd"]}', 1);

  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_in_cicd, 'multiple_choice', 'What does the "CI" in CI/CD stand for?', 'The practice of automating code merges.',
   '{"options": {"continuous_integration": "Continuous Integration", "code_injection": "Code Injection", "custom_infrastructure": "Custom Infrastructure"}, "correctOptionId": "continuous_integration"}', 1);

  insert into public.lab_challenges (topic_id, challenge_type, question, description, content, sort_order)
  values
  (v_in_cloud, 'fill_blank', 'Complete the AWS S3 bucket concept.', 'S3 is an object storage service.',
   '{"codeSnippet": "Amazon S3 stores data as {{0}} within resources called {{1}}.", "correctAnswers": {"0": "objects", "1": "buckets"}, "availableOptions": ["objects", "files", "buckets", "folders"]}', 1);

end
$$;
