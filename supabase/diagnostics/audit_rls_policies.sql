-- ============================================================
-- FitFuel AI — RLS policy audit (read-only, safe to run on production)
-- ============================================================
-- Run this in the Supabase SQL editor when the app reports
--   42501: new row violates row-level security policy for table "..."
-- That error means the table has RLS enabled but no PERMISSIVE policy
-- covering the write PostgREST attempted. `create table if not exists` in
-- schema.sql is a no-op on a table that already exists, so the policy block
-- beneath it never re-applies to older projects — re-run
-- `supabase/migrations/010_gamification_leaderboard.sql` to repair it.
--
-- Expected state for the gamification feature:
--   gamification  -> SELECT, INSERT, UPDATE   (app upserts the XP rollup)
--   achievements  -> SELECT, INSERT, UPDATE   (app upserts badge progress)
--   xp_events     -> SELECT, INSERT, DELETE   (append-only XP ledger)
-- Any table above showing fewer commands than its row lists is the bug.

-- ── Query 1: is RLS on, and how many policies cover each table? ──
select
  c.relname                                                           as table_name,
  c.relrowsecurity                                                    as rls_enabled,
  count(p.policyname)                                                 as policy_count,
  coalesce(string_agg(distinct p.cmd, ', ' order by p.cmd), '(none)') as commands
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
left join pg_policies p
       on p.schemaname = n.nspname
      and p.tablename = c.relname
where n.nspname = 'public'
  and c.relkind = 'r'
  and c.relname in ('gamification', 'achievements', 'xp_events')
group by 1, 2
order by 1;

-- ── Query 2: the full policy definitions, when query 1 looks wrong ──
-- `permissive` must be PERMISSIVE: a single RESTRICTIVE policy is ANDed into
-- every other policy and would still reject the app's write on its own.
select
  tablename,
  policyname,
  cmd,
  permissive::text as permissive,
  roles::text      as roles,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename in ('gamification', 'achievements', 'xp_events')
order by tablename, cmd, policyname;
