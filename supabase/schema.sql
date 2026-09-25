-- ============================================================
-- FitFuel AI - Supabase Database Schema
-- ============================================================
-- Run this in Supabase Dashboard > SQL Editor
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. USER PROFILES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  avatar_url TEXT,
  age INT,
  gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  height_cm DOUBLE PRECISION,
  weight_kg DOUBLE PRECISION,
  goal_weight_kg DOUBLE PRECISION,
  activity_level TEXT CHECK (activity_level IN ('sedentary', 'lightly_active', 'moderately_active', 'very_active')),
  goal_type TEXT CHECK (goal_type IN ('weight_loss', 'muscle_gain', 'maintenance', 'healthy_gain', 'cutting')),
  diet_preference TEXT DEFAULT 'balanced',
  workout_frequency INT DEFAULT 3,
  bio TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 2. GOALS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.goals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  goal_type TEXT,
  target_weight_kg DOUBLE PRECISION,
  weekly_pace_kg DOUBLE PRECISION DEFAULT 0.5,
  target_date DATE,
  target_calories INT DEFAULT 0,
  target_protein DOUBLE PRECISION DEFAULT 0,
  target_carbs DOUBLE PRECISION DEFAULT 0,
  target_fat DOUBLE PRECISION DEFAULT 0,
  daily_water_ml INT DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_goals_user_id ON public.goals(user_id);

-- ============================================================
-- 3. MEALS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.meals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  meal_type TEXT NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
  total_calories INT DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_meals_user_id_date ON public.meals(user_id, date);

-- ============================================================
-- 4. MEAL ITEMS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.meal_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  meal_id UUID NOT NULL REFERENCES public.meals(id) ON DELETE CASCADE,
  food_name TEXT NOT NULL,
  calories INT NOT NULL,
  protein DOUBLE PRECISION DEFAULT 0,
  carbs DOUBLE PRECISION DEFAULT 0,
  fat DOUBLE PRECISION DEFAULT 0,
  fiber DOUBLE PRECISION DEFAULT 0,
  serving_size DOUBLE PRECISION DEFAULT 100,
  serving_unit TEXT DEFAULT 'g',
  photo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_meal_items_meal_id ON public.meal_items(meal_id);

