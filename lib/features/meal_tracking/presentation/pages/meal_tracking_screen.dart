import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/domain/repositories/meal_repository.dart';
import '../../../../core/services/calorie_goal_resolver.dart';
import '../../../../core/services/home_data_cache.dart';
import '../../../../core/services/home_data_refresh_notifier.dart';
import '../../../../screens/camera_scan_screen.dart';
import '../../../../screens/food_search_screen.dart';
import '../../../../shared/theme/app_theme.dart';
import 'food_nutrition_detail_sheet.dart';
import 'meal_entry_screen.dart' show MealEntryBottomSheet;

bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
const _purple = Color(AppColors.authPurple);

// ─────────────────────────────────────────────
//  Meal Entry Model
// ─────────────────────────────────────────────
class MealLog {
  MealLog({
    required this.foodName,
    required this.calories,
    required this.mealType,
    required this.date,
    this.mealId = '',
    this.itemId = '',
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.servingSize = 100,
    this.servingUnit = 'g',
  });

  final String mealId;
  final String itemId;
  final String foodName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double servingSize;
  final String servingUnit;
  final String mealType;
  final DateTime date;
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
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _isDark ? AppDarkColors.background : const Color(0xFFF7F6FB);
  Color get _surface => _isDark ? AppDarkColors.surface : Colors.white;
  Color get _textPrimary => _isDark ? AppDarkColors.textPrimary : const Color(0xFF1F1F2E);
  Color get _textSecondary => _isDark ? AppDarkColors.textSecondary : const Color(0xFF706D7B);
  Color get _border => _isDark ? AppDarkColors.border : const Color(0xFFE7E3EF);

  int totalCalories = 0;
  int calorieGoal = 0;
  double totalProtein = 0, totalCarbs = 0, totalFat = 0;
  List<MealLog> todaysMeals = [];
  bool _hasLoaded = false;
  String _selectedFilter = 'all'; // 'all', 'breakfast', 'lunch', 'dinner', 'snack'

  // Dynamic targets based on calorie goal
  double get targetProtein => calorieGoal > 0 ? (calorieGoal * 0.25 / 4).roundToDouble() : 130.0;
  double get targetCarbs => calorieGoal > 0 ? (calorieGoal * 0.50 / 4).roundToDouble() : 250.0;
  double get targetFat => calorieGoal > 0 ? (calorieGoal * 0.25 / 9).roundToDouble() : 65.0;

  List<MealLog> get filteredMeals {
    if (_selectedFilter == 'all') return todaysMeals;
    return todaysMeals.where((m) => m.mealType.toLowerCase() == _selectedFilter).toList();
  }

  int get filteredCalories {
    return filteredMeals.fold<int>(0, (sum, m) => sum + m.calories);
  }

  @override
  void initState() {
    super.initState();
    _initFromCache();
    _loadData();
  }

