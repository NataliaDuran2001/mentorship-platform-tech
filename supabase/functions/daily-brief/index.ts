// Supabase Edge Function: daily-brief
//
// Receives the user's progress and onboarding parameters, calls Kimi3 (kimi-k3)
// to generate a personalized daily brief/motivation message, and caches it
// in `ai_profile_insights` for 24 hours.
//
// Endpoint: POST /functions/v1/daily-brief
// Auth: Bearer <supabase_anon_key> (user must be authenticated)
//
// Request body:
// {
//   "trackSlug": "frontend" | "backend" | "infrastructure",
//   "experienceLevelSlug": "student" | "junior_developer" | "career_switcher" | null,
//   "learningGoalSlug": "first_job" | "new_language" | "interview_skills" | "middle_level" | null,
//   "completedTopics": number,
//   "totalTopics": number
// }
//
// Response body:
// {
//   "brief": "Good morning! ..."
// }

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const KIMI_API_URL = 'https://api.moonshot.ai/v1/chat/completions';
const KIMI_MODEL = 'kimi-k3';

const SYSTEM_PROMPT = `You are a supportive and encouraging mentor.
Your task is to write a personalized "Daily Brief" (2 to 3 sentences) for a student on a mentorship platform.

The brief must:
1. Address the student directly and warmly.
2. Contextualize their progress (e.g. 5 of 10 topics completed).
3. Connect their track (Frontend/Backend/Infrastructure) and experience level/goal to their next logical steps in a motivational way.
4. Keep it concise, warm, and easy to read.
5. Speak in English.
6. Avoid unexplained technical jargon; write as if explaining to someone new to tech. If a technical term is unavoidable, explain it in plain words.

Format the output strictly as a JSON object:
{
  "brief": "..."
}
Do not return any markdown formatting or surrounding text.`;

function buildUserPrompt(
  trackSlug: string,
  experienceLevelSlug: string | null,
  learningGoalSlug: string | null,
  completedTopics: number,
  totalTopics: number,
): string {
  return `
Student context:
- Specialization Track: ${trackSlug}
- Current Level: ${experienceLevelSlug ?? 'not specified'}
- Focus/Goal: ${learningGoalSlug ?? 'not specified'}
- Progress: ${completedTopics} out of ${totalTopics} topics completed (${totalTopics > 0 ? Math.round((completedTopics / totalTopics) * 100) : 0}%).

Please write a personalized, highly relevant 2-3 sentence Daily Brief for this student.`.trim();
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
      completedTopics = 0,
      totalTopics = 0,
    } = body;

    if (!trackSlug) {
      return Response.json({ error: 'trackSlug is required' }, { status: 400 });
    }

    // --- Check cache (ai_profile_insights) ---
    // If there is an insight of type 'daily_brief' created in the last 24 hours, return it.
    const serviceSupabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    const { data: cachedInsights, error: cacheError } = await serviceSupabase
      .from('ai_profile_insights')
      .select('content')
      .eq('user_id', user.id)
      .eq('insight_type', 'daily_brief')
      .gt('created_at', twentyFourHoursAgo)
      .order('created_at', { ascending: false })
      .limit(1);

    if (!cacheError && cachedInsights && cachedInsights.length > 0) {
      const cachedBrief = cachedInsights[0].content as { brief: string };
      return Response.json(cachedBrief, {
        headers: { 'Access-Control-Allow-Origin': '*' },
      });
    }

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
              trackSlug,
              experienceLevelSlug,
              learningGoalSlug,
              completedTopics,
              totalTopics,
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
      console.error('Kimi3 API error (daily-brief):', kimiResponse.status, errorText);
      return Response.json({ error: 'AI service unavailable' }, { status: 502 });
    }

    const kimiData = await kimiResponse.json();
    const rawContent = kimiData.choices?.[0]?.message?.content;

    if (!rawContent) {
      return Response.json({ error: 'Empty AI response' }, { status: 502 });
    }

    const briefResult = JSON.parse(rawContent);

    if (!briefResult.brief) {
      return Response.json({ error: 'Invalid AI response structure' }, { status: 502 });
    }

    // --- Cache the result ---
    await serviceSupabase.from('ai_profile_insights').insert({
      user_id: user.id,
      insight_type: 'daily_brief',
      content: briefResult,
      model: KIMI_MODEL,
    });

    return Response.json(briefResult, {
      headers: { 'Access-Control-Allow-Origin': '*' },
    });
  } catch (e) {
    console.error('daily-brief error:', e);
    return Response.json({ error: 'Internal server error' }, { status: 500 });
  }
});
