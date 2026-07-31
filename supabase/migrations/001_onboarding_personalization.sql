-- ============================================================
-- FitFuel AI — Onboarding & Personalization Tables
-- Run this in your Supabase SQL Editor (https://supabase.com/dashboard)
-- ============================================================

-- ------------------------------------------------------------
-- 1. user_profiles table
--    Stores biological metrics & preferences from onboarding
-- ------------------------------------------------------------
create table if not exists public.user_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text,
  avatar_url text,
  age int,
  gender text check (gender in ('male', 'female', 'other')),
  height_cm numeric(5,1),
  weight_kg numeric(5,1),
  goal_weight_kg numeric(5,1),
  activity_level text check (activity_level in ('sedentary', 'lightly_active', 'moderately_active', 'very_active')),
  goal_type text check (goal_type in ('weight_loss', 'weight_gain', 'maintain', 'cutting')),
  diet_preference text check (diet_preference in ('balanced', 'high_protein', 'keto', 'vegan')),
  workout_frequency int default 3,
  bio text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (user_id)
);

-- Auto-update updated_at on profile changes
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists set_user_profiles_updated_at on public.user_profiles;
create trigger set_user_profiles_updated_at
  before update on public.user_profiles
  for each row execute function public.handle_updated_at();

-- ------------------------------------------------------------
-- 2. goals table
--    Stores calculated nutrition targets from FitnessCalculator
-- ------------------------------------------------------------
create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  goal_type text check (goal_type in ('weight_loss', 'weight_gain', 'maintain', 'cutting')),
  target_weight_kg numeric(5,1),
  weekly_pace_kg numeric(4,2) default 0.5,
  target_date date,
  target_calories int not null default 2000,
  target_protein numeric(6,1) not null default 150,
  target_carbs numeric(6,1) not null default 200,
  target_fat numeric(6,1) not null default 65,
  daily_water_ml int not null default 2500,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (user_id)
);

drop trigger if exists set_goals_updated_at on public.goals;
create trigger set_goals_updated_at
  before update on public.goals
  for each row execute function public.handle_updated_at();

-- ------------------------------------------------------------
-- 3. Row Level Security (RLS) — users can only touch their own rows
-- ------------------------------------------------------------
alter table public.user_profiles enable row level security;
alter table public.goals enable row level security;

-- user_profiles policies
drop policy if exists "Users can view own profile" on public.user_profiles;
create policy "Users can view own profile"
  on public.user_profiles for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own profile" on public.user_profiles;
create policy "Users can insert own profile"
  on public.user_profiles for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own profile" on public.user_profiles;
create policy "Users can update own profile"
  on public.user_profiles for update
  using (auth.uid() = user_id);

-- goals policies
drop policy if exists "Users can view own goals" on public.goals;
create policy "Users can view own goals"
  on public.goals for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own goals" on public.goals;
create policy "Users can insert own goals"
  on public.goals for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own goals" on public.goals;
create policy "Users can update own goals"
  on public.goals for update
  using (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 4. Helper function to harvest all onboarding data into a single JSON
--    (Optional — useful for dashboards / debugging)
-- ------------------------------------------------------------
create or replace function public.get_user_onboarding_summary(p_user_id uuid)
returns jsonb
language sql
security definer
stable
as $$
  select jsonb_build_object(
    'profile', to_jsonb(p),
    'goals', to_jsonb(g)
  )
  from public.user_profiles p
  left join public.goals g on g.user_id = p.user_id
  where p.user_id = p_user_id;
$$;