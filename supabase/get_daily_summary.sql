-- ============================================================
-- RPC: get_daily_summary
-- Resolves user's daily metrics using their LOCAL date (device timezone).
-- Fixes the UTC timezone mismatch bug where 'today' returned 0 kcal & 0 ml.
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_daily_summary(
  p_user_id UUID,
  p_local_date DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_calories_consumed INT := 0;
  v_calories_goal INT := 2000;
  v_water_ml INT := 0;
  v_water_goal_ml INT := 2500;
  v_protein_g DOUBLE PRECISION := 0;
  v_protein_goal_g DOUBLE PRECISION := 140;
  v_carbs_g DOUBLE PRECISION := 0;
  v_carbs_goal_g DOUBLE PRECISION := 250;
  v_fats_g DOUBLE PRECISION := 0;
  v_fats_goal_g DOUBLE PRECISION := 65;
  v_streak_days INT := 1;
  v_now TIMESTAMPTZ := NOW();
BEGIN
  -- 1. Calories consumed from meals on local date
  SELECT COALESCE(SUM(total_calories), 0)
  INTO v_calories_consumed
  FROM public.meals
  WHERE user_id = p_user_id AND date = p_local_date;

  -- 2. Macros from meal_items on local date
  SELECT 
    COALESCE(SUM(mi.protein), 0),
    COALESCE(SUM(mi.carbs), 0),
    COALESCE(SUM(mi.fat), 0)
  INTO v_protein_g, v_carbs_g, v_fats_g
  FROM public.meals m
  JOIN public.meal_items mi ON mi.meal_id = m.id
  WHERE m.user_id = p_user_id AND m.date = p_local_date;

  -- 3. Water intake on local date
  SELECT COALESCE(SUM(amount_ml), 0)
  INTO v_water_ml
  FROM public.water_intake
  WHERE user_id = p_user_id AND date = p_local_date;

  -- 4. Goals from goals table with non-zero fallbacks
  SELECT 
    COALESCE(NULLIF(target_calories, 0), v_calories_goal),
    COALESCE(NULLIF(daily_water_ml, 0), v_water_goal_ml),
    COALESCE(NULLIF(target_protein, 0), v_protein_goal_g),
    COALESCE(NULLIF(target_carbs, 0), v_carbs_goal_g),
    COALESCE(NULLIF(target_fat, 0), v_fats_goal_g)
  INTO 
    v_calories_goal,
    v_water_goal_ml,
    v_protein_goal_g,
    v_carbs_goal_g,
    v_fats_goal_g
  FROM public.goals
  WHERE user_id = p_user_id
  ORDER BY updated_at DESC
  LIMIT 1;

  -- 5. Streak days from gamification
  SELECT COALESCE(streak_days, 1)
  INTO v_streak_days
  FROM public.gamification
  WHERE user_id = p_user_id;

  RETURN jsonb_build_object(
    'calories_consumed', v_calories_consumed,
    'calories_goal', v_calories_goal,
    'water_ml', v_water_ml,
    'water_goal_ml', v_water_goal_ml,
    'protein_g', ROUND(v_protein_g::numeric, 1),
    'protein_goal_g', ROUND(v_protein_goal_g::numeric, 1),
    'carbs_g', ROUND(v_carbs_g::numeric, 1),
    'carbs_goal_g', ROUND(v_carbs_goal_g::numeric, 1),
    'fats_g', ROUND(v_fats_g::numeric, 1),
    'fats_goal_g', ROUND(v_fats_goal_g::numeric, 1),
    'streak_days', v_streak_days,
    'last_synced_at', v_now
  );
END;
$$;
