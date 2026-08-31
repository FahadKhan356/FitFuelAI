-- ============================================================
-- 007_fix_profile_bucket_rls.sql
-- Fixes the folder check in the 'profile' storage RLS policies.
--
-- Upload path: profile/{userId}/{date}/{image}.jpg
--
-- storage.foldername('profile/{uid}/{date}/{file}.jpg')
--   -> { profile, {uid}, {date} }   (Postgres arrays are 1-indexed)
--
-- So [1] = 'profile'  (bucket name only) and [2] = the userId.
-- The earlier policies used [1], which never matched auth.uid()
-- and every upload failed with:
--   'new row violates row-level security policy' (403).
-- ============================================================

-- Ensure the public bucket exists (idempotent).
insert into storage.buckets (id, name, public)
values ('profile', 'profile', true)
on conflict (id) do nothing;

-- 1) Anyone can read (bucket is public).
drop policy if exists "Anyone can read profile avatar" on storage.objects;
create policy "Anyone can read profile avatar"
  on storage.objects for select
  using (bucket_id = 'profile');

-- 2) Users can upload their own image.
--    Path: profile/{user_id}/...  -> userId is the 2nd folder: [2]
drop policy if exists "Users can upload own profile avatar" on storage.objects;
create policy "Users can upload own profile avatar"
  on storage.objects for insert
  with check (
    bucket_id = 'profile'
    and auth.uid()::text = (storage.foldername(name))[2]
  );

-- 3) Users can overwrite their own image.
drop policy if exists "Users can update own profile avatar" on storage.objects;
create policy "Users can update own profile avatar"
  on storage.objects for update
  using (
    bucket_id = 'profile'
    and auth.uid()::text = (storage.foldername(name))[2]
  );

-- 4) Users can delete their own image.
drop policy if exists "Users can delete own profile avatar" on storage.objects;
create policy "Users can delete own profile avatar"
  on storage.objects for delete
  using (
    bucket_id = 'profile'
    and auth.uid()::text = (storage.foldername(name))[2]
  );