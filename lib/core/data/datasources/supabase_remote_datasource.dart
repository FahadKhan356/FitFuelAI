import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';
import '../models/food_item_model.dart';
import '../models/scan_result_model.dart';
import '../models/barcode_model.dart';
import '../models/water_model.dart';
import '../models/weight_model.dart';
import '../models/notification_model.dart';
import '../models/subscription_model.dart';

class SupabaseRemoteDataSource {
  final SupabaseClient _client;

  SupabaseRemoteDataSource(this._client);

  // ==================== AUTH ====================
  Future<UserModel> signInWithEmail(String email, String password) async {
    final response = await _client.auth.signInWithPassword(email: email, password: password);
    final user = response.user!;
    return UserModel(id: user.id, email: user.email);
  }

  Future<UserModel> signUpWithEmail(String email, String password) async {
    final response = await _client.auth.signUp(email: email, password: password);
    final user = response.user!;
    return UserModel(id: user.id, email: user.email);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  UserModel? getCurrentUser() {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return UserModel(id: user.id, email: user.email);
  }

  // ==================== USER PROFILE ====================
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await _client
        .from('user_profiles')
        .select()
        .eq('user_id', userId)
        .single();
    return response as Map<String, dynamic>?;
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _client.from('user_profiles').upsert({
      'user_id': userId,
      ...data,
    });
  }

  // ==================== GOALS ====================
  Future<Map<String, dynamic>?> getUserGoals(String userId) async {
    final response = await _client
        .from('goals')
        .select()
        .eq('user_id', userId)
        .single();
    return response as Map<String, dynamic>?;
  }

  Future<void> updateGoals(String userId, Map<String, dynamic> data) async {
    await _client.from('goals').upsert({
      'user_id': userId,
      ...data,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ==================== MEALS ====================
  Future<List<MealModel>> getMealsByDate(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T').first;
    final response = await _client
        .from('meals')
        .select('*, meal_items(*)')
        .eq('user_id', userId)
        .eq('date', dateStr)
        .order('created_at');
    return (response as List).map((e) => MealModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MealModel> addMeal(Map<String, dynamic> mealData) async {
    final response = await _client.from('meals').insert(mealData).select().single();
    return MealModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> updateMeal(String mealId, Map<String, dynamic> data) async {
    await _client.from('meals').update(data).eq('id', mealId);
  }

  Future<void> deleteMeal(String mealId) async {
    await _client.from('meals').delete().eq('id', mealId);
  }

  Future<Map<String, dynamic>> addMealItem(Map<String, dynamic> itemData) async {
    final response = await _client.from('meal_items').insert(itemData).select().single();
    return response as Map<String, dynamic>;
  }

  // ==================== FOOD ITEMS ====================
  Future<List<FoodItemModel>> searchFoodItems(String query) async {
    final response = await _client
        .from('food_items')
        .select()
        .ilike('name', '%$query%')
        .limit(20);
    return (response as List).map((e) => FoodItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ==================== BARCODE ====================
  Future<BarcodeModel?> getProductByBarcode(String barcode) async {
    final response = await _client
        .from('barcode_products')
        .select()
        .eq('barcode', barcode)
        .maybeSingle();
    if (response == null) return null;
    return BarcodeModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> saveBarcodeProduct(Map<String, dynamic> data) async {
    await _client.from('barcode_products').upsert(data);
  }

  // ==================== FOOD SCANS ====================
  Future<ScanResultModel> saveScanResult(Map<String, dynamic> data) async {
    final response = await _client.from('food_scans').insert(data).select().single();
    return ScanResultModel.fromJson(response as Map<String, dynamic>);
  }

  // ==================== WATER ====================
  Future<List<WaterModel>> getWaterEntries(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T').first;
    final response = await _client
        .from('water_intake')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr);
    return (response as List).map((e) => WaterModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<WaterModel> addWaterEntry(Map<String, dynamic> data) async {
    final response = await _client.from('water_intake').insert(data).select().single();
    return WaterModel.fromJson(response as Map<String, dynamic>);
  }

  // ==================== WEIGHT ====================
  Future<List<WeightModel>> getWeightEntries(String userId) async {
    final response = await _client
        .from('weight_entries')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);
    return (response as List).map((e) => WeightModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<WeightModel> addWeightEntry(Map<String, dynamic> data) async {
    final response = await _client.from('weight_entries').insert(data).select().single();
    return WeightModel.fromJson(response as Map<String, dynamic>);
  }

  // ==================== GAMIFICATION ====================
  Future<Map<String, dynamic>?> getGamification(String userId) async {
    final response = await _client
        .from('gamification')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return response as Map<String, dynamic>?;
  }

  Future<List<Map<String, dynamic>>> getAchievements(String userId) async {
    final response = await _client
        .from('achievements')
        .select()
        .eq('user_id', userId);
    return (response as List).cast<Map<String, dynamic>>();
  }

  // ==================== AI CHAT ====================
  Future<List<Map<String, dynamic>>> getChatHistory(String userId) async {
    final response = await _client
        .from('ai_chat_sessions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<void> saveChatMessage(Map<String, dynamic> data) async {
    await _client.from('ai_chat_sessions').insert(data);
  }

  // ==================== ANALYTICS ====================
  Future<Map<String, dynamic>> getDailyAnalytics(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T').first;
    
    final mealsResponse = await _client
        .from('meals')
        .select('total_calories')
        .eq('user_id', userId)
        .eq('date', dateStr);
    
    final waterResponse = await _client
        .from('water_intake')
        .select('amount_ml')
        .eq('user_id', userId)
        .eq('date', dateStr);

    final totalCalories = (mealsResponse as List).fold<int>(0, (sum, meal) => sum + (meal['total_calories'] as int? ?? 0));
    final totalWater = (waterResponse as List).fold<int>(0, (sum, w) => sum + (w['amount_ml'] as int? ?? 0));

    return {
      'total_calories': totalCalories,
      'total_water_ml': totalWater,
    };
  }

  // ==================== SUBSCRIPTION ====================
  Future<SubscriptionModel?> getSubscription(String userId) async {
    final response = await _client
        .from('subscriptions')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (response == null) return null;
    return SubscriptionModel.fromJson(response as Map<String, dynamic>);
  }
}