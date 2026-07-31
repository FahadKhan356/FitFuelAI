import '../../data/models/user_profile_model.dart';

abstract class ProfileRepository {
  /// Fetches user profile + goals from Supabase and combines into UserProfileModel
  Future<UserProfileModel> fetchUserProfile(String userId);

  /// Updates both user_profiles and goals tables, returns updated model
  Future<UserProfileModel> updateUserProfile(UserProfileModel user);

  /// Re-runs the FitnessCalculator using the user's current metrics and
  /// updates the `goals` table so dashboard targets update immediately.
  Future<UserProfileModel> recalculateGoals(UserProfileModel user);
}
