import 'package:fitfuel_ai/features/food_search/presentation/pages/food_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/domain/repositories/meal_repository.dart';
import '../../../../core/services/calorie_goal_resolver.dart';
import '../../../../core/services/home_data_refresh_notifier.dart';
import 'meal_entry_screen.dart';

const _bg = Color(0xFFF7F6FB);
const _surface = Colors.white;
const _purple = Color(AppColors.authPurple);
const _textPrimary = Color(0xFF1F1F2E);
const _textSecondary = Color(0xFF706D7B);
const _border = Color(0xFFE7E3EF);

// ─────────────────────────────────────────────
//  Meal Entry Model
// ─────────────────────────────────────────────
class MealLog {
  final String mealId;
  final String itemId;
  final String foodName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String mealType;
  final DateTime date;

  MealLog({
    this.mealId = '',
    this.itemId = '',
    required this.foodName,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    required this.mealType,
    required this.date,
  });
}

// ─────────────────────────────────────────────
//  Meal Tracking Screen
// ─────────────────────────────────────────────
class MealTrackingScreen extends StatefulWidget {
  const MealTrackingScreen({super.key});

  @override
  State<MealTrackingScreen> createState() => _MealTrackingScreenState();
}

class _MealTrackingScreenState extends State<MealTrackingScreen> {
  int totalCalories = 0;
  int calorieGoal = 0;
  double totalProtein = 0, totalCarbs = 0, totalFat = 0;
  List<MealLog> todaysMeals = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Loads today's real meals + goals from the database and recomputes the
  /// consumed calories / macros so the tracker reflects live data.
  Future<void> _loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    try {
      // Use the same single source of truth for the calorie goal as the home
      // screen (DB goal → profile-based estimate → 2000) so both screens always
      // show an identical target (e.g. 2516).
      final goal = user != null
          ? await CalorieGoalResolver.resolve(user.id)
          : CalorieGoalResolver.defaultCalories;

      var cal = 0, protein = 0.0, carbs = 0.0, fat = 0.0;
      final meals = <MealLog>[];
      if (user != null) {
        final entities =
            await sl<MealRepository>().getMealsByDate(user.id, DateTime.now());
        for (final meal in entities) {
          for (final item in meal.items) {
            cal += item.calories;
            protein += item.protein;
            carbs += item.carbs;
            fat += item.fat;
            meals.add(MealLog(
              mealId: meal.id,
              itemId: item.id,
              foodName: item.foodName,
              calories: item.calories,
              protein: item.protein,
              carbs: item.carbs,
              fat: item.fat,
              mealType: meal.mealType,
              date: meal.date,
            ));
          }
        }
      }

      if (!mounted) return;
      setState(() {
        totalCalories = cal;
        calorieGoal = goal;
        totalProtein = protein;
        totalCarbs = carbs;
        totalFat = fat;
        todaysMeals = meals;
      });
    } catch (e) {
      debugPrint('MealTracking _loadData error: $e');
    }
  }

  void _showMealEntryDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MealEntryBottomSheet(
        onSearchFood: () {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FoodSearchScreen(
                onFoodSelected: (foodName, calories, protein, carbs, fat) {
                  _addMealFromSearch(foodName, calories, protein, carbs, fat);
                },
              ),
            ),
          );
        },
        onMealAdded: (foodName, calories, protein, carbs, fat, mealType) async {
          final now = DateTime.now();
          final user = Supabase.instance.client.auth.currentUser;

          setState(() {
            totalCalories += calories;
            totalProtein += protein;
            totalCarbs += carbs;
            totalFat += fat;
            todaysMeals.add(
              MealLog(
                foodName: foodName,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                mealType: mealType,
                date: now,
              ),
            );
          });

          if (user == null) {
            return;
          }
          try {
            await sl<MealRepository>().addFoodToMeal(
              userId: user.id,
              mealType: mealType.toLowerCase(),
              foodName: foodName,
              calories: calories,
              protein: protein,
              carbs: carbs,
              fat: fat,
              servingSize: 100,
              servingUnit: 'g',
              date: now,
            );
            if (mounted) {
              await _loadData();
            }
            HomeDataRefreshNotifier.instance.refresh();
          } catch (e) {
            debugPrint('Failed to persist meal: $e');
          }
        },
      ),
    );
  }

  Future<void> _addMealFromSearch(String foodName, int calories, double protein, double carbs, double fat) async {
    final now = DateTime.now();
    final user = Supabase.instance.client.auth.currentUser;

    setState(() {
      totalCalories += calories;
      totalProtein += protein;
      totalCarbs += carbs;
      totalFat += fat;
      todaysMeals.add(
        MealLog(
          foodName: foodName,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          mealType: 'snack',
          date: now,
        ),
      );
    });

    if (user == null) return;
    try {
      await sl<MealRepository>().addFoodToMeal(
        userId: user.id,
        mealType: 'snack',
        foodName: foodName,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        servingSize: 100,
        servingUnit: 'g',
        date: now,
      );
      if (mounted) await _loadData();
      HomeDataRefreshNotifier.instance.refresh();
    } catch (e) {
      debugPrint('Failed to add meal from search: $e');
    }
  }

  /// Removes an item locally and from the DB, then recomputes totals from the
  /// source of truth and refreshes the home dashboard.
  Future<void> _removeMeal(MealLog meal) async {
    final user = Supabase.instance.client.auth.currentUser;

    // Optimistic UI update for instant feedback.
    setState(() {
      totalCalories -= meal.calories;
      totalProtein -= meal.protein;
      totalCarbs -= meal.carbs;
      totalFat -= meal.fat;
      todaysMeals.removeWhere((m) => m.itemId == meal.itemId);
    });

    if (user == null) {
      return;
    }
    // Nothing to delete yet (e.g. a just-added item before reload finished).
    if (meal.itemId.isEmpty || meal.mealId.isEmpty) {
      return;
    }

    try {
      await sl<MealRepository>().deleteMealItem(meal.itemId, meal.mealId);
    } catch (e) {
      debugPrint('Failed to delete meal item: $e');
    }
    // Recompute from stored data so home/calendar totals stay correct.
    if (mounted) {
      await _loadData();
    }
    HomeDataRefreshNotifier.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton(
        onPressed: _showMealEntryDialog,
        backgroundColor: _purple,
        elevation: 6,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Meal Tracking',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: _border),

            // Calorie Progress
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$totalCalories',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                                height: 1.0,
                              ),
                            ),
                            TextSpan(
                              text: ' / ${calorieGoal} kcal',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${calorieGoal - totalCalories} kcal remaining',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: (totalCalories / calorieGoal).clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFFE7E3EF),
                      valueColor: const AlwaysStoppedAnimation<Color>(_purple),
                    ),
                  ),
                ],
              ),
            ),

            // Meals List
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: todaysMeals.length,
                itemBuilder: (context, index) {
                  final meal = todaysMeals[index];
                  return _MealCard(
                    meal: meal,
                    onRemove: () => _removeMeal(meal),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Meal Card
// ─────────────────────────────────────────────
class _MealCard extends StatelessWidget {
  final MealLog meal;
  final VoidCallback onRemove;

  const _MealCard({required this.meal, required this.onRemove});

  String _getMealIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return '🥐';
      case 'lunch':
        return '🍽️';
      case 'dinner':
        return '🍲';
      case 'snack':
        return '🍎';
      default:
        return '🍽️';
    }
  }

  Color _getMealColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return const Color(0xFFFFEDD5);
      case 'lunch':
        return const Color(0xFFE8F5E9);
      case 'dinner':
        return const Color(0xFFFCE4EC);
      case 'snack':
        return const Color(0xFFEDE7F6);
      default:
        return const Color(0xFFF5F5FA);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getMealColor(meal.mealType),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(_getMealIcon(meal.mealType), style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.foodName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                                const SizedBox(height: 3),
                Text(
                  meal.mealType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'P ${meal.protein.toStringAsFixed(0)}g · C ${meal.carbs.toStringAsFixed(0)}g · F ${meal.fat.toStringAsFixed(0)}g',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${meal.calories} kcal',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _purple,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 20, color: _textSecondary),
          ),
        ],
      ),
    );
  }
}
