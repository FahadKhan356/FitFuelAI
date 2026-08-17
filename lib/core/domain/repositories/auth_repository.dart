import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signInWithEmail(String email, String password);
  Future<UserEntity> signUpWithEmail(String email, String password);
  Future<void> signOut();
  UserEntity? getCurrentUser();
  Stream<UserEntity?> get authStateChanges;
  /// If the device has locally-saved onboarding data (SharedPreferences),
  /// upload it to the server for the given `userId` and clear the local cache.
  Future<void> syncLocalOnboarding(String userId);
}