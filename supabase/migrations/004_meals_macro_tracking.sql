-- ============================================================
-- FitFuel AI — Meals & Meal Items (macro tracking)
-- ============================================================

-- Meals table (one row per meal type per day, totals denormalized)
create table if not exists public.meals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null default current_date,
  meal_type text not null,
  total_calories int not null default 0,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Meal items table (individual logged foods with macros per serving)
create table if not exists public.meal_items (
  id uuid primary key default gen_random_uuid(),
  meal_id uuid not null references public.meals(id) on delete cascade,
  food_name text not null,
  calories int not null default 0,
  protein numeric(6,1) not null default 0,
  carbs numeric(6,1) not null default 0,
  fat numeric(6,1) not null default 0,
  fiber numeric(6,1) default 0,
  sugar numeric(6,1) default 0,
  sodium numeric(8,1) default 0,
  serving_size numeric(8,1) default 100,
  serving_unit text default 'g',
  photo_url text,
  created_at timestamptz default now()
);

create index if not exists meals_user_date_idx on public.meals (user_id, date);
create index if not exists meal_items_meal_idx on public.meal_items (meal_id);

-- Row Level Security
alter table public.meals enable row level security;
alter table public.meal_items enable row level security;

drop policy if exists "Users can view own meals" on public.meals;
create policy "Users can view own meals"
  on public.meals for select using (auth.uid() = user_id);
drop policy if exists "Users can insert own meals" on public.meals;
create policy "Users can insert own meals"
  on public.meals for insert with check (auth.uid() = user_id);
drop policy if exists "Users can update own meals" on public.meals;
create policy "Users can update own meals"
  on public.meals for update using (auth.uid() = user_id);
drop policy if exists "Users can delete own meals" on public.meals;
create policy "Users can delete own meals"
  on public.meals for delete using (auth.uid() = user_id);

drop policy if exists "Users can view own meal items" on public.meal_items;
create policy "Users can view own meal items"
  on public.meal_items
  for select using (
    exists (select 1 from public.meals m where m.id = meal_items.meal_id and m.user_id = auth.uid())
  );
drop policy if exists "Users can insert own meal items" on public.meal_items;
create policy "Users can insert own meal items"
  on public.meal_items
  for insert with check (
    exists (select 1 from public.meals m where m.id = meal_items.meal_id and m.user_id = auth.uid())
  );
drop policy if exists "Users can delete own meal items" on public.meal_items;
create policy "Users can delete own meal items"
  on public.meal_items
  for delete using (
    exists (select 1 from public.meals m where m.id = meal_items.meal_id and m.user_id = auth.uid())
  );