-- ============================================================
-- FitFuel AI — Gamification: XP ledger, achievements & leaderboard
-- ============================================================
-- Before this migration the `gamification` and `achievements` tables
-- defined in schema.sql had READ paths only:
--   * `AchievementsBloc` selected from them, but nothing ever wrote,
--     so the Achievements screen always rendered hardcoded demo values.
--   * RLS on `gamification` allows `auth.uid() = user_id` only, so a
--     leaderboard could never read other players' rows from the client.
--
-- This migration supplies the missing write model:
--   1. `xp_events`  — append-only XP ledger (source of truth).
--   2. `achievements` gains a unique (user_id, badge) key so the app can
--      upsert progress instead of inserting duplicates.
--   3. `compute_gamification_stats()` — aggregates the user's own logs
--      into a single JSON snapshot (still SECURITY INVOKER + RLS).
--   4. `get_leaderboard()` — SECURITY DEFINER, exposes only safe columns.

-- ============================================================
-- 1. XP EVENTS (append-only ledger)
-- ============================================================
-- One row per XP award. `xp_total` on `gamification` is a cached rollup
-- that can always be rebuilt with `sum(xp)` over this table.
create table if not exists public.xp_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source text not null,
  xp int not null check (xp > 0),
  event_date date not null default current_date,
  created_at timestamptz not null default now()
);

-- Daily awards are idempotent: re-running the evaluator on the same day
-- for the same source is a no-op (the app inserts with ignoreDuplicates).
create unique index if not exists idx_xp_events_user_source_date
  on public.xp_events(user_id, source, event_date);

create index if not exists idx_xp_events_user_date
  on public.xp_events(user_id, event_date desc);

-- ============================================================
-- 2. ACHIEVEMENTS — dedupe + unique key
-- ============================================================
-- Collapse any pre-existing duplicates, keeping the earliest row.
delete from public.achievements a
where exists (
  select 1
  from public.achievements b
  where b.user_id = a.user_id
    and b.badge = a.badge
    and (b.created_at, b.id) < (a.created_at, a.id)
);

create unique index if not exists idx_achievements_user_badge
  on public.achievements(user_id, badge);

-- ============================================================
-- 3. GAMIFICATION — keep updated_at fresh on every rollup
-- ============================================================
create or replace function public.touch_gamification_updated_at()
returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trigger_touch_gamification_updated_at on public.gamification;
create trigger trigger_touch_gamification_updated_at
  before update on public.gamification
  for each row execute function public.touch_gamification_updated_at();

-- ============================================================
-- 4. RLS for the XP ledger
-- ============================================================
alter table public.xp_events enable row level security;

drop policy if exists "Users can view own xp events" on public.xp_events;
create policy "Users can view own xp events"
  on public.xp_events for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own xp events" on public.xp_events;
create policy "Users can insert own xp events"
  on public.xp_events for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own xp events" on public.xp_events;
create policy "Users can delete own xp events"
  on public.xp_events for delete
  using (auth.uid() = user_id);

-- ============================================================
-- 5. STATS SNAPSHOT
-- ============================================================
-- Pure counting/aggregation over the caller's own rows — no business
-- rules. XP values, the level curve and badge criteria live in the app
-- (`lib/core/utils/xp_engine.dart`) so they stay unit testable.
--
-- SECURITY INVOKER: the caller's RLS policies apply, so this can only
-- ever read rows belonging to `auth.uid()`.
create or replace function public.compute_gamification_stats()
returns jsonb
language plpgsql
security invoker
stable
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_target_calories int := 0;
  v_target_protein double precision := 0;
  v_target_water int := 0;

  v_current_streak int := 0;
  v_longest_streak int := 0;
  v_days_logged_7 int := 0;

  v_meals_logged int := 0;
  v_meals_logged_30 int := 0;
  v_water_days int := 0;
  v_weight_entries int := 0;
  v_weight_entries_30 int := 0;
  v_scans int := 0;
  v_coach_messages int := 0;
  v_distinct_foods int := 0;

  v_water_goal_days_30 int := 0;
  v_protein_goal_days_30 int := 0;
  v_perfect_days_30 int := 0;
  v_breakfast_days_7 int := 0;
  v_profile_complete boolean := false;
