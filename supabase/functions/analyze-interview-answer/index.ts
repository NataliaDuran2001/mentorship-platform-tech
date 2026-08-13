// Supabase Edge Function: analyze-interview-answer
//
// Receives one typed answer to one interview-practice question and asks
// Kimi3 for constructive, encouraging feedback. Never cached: every answer
// is unique text, there is nothing to reuse.
//
// Endpoint: POST /functions/v1/analyze-interview-answer
// Auth: Bearer <supabase_anon_key> (user must be authenticated)
//
// Request body:
// {
//   "trackSlug": "frontend" | "backend" | "infrastructure",
//   "experienceLevelSlug": "student" | "junior_developer" | "career_switcher" | null,
//   "questionPrompt": string,
//   "answerText": string
// }
//
// Response body:
// {
//   "summary": "...",
//   "strengths": ["...", ...],
//   "improvements": ["...", ...],
//   "score": 0-100
// }

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const KIMI_API_URL = 'https://api.moonshot.ai/v1/chat/completions';
const KIMI_MODEL = 'kimi-k3';

const SYSTEM_PROMPT = `You are a supportive, encouraging interview coach giving feedback to someone new to tech who just practiced answering an interview question.

Your task is to read their answer and give constructive, actionable feedback.

The feedback must:
1. Never feel like a pass/fail grade: this is practice, not a real interview. Be encouraging even when the answer is weak.
2. Point out 1 to 3 concrete things the answer does well (strengths). If the answer is very thin, it is fine to have just 1.
3. Point out 1 to 3 concrete, actionable ways to improve (improvements) — specific advice, not vague ("be more specific"), e.g. "Mention a real example from a project you've worked on."
4. Give a 0-100 score reflecting how complete and clear the answer is, used only to track progress over time, not as a verdict.
5. Use plain, jargon-free language. Avoid unexplained technical jargon; write as if explaining to someone new to tech.
6. Speak in English.

Format the output strictly as a JSON object:
{
  "summary": "One or two encouraging sentences summarizing the answer.",
  "strengths": ["...", ...],
  "improvements": ["...", ...],
  "score": 0
}
Do not return any markdown formatting or surrounding text.`;

function buildUserPrompt(
  trackSlug: string,
  experienceLevelSlug: string | null,
  questionPrompt: string,
  answerText: string,
): string {
  return `
Student context:
- Specialization Track: ${trackSlug}
- Current Level: ${experienceLevelSlug ?? 'not specified'}

Interview question: "${questionPrompt}"

Student's answer: "${answerText}"

Please give feedback on this answer, following the rules.`.trim();
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
      questionPrompt,
      answerText,
    } = body;

    if (!trackSlug || !questionPrompt || !answerText) {
      return Response.json(
        { error: 'trackSlug, questionPrompt and answerText are required' },
        { status: 400 },
      );
    }

    // --- Call Kimi3 ---
    // No cache: every answer is unique text, there is nothing to reuse.
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
            content: buildUserPrompt(trackSlug, experienceLevelSlug, questionPrompt, answerText),
          },
        ],
        response_format: { type: 'json_object' },
        // kimi-k3 only accepts its default temperature (1); sending any other
        // value gets a 400 invalid_request_error back.
      }),
    });

    if (!kimiResponse.ok) {
      const errorText = await kimiResponse.text();
      console.error('Kimi3 API error (analyze-interview-answer):', kimiResponse.status, errorText);
      return Response.json({ error: 'AI service unavailable' }, { status: 502 });
    }

    const kimiData = await kimiResponse.json();
    const rawContent = kimiData.choices?.[0]?.message?.content;

    if (!rawContent) {
      return Response.json({ error: 'Empty AI response' }, { status: 502 });
    }

    const feedbackResult = JSON.parse(rawContent);

    if (!feedbackResult.summary || typeof feedbackResult.score !== 'number') {
      return Response.json({ error: 'Invalid AI response structure' }, { status: 502 });
    }

    return Response.json(feedbackResult, {
      headers: { 'Access-Control-Allow-Origin': '*' },
    });
  } catch (e) {
    console.error('analyze-interview-answer error:', e);
    return Response.json({ error: 'Internal server error' }, { status: 500 });
  }
});