-- ============================================================
-- 5. WATER INTAKE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.water_intake (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  amount_ml INT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_water_intake_user_date ON public.water_intake(user_id, date);

-- ============================================================
-- 6. WEIGHT ENTRIES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.weight_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  weight_kg DOUBLE PRECISION NOT NULL,
  bmi DOUBLE PRECISION,
  body_fat DOUBLE PRECISION,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_weight_entries_user_id_date ON public.weight_entries(user_id, date);

-- ============================================================
-- 7. FOOD ITEMS (Cached nutrition data)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.food_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  brand TEXT,
  source TEXT DEFAULT 'USDA',
  calories INT NOT NULL,
  protein DOUBLE PRECISION DEFAULT 0,
  carbs DOUBLE PRECISION DEFAULT 0,
  fat DOUBLE PRECISION DEFAULT 0,
  fiber DOUBLE PRECISION DEFAULT 0,
  sugar DOUBLE PRECISION DEFAULT 0,
  sodium DOUBLE PRECISION DEFAULT 0,
  serving_size DOUBLE PRECISION DEFAULT 100,
  serving_unit TEXT DEFAULT 'g',
  barcode TEXT,
  external_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_food_items_name ON public.food_items(name);

-- ============================================================
-- 8. BARCODE PRODUCTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.barcode_products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  barcode TEXT UNIQUE NOT NULL,
  product_name TEXT NOT NULL,
  brand TEXT,
  calories INT,
  nutrition_data JSONB,
  source TEXT DEFAULT 'OpenFoodFacts',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 9. FOOD SCANS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.food_scans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  scan_image_url TEXT,
  scan_result JSONB,
  confidence DOUBLE PRECISION,
  scan_type TEXT DEFAULT 'YOLOv8',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_food_scans_user_id ON public.food_scans(user_id);

-- ============================================================
-- 10. AI CHAT SESSIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.ai_chat_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  response TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_chat_sessions_user_id ON public.ai_chat_sessions(user_id);

-- ============================================================
-- 11. GAMIFICATION
-- ============================================================
CREATE TABLE IF NOT EXISTS public.gamification (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  xp_total INT DEFAULT 0,
  streak_days INT DEFAULT 0,
  level INT DEFAULT 1,
  tier TEXT DEFAULT 'Bronze' CHECK (tier IN ('Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond')),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 12. ACHIEVEMENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  badge TEXT NOT NULL,
  progress INT DEFAULT 0,
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_achievements_user_id ON public.achievements(user_id);

-- One row per badge slug (see lib/core/constants/badge_catalog.dart).
-- The unique key lets the app upsert progress instead of inserting
-- duplicate rows every time the evaluator runs.
CREATE UNIQUE INDEX IF NOT EXISTS idx_achievements_user_badge
  ON public.achievements(user_id, badge);

-- ============================================================
-- 12b. XP EVENTS (append-only XP ledger)
-- ============================================================
-- Source of truth for XP. `gamification.xp_total` is a cached rollup
-- that can always be rebuilt with sum(xp) over this table. The unique
-- key makes every daily award idempotent.
CREATE TABLE IF NOT EXISTS public.xp_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  source TEXT NOT NULL,
  xp INT NOT NULL CHECK (xp > 0),
  event_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_xp_events_user_source_date
  ON public.xp_events(user_id, source, event_date);

CREATE INDEX IF NOT EXISTS idx_xp_events_user_date
  ON public.xp_events(user_id, event_date DESC);

-- ============================================================
-- 13. SUBSCRIPTIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan TEXT DEFAULT 'free' CHECK (plan IN ('free', 'premium_monthly', 'premium_yearly', 'premium_lifetime')),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'canceled', 'expired', 'past_due')),
  started_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 14. NOTIFICATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_enabled BOOLEAN DEFAULT TRUE,
  scheduled_time TIME,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.water_intake ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weight_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.barcode_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_scans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gamification ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.xp_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own profile" ON public.user_profiles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own profile" ON public.user_profiles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own profile" ON public.user_profiles FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own goals" ON public.goals FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can upsert own goals" ON public.goals FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own goals" ON public.goals FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own meals" ON public.meals FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own meals" ON public.meals FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own meals" ON public.meals FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own meals" ON public.meals FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own meal items" ON public.meal_items FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.meals WHERE meals.id = meal_items.meal_id AND meals.user_id = auth.uid())
);
CREATE POLICY "Users can insert own meal items" ON public.meal_items FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.meals WHERE meals.id = meal_items.meal_id AND meals.user_id = auth.uid())
);
CREATE POLICY "Users can delete own meal items" ON public.meal_items FOR DELETE USING (
  EXISTS (SELECT 1 FROM public.meals WHERE meals.id = meal_items.meal_id AND meals.user_id = auth.uid())
);

CREATE POLICY "Users can view own water" ON public.water_intake FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own water" ON public.water_intake FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own water" ON public.water_intake FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own weight" ON public.weight_entries FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own weight" ON public.weight_entries FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own weight" ON public.weight_entries FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own weight" ON public.weight_entries FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view food items" ON public.food_items FOR SELECT USING (true);
CREATE POLICY "Anyone can insert food items" ON public.food_items FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can view barcode products" ON public.barcode_products FOR SELECT USING (true);
CREATE POLICY "Anyone can insert barcode products" ON public.barcode_products FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view own scans" ON public.food_scans FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own scans" ON public.food_scans FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own chat" ON public.ai_chat_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own chat" ON public.ai_chat_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own gamification" ON public.gamification FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can upsert own gamification" ON public.gamification FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own gamification" ON public.gamification FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own achievements" ON public.achievements FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own achievements" ON public.achievements FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own achievements" ON public.achievements FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own xp events" ON public.xp_events FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own xp events" ON public.xp_events FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own xp events" ON public.xp_events FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own subscription" ON public.subscriptions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own subscription" ON public.subscriptions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own subscription" ON public.subscriptions FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- ============================================================
-- STORED FUNCTIONS
-- ============================================================

