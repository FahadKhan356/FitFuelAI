-- ============================================================================
-- FitFuel AI: User AI Quota & Limits Tracking
-- Enforces 24-hour rolling / daily reset quotas for AI Chat & Food Scans
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.user_ai_limits (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_type TEXT DEFAULT 'free', -- 'free', 'monthly', 'annual', 'lifetime'
  daily_chat_limit INT DEFAULT 3,
  daily_scan_limit INT DEFAULT 2,
  chats_used_today INT DEFAULT 0,
  scans_used_today INT DEFAULT 0,
  last_reset_date DATE DEFAULT CURRENT_DATE
);

-- RLS: Authenticated users can view and update their own limits
ALTER TABLE public.user_ai_limits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own ai limits"
ON public.user_ai_limits
FOR ALL
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- Function: check_and_consume_ai_quota
-- Atomically resets daily count if past last_reset_date, checks limit,
-- increments usage, and returns status JSON.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_and_consume_ai_quota(
  p_user_id UUID,
  p_quota_type TEXT, -- 'chat' or 'scan'
  p_local_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_plan_type TEXT := 'free';
  v_chat_limit INT := 3;
  v_scan_limit INT := 2;
  v_row RECORD;
  v_allowed BOOLEAN := FALSE;
  v_used INT := 0;
  v_limit INT := 0;
  v_remaining INT := 0;
BEGIN
  -- Determine user's active subscription tier from subscriptions table if present
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'subscriptions'
  ) THEN
    SELECT COALESCE(plan, 'free') INTO v_plan_type
    FROM public.subscriptions
    WHERE user_id = p_user_id AND status = 'active'
    LIMIT 1;
  END IF;

  -- Default limits per tier:
  -- Free: 3 chats / day, 2 scans / day
  -- Monthly / Annual: 100 chats / day, 30 scans / day
  -- Lifetime Legend: 50 chats / day, 20 scans / day
  IF v_plan_type IN ('monthly', 'premium_monthly', 'annual', 'premium_yearly', 'yearly') THEN
    v_chat_limit := 100;
    v_scan_limit := 30;
  ELSIF v_plan_type IN ('lifetime', 'premium_lifetime') THEN
    v_chat_limit := 50;
    v_scan_limit := 20;
  ELSE
    v_plan_type := 'free';
    v_chat_limit := 3;
    v_scan_limit := 2;
  END IF;

  -- Upsert user_ai_limits record
  INSERT INTO public.user_ai_limits (
    user_id, plan_type, daily_chat_limit, daily_scan_limit, chats_used_today, scans_used_today, last_reset_date
  )
  VALUES (
    p_user_id, v_plan_type, v_chat_limit, v_scan_limit, 0, 0, p_local_date
  )
  ON CONFLICT (user_id) DO UPDATE SET
    plan_type = EXCLUDED.plan_type,
    daily_chat_limit = EXCLUDED.daily_chat_limit,
    daily_scan_limit = EXCLUDED.daily_scan_limit,
    chats_used_today = CASE 
      WHEN user_ai_limits.last_reset_date < p_local_date THEN 0 
      ELSE user_ai_limits.chats_used_today 
    END,
    scans_used_today = CASE 
      WHEN user_ai_limits.last_reset_date < p_local_date THEN 0 
      ELSE user_ai_limits.scans_used_today 
    END,
    last_reset_date = p_local_date;

  -- Fetch current state for atomic quota check
  SELECT * INTO v_row FROM public.user_ai_limits WHERE user_id = p_user_id;

  IF p_quota_type = 'chat' THEN
    v_limit := v_row.daily_chat_limit;
    IF v_row.chats_used_today < v_limit THEN
      UPDATE public.user_ai_limits 
      SET chats_used_today = chats_used_today + 1 
      WHERE user_id = p_user_id;
      
      v_allowed := TRUE;
      v_used := v_row.chats_used_today + 1;
    ELSE
      v_allowed := FALSE;
      v_used := v_row.chats_used_today;
    END IF;
  ELSIF p_quota_type = 'scan' THEN
    v_limit := v_row.daily_scan_limit;
    IF v_row.scans_used_today < v_limit THEN
      UPDATE public.user_ai_limits 
      SET scans_used_today = scans_used_today + 1 
      WHERE user_id = p_user_id;
      
      v_allowed := TRUE;
      v_used := v_row.scans_used_today + 1;
    ELSE
      v_allowed := FALSE;
      v_used := v_row.scans_used_today;
    END IF;
  END IF;

  v_remaining := GREATEST(0, v_limit - v_used);

  RETURN jsonb_build_object(
    'allowed', v_allowed,
    'quota_type', p_quota_type,
    'used_today', v_used,
    'daily_limit', v_limit,
    'remaining', v_remaining,
    'plan_type', v_plan_type
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- Function: get_user_ai_limits
-- Retrieves current quota status without incrementing consumption.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_user_ai_limits(
  p_user_id UUID,
  p_local_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_plan_type TEXT := 'free';
  v_chat_limit INT := 3;
  v_scan_limit INT := 2;
  v_row RECORD;
BEGIN
  -- Determine user's active subscription tier
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'subscriptions'
  ) THEN
    SELECT COALESCE(plan, 'free') INTO v_plan_type
    FROM public.subscriptions
    WHERE user_id = p_user_id AND status = 'active'
    LIMIT 1;
  END IF;

  IF v_plan_type IN ('monthly', 'premium_monthly', 'annual', 'premium_yearly', 'yearly') THEN
    v_chat_limit := 100;
    v_scan_limit := 30;
  ELSIF v_plan_type IN ('lifetime', 'premium_lifetime') THEN
    v_chat_limit := 50;
    v_scan_limit := 20;
  ELSE
    v_plan_type := 'free';
    v_chat_limit := 3;
    v_scan_limit := 2;
  END IF;

  -- Ensure record exists & check date reset
  INSERT INTO public.user_ai_limits (
    user_id, plan_type, daily_chat_limit, daily_scan_limit, chats_used_today, scans_used_today, last_reset_date
  )
  VALUES (
    p_user_id, v_plan_type, v_chat_limit, v_scan_limit, 0, 0, p_local_date
  )
  ON CONFLICT (user_id) DO UPDATE SET
    plan_type = EXCLUDED.plan_type,
    daily_chat_limit = EXCLUDED.daily_chat_limit,
    daily_scan_limit = EXCLUDED.daily_scan_limit,
    chats_used_today = CASE 
      WHEN user_ai_limits.last_reset_date < p_local_date THEN 0 
      ELSE user_ai_limits.chats_used_today 
    END,
    scans_used_today = CASE 
      WHEN user_ai_limits.last_reset_date < p_local_date THEN 0 
      ELSE user_ai_limits.scans_used_today 
    END,
    last_reset_date = p_local_date;

  SELECT * INTO v_row FROM public.user_ai_limits WHERE user_id = p_user_id;

  RETURN jsonb_build_object(
    'user_id', v_row.user_id,
    'plan_type', v_row.plan_type,
    'daily_chat_limit', v_row.daily_chat_limit,
    'daily_scan_limit', v_row.daily_scan_limit,
    'chats_used_today', v_row.chats_used_today,
    'scans_used_today', v_row.scans_used_today,
    'chats_remaining', GREATEST(0, v_row.daily_chat_limit - v_row.chats_used_today),
    'scans_remaining', GREATEST(0, v_row.daily_scan_limit - v_row.scans_used_today),
    'last_reset_date', v_row.last_reset_date
  );
END;
$$;
