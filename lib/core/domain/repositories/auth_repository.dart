import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signInWithEmail(String email, String password);
  Future<UserEntity> signUpWithEmail(String email, String password);
  Future<void> signOut();
  UserEntity? getCurrentUser();
  Stream<UserEntity?> get authStateChanges;
}