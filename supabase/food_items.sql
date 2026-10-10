-- FitFuel AI — Hybrid Food Search Cache Table
-- Stores cached food items from FatSecret and Gemini fallback

CREATE TABLE IF NOT EXISTS public.food_items (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  search_key      TEXT NOT NULL,
  country_code    VARCHAR(5) NOT NULL DEFAULT 'GLOBAL',
  food_name       TEXT NOT NULL,
  cuisine_type    TEXT,
  serving_quantity NUMERIC NOT NULL DEFAULT 100,
  serving_unit    TEXT NOT NULL DEFAULT 'grams',
  calories        NUMERIC NOT NULL DEFAULT 0,
  protein_g       NUMERIC NOT NULL DEFAULT 0,
  carbs_g         NUMERIC NOT NULL DEFAULT 0,
  fat_g           NUMERIC NOT NULL DEFAULT 0,
  sodium_mg       NUMERIC DEFAULT 0,
  potassium_mg    NUMERIC DEFAULT 0,
  fiber_g         NUMERIC DEFAULT 0,
  sugar_g         NUMERIC DEFAULT 0,
  source          TEXT NOT NULL DEFAULT 'gemini_ai',
  accuracy_warning BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_food_search ON public.food_items (search_key, country_code);
CREATE INDEX IF NOT EXISTS idx_food_name   ON public.food_items (food_name);

-- RLS
ALTER TABLE public.food_items ENABLE ROW LEVEL SECURITY;

-- All logged-in users can read
DROP POLICY IF EXISTS "Anyone can read food_items" ON public.food_items;
CREATE POLICY "Anyone can read food_items"
  ON public.food_items FOR SELECT
  TO authenticated
  USING (true);

-- Authenticated users can insert cached items
DROP POLICY IF EXISTS "Service role can insert food_items" ON public.food_items;
DROP POLICY IF EXISTS "Users can insert food_items" ON public.food_items;
CREATE POLICY "Users can insert food_items"
  ON public.food_items FOR INSERT
  TO authenticated
  WITH CHECK (true);
