// Supabase Edge Function: analyze-profile
//
// Receives the full onboarding answers for a user, calls Kimi3 (kimi-k3)
// to reason about them, and returns a structured track recommendation with
// a natural-language rationale.
//
// Endpoint: POST /functions/v1/analyze-profile
// Auth: Bearer <supabase_anon_key>  (user must be authenticated)
//
// Request body:
// {
//   "answers": [{ "stepKey": "quiz_1", "value": "frontend" }, ...],
//   "experienceLevel": "student" | "junior_developer" | "career_switcher",
//   "learningGoal": "first_job" | "new_language" | "interview_skills" | "middle_level",
//   "language": "en" | "es" (optional, default "en")
// }
//
// Response body:
// {
//   "recommendedTrack": "frontend" | "backend" | "infrastructure",
//   "reasoning": "Based on your answers...",
//   "confidence": 0.92,
//   "alternatives": [
//     { "track": "backend", "reason": "..." }
//   ]
// }

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const KIMI_API_URL = 'https://api.moonshot.ai/v1/chat/completions';
const KIMI_MODEL = 'kimi-k3';

const VALID_TRACKS = ['frontend', 'backend', 'infrastructure'] as const;
type Track = (typeof VALID_TRACKS)[number];

const SYSTEM_PROMPT = `You are an expert career counselor and tech educator specialized in helping people enter the software industry.

Your task is to analyze a user's onboarding answers and recommend the best learning track for them.

Available tracks:
- frontend: Visual interfaces, user experience, HTML/CSS/JavaScript, React, etc.
- backend: Server logic, APIs, databases, Node.js, Python, SQL, etc.
- infrastructure: DevOps, containers, CI/CD, cloud computing, Docker, Kubernetes, etc.

Analyze the provided answers deeply — consider the patterns, the hesitations (quiz answers), the experience level, and the stated goal.

Write the "reasoning" and "reason" fields in plain, jargon-free, beginner-friendly language, as if explaining to someone new to tech. If a technical term is unavoidable, explain it in plain words.

Respond with a JSON object in this exact schema:
{
  "recommendedTrack": "frontend" | "backend" | "infrastructure",
  "reasoning": "A 2-3 sentence explanation personalized to this user's answers and goal. Be specific about what in their answers led to this recommendation.",
  "confidence": number between 0.5 and 1.0,
  "alternatives": [
    {
      "track": "...",
      "reason": "One sentence on why this could also work for them"
    }
  ]
}

Only include alternatives if confidence < 0.85. Maximum 2 alternatives.
Write every "reasoning" and "reason" field in the language requested at the end of the student profile below.
Always respond with valid JSON only. No markdown, no extra text.`;

function buildUserPrompt(
  answers: Array<{ stepKey: string; value: string }>,
  experienceLevel: string | null,
  learningGoal: string | null,
  languageName: string,
): string {
  const quizAnswers = answers
    .filter((a) => a.stepKey.startsWith('quiz_'))
    .map((a) => `- Question ${a.stepKey.replace('quiz_', '')}: voted for ${a.value}`)
    .join('\n');

  const directTrack = answers.find((a) => a.stepKey === 'track')?.value;

  return `
User profile:
- Experience level: ${experienceLevel ?? 'not specified'}
- Learning goal: ${learningGoal ?? 'not specified'}
- Direct track choice: ${directTrack === 'unknown' ? 'User was not sure, took the guided quiz' : (directTrack ?? 'not specified')}

Quiz answers (each shows affinity toward a track):
${quizAnswers || '(no quiz answers)'}

Please analyze this profile and recommend the best learning track. Write your response in ${languageName}.`.trim();
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
    const { answers = [], experienceLevel = null, learningGoal = null, language = 'en' } = body;

    if (!Array.isArray(answers)) {
      return Response.json({ error: 'answers must be an array' }, { status: 400 });
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
            content: buildUserPrompt(answers, experienceLevel, learningGoal, languageName),
          },
        ],
        response_format: { type: 'json_object' },
        // kimi-k3 only accepts its default temperature (1); sending any other
        // value gets a 400 invalid_request_error back.
      }),
    });

    if (!kimiResponse.ok) {
      const errorText = await kimiResponse.text();
      console.error('Kimi3 API error:', kimiResponse.status, errorText);
      return Response.json({ error: 'AI service unavailable' }, { status: 502 });
    }

    const kimiData = await kimiResponse.json();
    const rawContent = kimiData.choices?.[0]?.message?.content;

    if (!rawContent) {
      return Response.json({ error: 'Empty AI response' }, { status: 502 });
    }

    const recommendation = JSON.parse(rawContent);

    // Validate the recommended track is one of the valid values
    if (!VALID_TRACKS.includes(recommendation.recommendedTrack)) {
      console.error('Invalid track from AI:', recommendation.recommendedTrack);
      return Response.json({ error: 'Invalid AI response structure' }, { status: 502 });
    }

    // --- Cache the result in ai_profile_insights ---
    // Use service role key to write server-side (bypasses RLS correctly)
    const serviceSupabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    await serviceSupabase.from('ai_profile_insights').insert({
      user_id: user.id,
      insight_type: 'track_recommendation',
      content: recommendation,
      model: KIMI_MODEL,
    });

    return Response.json(recommendation, {
      headers: { 'Access-Control-Allow-Origin': '*' },
    });
  } catch (e) {
    console.error('analyze-profile error:', e);
    return Response.json({ error: 'Internal server error' }, { status: 500 });
  }
});
