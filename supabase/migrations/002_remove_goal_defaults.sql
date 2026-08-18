-- ============================================================
-- FitFuel AI — Remove Goal Default Values
-- ============================================================

-- Remove default values from calculated nutrition targets
-- These should be calculated dynamically, not hardcoded

ALTER TABLE public.goals
ALTER COLUMN target_calories DROP DEFAULT;

ALTER TABLE public.goals
ALTER COLUMN target_protein DROP DEFAULT;

ALTER TABLE public.goals
ALTER COLUMN target_carbs DROP DEFAULT;

ALTER TABLE public.goals
ALTER COLUMN target_fat DROP DEFAULT;

ALTER TABLE public.goals
ALTER COLUMN daily_water_ml DROP DEFAULT;
