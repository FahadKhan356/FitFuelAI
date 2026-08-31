-- ============================================================
-- 005_avatars_storage_bucket.sql
-- Creates a public storage bucket for user profile photos.
-- Images are publicly readable so the profile photo can be shown
-- anywhere (home top bar, profile screen, etc.) without auth.
-- Users can only Upload / Delete their own files.
-- ============================================================

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Allow authenticated users to read any avatar (required since the bucket is
-- public and used via public URLs).
drop policy if exists "Anyone can read avatars" on storage.objects;
create policy "Anyone can read avatars"
  on storage.objects for select
  using (bucket_id = 'avatars');

-- Allow users to upload their own avatar image.
drop policy if exists "Users can upload own avatar" on storage.objects;
create policy "Users can upload own avatar"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- Allow users to update / overwrite their own avatar image.
drop policy if exists "Users can update own avatar" on storage.objects;
create policy "Users can update own avatar"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- Allow users to delete their own avatar image.
drop policy if exists "Users can delete own avatar" on storage.objects;
create policy "Users can delete own avatar"
  on storage.objects for delete
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );