// Supabase Edge Function: analyze-interview-session
//
// Receives every question and typed answer of one interview-practice
// session and asks Kimi3 for feedback on all of them in a single call. Never
// cached: every session's answers are unique text, there is nothing to
// reuse. Grading everything together (instead of one call per answer) is
// also what gives Kimi a basis to calibrate scores against each other,
// rather than scoring each answer in total isolation.
//
// Endpoint: POST /functions/v1/analyze-interview-session
// Auth: Bearer <supabase_anon_key> (user must be authenticated)
//
// Request body:
// {
//   "trackSlug": "frontend" | "backend" | "infrastructure",
//   "experienceLevelSlug": "student" | "junior_developer" | "career_switcher" | null,
//   "items": [
//     { "questionId": "...", "questionPrompt": "...", "category": "behavioral" | "technical", "answerText": "..." },
//     ...
//   ]
// }
//
// Response body:
// {
//   "overallSummary": "...",
//   "results": [
//     { "questionId": "...", "summary": "...", "strengths": ["...", ...], "improvements": ["...", ...], "score": 0 },
//     ...
//   ]
// }

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const KIMI_API_URL = 'https://api.moonshot.ai/v1/chat/completions';
const KIMI_MODEL = 'kimi-k3';

const SYSTEM_PROMPT = `You are a supportive, encouraging interview coach giving feedback to someone new to tech who just practiced a full set of interview questions.

Your task is to read every question and answer of the session together, and give feedback on each answer.

The feedback must:
1. Never feel like a pass/fail grade: this is practice, not a real interview. Be warm and friendly, never clinical, even when an answer is weak.
2. Point out 1 to 3 concrete things each answer does well (strengths). If an answer is very thin, it is fine to have just 1.
3. Point out 1 to 3 concrete, actionable ways to improve each answer (improvements) — specific advice, not vague ("be more specific"), e.g. "Mention a real example from a project you've worked on."
4. Give a 0-100 score per answer that reflects how complete and clear it is, used only to track progress over time, not as a verdict. Score every answer using this rubric, and use the full range — do not default to the same score for different answers:
   - 0-20: empty, off-topic, or no real attempt to answer.
   - 21-40: a short or vague attempt with little relevant content.
   - 41-60: a partial answer that touches the topic but has clear gaps.
   - 61-80: a solid answer with only minor gaps or missing detail.
   - 81-100: a clear, complete, well-explained answer.
   Look at all the answers in this session together and grade them relative to each other: if two answers are clearly different in quality or effort, their scores must be different too.
5. In each answer's "summary", name one specific detail from what the student actually wrote (or, if they wrote very little, say that plainly and kindly) — the score must always feel justified by something concrete in the text, never arbitrary.
6. Use plain, simple English at an A2/B1 level: short sentences, common everyday words, no idioms, no unexplained technical jargon.
7. Also write one short "overallSummary" for the whole session: 1-2 friendly sentences on how the session went overall.

Format the output strictly as a JSON object:
{
  "overallSummary": "1-2 friendly sentences about the whole session.",
  "results": [
    {
      "questionId": "same id the question had in the input",
      "summary": "One or two encouraging sentences, naming something specific from this answer.",
      "strengths": ["...", ...],
      "improvements": ["...", ...],
      "score": 0
    },
    ...
  ]
}
Return exactly one "results" entry per item received, each with the same "questionId" it was given. Do not return any markdown formatting or surrounding text.`;

function buildUserPrompt(
  trackSlug: string,
  experienceLevelSlug: string | null,
  items: { questionId: string; questionPrompt: string; category: string; answerText: string }[],
): string {
  const questionsBlock = items
    .map(
      (item, i) =>
        `${i + 1}. [id: ${item.questionId}] (${item.category}) "${item.questionPrompt}"\nStudent's answer: "${item.answerText}"`,
    )
    .join('\n\n');

  return `
Student context:
- Specialization Track: ${trackSlug}
- Current Level: ${experienceLevelSlug ?? 'not specified'}

Interview practice session — ${items.length} questions and the student's answers:

${questionsBlock}

Please give feedback on every answer above, following the rules.`.trim();
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
      trackSlug,
      experienceLevelSlug = null,
      items,
    } = body;

    if (!trackSlug || !Array.isArray(items) || items.length === 0) {
      return Response.json(
        { error: 'trackSlug and a non-empty items array are required' },
        { status: 400 },
      );
    }
    for (const item of items) {
      if (!item.questionId || !item.questionPrompt || !item.answerText) {
        return Response.json(
          { error: 'each item requires questionId, questionPrompt and answerText' },
          { status: 400 },
        );
      }
    }

    // --- Call Kimi3 ---
    // No cache: every session's answers are unique text, there is nothing to
    // reuse.
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
            content: buildUserPrompt(trackSlug, experienceLevelSlug, items),
          },
        ],
        response_format: { type: 'json_object' },
        // kimi-k3 only accepts its default temperature (1); sending any other
        // value gets a 400 invalid_request_error back.
      }),
    });

    if (!kimiResponse.ok) {
      const errorText = await kimiResponse.text();
      console.error('Kimi3 API error (analyze-interview-session):', kimiResponse.status, errorText);
      return Response.json({ error: 'AI service unavailable' }, { status: 502 });
    }

    const kimiData = await kimiResponse.json();
    const rawContent = kimiData.choices?.[0]?.message?.content;

    if (!rawContent) {
      return Response.json({ error: 'Empty AI response' }, { status: 502 });
    }

    const sessionResult = JSON.parse(rawContent);

    if (
      !sessionResult.overallSummary ||
      !Array.isArray(sessionResult.results) ||
      sessionResult.results.length !== items.length
    ) {
      return Response.json({ error: 'Invalid AI response structure' }, { status: 502 });
    }

    return Response.json(sessionResult, {
      headers: { 'Access-Control-Allow-Origin': '*' },
    });
  } catch (e) {
    console.error('analyze-interview-session error:', e);
    return Response.json({ error: 'Internal server error' }, { status: 500 });
  }
});
