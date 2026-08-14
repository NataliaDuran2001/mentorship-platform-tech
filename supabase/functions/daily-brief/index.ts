// Supabase Edge Function: daily-brief
//
// Receives the user's progress and onboarding parameters, calls Kimi3 (kimi-k3)
// to generate the dashboard summary —where the learner stands on their path and
// what comes next— and caches it in `ai_profile_insights` for 24 hours.
//
// The function name and the `daily_brief` insight type are kept as they are:
// renaming them would orphan every cached row and break the deployed function's
// URL. What changed is what the model is asked to write.
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

const SYSTEM_PROMPT = `You are a supportive mentor writing the "Your Summary" card on a learner's dashboard.

Write 2 to 3 sentences that tell the learner where they stand on their learning path.

The summary must:
1. Speak to the learner directly, by "you", in a warm and plain tone.
2. State where they are on their path in concrete terms — how much of it they have completed and what that means. Name the numbers rather than only the percentage.
3. Say what the sensible next move is, tied to their track (Frontend/Backend/Infrastructure) and their goal.
4. Match the tone to the actual state: a learner who has just started needs reassurance that the beginning is the right place to be; one who is halfway needs to see the distance already covered; one who has finished everything available needs to know there is nothing pending.
5. Speak in English.
6. Avoid unexplained technical jargon; write as if explaining to someone new to tech. If a technical term is unavoidable, explain it in plain words.
7. Never invent progress, topic names, deadlines, streaks or achievements that are not in the context given to you.
8. Do not open with a time-of-day greeting ("Good morning", "Today"): the card is not tied to a moment of the day.

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
  const percentage = totalTopics > 0
    ? Math.round((completedTopics / totalTopics) * 100)
    : 0;

  // Naming the stage keeps the model from congratulating someone at 0% or
  // pushing "keep going" at someone who has nothing left to do.
  const stage = totalTopics === 0
    ? 'their path has no topics available yet'
    : completedTopics === 0
    ? 'they are about to start their path and have not completed any topic yet'
    : completedTopics >= totalTopics
    ? 'they have completed every topic currently available on their path'
    : 'they are partway through their path';

  return `
Learner context:
- Specialization Track: ${trackSlug}
- Current Level: ${experienceLevelSlug ?? 'not specified'}
- Focus/Goal: ${learningGoalSlug ?? 'not specified'}
- Path progress: ${completedTopics} of ${totalTopics} topics completed (${percentage}%).
- Stage: ${stage}.

Write the 2-3 sentence summary for this learner.`.trim();
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
