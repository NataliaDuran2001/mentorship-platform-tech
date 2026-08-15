// Supabase Edge Function: generate-interview-questions
//
// Receives the user's track/level/goal and asks Kimi3 for a fresh set of
// interview-practice questions. Never cached: unlike the other AI features,
// dynamic variation between calls is a requirement here, not something to
// avoid.
//
// Endpoint: POST /functions/v1/generate-interview-questions
// Auth: Bearer <supabase_anon_key> (user must be authenticated)
//
// Request body:
// {
//   "trackSlug": "frontend" | "backend" | "infrastructure",
//   "experienceLevelSlug": "student" | "junior_developer" | "career_switcher" | null,
//   "learningGoalSlug": "first_job" | "new_language" | "interview_skills" | "middle_level" | null,
//   "desiredRole": string | null (free text, e.g. "Frontend Developer"),
//   "count": number (optional, default 5)
// }
//
// Response body:
// {
//   "questions": [{ "prompt": "...", "category": "behavioral" | "technical" }, ...]
// }

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const KIMI_API_URL = 'https://api.moonshot.ai/v1/chat/completions';
const KIMI_MODEL = 'kimi-k3';

const TOPIC_ANGLES: Record<string, string[]> = {
  frontend: ['layout/CSS', 'state management', 'accessibility', 'API integration', 'performance', 'testing', 'debugging a bug report'],
  backend: ['data modeling', 'API design', 'authentication/authorization', 'error handling', 'performance', 'testing', 'debugging a production issue'],
  infrastructure: ['CI/CD', 'monitoring/alerting', 'containers', 'networking basics', 'cost/scaling trade-offs', 'incident response', 'infrastructure as code'],
};

const SYSTEM_PROMPT = `You are a friendly interview coach helping someone new to tech practice for a job interview.

Your task is to write a set of interview-practice questions tailored to the student's track, level, goal, and — when given — the specific role they are practicing for.

The questions must:
1. Mix "behavioral" questions (about teamwork, problem-solving, motivation) and "technical" questions (about concepts from the student's track), roughly half and half.
2. Match the student's experience level: simpler, foundational questions for a student/self-taught learner; more specific ones for someone with some professional experience.
3. When a target role is given, write questions a real interviewer for that specific role would ask, not generic track questions.
4. Be realistic questions a real interviewer would ask, not trick questions.
5. Vary from one request to the next — this matters a lot: do not always reach for the most common/textbook question for the track. Use the "topic angles" and "variety seed" given below to spread the technical questions across different subtopics instead of repeating the same one or two obvious questions every time.
6. Use plain, simple English at an A2/B1 level: short sentences, common everyday words, no idioms, no unexplained technical jargon. Write as if explaining to someone new to tech.

Format the output strictly as a JSON object:
{
  "questions": [
    { "prompt": "...", "category": "behavioral" },
    { "prompt": "...", "category": "technical" }
  ]
}
Do not return any markdown formatting or surrounding text.`;

function buildUserPrompt(
  trackSlug: string,
  experienceLevelSlug: string | null,
  learningGoalSlug: string | null,
  desiredRole: string | null,
  count: number,
): string {
  const angles = TOPIC_ANGLES[trackSlug] ?? [];
  const varietySeed = crypto.randomUUID();

  return `
Student context:
- Specialization Track: ${trackSlug}
- Current Level: ${experienceLevelSlug ?? 'not specified'}
- Focus/Goal: ${learningGoalSlug ?? 'not specified'}
- Target role: ${desiredRole ?? 'not specified — use the track in general'}

Topic angles to pick from for the technical questions (spread across different ones, do not use them all): ${angles.join(', ') || 'use your judgement for this track'}.
Variety seed for this request: ${varietySeed} — treat this as a new, independent session. Do not default to the same questions you would normally give first; pick a different mix of angles than the most obvious one.

Please write ${count} interview-practice questions for this student, following the rules.`.trim();
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
      learningGoalSlug = null,
      desiredRole = null,
      count = 5,
    } = body;

    if (!trackSlug) {
      return Response.json({ error: 'trackSlug is required' }, { status: 400 });
    }

    // --- Call Kimi3 ---
    // No cache check here on purpose: dynamic variation between sessions is
    // a stated requirement of the interview simulator, unlike the other AI
    // features, which cache to save cost.
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
            content: buildUserPrompt(trackSlug, experienceLevelSlug, learningGoalSlug, desiredRole, count),
          },
        ],
        response_format: { type: 'json_object' },
        // kimi-k3 only accepts its default temperature (1); sending any other
        // value gets a 400 invalid_request_error back. Variation between
        // calls comes from the prompt instructions instead (rule 5 above).
      }),
    });

    if (!kimiResponse.ok) {
      const errorText = await kimiResponse.text();
      console.error('Kimi3 API error (generate-interview-questions):', kimiResponse.status, errorText);
      return Response.json({ error: 'AI service unavailable' }, { status: 502 });
    }

    const kimiData = await kimiResponse.json();
    const rawContent = kimiData.choices?.[0]?.message?.content;

    if (!rawContent) {
      return Response.json({ error: 'Empty AI response' }, { status: 502 });
    }

    const questionsResult = JSON.parse(rawContent);

    if (!Array.isArray(questionsResult.questions) || questionsResult.questions.length === 0) {
      return Response.json({ error: 'Invalid AI response structure' }, { status: 502 });
    }

    return Response.json(questionsResult, {
      headers: { 'Access-Control-Allow-Origin': '*' },
    });
  } catch (e) {
    console.error('generate-interview-questions error:', e);
    return Response.json({ error: 'Internal server error' }, { status: 500 });
  }
});
