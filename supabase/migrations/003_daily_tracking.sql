-- ============================================================
-- FitFuel AI — Per-Day Tracking & Calendar Support
-- ============================================================

-- ------------------------------------------------------------
-- 1. Daily summary view.
--    Produces one record per (user_id, date) combining total
--    water (from water_intake) and total calories (from meals).
--    This powers the activity calendar with green-tick markers.
-- ------------------------------------------------------------
create or replace view public.daily_summary as
select
  coalesce(w.user_id, m.user_id) as user_id,
  coalesce(w.entry_date, m.entry_date) as entry_date,
  coalesce(w.total_water_ml, 0) as total_water_ml,
  coalesce(m.total_calories, 0) as total_calories
from (
  select user_id, date as entry_date, sum(amount_ml) as total_water_ml
  from public.water_intake
  group by user_id, date
) w
full outer join (
  select user_id, date as entry_date, sum(total_calories) as total_calories
  from public.meals
  group by user_id, date
) m
  on w.user_id = m.user_id and w.entry_date = m.entry_date;

-- ------------------------------------------------------------
-- 2. Water per-day uniqueness (SAFE MERGE — NO DATA LOSS).
--    Same (user_id, date) rows are summed into a single record,
--    keeping the oldest row to hold the running total, then the
--    leftover duplicates are removed and a unique index enforces
--    one row per (user, date) going forward.
--    Example: 250 + 250 + 250 + 500 + 100 on one date → 1350.
-- ------------------------------------------------------------
-- (a) Compute sums and pick one "keeper" row per (user_id, date).
create temp table _water_merged on commit drop as
select
  (array_agg(id order by created_at asc, id asc))[1] as keep_id,
  user_id,
  date,
  sum(amount_ml) as total_ml
from public.water_intake
group by user_id, date;

-- (b) Write the summed total into the keeper row.
update public.water_intake as w
set amount_ml = m.total_ml
from _water_merged m
where w.id = m.keep_id
  and w.amount_ml is distinct from m.total_ml;

-- (c) Remove the duplicate rows (the ones that were NOT the keeper).
delete from public.water_intake as w
using _water_merged m
where w.user_id = m.user_id
  and w.date = m.date
  and w.id <> m.keep_id;

-- (d) Enforce the per-day uniqueness going forward.
create unique index if not exists water_intake_user_date_uidx
  on public.water_intake (user_id, date);

drop table _water_merged;