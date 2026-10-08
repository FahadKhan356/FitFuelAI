import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { prompt, daily_summary, weekly_summary, user_goal, local_time } = await req.json();

    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) {
      // Deterministic structured fallback if Gemini API key is missing
      const remainingCals = Math.max(0, (daily_summary?.calories_goal || 2000) - (daily_summary?.calories_consumed || 0));
      return new Response(
        JSON.stringify({
          headline: daily_summary?.calories_consumed > 0 ? "You're on track, but protein is behind." : "Start your logs today to see AI coaching.",
          summary: `${remainingCals.toLocaleString()} kcal left. Aim for balanced macros at your next meal.`,
          blocks: [
            {
              type: "progress_bars",
              title: "Macros today",
              items: [
                { label: "Protein", value: daily_summary?.protein_g || 0, target: daily_summary?.protein_goal_g || 140, unit: "g", color: "protein" },
                { label: "Carbs", value: daily_summary?.carbs_g || 0, target: daily_summary?.carbs_goal_g || 250, unit: "g", color: "calories" }
              ]
            },
            {
              type: "ring",
              title: "Calorie goal",
              value: daily_summary?.calories_consumed || 0,
              target: daily_summary?.calories_goal || 2000,
              unit: "kcal"
            }
          ],
          actions: [
            { label: "Log 250 ml", icon: "water_drop", action: "log_water", payload: { ml: 250 } },
            { label: "Plan lunch", icon: "restaurant", action: "open_meal_planner", payload: { protein_g: 40 } }
          ],
          followups: ["What should I eat for dinner?", "Show my weekly protein"]
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const systemPrompt = `You are FitFuel AI Coach. You must respond with JSON ONLY (no markdown backticks, no code blocks, no intro text).
Use ONLY the numbers provided in the user's context. Never invent data.
Headline under 12 words. Summary under 25 words. Choose blocks relevant to the question.
Schema:
{
  "headline": string,
  "summary": string,
  "blocks": [
    { "type": "progress_bars", "title": string, "items": [{"label": string, "value": number, "target": number, "unit": string, "color": "protein"|"calories"|"water"}] },
    { "type": "bar_chart", "title": string, "unit": string, "target": number, "x": string[], "y": number[] },
    { "type": "line_chart", "title": string, "unit": string, "target": number, "x": string[], "y": number[] },
    { "type": "ring", "title": string, "value": number, "target": number, "unit": string },
    { "type": "stat_row", "items": [{"label": string, "value": string}] }
  ],
  "actions": [{"label": string, "icon": string, "action": "log_water"|"open_meal_planner", "payload": object}],
  "followups": string[]
}`;

    const userPrompt = `Context:
Daily Summary: ${JSON.stringify(daily_summary)}
Weekly Summary: ${JSON.stringify(weekly_summary)}
User Goal: ${JSON.stringify(user_goal)}
Current Local Time: ${local_time}

Question: ${prompt}`;

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
    const geminiRes = await fetch(geminiUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: `${systemPrompt}\n\n${userPrompt}` }] }],
        generationConfig: { responseMimeType: "application/json" }
      })
    });

    const geminiJson = await geminiRes.json();
    const rawText = geminiJson.candidates?.[0]?.content?.parts?.[0]?.text || "{}";
    const cleaned = rawText.replace(/```json/g, "").replace(/```/g, "").trim();

    return new Response(cleaned, { headers: { ...corsHeaders, "Content-Type": "application/json" } });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
