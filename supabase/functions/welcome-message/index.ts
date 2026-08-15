// Supabase Edge Function: welcome-message
//
// Receives the learner's display name, track, learning goal, and progress,
// and returns a short personalized welcome-back headline from Kimi3, in
// place of the static "WELCOME BACK" label on the dashboard.
//
// Endpoint: POST /functions/v1/welcome-message
// Auth: Bearer <supabase_anon_key> (user must be authenticated)
//
// Request body:
// {
//   "displayName": string,
//   "trackSlug": "frontend" | "backend" | "infrastructure" | "uiux" | "project_management" | null,
//   "learningGoalSlug": "first_job" | "new_language" | "interview_skills" | "middle_level" | null,
//   "progressPercent": number,
//   "language": "en" | "es" (optional, default "en")
// }
//
// Response body:
// {
//   "message": "Welcome back, Ana!"
// }

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const KIMI_API_URL = 'https://api.moonshot.ai/v1/chat/completions';
const KIMI_MODEL = 'kimi-k3';

const SYSTEM_PROMPT = `You are a warm, encouraging onboarding assistant for a mentorship platform helping women in Bolivia enter the tech industry.

Your task is to write a single, brief eyebrow-style label (max 5 words, no punctuation at the end) for the top of a student's dashboard, replacing a generic static "WELCOME BACK" label. The student's own name is already shown right below it — do NOT repeat it here.

The label must:
1. Optionally nod to their track or progress to make it feel personal, without being verbose.
2. Be extremely concise — a short label, not a sentence.
3. Read naturally in uppercase (it will be rendered in caps), so avoid using the same word for "welcome" every time — vary the phrasing across requests.
4. Avoid unexplained technical jargon.
5. Write it in the language requested at the end of the context below.

Format the output strictly as a JSON object:
{
  "message": "..."
}
Do not return any markdown formatting or surrounding text.`;

function buildUserPrompt(
  displayName: string,
  trackSlug: string | null,
  learningGoalSlug: string | null,
  progressPercent: number,
  languageName: string,
): string {
  return `
Student context:
- Name: ${displayName}
- Track: ${trackSlug ?? 'not specified'}
- Goal: ${learningGoalSlug ?? 'not specified'}
- Current Progress: ${progressPercent}% complete

Please write a highly relevant welcome-back eyebrow label for this student, in ${languageName}.`.trim();
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
      displayName,
      trackSlug = null,
      learningGoalSlug = null,
      progressPercent = 0,
      language = 'en',
    } = body;

    if (!displayName) {
      return Response.json({ error: 'displayName is required' }, { status: 400 });
    }

    const languageName = language === 'es' ? 'Spanish' : 'English';
    // Cached separately per language, same reasoning as daily-brief/roadmap-coach:
    // a language switch must not surface a stale-language cached message.
    const insightType = `welcome_message_${language}`;

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
      .eq('insight_type', insightType)
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
              displayName,
              trackSlug,
              learningGoalSlug,
              progressPercent,
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
      console.error('Kimi3 API error (welcome-message):', kimiResponse.status, errorText);
      return Response.json({ error: 'AI service unavailable' }, { status: 502 });
    }

    const kimiData = await kimiResponse.json();
    const rawContent = kimiData.choices?.[0]?.message?.content;

    if (!rawContent) {
      return Response.json({ error: 'Empty AI response' }, { status: 502 });
    }

    const welcomeResult = JSON.parse(rawContent);

    if (!welcomeResult.message) {
      return Response.json({ error: 'Invalid AI response structure' }, { status: 502 });
    }

    // --- Cache the result ---
    await serviceSupabase.from('ai_profile_insights').insert({
      user_id: user.id,
      insight_type: insightType,
      content: welcomeResult,
      model: KIMI_MODEL,
    });

    return Response.json(welcomeResult, {
      headers: { 'Access-Control-Allow-Origin': '*' },
    });
  } catch (e) {
    console.error('welcome-message error:', e);
    return Response.json({ error: 'Internal server error' }, { status: 500 });
  }
});
