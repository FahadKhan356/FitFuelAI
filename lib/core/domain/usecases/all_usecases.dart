import '../entities/user_entity.dart';
import '../entities/meal_entity.dart';
import '../entities/food_item_entity.dart';
import '../entities/barcode_product_entity.dart';
import '../entities/food_scan_result_entity.dart';
import '../entities/water_entry_entity.dart';
import '../entities/weight_entry_entity.dart';
import '../entities/user_profile_entity.dart';
import '../entities/goal_entity.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/meal_repository.dart';
import '../repositories/food_search_repository.dart';
import '../repositories/food_scan_repository.dart';
import '../repositories/barcode_repository.dart';
import '../repositories/water_repository.dart';
import '../repositories/weight_repository.dart';
import '../repositories/analytics_repository.dart';
import '../repositories/ai_coach_repository.dart';
import '../repositories/subscription_repository.dart';

// ==================== AUTH USE CASES ====================
class SignInWithEmailUseCase {
  final AuthRepository _repo; SignInWithEmailUseCase(this._repo);
  Future<UserEntity> call(String email, String password) => _repo.signInWithEmail(email, password);
}

class SignUpWithEmailUseCase {
  final AuthRepository _repo; SignUpWithEmailUseCase(this._repo);
  Future<UserEntity> call(String email, String password) => _repo.signUpWithEmail(email, password);
}

// ==================== USER USE CASES ====================
class LoadUserProfileUseCase {
  final UserRepository _repo; LoadUserProfileUseCase(this._repo);
  Future<UserProfileEntity?> call(String userId) => _repo.getUserProfile(userId);
}

class UpdateUserProfileUseCase {
  final UserRepository _repo; UpdateUserProfileUseCase(this._repo);
  Future<void> call(String userId, Map<String, dynamic> data) => _repo.updateUserProfile(userId, data);
}

// ==================== HOME USE CASE ====================
class FetchHomeDashboardUseCase {
  final MealRepository _mealRepo;
  final WaterRepository _waterRepo;
  final UserRepository _userRepo;
  FetchHomeDashboardUseCase(this._mealRepo, this._waterRepo, this._userRepo);

  Future<Map<String, dynamic>> call(String userId, DateTime date) async {
    final meals = await _mealRepo.getMealsByDate(userId, date);
    final water = await _waterRepo.getWaterEntries(userId, date);
    final goals = await _userRepo.getUserGoals(userId);
    final totalCalories = meals.fold<int>(0, (sum, m) => sum + m.totalCalories);
    final totalWater = water.fold<int>(0, (sum, w) => sum + w.amountMl);
    return {
      'meals': meals,
      'water': water,
      'goals': goals,
      'total_calories': totalCalories,
      'total_water_ml': totalWater,
    };
  }
}

// ==================== FOOD SEARCH ====================
class SearchFoodUseCase {
  final FoodSearchRepository _repo; SearchFoodUseCase(this._repo);
  Future<List<FoodItemEntity>> call(String query) => _repo.searchFoodItems(query);
}

// ==================== FOOD SCAN ====================
class ScanFoodImageUseCase {
  final FoodScanRepository _repo; ScanFoodImageUseCase(this._repo);
  Future<FoodScanResultEntity> call(Map<String, dynamic> data) => _repo.saveScanResult(data);
}

class SaveScanResultUseCase {
  final FoodScanRepository _repo; SaveScanResultUseCase(this._repo);
  Future<FoodScanResultEntity> call(Map<String, dynamic> data) => _repo.saveScanResult(data);
}

// ==================== BARCODE ====================
class SearchBarcodeUseCase {
  final BarcodeRepository _repo; SearchBarcodeUseCase(this._repo);
  Future<BarcodeProductEntity?> call(String barcode) => _repo.getProductByBarcode(barcode);
}

// ==================== MEAL USE CASES ====================
class AddMealUseCase {
  final MealRepository _repo; AddMealUseCase(this._repo);
  Future<MealEntity> call(MealEntity meal, List<Map<String, dynamic>> items) => _repo.addMeal(meal, items);
}

class UpdateMealUseCase {
  final MealRepository _repo; UpdateMealUseCase(this._repo);
  Future<void> call(String mealId, Map<String, dynamic> data) => _repo.updateMeal(mealId, data);
}

class DeleteMealUseCase {
  final MealRepository _repo; DeleteMealUseCase(this._repo);
  Future<void> call(String mealId) => _repo.deleteMeal(mealId);
}

// ==================== WATER ====================
class TrackWaterUseCase {
  final WaterRepository _repo; TrackWaterUseCase(this._repo);
  Future<WaterEntryEntity> call(String userId, int amountMl, DateTime date) => _repo.addWaterEntry(userId, amountMl, date);
}

// ==================== WEIGHT ====================
class TrackWeightUseCase {
  final WeightRepository _repo; TrackWeightUseCase(this._repo);
  Future<WeightEntryEntity> call(String userId, double weightKg, double? bmi, double? bodyFat, String? notes) => _repo.addWeightEntry(userId, weightKg, bmi, bodyFat, notes);
}

// ==================== ANALYTICS ====================
class FetchAnalyticsUseCase {
  final AnalyticsRepository _repo; FetchAnalyticsUseCase(this._repo);
  Future<Map<String, dynamic>> call(String userId, DateTime date) => _repo.getDailyAnalytics(userId, date);
}

// ==================== AI COACH ====================
class SendAiCoachMessageUseCase {
  final AiCoachRepository _repo; SendAiCoachMessageUseCase(this._repo);
  Future<void> call(String userId, String message, String response) => _repo.sendMessage(userId, message, response);
}

// ==================== SUBSCRIPTION ====================
class SubscribePremiumUseCase {
  final SubscriptionRepository _repo; SubscribePremiumUseCase(this._repo);
  Future<bool> call(String userId) => _repo.isSubscribed(userId);
}

// ==================== ACHIEVEMENTS ====================
class FetchAchievementsUseCase {
  final UserRepository _repo; FetchAchievementsUseCase(this._repo);
  Future<List<Map<String, dynamic>>> call(String userId) async {
    // Through UserRepository or separate datasource
    throw UnimplementedError('Use SupabaseRemoteDataSource directly for now');
  }
}