-- Recalculate user goals based on profile
CREATE OR REPLACE FUNCTION public.calculate_user_goals(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  profile RECORD;
  bmr DOUBLE PRECISION;
  tdee DOUBLE PRECISION;
  target_calories INT;
  target_protein DOUBLE PRECISION;
  target_carbs DOUBLE PRECISION;
  target_fat DOUBLE PRECISION;
  daily_water_ml INT;
BEGIN
  SELECT * INTO profile FROM public.user_profiles WHERE user_id = p_user_id;
  
  IF NOT FOUND THEN RETURN; END IF;

  bmr := (10 * COALESCE(profile.weight_kg, 70)) + (6.25 * COALESCE(profile.height_cm, 170)) - (5 * COALESCE(profile.age, 25));
  IF LOWER(profile.gender) = 'male' THEN bmr := bmr + 5; ELSE bmr := bmr - 161; END IF;

  tdee := bmr * CASE profile.activity_level
    WHEN 'lightly_active' THEN 1.375
    WHEN 'moderately_active' THEN 1.55
    WHEN 'very_active' THEN 1.725
    ELSE 1.2
  END;

  target_calories := CASE profile.goal_type
    WHEN 'weight_loss' THEN GREATEST(1200, (tdee - (COALESCE(profile.weekly_pace_kg, 0.5) * 1100 / 7))::INT)
    WHEN 'muscle_gain' THEN (tdee + (COALESCE(profile.weekly_pace_kg, 0.5) * 1100 / 7))::INT
    ELSE tdee::INT
  END;

  target_protein := COALESCE(profile.weight_kg, 70) * 2.0;
  target_fat := (target_calories * 0.25) / 9;
  target_carbs := (target_calories - (target_protein * 4) - (target_fat * 9)) / 4;
  daily_water_ml := (COALESCE(profile.weight_kg, 70) * 35)::INT + CASE WHEN profile.activity_level = 'very_active' THEN 500 ELSE 0 END;

  INSERT INTO public.goals (user_id, goal_type, target_weight_kg, weekly_pace_kg, target_calories, target_protein, target_carbs, target_fat, daily_water_ml, updated_at)
  VALUES (p_user_id, profile.goal_type, profile.goal_weight_kg, COALESCE(profile.weekly_pace_kg, 0.5), target_calories, target_protein, target_carbs, target_fat, daily_water_ml, NOW())
  ON CONFLICT (user_id) DO UPDATE SET
    target_calories = EXCLUDED.target_calories,
    target_protein = EXCLUDED.target_protein,
    target_carbs = EXCLUDED.target_carbs,
    target_fat = EXCLUDED.target_fat,
    daily_water_ml = EXCLUDED.daily_water_ml,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql;
-- ============================================================
-- Gamification: stats snapshot
-- ============================================================
-- Pure counting/aggregation over the caller's own rows — no business
-- rules. XP values, the level curve and badge criteria live in the app
-- (`lib/core/utils/xp_engine.dart`) so they stay unit testable.
-- SECURITY INVOKER, so the caller's RLS policies still apply.
CREATE OR REPLACE FUNCTION public.compute_gamification_stats()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
STABLE
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_target_calories INT := 0;
  v_target_protein DOUBLE PRECISION := 0;
  v_target_water INT := 0;
  v_current_streak INT := 0;
  v_longest_streak INT := 0;
  v_days_logged_7 INT := 0;
  v_meals_logged INT := 0;
  v_meals_logged_30 INT := 0;
  v_water_days INT := 0;
  v_weight_entries INT := 0;
  v_weight_entries_30 INT := 0;
  v_scans INT := 0;
  v_coach_messages INT := 0;
  v_distinct_foods INT := 0;
  v_water_goal_days_30 INT := 0;
  v_protein_goal_days_30 INT := 0;
  v_perfect_days_30 INT := 0;
  v_breakfast_days_7 INT := 0;
  v_profile_complete BOOLEAN := FALSE;

  -- Per-day flags. The app awards XP for things done *today*, and the
  -- rolling counters above cannot answer that (a 30-day count of 1 does
  -- not mean the goal was hit today).
  v_meal_today BOOLEAN := FALSE;
  v_water_today BOOLEAN := FALSE;
  v_water_goal_today BOOLEAN := FALSE;
  v_weight_today BOOLEAN := FALSE;
  v_scan_today BOOLEAN := FALSE;
  v_coach_today BOOLEAN := FALSE;
  v_breakfast_today BOOLEAN := FALSE;
  v_perfect_today BOOLEAN := FALSE;
  v_protein_today BOOLEAN := FALSE;
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('authenticated', FALSE);
  END IF;

  SELECT g.target_calories, g.target_protein, g.daily_water_ml
    INTO v_target_calories, v_target_protein, v_target_water
  FROM public.goals g
  WHERE g.user_id = v_uid
  ORDER BY g.updated_at DESC
  LIMIT 1;

  v_target_calories := COALESCE(v_target_calories, 0);
  v_target_protein := COALESCE(v_target_protein, 0);
  v_target_water := COALESCE(v_target_water, 0);

  -- Streak: consecutive days with a meal OR a water entry.
  -- Gaps-and-islands: subtracting a row number from the date collapses
  -- every consecutive run onto one constant group key.
  WITH activity AS (
    SELECT DISTINCT d FROM (
      SELECT m.date AS d FROM public.meals m
        WHERE m.user_id = v_uid AND m.date >= CURRENT_DATE - 400
      UNION
      SELECT w.date AS d FROM public.water_intake w
        WHERE w.user_id = v_uid AND w.date >= CURRENT_DATE - 400
    ) merged
  ),
  grouped AS (
    SELECT d, d - (row_number() OVER (ORDER BY d))::INT AS grp FROM activity
  ),
  runs AS (
    SELECT grp, count(*)::INT AS len, max(d) AS last_day FROM grouped GROUP BY grp
  )
  SELECT
    COALESCE(max(len) FILTER (WHERE last_day >= CURRENT_DATE - 1), 0),
    COALESCE(max(len), 0)
  INTO v_current_streak, v_longest_streak
  FROM runs;

  SELECT count(*)::INT INTO v_days_logged_7
  FROM (
    SELECT m.date AS d FROM public.meals m
      WHERE m.user_id = v_uid AND m.date >= CURRENT_DATE - 6
    UNION
    SELECT w.date AS d FROM public.water_intake w
      WHERE w.user_id = v_uid AND w.date >= CURRENT_DATE - 6
  ) recent;
  SELECT count(*)::INT INTO v_meals_logged
  FROM public.meals m WHERE m.user_id = v_uid;

  SELECT count(*)::INT INTO v_meals_logged_30
  FROM public.meals m WHERE m.user_id = v_uid AND m.date >= CURRENT_DATE - 30;

  SELECT count(*)::INT INTO v_water_days
  FROM public.water_intake w WHERE w.user_id = v_uid;

  SELECT count(*)::INT INTO v_weight_entries
  FROM public.weight_entries e WHERE e.user_id = v_uid;

  SELECT count(*)::INT INTO v_weight_entries_30
  FROM public.weight_entries e
  WHERE e.user_id = v_uid AND e.date >= CURRENT_DATE - 30;

  SELECT count(*)::INT INTO v_scans
  FROM public.food_scans s WHERE s.user_id = v_uid;

  SELECT count(*)::INT INTO v_coach_messages
  FROM public.ai_chat_sessions c WHERE c.user_id = v_uid;

  SELECT count(DISTINCT i.food_name)::INT INTO v_distinct_foods
  FROM public.meal_items i
  JOIN public.meals m ON m.id = i.meal_id
  WHERE m.user_id = v_uid;

  IF v_target_water > 0 THEN
    SELECT count(*)::INT INTO v_water_goal_days_30
    FROM public.water_intake w
    WHERE w.user_id = v_uid
      AND w.date >= CURRENT_DATE - 30
      AND w.amount_ml >= v_target_water;
  END IF;

  IF v_target_protein > 0 THEN
    SELECT count(*)::INT INTO v_protein_goal_days_30
    FROM (
      SELECT m.date, sum(i.protein) AS protein
      FROM public.meals m
      JOIN public.meal_items i ON i.meal_id = m.id
      WHERE m.user_id = v_uid AND m.date >= CURRENT_DATE - 30
      GROUP BY m.date
    ) daily
    WHERE daily.protein >= v_target_protein * 0.9;
  END IF;

  IF v_target_calories > 0 THEN
    SELECT count(*)::INT INTO v_perfect_days_30
    FROM (
      SELECT m.date, sum(m.total_calories) AS calories
      FROM public.meals m
      WHERE m.user_id = v_uid AND m.date >= CURRENT_DATE - 30
      GROUP BY m.date
    ) daily
    WHERE daily.calories BETWEEN v_target_calories * 0.9 AND v_target_calories * 1.1;
  END IF;

  SELECT count(DISTINCT m.date)::INT INTO v_breakfast_days_7
  FROM public.meals m
  WHERE m.user_id = v_uid
    AND m.meal_type = 'breakfast'
    AND m.date >= CURRENT_DATE - 6;

  SELECT COALESCE((
    SELECT p.name IS NOT NULL
       AND p.age IS NOT NULL
       AND p.height_cm IS NOT NULL
       AND p.weight_kg IS NOT NULL
       AND p.activity_level IS NOT NULL
       AND p.goal_type IS NOT NULL
    FROM public.user_profiles p
    WHERE p.user_id = v_uid
  ), FALSE) INTO v_profile_complete;

  -- Today's activity
  SELECT EXISTS (
    SELECT 1 FROM public.meals m WHERE m.user_id = v_uid AND m.date = CURRENT_DATE
  ) INTO v_meal_today;

  SELECT EXISTS (
    SELECT 1 FROM public.meals m
    WHERE m.user_id = v_uid AND m.date = CURRENT_DATE AND m.meal_type = 'breakfast'
  ) INTO v_breakfast_today;

  SELECT EXISTS (
    SELECT 1 FROM public.water_intake w WHERE w.user_id = v_uid AND w.date = CURRENT_DATE
  ) INTO v_water_today;

  IF v_target_water > 0 THEN
    SELECT EXISTS (
      SELECT 1 FROM public.water_intake w
      WHERE w.user_id = v_uid AND w.date = CURRENT_DATE AND w.amount_ml >= v_target_water
    ) INTO v_water_goal_today;
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.weight_entries e WHERE e.user_id = v_uid AND e.date = CURRENT_DATE
  ) INTO v_weight_today;

  SELECT EXISTS (
    SELECT 1 FROM public.food_scans s WHERE s.user_id = v_uid AND s.created_at::DATE = CURRENT_DATE
  ) INTO v_scan_today;

  SELECT EXISTS (
    SELECT 1 FROM public.ai_chat_sessions c WHERE c.user_id = v_uid AND c.created_at::DATE = CURRENT_DATE
  ) INTO v_coach_today;

  IF v_target_calories > 0 THEN
    SELECT COALESCE((
      SELECT sum(m.total_calories) BETWEEN v_target_calories * 0.9 AND v_target_calories * 1.1
      FROM public.meals m
      WHERE m.user_id = v_uid AND m.date = CURRENT_DATE
    ), FALSE) INTO v_perfect_today;
  END IF;

  IF v_target_protein > 0 THEN
    SELECT COALESCE((
      SELECT sum(i.protein) >= v_target_protein * 0.9
      FROM public.meals m
      JOIN public.meal_items i ON i.meal_id = m.id
      WHERE m.user_id = v_uid AND m.date = CURRENT_DATE
    ), FALSE) INTO v_protein_today;
  END IF;

  RETURN jsonb_build_object(
    'authenticated', TRUE,
    'current_streak_days', v_current_streak,
    'longest_streak_days', v_longest_streak,
    'days_logged_7', v_days_logged_7,
    'meals_logged', v_meals_logged,
    'meals_logged_30', v_meals_logged_30,
    'water_days', v_water_days,
    'weight_entries', v_weight_entries,
    'weight_entries_30', v_weight_entries_30,
    'scans_count', v_scans,
    'coach_messages', v_coach_messages,
    'distinct_foods', v_distinct_foods,
    'water_goal_days_30', v_water_goal_days_30,
    'protein_goal_days_30', v_protein_goal_days_30,
    'perfect_days_30', v_perfect_days_30,
    'breakfast_days_7', v_breakfast_days_7,
    'profile_complete', v_profile_complete,
    'meal_logged_today', v_meal_today,
    'breakfast_today', v_breakfast_today,
    'water_logged_today', v_water_today,
    'water_goal_hit_today', v_water_goal_today,
    'weight_logged_today', v_weight_today,
    'scan_today', v_scan_today,
    'coach_today', v_coach_today,
    'perfect_day_today', v_perfect_today,
    'protein_goal_today', v_protein_today,
    'target_calories', v_target_calories,
    'target_protein', v_target_protein,
    'target_water_ml', v_target_water
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.compute_gamification_stats() TO authenticated;

-- ============================================================
-- Gamification: leaderboard
-- ============================================================
-- RLS on `gamification` is `auth.uid() = user_id`, so the client can only
-- read its own row. A SECURITY DEFINER function is the Supabase-blessed
-- way to expose a read-only ranking without weakening that policy.
-- Only safe columns are projected: rank, display name, avatar, XP, level,
-- tier and streak. No email, no raw rows, no write access.
--
-- p_scope: 'global' (all-time) | 'weekly' (XP earned since Monday).
--          'friends' has no friends graph yet, so it falls back to global
--          rather than pretending to filter.
CREATE OR REPLACE FUNCTION public.get_leaderboard(
  p_scope TEXT DEFAULT 'global',
  p_limit INT DEFAULT 50
)
RETURNS TABLE (
  rank INT,
  user_id UUID,
  display_name TEXT,
  avatar_url TEXT,
  xp INT,
  level INT,
  tier TEXT,
  streak_days INT,
  is_me BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_limit INT := greatest(1, least(COALESCE(p_limit, 50), 100));
  v_scope TEXT := lower(COALESCE(p_scope, 'global'));
BEGIN
  IF v_scope = 'weekly' THEN
    RETURN QUERY
    WITH weekly AS (
      SELECT e.user_id AS uid, sum(e.xp)::INT AS weekly_xp
      FROM public.xp_events e
      WHERE e.event_date >= date_trunc('week', now())::DATE
      GROUP BY e.user_id
      HAVING sum(e.xp) > 0
    )
    SELECT
      (row_number() OVER (ORDER BY w.weekly_xp DESC, w.uid))::INT AS rank,
      w.uid AS user_id,
      COALESCE(nullif(btrim(p.name), ''), 'FitFuel Athlete') AS display_name,
      p.avatar_url,
      w.weekly_xp AS xp,
      COALESCE(g.level, 1) AS level,
      COALESCE(g.tier, 'Bronze') AS tier,
      COALESCE(g.streak_days, 0) AS streak_days,
      (w.uid = auth.uid()) AS is_me
    FROM weekly w
    LEFT JOIN public.gamification g ON g.user_id = w.uid
    LEFT JOIN public.user_profiles p ON p.user_id = w.uid
    ORDER BY w.weekly_xp DESC, w.uid
    LIMIT v_limit;
  ELSE
    RETURN QUERY
    SELECT
      (row_number() OVER (ORDER BY g.xp_total DESC, g.updated_at ASC, g.user_id))::INT AS rank,
      g.user_id,
      COALESCE(nullif(btrim(p.name), ''), 'FitFuel Athlete') AS display_name,
      p.avatar_url,
      g.xp_total AS xp,
      g.level,
      g.tier,
      g.streak_days,
      (g.user_id = auth.uid()) AS is_me
    FROM public.gamification g
    LEFT JOIN public.user_profiles p ON p.user_id = g.user_id
    WHERE g.xp_total > 0
    ORDER BY g.xp_total DESC, g.updated_at ASC, g.user_id
    LIMIT v_limit;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.get_leaderboard(TEXT, INT) FROM public;
GRANT EXECUTE ON FUNCTION public.get_leaderboard(TEXT, INT) TO authenticated;

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Auto-recalculate meal total_calories from items
CREATE OR REPLACE FUNCTION public.recalc_meal_calories()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.meals
  SET total_calories = (
    SELECT COALESCE(SUM(calories), 0)
    FROM public.meal_items
    WHERE meal_id = NEW.meal_id
  )
  WHERE id = NEW.meal_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_recalc_meal_calories
  AFTER INSERT OR UPDATE OR DELETE ON public.meal_items
  FOR EACH ROW EXECUTE FUNCTION public.recalc_meal_calories();

-- Update goals timestamp
CREATE OR REPLACE FUNCTION public.update_goals_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_goals_timestamp
  BEFORE UPDATE ON public.goals
  FOR EACH ROW EXECUTE FUNCTION public.update_goals_timestamp();

-- Keep gamification.updated_at fresh on every XP rollup
CREATE OR REPLACE FUNCTION public.touch_gamification_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_touch_gamification_updated_at ON public.gamification;
CREATE TRIGGER trigger_touch_gamification_updated_at
  BEFORE UPDATE ON public.gamification
  FOR EACH ROW EXECUTE FUNCTION public.touch_gamification_updated_at();

-- ============================================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================================

-- Insert sample notification settings
INSERT INTO public.notifications (user_id, type, title, message, is_enabled, scheduled_time)
SELECT 
  id,
  'meal_reminder',
  'Meal Reminder',
  'Time to log your meal!',
  true,
  '12:00:00'
FROM auth.users
WHERE NOT EXISTS (
  SELECT 1 FROM public.notifications WHERE user_id = auth.users.id
)
LIMIT 1;
