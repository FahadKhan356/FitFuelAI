-- ============================================================
-- FitFuel AI — Weight Entries
-- ============================================================
-- The weight tracking feature reads/writes `public.weight_entries`,
-- but this table was only ever defined in schema.sql and never ported
-- into a numbered migration. Projects built from migrations 001-007
-- therefore have NO weight_entries table, so logging a weight silently
-- fails and the screen keeps showing the profile weight.
-- This migration creates it to match schema.sql exactly.

-- 1. Table
create table if not exists public.weight_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  weight_kg double precision not null,
  bmi double precision,
  body_fat double precision,
  notes text,
  created_at timestamptz default now()
);

create index if not exists idx_weight_entries_user_id_date
  on public.weight_entries(user_id, date);

-- 2. Row Level Security
alter table public.weight_entries enable row level security;

-- 3. Policies (match schema.sql)
drop policy if exists "Users can view own weight" on public.weight_entries;
create policy "Users can view own weight"
  on public.weight_entries for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own weight" on public.weight_entries;
create policy "Users can insert own weight"
  on public.weight_entries for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own weight" on public.weight_entries;
create policy "Users can update own weight"
  on public.weight_entries for update
  using (auth.uid() = user_id);

drop policy if exists "Users can delete own weight" on public.weight_entries;
create policy "Users can delete own weight"
  on public.weight_entries for delete
  using (auth.uid() = user_id);