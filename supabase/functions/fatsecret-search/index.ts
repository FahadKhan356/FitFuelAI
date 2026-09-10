import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })

serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { query } = await request.json()
    if (typeof query !== 'string' || query.trim().length < 2) {
      return json({ error: 'query must contain at least 2 characters' }, 400)
    }

    const clientId = Deno.env.get('FATSECRET_CLIENT_ID')
    const clientSecret = Deno.env.get('FATSECRET_CLIENT_SECRET')
    if (!clientId || !clientSecret) {
      return json({ error: 'FatSecret is not configured on the server' }, 503)
    }

    const basicAuth = btoa(`${clientId}:${clientSecret}`)
    const tokenResponse = await fetch('https://oauth.fatsecret.com/connect/token', {
      method: 'POST',
      headers: {
        Authorization: `Basic ${basicAuth}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials&scope=basic',
    })
    if (!tokenResponse.ok) {
      return json({ error: 'FatSecret authentication failed' }, 502)
    }

    const token = await tokenResponse.json()
    const params = new URLSearchParams({
      method: 'foods.search.v3',
      search_expression: query.trim(),
      max_results: '50',
      format: 'json',
      include_sub_categories: 'true',
    })
    const foodResponse = await fetch('https://platform.fatsecret.com/rest/server.api', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token.access_token}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params,
    })
    if (!foodResponse.ok) {
      return json({ error: 'FatSecret search failed' }, 502)
    }

    const payload = await foodResponse.json()
    const foods = Array.isArray(payload?.foods?.food)
      ? payload.foods.food
      : payload?.foods?.food
        ? [payload.foods.food]
        : []

    const results = foods.map((food: Record<string, unknown>) => {
      const servings = food.servings as Record<string, unknown> | undefined
      const rawServing = servings?.serving
      const serving = Array.isArray(rawServing) ? rawServing[0] : rawServing
      const nutrition = (serving ?? {}) as Record<string, unknown>
      return {
        source: 'FatSecret',
        externalId: String(food.food_id ?? ''),
        name: String(food.food_name ?? 'Food'),
        brand: typeof food.brand_name === 'string' ? food.brand_name : null,
        imageUrl: null,
        energyKcal: number(nutrition.calories),
        protein: number(nutrition.protein),
        carbs: number(nutrition.carbohydrate),
        fat: number(nutrition.fat),
        saturatedFatG: number(nutrition.saturated_fat),
        fiber: number(nutrition.fiber),
        sugar: number(nutrition.sugar),
        sodiumMg: number(nutrition.sodium),
        potassiumMg: 0,
        calciumMg: 0,
        ironMg: 0,
        vitaminCMg: 0,
      }
    }).filter((food: Record<string, number>) => food.energyKcal > 0)

    return json({ results })
  } catch (_) {
    return json({ error: 'Unexpected FatSecret proxy error' }, 500)
  }
})

function number(value: unknown): number {
  if (typeof value === 'number') return value
  if (typeof value === 'string') return Number.parseFloat(value) || 0
  return 0
}