  void _initFromCache() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final cached = HomeDataCache.getCached(user.id);
      if (cached != null) {
        totalCalories = cached.consumedCalories;
        calorieGoal = cached.targetCalories > 0 ? cached.targetCalories : 2000;
        totalProtein = cached.consumedProtein;
        totalCarbs = cached.consumedCarbs;
        totalFat = cached.consumedFat;
        _hasLoaded = true;
      }
    }
  }

  Future<void> _loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    try {
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
              fiber: item.fiber,
              servingSize: item.servingSize,
              servingUnit: item.servingUnit,
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
        _hasLoaded = true;
      });

      if (user != null) {
        HomeDataCache.updateNutrition(
          user.id,
          consumedCalories: cal,
          consumedProtein: protein,
          consumedCarbs: carbs,
          consumedFat: fat,
          targetCalories: goal,
        );
      }
    } catch (e) {
      debugPrint('MealTracking _loadData error: $e');
      if (mounted) {
        setState(() => _hasLoaded = true);
      }
    }
  }

  void _showMealEntryDialog([String? defaultMealType]) {
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
                mealType: defaultMealType ?? (_selectedFilter == 'all' ? 'lunch' : _selectedFilter),
                onFoodSelected: (foodName, calories, protein, carbs, fat) {
                  _addMealFromSearch(foodName, calories, protein, carbs, fat, defaultMealType ?? _selectedFilter);
                },
              ),
            ),
          );
        },
        onMealAdded: (foodName, calories, protein, carbs, fat, mealType) async {
          HapticFeedback.lightImpact();
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

          if (user != null) {
            HomeDataCache.updateNutrition(
              user.id,
              consumedCalories: totalCalories,
              consumedProtein: totalProtein,
              consumedCarbs: totalCarbs,
              consumedFat: totalFat,
            );
            HomeDataRefreshNotifier.instance.refresh();
          }

          if (user == null) return;
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
            if (mounted) await _loadData();
            HomeDataRefreshNotifier.instance.refresh();
          } catch (e) {
            debugPrint('Failed to persist meal: $e');
          }
        },
      ),
    );
  }

  Future<void> _addMealFromSearch(
    String foodName,
    int calories,
    double protein,
    double carbs,
    double fat, [
    String mealType = 'lunch',
  ]) async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final user = Supabase.instance.client.auth.currentUser;
    final type = mealType == 'all' ? 'lunch' : mealType;

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
          mealType: type,
          date: now,
        ),
      );
    });

    if (user != null) {
      HomeDataCache.updateNutrition(
        user.id,
        consumedCalories: totalCalories,
        consumedProtein: totalProtein,
        consumedCarbs: totalCarbs,
        consumedFat: totalFat,
      );
      HomeDataRefreshNotifier.instance.refresh();
    }

    if (user == null) return;
    try {
      await sl<MealRepository>().addFoodToMeal(
        userId: user.id,
        mealType: type,
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

  Future<void> _removeMeal(MealLog meal) async {
    HapticFeedback.mediumImpact();
    final user = Supabase.instance.client.auth.currentUser;

    setState(() {
      totalCalories = (totalCalories - meal.calories).clamp(0, 999999);
      totalProtein = (totalProtein - meal.protein).clamp(0.0, 9999.0);
      totalCarbs = (totalCarbs - meal.carbs).clamp(0.0, 9999.0);
      totalFat = (totalFat - meal.fat).clamp(0.0, 9999.0);
      todaysMeals.removeWhere((m) => m.itemId == meal.itemId);
    });

    if (user != null) {
      HomeDataCache.updateNutrition(
        user.id,
        consumedCalories: totalCalories,
        consumedProtein: totalProtein,
        consumedCarbs: totalCarbs,
        consumedFat: totalFat,
      );
      HomeDataRefreshNotifier.instance.refresh();
    }

    if (user == null || meal.itemId.isEmpty || meal.mealId.isEmpty) return;

    try {
      await sl<MealRepository>().deleteMealItem(meal.itemId, meal.mealId);
    } catch (e) {
      debugPrint('Failed to delete meal item: $e');
    }
    if (mounted) await _loadData();
    HomeDataRefreshNotifier.instance.refresh();
  }

  int _countMeals(String type) {
    if (type == 'all') return todaysMeals.length;
    return todaysMeals.where((m) => m.mealType.toLowerCase() == type).length;
  }

  @override
  Widget build(BuildContext context) {
    final remainingKcal = calorieGoal - totalCalories;
    final progress = calorieGoal > 0 ? (totalCalories / calorieGoal).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMealEntryDialog(),
        backgroundColor: _purple,
        elevation: 6,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
        label: const Text(
          'Log Meal',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isDark ? AppDarkColors.surfaceAlt : const Color(0xFFF5F5FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meal Tracking',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Track & explore detailed micro/macro nutrition',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _purple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 12, color: _purple),
                        SizedBox(width: 4),
                        Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: _border),

            // ─── Interactive Hero Calorie & Macro Dashboard ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _isDark ? 0.25 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Calorie Numbers & Remaining Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$totalCalories',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: _textPrimary,
                                      height: 1,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' / $calorieGoal kcal',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: _textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              remainingKcal >= 0
                                  ? '$remainingKcal kcal remaining'
                                  : '${remainingKcal.abs()} kcal over budget',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: remainingKcal >= 0 ? _textSecondary : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _purple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Animated Gradient Calorie Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 9,
                        color: _isDark ? AppDarkColors.surfaceAlt : const Color(0xFFEBE8F5),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_purple, Color(0xFF9080FF)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── 3 Interactive Macro Indicators ───
                    Row(
                      children: [
                        Expanded(
                          child: _macroIndicator(
                            title: 'Protein',
                            current: totalProtein,
                            target: targetProtein,
                            color: const Color(0xFF6366F1),
                            bg: _isDark ? const Color(0xFF1E1B38) : const Color(0xFFEEF2FF),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _macroIndicator(
                            title: 'Carbs',
                            current: totalCarbs,
                            target: targetCarbs,
                            color: const Color(0xFFF59E0B),
                            bg: _isDark ? const Color(0xFF262016) : const Color(0xFFFFFBEB),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _macroIndicator(
                            title: 'Fat',
                            current: totalFat,
                            target: targetFat,
                            color: const Color(0xFF06B6D4),
                            bg: _isDark ? const Color(0xFF15222E) : const Color(0xFFECFEFF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── Interactive Quick Shortcuts ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: _quickActionButton(
                      icon: Icons.search_rounded,
                      label: 'Search Food',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FoodSearchScreen(
                              mealType: _selectedFilter == 'all' ? 'lunch' : _selectedFilter,
                              onFoodSelected: (foodName, calories, protein, carbs, fat) {
                                _addMealFromSearch(foodName, calories, protein, carbs, fat, _selectedFilter);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _quickActionButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Scan Meal',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CameraScanScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ─── Interactive Meal Filter Pills ───
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _filterChip('all', 'All (${_countMeals('all')})'),
                  _filterChip('breakfast', 'Breakfast (${_countMeals('breakfast')})'),
                  _filterChip('lunch', 'Lunch (${_countMeals('lunch')})'),
                  _filterChip('dinner', 'Dinner (${_countMeals('dinner')})'),
                  _filterChip('snack', 'Snacks (${_countMeals('snack')})'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ─── Section Header with Subtotal ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedFilter == 'all' ? 'Today\'s Meals' : '${_selectedFilter.toUpperCase()} MEALS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '$filteredCalories kcal · ${filteredMeals.length} items',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _purple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // ─── Meals List ───
            Expanded(
              child: filteredMeals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: _purple.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.restaurant_menu_rounded,
                              size: 32,
                              color: _purple,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFilter == 'all'
                                ? 'No meals logged today yet'
                                : 'No ${_selectedFilter} logged today',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap the button below or scan food to log',
                            style: TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showMealEntryDialog(_selectedFilter),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(
                              '+ Add ${_selectedFilter == 'all' ? 'Meal' : _selectedFilter.toUpperCase()}',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _purple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: filteredMeals.length,
                      itemBuilder: (context, index) {
                        final meal = filteredMeals[index];
                        return _MealCard(
                          meal: meal,
                          onTap: () {
                            // Opens the full micro & macro nutrition detail screen!
                            FoodNutritionDetailSheet.show(
                              context,
                              meal: meal,
                              onRemove: () => _removeMeal(meal),
                              dailyCalorieGoal: calorieGoal,
                            );
                          },
                          onRemove: () => _confirmRemoveMeal(meal),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroIndicator({
    required String title,
    required double current,
    required double target,
    required Color color,
    required Color bg,
  }) {
    final ratio = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                '${(ratio * 100).round()}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${current.round()} / ${target.round()}g',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 4,
              backgroundColor: color.withValues(alpha: 0.20),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: _isDark ? AppDarkColors.surfaceAlt : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: _purple),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedFilter = key);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? _purple
                  : (_isDark ? AppDarkColors.surfaceAlt : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? _purple : _border,
                width: 1.0,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : _textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmRemoveMeal(MealLog meal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Food?'),
        content: Text('Remove "${meal.foodName}" from your meal log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeMeal(meal);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Interactive Meal Card
// ─────────────────────────────────────────────
class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.meal,
    required this.onTap,
    required this.onRemove,
  });

  final MealLog meal;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  IconData _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast_rounded;
      case 'lunch':
        return Icons.lunch_dining_rounded;
      case 'dinner':
        return Icons.dinner_dining_rounded;
      case 'snack':
        return Icons.fastfood_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  Color _getMealColor(String mealType) {
    switch (mealType.toLowerCase()) {
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
    final dark = _isDark(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: dark ? AppDarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? AppDarkColors.border : const Color(0xFFE7E3EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Meal type icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: dark ? AppDarkColors.surfaceAlt : _getMealColor(meal.mealType),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      _getMealIcon(meal.mealType),
                      size: 22,
                      color: _purple,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Macros
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              meal.foodName,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: dark ? AppDarkColors.textPrimary : const Color(0xFF1F1F2E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            meal.mealType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _purple,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dark ? Colors.white30 : Colors.black26,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tap for nutrition',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: dark ? AppDarkColors.textSecondary : const Color(0xFF8A8799),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Color-coded Macro Mini-Pills
                      Row(
                        children: [
                          _macroPill('P', '${meal.protein.round()}g', const Color(0xFF6366F1), dark),
                          const SizedBox(width: 6),
                          _macroPill('C', '${meal.carbs.round()}g', const Color(0xFFF59E0B), dark),
                          const SizedBox(width: 6),
                          _macroPill('F', '${meal.fat.round()}g', const Color(0xFF06B6D4), dark),
                        ],
                      ),
                    ],
                  ),
                ),

                // Calories & Chevron
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${meal.calories} kcal',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: _purple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: _purple,
                    ),
                  ],
                ),
                const SizedBox(width: 4),

                // Delete 'X' button
                GestureDetector(
                  onTap: onRemove,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: dark ? AppDarkColors.textSecondary : const Color(0xFF9E9BAA),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _macroPill(String label, String value, Color color, bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
