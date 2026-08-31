-- ============================================================
-- 006_profile_avatars_bucket.sql
-- Creates a public storage bucket 'profile' for user profile photos.
--
-- Files are stored under:
--   profile/{user_id}/{date}/{image}.jpg
--
-- e.g.  profile/77cfa4ee-.../2026-08-31/1725100000000.jpg
--
-- The public URL is saved into user_profiles.avatar_url so the image
-- shows on the home top bar, profile screen and personal info screen.
-- ============================================================

-- 1) Create the public bucket.
insert into storage.buckets (id, name, public)
values ('profile', 'profile', true)
on conflict (id) do nothing;

-- 2) Anyone can read (bucket is public -> used via public URLs).
drop policy if exists "Anyone can read profile avatar" on storage.objects;
create policy "Anyone can read profile avatar"
  on storage.objects for select
  using (bucket_id = 'profile');

-- 3) Users can upload their own image.
--    The first path segment must equal the user's auth uid, i.e.
--    profile/{user_id}/...
drop policy if exists "Users can upload own profile avatar" on storage.objects;
create policy "Users can upload own profile avatar"
  on storage.objects for insert
  with check (
    bucket_id = 'profile'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- 4) Users can overwrite their own image.
drop policy if exists "Users can update own profile avatar" on storage.objects;
create policy "Users can update own profile avatar"
  on storage.objects for update
  using (
    bucket_id = 'profile'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- 5) Users can delete their own image.
drop policy if exists "Users can delete own profile avatar" on storage.objects;
create policy "Users can delete own profile avatar"
  on storage.objects for delete
  using (
    bucket_id = 'profile'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- ============================================================
-- NOTE: If the previous 'avatars' bucket (migration 005) is no
-- longer needed you can optionally remove it with:
--
--   delete from storage.buckets where id = 'avatars';
-- ============================================================