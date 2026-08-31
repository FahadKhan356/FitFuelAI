import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads a profile photo to Supabase Storage under:
///
///   profile/{userId}/{yyyy-MM-dd}/{timestamp}.jpg
///
/// and returns the public URL (to be saved into `user_profiles.avatar_url`).
///
/// If the `profile` bucket hasn't been created yet (e.g. the storage migration
/// wasn't applied), it auto-creates the bucket and retries once so the feature
/// works even before migrations are run.
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

    try {
      await storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
    } catch (_) {
      // Bucket might be missing — try to create it (public) then retry once.
      try {
        await storage.createBucket(bucket,
            const BucketOptions(public: true));
        await storage.from(bucket).uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
      } catch (retryError) {
        // Re-throw so callers show a meaningful message.
        throw retryError;
      }
    }

    return storage.from(bucket).getPublicUrl(path);
  }
}