// Supabase Edge Function: translate-content
//
// Translates topics/lab_challenges content (sembrado únicamente en inglés)
// into Spanish via Kimi3, and caches the result in `content_translations` —
// a table shared across all users (not per-user like `ai_profile_insights`),
// since the same topic/theory challenge translates to the same Spanish text
// for everyone.
//
// English is never generated here: the client already has the English rows
// from `topics`/`lab_challenges` and only calls this function when the
// requested language is not English.
//
// `lab_challenges` rows of every challenge type are translatable, but only
// their prose: exercises never expose the graded answer to the model.
// multiple_choice/order_logic translate their option/block text by value,
// keyed by the same stable id the client already has (the id is never sent
// back, so the correct answer/order can never shift). fill_blank only
// translates its question/description — its codeSnippet, correctAnswers and
// availableOptions are literal code, not language, and are never sent to
// the model.
//
// Endpoint: POST /functions/v1/translate-content
// Auth: Bearer <supabase_anon_key> (user must be authenticated)
//
// Request body:
// {
//   "items": [{ "sourceTable": "topics" | "lab_challenges", "sourceId": "<uuid>" }, ...],
//   "language": "es"
// }
//
// Response body:
// {
//   "translations": [{ "sourceId": "<uuid>", "content": { ... } }, ...]
// }
// Items that fail to translate (source not found, not a theory challenge,
// Kimi error) are silently omitted: the client falls back to the English
// content it already has for that id.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const KIMI_API_URL = 'https://api.moonshot.ai/v1/chat/completions';
const KIMI_MODEL = 'kimi-k3';

const MAX_ITEMS = 100;

const TOPIC_SYSTEM_PROMPT = `You are translating educational content for a mentorship platform that helps women in Bolivia entering the tech industry.

Translate the given topic title and description from English to natural, warm Latin American Spanish, informal "tú" register, matching a beginner-friendly educational tone. Keep the same meaning and length in spirit — do not summarize, do not add content.

Format the output strictly as a JSON object:
{
  "title": "...",
  "description": "..." | null
}
Do not return any markdown formatting or surrounding text.`;

const THEORY_SYSTEM_PROMPT = `You are translating an interactive learning-lab explanation ("theory" step) for a mentorship platform that helps women in Bolivia entering the tech industry.

Translate the "question" (the explanation's title), every "text"/"items" string inside "blocks" whose type is "paragraph" or "list", and "keyTakeaway" from English to natural, warm Latin American Spanish, informal "tú" register, beginner-friendly tone.

Blocks whose type is "code" must be copied VERBATIM in their "text" field — never translate code syntax, identifiers, or sample output. Their "language" field must also be copied verbatim.

Preserve the exact JSON structure and keys you were given — same number of blocks, same order, same "type" per block.

Format the output strictly as a JSON object:
{
  "question": "...",
  "blocks": [ ... same shape as input ... ],
  "keyTakeaway": "..." | null
}
Do not return any markdown formatting or surrounding text.`;

// Shared by multiple_choice and order_logic: both are a question/description
// plus a map of stable id -> displayed text. The id is never sent back, so
// translating the text can never change which id is the correct answer.
const EXERCISE_WITH_ITEMS_SYSTEM_PROMPT = `You are translating an interactive exercise for a mentorship platform that helps women in Bolivia entering the tech industry. This is a graded exercise, not an explanation — you are only translating its wording, never solving it or changing what it asks.

Translate "question", "description" (may be null), and every value in the "items" object from English to natural, warm Latin American Spanish, informal "tú" register, beginner-friendly tone.

CRITICAL — never translate technical substance, only surrounding prose:
- Never translate HTML/CSS/JS tag names, attribute names, property names, function/variable names, file extensions, or any code fragment (e.g. "<header>", "padding", "display: flex", "className").
- If an "items" value is ENTIRELY a technical term or code (e.g. "Padding", "<nav>"), copy it verbatim, unchanged.
- If an "items" value mixes a technical term with a prose explanation (e.g. "<header> — site title"), keep the technical part exactly as given and translate only the prose part.
- Never invent, remove, or reorder items — return exactly the same keys you were given, each with its translated (or verbatim, per the rules above) value.

Format the output strictly as a JSON object:
{
  "question": "...",
  "description": "..." | null,
  "items": { "same-keys-as-given": "..." }
}
Do not return any markdown formatting or surrounding text.`;

