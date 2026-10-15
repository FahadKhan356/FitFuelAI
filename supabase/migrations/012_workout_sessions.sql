-- Migration: 012_workout_sessions.sql
-- Table: workout_sessions for Posture Coach exercises & calories tracking

CREATE TABLE IF NOT EXISTS public.workout_sessions (
  id               UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id          UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  exercise_name    TEXT NOT NULL,
  sets_completed   INTEGER DEFAULT 0,
  reps_completed   INTEGER DEFAULT 0,
  duration_seconds INTEGER DEFAULT 0,
  calories_burned  NUMERIC DEFAULT 0,
  met_value        NUMERIC DEFAULT 0,
  session_date     DATE DEFAULT CURRENT_DATE,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- Index for dashboard queries
CREATE INDEX IF NOT EXISTS idx_workout_user_date
  ON public.workout_sessions (user_id, session_date);

-- RLS
ALTER TABLE public.workout_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own workouts"
  ON public.workout_sessions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
