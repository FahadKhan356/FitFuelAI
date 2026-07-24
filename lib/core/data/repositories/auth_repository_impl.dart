import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;

  AuthRepositoryImpl(this._supabase);

  @override
  Future<UserEntity> signInWithEmail(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(email: email, password: password);
    final user = response.user!;
    return UserEntity(id: user.id, email: user.email);
  }

  @override
  Future<UserEntity> signUpWithEmail(String email, String password) async {
    final response = await _supabase.auth.signUp(email: email, password: password);
    final user = response.user!;
    return UserEntity(id: user.id, email: user.email);
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  @override
  UserEntity? getCurrentUser() {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return UserEntity(id: user.id, email: user.email);
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((event) {
      if (event.session?.user != null) {
        return UserEntity(id: event.session!.user.id, email: event.session!.user.email);
      }
      return null;
    });
  }
}