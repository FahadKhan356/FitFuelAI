
import 'package:fitfuel_ai/core/domain/entities/user_entity.dart';
import 'package:flutter/foundation.dart';

import '../../services/calorie_goal_resolver.dart';
import '../../services/water_goal_resolver.dart';
import '../entities/barcode_product_entity.dart';
import '../entities/calendar_tracking.dart';
import '../entities/coach_insight.dart';
import '../entities/food_item_entity.dart';
import '../entities/food_scan_result_entity.dart';
import '../entities/goal_entity.dart';
import '../entities/meal_entity.dart';
import '../entities/user_profile_entity.dart';
import '../entities/water_entry_entity.dart';
import '../entities/weight_entry_entity.dart';
import '../repositories/ai_coach_repository.dart';
import '../repositories/analytics_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/barcode_repository.dart';
import '../repositories/food_scan_repository.dart';
import '../repositories/food_search_repository.dart';
import '../repositories/meal_repository.dart';
import '../repositories/subscription_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/water_repository.dart';
import '../repositories/weight_repository.dart';

// ==================== AUTH USE CASES ====================
class SignInWithEmailUseCase { SignInWithEmailUseCase(this._repo);
  final AuthRepository _repo;
  Future<UserEntity> call(String email, String password) => _repo.signInWithEmail(email, password);
}

class SignUpWithEmailUseCase { SignUpWithEmailUseCase(this._repo);
  final AuthRepository _repo;
  Future<UserEntity> call(String email, String password) => _repo.signUpWithEmail(email, password);
}

// ==================== USER USE CASES ====================
class LoadUserProfileUseCase { LoadUserProfileUseCase(this._repo);
  final UserRepository _repo;
  Future<UserProfileEntity?> call(String userId) => _repo.getUserProfile(userId);
}

class UpdateUserProfileUseCase { UpdateUserProfileUseCase(this._repo);
  final UserRepository _repo;
  Future<void> call(String userId, Map<String, dynamic> data) => _repo.updateUserProfile(userId, data);
}

// ==================== HOME USE CASE ====================
class FetchHomeDashboardUseCase {
  FetchHomeDashboardUseCase(this._mealRepo, this._waterRepo, this._userRepo);
  final MealRepository _mealRepo;
  final WaterRepository _waterRepo;
  final UserRepository _userRepo;

  Future<Map<String, dynamic>> call(String userId, DateTime date) async {
    var meals = const <MealEntity>[];
    var water = const <WaterEntryEntity>[];
    GoalEntity? goals;
    UserProfileEntity? profile;

    await Future.wait([
      _mealRepo.getMealsByDate(userId, date).then((res) {
        meals = res;
      }).catchError((e) {
        debugPrint('FetchHomeDashboard: getMealsByDate error: $e');
      }),
      _waterRepo.getWaterEntries(userId, date).then((res) {
        water = res;
      }).catchError((e) {
        debugPrint('FetchHomeDashboard: getWaterEntries error: $e');
      }),
      _userRepo.getUserGoals(userId).then((res) {
        goals = res;
        debugPrint('FetchHomeDashboard: goals fetched = ${res?.targetCalories} kcal');
      }).catchError((e) {
        debugPrint('FetchHomeDashboard: getUserGoals error: $e');
        return null;
      }),
      _userRepo.getUserProfile(userId).then((res) {
        profile = res;
      }).catchError((e) {
        debugPrint('FetchHomeDashboard: getUserProfile error: $e');
        return null;
      }),
    ]);

    final totalCalories = meals.fold<int>(
      0,
      (sum, m) => sum + m.items.fold<int>(0, (itemSum, i) => itemSum + i.calories),
    );
    final totalWater = water.fold<int>(0, (sum, w) => sum + w.amountMl);

    return {
      'meals': meals,
      'water': water,
      'goals': goals,
      'profile': profile,
      'total_calories': totalCalories,
      'total_water_ml': totalWater,
    };
  }
}

// ==================== FOOD SEARCH ====================
class SearchFoodUseCase { SearchFoodUseCase(this._repo);
  final FoodSearchRepository _repo;
  Future<List<FoodItemEntity>> call(String query) => _repo.searchFoodItems(query);
}

// ==================== FOOD SCAN ====================
class ScanFoodImageUseCase { ScanFoodImageUseCase(this._repo);
  final FoodScanRepository _repo;
  Future<FoodScanResultEntity> call({
    required String userId,
    required String imageUrl,
    required Map<String, dynamic> rawResult,
    required double confidence,
  }) => _repo.saveScanResult(userId: userId, imageUrl: imageUrl, rawResult: rawResult, confidence: confidence);
}

