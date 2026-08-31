import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads a profile photo to Supabase Storage under:
///
///   profile/{userId}/{yyyy-MM-dd}/{timestamp}.jpg
///
/// and returns the public URL (to be saved into `user_profiles.avatar_url`).
///
/// NOTE: The bucket MUST be created server-side (see the `profile` storage
/// migration). It cannot be created at runtime from the client because the
/// anon key has no INSERT rights on `storage.buckets` (RLS) — attempting to do
/// so throws "new row violates row-level security policy for table buckets".
class AvatarUploader {
  const AvatarUploader._();

  static const String bucket = 'profile';

  static Future<String> upload({
    required String userId,
    required Uint8List bytes,
  }) async {
    final storage = Supabase.instance.client.storage;

    final now = DateTime.now();
    final dateStr = now.toIso8601String().split('T').first;
    final path =
        'profile/$userId/$dateStr/${now.millisecondsSinceEpoch}.jpg';

    await storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    return storage.from(bucket).getPublicUrl(path);
  }
}