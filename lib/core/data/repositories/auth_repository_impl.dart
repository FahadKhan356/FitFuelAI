import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
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
    // After successful sign in, attempt to sync any locally-saved onboarding data.
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('onboarding_profile');
      final goalsJson = prefs.getString('onboarding_goals');
      if (profileJson != null) {
        final Map<String, dynamic> profile =
            _withoutStaleUserId(jsonDecode(profileJson) as Map<String, dynamic>);
        await _supabase.from('user_profiles').upsert({
          'user_id': user.id,
          ...profile,
        }, onConflict: 'user_id');
      }
      if (goalsJson != null) {
        final Map<String, dynamic> goals =
            _withoutStaleUserId(jsonDecode(goalsJson) as Map<String, dynamic>);
        await _supabase.from('goals').upsert({
          'user_id': user.id,
          ...goals,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');
      }
      // If we synced anything, clear local onboarding cache
      if (profileJson != null || goalsJson != null) {
        await prefs.remove('onboarding_profile');
        await prefs.remove('onboarding_goals');
        await prefs.setBool('onboarding_completed', true);
      }
    } catch (_) {
      // ignore sync errors here; app can retry later
    }
    // Attempt to sync local onboarding data (if present)
    try {
      final goalsResponse = await _supabase
          .from('goals')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (goalsResponse != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_goals', jsonEncode(goalsResponse));
      }
    } catch (_) {}

    return UserEntity(id: user.id, email: user.email);
  }

  @override
  Future<UserEntity> signUpWithEmail                                   (String email, String password) async {
    final response = await _supabase.auth.signUp(email: email, password: password);
    final user = response.user!;
    
    // Create user profile in user_profiles table
    await _supabase.from('user_profiles').upsert({
      'user_id': user.id,
    });
    // After signup, if there is local onboarding data, sync it to Supabase
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('onboarding_profile');
      final goalsJson = prefs.getString('onboarding_goals');
      if (profileJson != null) {
        final Map<String, dynamic> profile =
            _withoutStaleUserId(jsonDecode(profileJson) as Map<String, dynamic>);
        await _supabase.from('user_profiles').upsert({
          'user_id': user.id,
          ...profile,
        }, onConflict: 'user_id');
      }
      if (goalsJson != null) {
        final Map<String, dynamic> goals =
            _withoutStaleUserId(jsonDecode(goalsJson) as Map<String, dynamic>);
        await _supabase.from('goals').upsert({
          'user_id': user.id,
          ...goals,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');
      }
      if (profileJson != null || goalsJson != null) {
        await prefs.remove('onboarding_profile');
        await prefs.remove('onboarding_goals');
        await prefs.setBool('onboarding_completed', true);
      }
    } catch (_) {
      // ignore sync errors; they can be retried later
    }
    // After signup, attempt to sync any locally-saved onboarding data
    try {
      final goalsResponse = await _supabase
          .from('goals')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (goalsResponse != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_goals', jsonEncode(goalsResponse));
      }
    } catch (_) {}

    return UserEntity(id: user.id, email: user.email);
  }

  @override
  Future<void> syncLocalOnboarding(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString('onboarding_profile');
    final goalsJson = prefs.getString('onboarding_goals');

    try {
      if (profileJson != null) {
        final Map<String, dynamic> profile =
            _withoutStaleUserId(jsonDecode(profileJson) as Map<String, dynamic>);
        await _supabase.from('user_profiles').upsert({
          'user_id': userId,
          ...profile,
        }, onConflict: 'user_id');
      }

      if (goalsJson != null) {
        final Map<String, dynamic> goals =
            _withoutStaleUserId(jsonDecode(goalsJson) as Map<String, dynamic>);
        await _supabase.from('goals').upsert({
          'user_id': userId,
          ...goals,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');
      }

      if (profileJson != null || goalsJson != null) {
        await prefs.remove('onboarding_profile');
        await prefs.remove('onboarding_goals');
        await prefs.setBool('onboarding_completed', true);
      }

      // Cache the upserted goals for quick access
      final goalsResponse = await _supabase
          .from('goals')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (goalsResponse != null) {
        await prefs.setString('current_goals', jsonEncode(goalsResponse));
      }
    } catch (e) {
      // Re-throw so callers can handle/log if needed
      rethrow;
    }
  }
  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Locally-saved onboarding maps can contain a stale `user_id` (the
  /// "local" placeholder used before sign-in). Strip it so the upsert always
  /// associates the row with the real authenticated user id.
  Map<String, dynamic> _withoutStaleUserId(Map<String, dynamic> data) {
    data.remove('user_id');
    return data;
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