begin
  if v_uid is null then
    return jsonb_build_object('authenticated', false);
  end if;

  -- Nutrition targets (single row per user, upserted by calculate_user_goals)
  select g.target_calories, g.target_protein, g.daily_water_ml
    into v_target_calories, v_target_protein, v_target_water
  from public.goals g
  where g.user_id = v_uid
  order by g.updated_at desc
  limit 1;

  v_target_calories := coalesce(v_target_calories, 0);
  v_target_protein := coalesce(v_target_protein, 0);
  v_target_water := coalesce(v_target_water, 0);

  -- ── Streak: consecutive days with a meal OR a water entry ──
  -- Gaps-and-islands: subtracting a row number from the date collapses
  -- every consecutive run onto one constant group key.
  with activity as (
    select distinct d from (
      select m.date as d from public.meals m
        where m.user_id = v_uid and m.date >= current_date - 400
      union
      select w.date as d from public.water_intake w
        where w.user_id = v_uid and w.date >= current_date - 400
    ) merged
  ),
  grouped as (
    select d, d - (row_number() over (order by d))::int as grp from activity
  ),
  runs as (
    select grp, count(*)::int as len, max(d) as last_day from grouped group by grp
  )
  select
    coalesce(max(len) filter (where last_day >= current_date - 1), 0),
    coalesce(max(len), 0)
  into v_current_streak, v_longest_streak
  from runs;

  select count(*)::int into v_days_logged_7
  from (
    select m.date as d from public.meals m
      where m.user_id = v_uid and m.date >= current_date - 6
    union
    select w.date as d from public.water_intake w
      where w.user_id = v_uid and w.date >= current_date - 6
  ) recent;

  -- ── Simple counters ──
  select count(*)::int into v_meals_logged
  from public.meals m where m.user_id = v_uid;

  select count(*)::int into v_meals_logged_30
  from public.meals m where m.user_id = v_uid and m.date >= current_date - 30;

  select count(*)::int into v_water_days
  from public.water_intake w where w.user_id = v_uid;

  select count(*)::int into v_weight_entries
  from public.weight_entries e where e.user_id = v_uid;

  select count(*)::int into v_weight_entries_30
  from public.weight_entries e
  where e.user_id = v_uid and e.date >= current_date - 30;

  select count(*)::int into v_scans
  from public.food_scans s where s.user_id = v_uid;

  select count(*)::int into v_coach_messages
  from public.ai_chat_sessions c where c.user_id = v_uid;

  select count(distinct i.food_name)::int into v_distinct_foods
  from public.meal_items i
  join public.meals m on m.id = i.meal_id
  where m.user_id = v_uid;

  -- ── Goal-hit counters (last 30 days) ──
  if v_target_water > 0 then
    select count(*)::int into v_water_goal_days_30
    from public.water_intake w
    where w.user_id = v_uid
      and w.date >= current_date - 30
      and w.amount_ml >= v_target_water;
  end if;

  if v_target_protein > 0 then
    select count(*)::int into v_protein_goal_days_30
    from (
      select m.date, sum(i.protein) as protein
      from public.meals m
      join public.meal_items i on i.meal_id = m.id
      where m.user_id = v_uid and m.date >= current_date - 30
      group by m.date
    ) daily
    where daily.protein >= v_target_protein * 0.9;
  end if;

  if v_target_calories > 0 then
    select count(*)::int into v_perfect_days_30
    from (
      select m.date, sum(m.total_calories) as calories
      from public.meals m
      where m.user_id = v_uid and m.date >= current_date - 30
      group by m.date
    ) daily
    where daily.calories between v_target_calories * 0.9 and v_target_calories * 1.1;
  end if;

  select count(distinct m.date)::int into v_breakfast_days_7
  from public.meals m
  where m.user_id = v_uid
    and m.meal_type = 'breakfast'
    and m.date >= current_date - 6;

  -- ── Profile completeness ──
  select coalesce((
    select p.name is not null
       and p.age is not null
       and p.height_cm is not null
       and p.weight_kg is not null
       and p.activity_level is not null
       and p.goal_type is not null
    from public.user_profiles p
    where p.user_id = v_uid
  ), false) into v_profile_complete;

  return jsonb_build_object(
    'authenticated', true,
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
    'target_calories', v_target_calories,
    'target_protein', v_target_protein,
    'target_water_ml', v_target_water
  );
end;
$$;

grant execute on function public.compute_gamification_stats() to authenticated;

-- ============================================================
-- 6. LEADERBOARD
-- ============================================================
-- RLS on `gamification` is `auth.uid() = user_id`, so the client can only
-- read its own row. A SECURITY DEFINER function is the Supabase-blessed
-- way to expose a read-only ranking without weakening that policy.
--
-- Only safe columns are projected: rank, display name, avatar, XP, level,
-- tier and streak. No email, no raw rows, no write access.
--
-- p_scope: 'global' (all-time) | 'weekly' (XP earned since Monday).
--          'friends' has no friends graph yet, so it falls back to global
--          rather than pretending to filter.
create or replace function public.get_leaderboard(
  p_scope text default 'global',
  p_limit int default 50
)
returns table (
  rank int,
  user_id uuid,
  display_name text,
  avatar_url text,
  xp int,
  level int,
  tier text,
  streak_days int,
  is_me boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_limit int := greatest(1, least(coalesce(p_limit, 50), 100));
  v_scope text := lower(coalesce(p_scope, 'global'));
begin
  if v_scope = 'weekly' then
    return query
    with weekly as (
      select e.user_id as uid, sum(e.xp)::int as weekly_xp
      from public.xp_events e
      where e.event_date >= date_trunc('week', now())::date
      group by e.user_id
      having sum(e.xp) > 0
    )
    select
      (row_number() over (order by w.weekly_xp desc, w.uid))::int as rank,
      w.uid as user_id,
      coalesce(nullif(btrim(p.name), ''), 'FitFuel Athlete') as display_name,
      p.avatar_url,
      w.weekly_xp as xp,
      coalesce(g.level, 1) as level,
      coalesce(g.tier, 'Bronze') as tier,
      coalesce(g.streak_days, 0) as streak_days,
      (w.uid = auth.uid()) as is_me
    from weekly w
    left join public.gamification g on g.user_id = w.uid
    left join public.user_profiles p on p.user_id = w.uid
    order by w.weekly_xp desc, w.uid
    limit v_limit;
  else
    return query
    select
      (row_number() over (order by g.xp_total desc, g.updated_at asc, g.user_id))::int as rank,
      g.user_id,
      coalesce(nullif(btrim(p.name), ''), 'FitFuel Athlete') as display_name,
      p.avatar_url,
      g.xp_total as xp,
      g.level,
      g.tier,
      g.streak_days,
      (g.user_id = auth.uid()) as is_me
    from public.gamification g
    left join public.user_profiles p on p.user_id = g.user_id
    where g.xp_total > 0
    order by g.xp_total desc, g.updated_at asc, g.user_id
    limit v_limit;
  end if;
end;
$$;

revoke all on function public.get_leaderboard(text, int) from public;
grant execute on function public.get_leaderboard(text, int) to authenticated;
