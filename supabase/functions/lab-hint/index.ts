// Supabase Edge Function: lab-hint
//
// Receives context about the current lab challenge question, the challenge type,
// the number of failed attempts, and the user profile context, and calls Kimi3
// to generate a helpful Socratic hint without giving away the answer.
//
// Endpoint: POST /functions/v1/lab-hint
// Auth: Bearer <supabase_anon_key> (user must be authenticated)
//
// Request body:
// {
//   "challengeQuestion": string,
//   "challengeType": "multiple_choice" | "fill_blank" | "order_logic",
//   "attemptCount": number,
//   "userContext": string | null,
//   "language": "en" | "es" (optional, default "en")
// }
//
// Response body:
// {
//   "hint": "Try checking..."
// }

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const KIMI_API_URL = 'https://api.moonshot.ai/v1/chat/completions';
const KIMI_MODEL = 'kimi-k3';

const SYSTEM_PROMPT = `You are a patient and expert Socratic coding tutor.
Your task is to generate a helpful hint for a student struggling with an interactive challenge.

CRITICAL RULES:
1. NEVER reveal the correct answer or show the correct code snippet directly. Doing so breaks learning!
2. Keep your hint brief (1 to 2 sentences max).
3. Use a Socratic approach: guide them with a question or point their attention to a concept (e.g. "Think about how space is distributed around an element in the box model").
4. Adapt the hint's directness based on the attempt count:
   - Attempt 1: Very conceptual, pointing to the general topic.
   - Attempt 2: Slightly more specific, pointing to a key property or tag.
   - Attempt 3+: Specific tip on where they might have made a typo or logical mistake, but still no direct answer.
5. Write it in the language requested at the end of the challenge context below.
6. Avoid unexplained technical jargon; write as if explaining to someone new to tech. If a technical term is unavoidable, explain it in plain words.

Format the output strictly as a JSON object:
{
  "hint": "..."
}
Do not return any markdown formatting or surrounding text.`;

function buildUserPrompt(
  challengeQuestion: string,
  challengeType: string,
  attemptCount: number,
  userContext: string | null,
  languageName: string,
): string {
  return `
Challenge context:
- Type: ${challengeType}
- Question: "${challengeQuestion}"
- Attempt Count: ${attemptCount} (this is the student's attempt #${attemptCount})
- Student Level: ${userContext ?? 'not specified'}

Please generate a helpful hint conforming to the Socratic tutor rules, in ${languageName}.`.trim();
}

serve(async (req: Request) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    });
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
    const {
      challengeQuestion,
      challengeType,
      attemptCount = 1,
      userContext = null,
      language = 'en',
    } = body;

    if (!challengeQuestion || !challengeType) {
      return Response.json({ error: 'challengeQuestion and challengeType are required' }, { status: 400 });
    }

    const languageName = language === 'es' ? 'Spanish' : 'English';

    // --- Call Kimi3 ---
    const kimiKey = Deno.env.get('KIMI_API_KEY');
    if (!kimiKey) {
      return Response.json({ error: 'AI service not configured' }, { status: 503 });
    }

    const kimiResponse = await fetch(KIMI_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${kimiKey}`,
      },
      body: JSON.stringify({
        model: KIMI_MODEL,
        messages: [
          { role: 'system', content: SYSTEM_PROMPT },
          {
            role: 'user',
            content: buildUserPrompt(
              challengeQuestion,
              challengeType,
              attemptCount,
              userContext,
              languageName,
            ),
          },
        ],
        response_format: { type: 'json_object' },
        // kimi-k3 only accepts its default temperature (1); sending any other
        // value gets a 400 invalid_request_error back.
      }),
    });

    if (!kimiResponse.ok) {
      const errorText = await kimiResponse.text();
      console.error('Kimi3 API error (lab-hint):', kimiResponse.status, errorText);
      return Response.json({ error: 'AI service unavailable' }, { status: 502 });
    }

    const kimiData = await kimiResponse.json();
    const rawContent = kimiData.choices?.[0]?.message?.content;

    if (!rawContent) {
      return Response.json({ error: 'Empty AI response' }, { status: 502 });
    }

    const hintResult = JSON.parse(rawContent);

    if (!hintResult.hint) {
      return Response.json({ error: 'Invalid AI response structure' }, { status: 502 });
    }

    // No DB caching for hints is needed since attempts increase and change dynamically,
    // and hints are stateless on-demand guides.

    return Response.json(hintResult, {
      headers: { 'Access-Control-Allow-Origin': '*' },
    });
  } catch (e) {
    console.error('lab-hint error:', e);
    return Response.json({ error: 'Internal server error' }, { status: 500 });
  }
});
