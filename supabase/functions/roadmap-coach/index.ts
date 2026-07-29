// Supabase Edge Function: roadmap-coach
//
// Receives the current track, learning goal, progress fraction, and next topic,
// and returns a personalized short motivational header coaching message from Kimi3.
//
// Endpoint: POST /functions/v1/roadmap-coach
// Auth: Bearer <supabase_anon_key> (user must be authenticated)
//
// Request body:
// {
//   "trackSlug": "frontend" | "backend" | "infrastructure",
//   "learningGoalSlug": "first_job" | "new_language" | "interview_skills" | "middle_level" | null,
//   "progressPercent": number,
//   "nextTopicTitle": string | null
// }
//
// Response body:
// {
//   "message": "Step by step, you are mastering the front-end! Today's goal is..."
// }

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const KIMI_API_URL = 'https://api.moonshot.ai/v1/chat/completions';
const KIMI_MODEL = 'kimi-k3';

const SYSTEM_PROMPT = `You are a supportive, high-energy coding coach.
Your task is to write a single, brief, punchy motivational coaching statement (1 sentence, max 15 words) for a student's learning path header.

The coaching message must:
1. Speak directly to the student in English.
2. Be extremely concise (exactly 1 sentence).
3. Personalize the message based on their progress percentage and what is coming up next.
4. Keep it positive and action-oriented.

Format the output strictly as a JSON object:
{
  "message": "..."
}
Do not return any markdown formatting or surrounding text.`;

function buildUserPrompt(
  trackSlug: string,
  learningGoalSlug: string | null,
  progressPercent: number,
  nextTopicTitle: string | null,
): string {
  return `
Coach Context:
- Track: ${trackSlug}
- Goal: ${learningGoalSlug ?? 'not specified'}
- Current Progress: ${progressPercent}% complete
- Next upcoming topic: ${nextTopicTitle ?? 'None (all completed)'}

Please write a highly relevant 1-sentence motivational coaching header message for this student.`.trim();
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
      learningGoalSlug = null,
      progressPercent = 0,
      nextTopicTitle = null,
    } = body;

    if (!trackSlug) {
      return Response.json({ error: 'trackSlug is required' }, { status: 400 });
    }

    // --- Check cache (ai_profile_insights) ---
    const serviceSupabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const twelveHoursAgo = new Date(Date.now() - 12 * 60 * 60 * 1000).toISOString();
    const { data: cachedInsights, error: cacheError } = await serviceSupabase
      .from('ai_profile_insights')
      .select('content')
      .eq('user_id', user.id)
      .eq('insight_type', 'roadmap_coach')
      .gt('created_at', twelveHoursAgo)
      .order('created_at', { ascending: false })
      .limit(1);

    if (!cacheError && cachedInsights && cachedInsights.length > 0) {
      const cachedMessage = cachedInsights[0].content as { message: string };
      return Response.json(cachedMessage, {
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
              learningGoalSlug,
              progressPercent,
              nextTopicTitle,
            ),
          },
        ],
        response_format: { type: 'json_object' },
        temperature: 0.8, // Fun and energetic coaching variation
      }),
    });

    if (!kimiResponse.ok) {
      const errorText = await kimiResponse.text();
      console.error('Kimi3 API error (roadmap-coach):', kimiResponse.status, errorText);
      return Response.json({ error: 'AI service unavailable' }, { status: 502 });
    }

    const kimiData = await kimiResponse.json();
    const rawContent = kimiData.choices?.[0]?.message?.content;

    if (!rawContent) {
      return Response.json({ error: 'Empty AI response' }, { status: 502 });
    }

    const coachResult = JSON.parse(rawContent);

    if (!coachResult.message) {
      return Response.json({ error: 'Invalid AI response structure' }, { status: 502 });
    }

    // --- Cache the result ---
    await serviceSupabase.from('ai_profile_insights').insert({
      user_id: user.id,
      insight_type: 'roadmap_coach',
      content: coachResult,
      model: KIMI_MODEL,
    });

    return Response.json(coachResult, {
      headers: { 'Access-Control-Allow-Origin': '*' },
    });
  } catch (e) {
    console.error('roadmap-coach error:', e);
    return Response.json({ error: 'Internal server error' }, { status: 500 });
  }
});