class SaveScanResultUseCase { SaveScanResultUseCase(this._repo);
  final FoodScanRepository _repo;
  Future<FoodScanResultEntity> call({
    required String userId,
    required String imageUrl,
    required Map<String, dynamic> rawResult,
    required double confidence,
  }) => _repo.saveScanResult(userId: userId, imageUrl: imageUrl, rawResult: rawResult, confidence: confidence);
}

// ==================== BARCODE ====================
class SearchBarcodeUseCase { SearchBarcodeUseCase(this._repo);
  final BarcodeRepository _repo;
  Future<BarcodeProductEntity?> call(String barcode) => _repo.getProductByBarcode(barcode);
}

// ==================== MEAL USE CASES ====================
class AddMealUseCase { AddMealUseCase(this._repo);
  final MealRepository _repo;
  Future<MealEntity> call(MealEntity meal, List<Map<String, dynamic>> items) => _repo.addMeal(meal, items);
}

class UpdateMealUseCase { UpdateMealUseCase(this._repo);
  final MealRepository _repo;
  Future<void> call(String mealId, Map<String, dynamic> data) => _repo.updateMeal(mealId, data);
}

class DeleteMealUseCase { DeleteMealUseCase(this._repo);
  final MealRepository _repo;
  Future<void> call(String mealId) => _repo.deleteMeal(mealId);
}

// ==================== WATER ====================
class TrackWaterUseCase { TrackWaterUseCase(this._repo);
  final WaterRepository _repo;
  Future<WaterEntryEntity> call(String userId, int amountMl, DateTime date) => _repo.addWaterEntry(userId, amountMl, date);
}

// ==================== WEIGHT ====================
class TrackWeightUseCase { TrackWeightUseCase(this._repo);
  final WeightRepository _repo;
  Future<WeightEntryEntity> call(String userId, DateTime date, double weightKg, double heightCm, double? bodyFat, String? notes) => _repo.addWeightEntry(userId, date, weightKg, heightCm, bodyFat, notes);
}

// ==================== ANALYTICS ====================
class FetchAnalyticsUseCase { FetchAnalyticsUseCase(this._repo);
  final AnalyticsRepository _repo;
  Future<Map<String, dynamic>> call(String userId, DateTime date) => _repo.getDailyAnalytics(userId, date);
}

// ==================== AI COACH ====================
class SendAiCoachMessageUseCase { SendAiCoachMessageUseCase(this._repo);
  final AiCoachRepository _repo;
  Future<void> call(String userId, String message, String response) => _repo.sendMessage(userId, message, response);
}

/// Generates a coach reply grounded in the user's tracked history.
///
/// The repository injects the read-only context (profile, goals, meals, water,
/// weight) into the Gemini prompt and falls back to a locally composed answer
/// when the model is unavailable.
class GenerateAiCoachReplyUseCase { GenerateAiCoachReplyUseCase(this._repo);
  final AiCoachRepository _repo;
  Future<String> call(String userId, String message, {CoachInsight? insight}) =>
      _repo.generateCoachReply(userId, message, insight: insight);
}

// ==================== SUBSCRIPTION ====================
class SubscribePremiumUseCase { SubscribePremiumUseCase(this._repo);
  final SubscriptionRepository _repo;
  Future<bool> call(String userId) => _repo.isSubscribed(userId);
}

// ==================== CALENDAR TRACKING ====================
class FetchCalendarTrackingUseCase {
  FetchCalendarTrackingUseCase(this._waterRepo, this._mealRepo);
  final WaterRepository _waterRepo;
  final MealRepository _mealRepo;

  Future<CalendarTracking> call({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    final water = await _waterRepo.getWaterTotalsByDateRange(userId, start, end);
    final calories = await _mealRepo.getCalorieTotalsByDateRange(userId, start, end);

    // Resolve non-zero targets via shared resolvers. The goals row can carry
    // 0/null targets when the calculate_user_goals RPC hasn't run, which would
    // otherwise show a broken `0 kcal`/`0 ml` goal and hide the tick/cross.
    final targetCalories = await CalorieGoalResolver.resolve(userId);
    final targetWaterMl = await WaterGoalResolver.resolve(userId);

    return CalendarTracking(
      waterByDate: water,
      caloriesByDate: calories,
      targetCalories: targetCalories,
      targetWaterMl: targetWaterMl,
    );
  }
}