// fill_blank's codeSnippet/correctAnswers/availableOptions are literal code,
// never language — only question/description are ever translated.
const FILL_BLANK_SYSTEM_PROMPT = `You are translating an interactive fill-in-the-blank coding exercise for a mentorship platform that helps women in Bolivia entering the tech industry. This is a graded exercise, not an explanation.

Translate only "question" and "description" (may be null) from English to natural, warm Latin American Spanish, informal "tú" register, beginner-friendly tone. You are not given the code snippet or the answers — do not invent them, translate only the two fields you received.

Never translate technical terms, tag names, or code fragments that may appear inside "question"/"description" — copy those verbatim and translate only the surrounding prose.

Format the output strictly as a JSON object:
{
  "question": "...",
  "description": "..." | null
}
Do not return any markdown formatting or surrounding text.`;

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };
}

async function callKimi(kimiKey: string, systemPrompt: string, userPrompt: string) {
  const response = await fetch(KIMI_API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${kimiKey}`,
    },
    body: JSON.stringify({
      model: KIMI_MODEL,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ],
      response_format: { type: 'json_object' },
      // kimi-k3 only accepts its default temperature (1); sending any other
      // value gets a 400 invalid_request_error back.
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error('Kimi3 API error (translate-content):', response.status, errorText);
    return null;
  }

  const data = await response.json();
  const rawContent = data.choices?.[0]?.message?.content;
  if (!rawContent) return null;

  try {
    return JSON.parse(rawContent);
  } catch (e) {
    console.error('translate-content: could not parse Kimi response as JSON', e);
    return null;
  }
}

async function translateTopic(kimiKey: string, source: { title: string; description: string | null }) {
  const userPrompt = `Topic to translate:\n{"title": ${JSON.stringify(source.title)}, "description": ${JSON.stringify(source.description)}}`;
  const result = await callKimi(kimiKey, TOPIC_SYSTEM_PROMPT, userPrompt);
  if (!result || typeof result.title !== 'string') return null;
  return { title: result.title, description: (result.description ?? null) as string | null };
}

async function translateTheory(
  kimiKey: string,
  source: { question: string; blocks: unknown[]; keyTakeaway: string | null },
) {
  const userPrompt = `Theory step to translate:\n${JSON.stringify({
    question: source.question,
    blocks: source.blocks,
    keyTakeaway: source.keyTakeaway,
  })}`;
  const result = await callKimi(kimiKey, THEORY_SYSTEM_PROMPT, userPrompt);
  if (!result || typeof result.question !== 'string' || !Array.isArray(result.blocks)) return null;
  return {
    question: result.question,
    blocks: result.blocks,
    keyTakeaway: (result.keyTakeaway ?? null) as string | null,
  };
}

/// multiple_choice (`items` = options) and order_logic (`items` = blocks)
/// share this: a question/description plus an id -> text map, translated
/// without ever exposing which id is the graded answer.
async function translateExerciseWithItems(
  kimiKey: string,
  source: { question: string; description: string | null; items: Record<string, string> },
) {
  const userPrompt = `Exercise to translate:\n${JSON.stringify({
    question: source.question,
    description: source.description,
    items: source.items,
  })}`;
  const result = await callKimi(kimiKey, EXERCISE_WITH_ITEMS_SYSTEM_PROMPT, userPrompt);
  if (!result || typeof result.question !== 'string' || typeof result.items !== 'object' || result.items === null) {
    return null;
  }
  return {
    question: result.question,
    description: (result.description ?? null) as string | null,
    items: result.items as Record<string, string>,
  };
}

async function translateFillBlank(
  kimiKey: string,
  source: { question: string; description: string | null },
) {
  const userPrompt = `Exercise to translate:\n${JSON.stringify({
    question: source.question,
    description: source.description,
  })}`;
  const result = await callKimi(kimiKey, FILL_BLANK_SYSTEM_PROMPT, userPrompt);
  if (!result || typeof result.question !== 'string') return null;
  return {
    question: result.question,
    description: (result.description ?? null) as string | null,
  };
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders() });
  }

  try {
    // --- Auth check ---
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return Response.json({ error: 'Missing authorization header' }, { status: 401 });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return Response.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // --- Parse body ---
    const body = await req.json();
    const { items, language } = body as {
      items?: { sourceTable: string; sourceId: string }[];
      language?: string;
    };

    if (language !== 'es') {
      return Response.json(
        { error: 'Only "es" is translatable; English is served from source' },
        { status: 400 },
      );
    }
    if (!Array.isArray(items) || items.length === 0) {
      return Response.json({ error: 'items is required' }, { status: 400 });
    }
    if (items.length > MAX_ITEMS) {
      return Response.json({ error: `items exceeds the ${MAX_ITEMS} limit` }, { status: 400 });
    }
    const validItems = items.filter(
      (item) =>
        (item.sourceTable === 'topics' || item.sourceTable === 'lab_challenges') &&
        typeof item.sourceId === 'string' &&
        item.sourceId.length > 0,
    );
    if (validItems.length === 0) {
      return Response.json({ translations: [] }, { headers: corsHeaders() });
    }

    const serviceSupabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // --- Check cache ---
    const idsByTable = {
      topics: validItems.filter((i) => i.sourceTable === 'topics').map((i) => i.sourceId),
      lab_challenges: validItems
        .filter((i) => i.sourceTable === 'lab_challenges')
        .map((i) => i.sourceId),
    };

    const translations = new Map<string, unknown>();
    const missing: { sourceTable: 'topics' | 'lab_challenges'; sourceId: string }[] = [];

    for (const sourceTable of ['topics', 'lab_challenges'] as const) {
      const ids = idsByTable[sourceTable];
      if (ids.length === 0) continue;

      const { data: cached, error: cacheError } = await serviceSupabase
        .from('content_translations')
        .select('source_id, content')
        .eq('source_table', sourceTable)
        .eq('language', 'es')
        .in('source_id', ids);

      const cachedIds = new Set<string>();
      if (!cacheError && cached) {
        for (const row of cached) {
          translations.set(row.source_id, row.content);
          cachedIds.add(row.source_id);
        }
      }
      for (const id of ids) {
        if (!cachedIds.has(id)) missing.push({ sourceTable, sourceId: id });
      }
    }

    // --- Translate what is missing ---
    if (missing.length > 0) {
      const kimiKey = Deno.env.get('KIMI_API_KEY');
      if (!kimiKey) {
        // Degrade gracefully: return whatever was cached, nothing more.
        return Response.json(
          {
            translations: Array.from(translations.entries()).map(([sourceId, content]) => ({
              sourceId,
              content,
            })),
          },
          { headers: corsHeaders() },
        );
      }

      const missingTopicIds = missing.filter((m) => m.sourceTable === 'topics').map((m) => m.sourceId);
      const missingChallengeIds = missing
        .filter((m) => m.sourceTable === 'lab_challenges')
        .map((m) => m.sourceId);

      const [topicRows, challengeRows] = await Promise.all([
        missingTopicIds.length > 0
          ? serviceSupabase
              .from('topics')
              .select('id, title, description')
              .in('id', missingTopicIds)
          : Promise.resolve({ data: [], error: null }),
        missingChallengeIds.length > 0
          ? serviceSupabase
              .from('lab_challenges')
              .select('id, question, description, content, challenge_type')
              .in('id', missingChallengeIds)
          : Promise.resolve({ data: [], error: null }),
      ]);

      const rowsToInsert: {
        source_table: string;
        source_id: string;
        language: string;
        content: unknown;
        model: string;
      }[] = [];

      await Promise.all([
        ...(topicRows.data ?? []).map(async (row: { id: string; title: string; description: string | null }) => {
          const translated = await translateTopic(kimiKey, { title: row.title, description: row.description });
          if (!translated) return;
          translations.set(row.id, translated);
          rowsToInsert.push({
            source_table: 'topics',
            source_id: row.id,
            language: 'es',
            content: translated,
            model: KIMI_MODEL,
          });
        }),
        ...(challengeRows.data ?? []).map(async (row: {
          id: string;
          question: string;
          description: string | null;
          challenge_type: string;
          content: {
            blocks?: unknown[];
            keyTakeaway?: string | null;
            options?: Record<string, string>;
          };
        }) => {
          let translated: unknown;
          switch (row.challenge_type) {
            case 'theory':
              translated = await translateTheory(kimiKey, {
                question: row.question,
                blocks: row.content?.blocks ?? [],
                keyTakeaway: row.content?.keyTakeaway ?? null,
              });
              break;
            case 'multiple_choice':
              translated = await translateExerciseWithItems(kimiKey, {
                question: row.question,
                description: row.description,
                items: row.content?.options ?? {},
              });
              break;
            case 'order_logic':
              translated = await translateExerciseWithItems(kimiKey, {
                question: row.question,
                description: row.description,
                items: (row.content as { blocks?: Record<string, string> })?.blocks ?? {},
              });
              break;
            case 'fill_blank':
              translated = await translateFillBlank(kimiKey, {
                question: row.question,
                description: row.description,
              });
              break;
            default:
              translated = null;
          }
          if (!translated) return;
          translations.set(row.id, translated);
          rowsToInsert.push({
            source_table: 'lab_challenges',
            source_id: row.id,
            language: 'es',
            content: translated,
            model: KIMI_MODEL,
          });
        }),
      ]);

      if (rowsToInsert.length > 0) {
        await serviceSupabase
          .from('content_translations')
          .upsert(rowsToInsert, { onConflict: 'source_table,source_id,language' });
      }
    }

    return Response.json(
      {
        translations: Array.from(translations.entries()).map(([sourceId, content]) => ({
          sourceId,
          content,
        })),
      },
      { headers: corsHeaders() },
    );
  } catch (e) {
    console.error('translate-content error:', e);
    return Response.json({ error: 'Internal server error' }, { status: 500 });
  }
});
