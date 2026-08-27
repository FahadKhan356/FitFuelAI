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

-- ============================================================
-- 13. SUBSCRIPTIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan TEXT DEFAULT 'free' CHECK (plan IN ('free', 'premium_monthly', 'premium_yearly')),
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
