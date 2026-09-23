-- Keep existing deployed subscriptions tables aligned with SubscriptionModel.
-- The base schema already uses plan, status and expires_at; this extends the
-- plan check for the Lifetime plan exposed by the paywall.
ALTER TABLE public.subscriptions
  DROP CONSTRAINT IF EXISTS subscriptions_plan_check;

ALTER TABLE public.subscriptions
  ADD CONSTRAINT subscriptions_plan_check
  CHECK (plan IN ('free', 'premium_monthly', 'premium_yearly', 'premium_lifetime'));
