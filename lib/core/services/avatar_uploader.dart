import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads a profile photo to Supabase Storage under:
///
///   profile/{userId}/{yyyy-MM-dd}/{timestamp}.jpg
///
/// and returns the public URL (to be saved into `user_profiles.avatar_url`).
///
/// NOTE: The bucket MUST be created server-side (see the `profile` storage
/// migration). It cannot be created at runtime from the client because the
/// anon key has no INSERT rights on `storage.buckets` (RLS).
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

    debugPrint('[AvatarUploader] uploading to bucket="$bucket" path="$path" '
        'bytes=${bytes.length}');

    final session = Supabase.instance.client.auth.currentSession;
    debugPrint('[AvatarUploader] authenticated=${session?.user != null} '
        'userId=$userId');

    try {
      await storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      debugPrint('[AvatarUploader] upload OK');
    } catch (e) {
      // Print the underlying cause including HTTP status / RLS info.
      debugPrint('[AvatarUploader] upload FAILED: $e');
      debugPrint('[AvatarUploader] error type: ${e.runtimeType}');
      if (e is StorageException) {
        debugPrint('[AvatarUploader] StorageException message=${e.message} '
            'statusCode=${e.statusCode}');
      }
      rethrow;
    }

    final url = storage.from(bucket).getPublicUrl(path);
    debugPrint('[AvatarUploader] public url=$url');
    return url;
  }
}