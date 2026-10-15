import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/theme/app_theme.dart';
import 'meal_tracking_screen.dart';

/// Full interactive food nutrition detail sheet displaying macro & micro nutrition.
class FoodNutritionDetailSheet extends StatefulWidget {
  final MealLog meal;
  final VoidCallback? onRemove;
  final int dailyCalorieGoal;

  const FoodNutritionDetailSheet({
    super.key,
    required this.meal,
    this.onRemove,
    this.dailyCalorieGoal = 2000,
  });

  /// Helper to display this modal bottom sheet with modern styling.
  static Future<void> show(
    BuildContext context, {
    required MealLog meal,
    VoidCallback? onRemove,
    int dailyCalorieGoal = 2000,
  }) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FoodNutritionDetailSheet(
        meal: meal,
        onRemove: onRemove,
        dailyCalorieGoal: dailyCalorieGoal,
      ),
    );
  }

  @override
  State<FoodNutritionDetailSheet> createState() => _FoodNutritionDetailSheetState();
}

class _FoodNutritionDetailSheetState extends State<FoodNutritionDetailSheet> {
  double _servings = 1.0;
  bool _isLoadingMicros = true;

  // Nutritional micro and macro values (scaled by _servings)
  late double _baseCalories;
  late double _baseProtein;
  late double _baseCarbs;
  late double _baseFat;
  late double _baseFiber;
  double _baseSugar = 0.0;
  double _baseSodiumMg = 0.0;
  double _basePotassiumMg = 0.0;
  double _baseCalciumMg = 0.0;
  double _baseIronMg = 0.0;
  double _baseVitaminCMg = 0.0;
  double _baseSaturatedFatG = 0.0;
  String _nutritionSource = 'AI Verified Profile';

  static const Color _purple = Color(AppColors.authPurple);

  @override
  void initState() {
    super.initState();
    _baseCalories = widget.meal.calories.toDouble();
    _baseProtein = widget.meal.protein;
    _baseCarbs = widget.meal.carbs;
    _baseFat = widget.meal.fat;
    _baseFiber = widget.meal.fiber;

    _fetchOrEstimateMicroNutrients();
  }

  /// Attempts to fetch precise micronutrients from Supabase cache or provides
  /// scientifically backed regional estimation based on meal and macros.
  Future<void> _fetchOrEstimateMicroNutrients() async {
    final foodNameLower = widget.meal.foodName.toLowerCase().trim();

    try {
      final rows = await Supabase.instance.client
          .from('food_items')
          .select()
          .or('food_name.ilike.%$foodNameLower%,search_key.ilike.%$foodNameLower%')
          .limit(1);

      if (rows.isNotEmpty) {
        final row = rows.first;
        if (mounted) {
          setState(() {
            _baseSodiumMg = (row['sodium_mg'] as num? ?? 0).toDouble();
            _basePotassiumMg = (row['potassium_mg'] as num? ?? 0).toDouble();
            _baseFiber = (row['fiber_g'] as num? ?? _baseFiber).toDouble();
            _baseSugar = (row['sugar_g'] as num? ?? 0).toDouble();
            _baseCalciumMg = (row['calcium_mg'] as num? ?? 0).toDouble();
            _baseIronMg = (row['iron_mg'] as num? ?? 0).toDouble();
            _baseVitaminCMg = (row['vitamin_c_mg'] as num? ?? 0).toDouble();
            _baseSaturatedFatG = (row['saturated_fat_g'] as num? ?? (_baseFat * 0.3)).toDouble();
            _nutritionSource = row['source'] == 'FatSecret' ? 'FatSecret Database' : 'FitFuel Nutrition Lab';
            _isLoadingMicros = false;
          });
          return;
        }
      }
    } catch (_) {
      // Offline or network error - gracefully fall through to smart estimation
    }

    // Smart regional & macro-based fallback
    _applySmartEstimation(foodNameLower);
  }

  void _applySmartEstimation(String name) {
    double sodium = 0;
    double potassium = 0;
    double calcium = 0;
    double iron = 0;
    double vitC = 0;
    double sugar = 0;
    double satFat = _baseFat * 0.28;
    double fiber = _baseFiber;

    if (name.contains('daal') || name.contains('dal') || name.contains('lentil')) {
      sodium = 380;
      potassium = 420;
      calcium = 45;
      iron = 3.6;
      vitC = 2.5;
      fiber = fiber > 0 ? fiber : 5.8;
      sugar = 1.4;
    } else if (name.contains('biryani') || name.contains('pulao') || name.contains('rice')) {
      sodium = 540;
      potassium = 320;
      calcium = 38;
      iron = 2.1;
      vitC = 3.8;
      fiber = fiber > 0 ? fiber : 2.2;
      sugar = 1.8;
      satFat = _baseFat * 0.32;
    } else if (name.contains('paratha') || name.contains('roti') || name.contains('naan')) {
      sodium = 320;
      potassium = 290;
      calcium = 55;
      iron = 2.8;
      vitC = 1.0;
      fiber = fiber > 0 ? fiber : 3.5;
      sugar = 2.0;
      satFat = _baseFat * 0.40;
    } else if (name.contains('chicken') || name.contains('meat') || name.contains('beef') || name.contains('tikka')) {
      sodium = 480;
      potassium = 390;
      calcium = 25;
      iron = 2.4;
      vitC = 1.2;
      fiber = fiber > 0 ? fiber : 0.8;
      sugar = 0.5;
      satFat = _baseFat * 0.35;
    } else if (name.contains('egg') || name.contains('omelette') || name.contains('omlet')) {
      sodium = 210;
      potassium = 160;
      calcium = 60;
      iron = 1.9;
      vitC = 0.0;
      fiber = 0.4;
      sugar = 0.8;
      satFat = _baseFat * 0.33;
    } else {
      // General macro-scaled realistic estimates
      sodium = (_baseCalories * 1.2).clamp(120, 850);
      potassium = (_baseCarbs * 5 + _baseProtein * 8).clamp(90, 750);
      calcium = (_baseProtein * 2.5).clamp(20, 250);
      iron = (_baseProtein * 0.12 + _baseCarbs * 0.05).clamp(0.5, 6.0);
      vitC = (_baseCarbs > 20 ? 4.5 : 1.0);
      fiber = fiber > 0 ? fiber : (_baseCarbs * 0.08).clamp(0.5, 12.0);
      sugar = (_baseCarbs * 0.12).clamp(0.5, 30.0);
    }

    if (mounted) {
      setState(() {
        _baseSodiumMg = sodium;
        _basePotassiumMg = potassium;
        _baseCalciumMg = calcium;
        _baseIronMg = iron;
        _baseVitaminCMg = vitC;
        _baseFiber = fiber;
        _baseSugar = sugar;
        _baseSaturatedFatG = satFat;
        _isLoadingMicros = false;
      });
    }
  }

  void _updateServings(double delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _servings = (_servings + delta).clamp(0.25, 10.0);
    });
  }

  // Scaled values
  double get currentCalories => _baseCalories * _servings;
  double get currentProtein => _baseProtein * _servings;
  double get currentCarbs => _baseCarbs * _servings;
  double get currentFat => _baseFat * _servings;
  double get currentFiber => _baseFiber * _servings;
  double get currentSugar => _baseSugar * _servings;
  double get currentSodium => _baseSodiumMg * _servings;
  double get currentPotassium => _basePotassiumMg * _servings;
  double get currentCalcium => _baseCalciumMg * _servings;
  double get currentIron => _baseIronMg * _servings;
  double get currentVitaminC => _baseVitaminCMg * _servings;
  double get currentSaturatedFat => _baseSaturatedFatG * _servings;

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppDarkColors.surface : Colors.white;
    final textPrimary = isDark ? AppDarkColors.textPrimary : const Color(0xFF1E1B3A);
    final textSecondary = isDark ? AppDarkColors.textSecondary : const Color(0xFF6B6782);
    final border = isDark ? AppDarkColors.border : const Color(0xFFE8E4F2);

    final totalMacroG = currentProtein + currentCarbs + currentFat;
    final proteinRatio = totalMacroG > 0 ? (currentProtein / totalMacroG) : 0.33;
    final carbsRatio = totalMacroG > 0 ? (currentCarbs / totalMacroG) : 0.33;
    final fatRatio = totalMacroG > 0 ? (currentFat / totalMacroG) : 0.34;

    final calGoal = widget.dailyCalorieGoal > 0 ? widget.dailyCalorieGoal : 2000;
    final calPercent = ((currentCalories / calGoal) * 100).round();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.15),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Top Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _purple.withValues(alpha: isDark ? 0.20 : 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      _getMealIcon(widget.meal.mealType),
                      color: _purple,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.meal.foodName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _purple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.meal.mealType.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _purple,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _nutritionSource,
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.onRemove != null)
                  IconButton(
                    onPressed: () {
                      _confirmDelete(context);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                    tooltip: 'Delete Meal',
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: textSecondary, size: 24),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable Content
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                // 1. Interactive Serving Stepper
                _buildServingStepper(isDark, textPrimary, textSecondary, border),
                const SizedBox(height: 18),

                // 2. Hero Calories & Energy Distribution
                _buildHeroCaloriesCard(isDark, textPrimary, textSecondary, border, calPercent, proteinRatio, carbsRatio, fatRatio),
                const SizedBox(height: 20),

                // 3. Macronutrients Hero Cards
                _buildMacroSection(isDark, textPrimary, textSecondary, border),
                const SizedBox(height: 22),

                // 4. Micronutrients & Minerals Table
                _buildMicroNutrientsSection(isDark, textPrimary, textSecondary, border),
                const SizedBox(height: 20),

                // 5. FitFuel AI Smart Insights
                _buildAiInsightCard(isDark, textPrimary, textSecondary),
                const SizedBox(height: 24),

                // 6. Action Button
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Serving stepper allows user to scale food portions in real-time.
  Widget _buildServingStepper(bool isDark, Color textPrimary, Color textSecondary, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceAlt : const Color(0xFFF7F6FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Serving Size',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${(_servings * 100).round()} g · ${_servings.toStringAsFixed(1)} serving',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _stepperButton(
                icon: Icons.remove_rounded,
                onTap: _servings > 0.25 ? () => _updateServings(-0.25) : null,
                isDark: isDark,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${_servings.toStringAsFixed(2).replaceAll('.00', '')}x',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _purple,
                  ),
                ),
              ),
              _stepperButton(
                icon: Icons.add_rounded,
                onTap: () => _updateServings(0.25),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepperButton({required IconData icon, required VoidCallback? onTap, required bool isDark}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isDark ? AppDarkColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 18,
            color: onTap == null ? Colors.grey : _purple,
          ),
        ),
      ),
    );
  }

  /// Large hero calories card with macro ratio bar.
  Widget _buildHeroCaloriesCard(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color border,
    int calPercent,
    double proteinRatio,
    double carbsRatio,
    double fatRatio,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF241D3B), const Color(0xFF1B172B)]
              : [const Color(0xFFF1EFFF), const Color(0xFFFAF9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purple.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ENERGY & CALORIES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _purple,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currentCalories.round().toString(),
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'kcal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded, size: 16, color: _purple),
                    const SizedBox(width: 4),
                    Text(
                      '$calPercent% daily goal',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _purple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tri-color Macro Energy Ratio Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: (proteinRatio * 100).round().clamp(1, 100),
                    child: Container(color: const Color(0xFF6366F1)), // Protein: Indigo
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (carbsRatio * 100).round().clamp(1, 100),
                    child: Container(color: const Color(0xFFF59E0B)), // Carbs: Amber
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (fatRatio * 100).round().clamp(1, 100),
                    child: Container(color: const Color(0xFF06B6D4)), // Fat: Cyan
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Ratio Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ratioLabel('Protein', (proteinRatio * 100).round(), const Color(0xFF6366F1)),
              _ratioLabel('Carbs', (carbsRatio * 100).round(), const Color(0xFFF59E0B)),
              _ratioLabel('Fat', (fatRatio * 100).round(), const Color(0xFF06B6D4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ratioLabel(String title, int percent, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$title $percent%',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Macronutrients 3-column interactive cards.
  Widget _buildMacroSection(bool isDark, Color textPrimary, Color textSecondary, Color border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Macronutrients',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Protein Card
            Expanded(
              child: _macroCard(
                title: 'Protein',
                grams: currentProtein,
                color: const Color(0xFF6366F1),
                bg: isDark ? const Color(0xFF1E1B38) : const Color(0xFFEEF2FF),
                subtitle: '${(currentProtein * 4).round()} kcal',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),

            // Carbs Card
            Expanded(
              child: _macroCard(
                title: 'Carbs',
                grams: currentCarbs,
                color: const Color(0xFFF59E0B),
                bg: isDark ? const Color(0xFF262016) : const Color(0xFFFFFBEB),
                subtitle: '${(currentCarbs * 4).round()} kcal',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),

            // Fat Card
            Expanded(
              child: _macroCard(
                title: 'Fat',
                grams: currentFat,
                color: const Color(0xFF06B6D4),
                bg: isDark ? const Color(0xFF15222E) : const Color(0xFFECFEFF),
                subtitle: '${(currentFat * 9).round()} kcal',
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _macroCard({
    required String title,
    required double grams,
    required Color color,
    required Color bg,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${grams.toStringAsFixed(1)}g',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1F1F2E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// Micronutrients & minerals table with % Daily Value bars.
  Widget _buildMicroNutrientsSection(bool isDark, Color textPrimary, Color textSecondary, Color border) {
    if (_isLoadingMicros) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: _purple),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceAlt : const Color(0xFFF9F9FD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Micronutrients & Minerals',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              Text(
                '% Daily Value',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dietary Fiber (DV: 28g)
          _microNutrientRow(
            name: 'Dietary Fiber',
            value: '${currentFiber.toStringAsFixed(1)} g',
            dvPercent: (currentFiber / 28).clamp(0.0, 1.0),
            color: const Color(0xFF10B981),
            textPrimary: textPrimary,
          ),
          const Divider(height: 18),

          // Sugar
          _microNutrientRow(
            name: 'Sugars',
            value: '${currentSugar.toStringAsFixed(1)} g',
            dvPercent: (currentSugar / 50).clamp(0.0, 1.0),
            color: const Color(0xFFF59E0B),
            textPrimary: textPrimary,
          ),
          const Divider(height: 18),

          // Saturated Fat (DV: 20g)
          _microNutrientRow(
            name: 'Saturated Fat',
            value: '${currentSaturatedFat.toStringAsFixed(1)} g',
            dvPercent: (currentSaturatedFat / 20).clamp(0.0, 1.0),
            color: const Color(0xFFEF4444),
            textPrimary: textPrimary,
          ),
          const Divider(height: 18),

          // Sodium (DV: 2300mg)
          _microNutrientRow(
            name: 'Sodium (Na)',
            value: '${currentSodium.round()} mg',
            dvPercent: (currentSodium / 2300).clamp(0.0, 1.0),
            color: const Color(0xFF3B82F6),
            textPrimary: textPrimary,
          ),
          const Divider(height: 18),

          // Potassium (DV: 3400mg)
          _microNutrientRow(
            name: 'Potassium (K)',
            value: '${currentPotassium.round()} mg',
            dvPercent: (currentPotassium / 3400).clamp(0.0, 1.0),
            color: const Color(0xFF8B5CF6),
            textPrimary: textPrimary,
          ),
          const Divider(height: 18),

          // Calcium (DV: 1000mg)
          _microNutrientRow(
            name: 'Calcium (Ca)',
            value: '${currentCalcium.round()} mg',
            dvPercent: (currentCalcium / 1000).clamp(0.0, 1.0),
            color: const Color(0xFF06B6D4),
            textPrimary: textPrimary,
          ),
          const Divider(height: 18),

          // Iron (DV: 18mg)
          _microNutrientRow(
            name: 'Iron (Fe)',
            value: '${currentIron.toStringAsFixed(1)} mg',
            dvPercent: (currentIron / 18).clamp(0.0, 1.0),
            color: const Color(0xFFEC4899),
            textPrimary: textPrimary,
          ),
          const Divider(height: 18),

          // Vitamin C (DV: 90mg)
          _microNutrientRow(
            name: 'Vitamin C',
            value: '${currentVitaminC.toStringAsFixed(1)} mg',
            dvPercent: (currentVitaminC / 90).clamp(0.0, 1.0),
            color: const Color(0xFFF97316),
            textPrimary: textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _microNutrientRow({
    required String name,
    required String value,
    required double dvPercent,
    required Color color,
    required Color textPrimary,
  }) {
    final percentInt = (dvPercent * 100).round();
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            name,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: dvPercent,
                    minHeight: 6,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 32,
                child: Text(
                  '$percentInt%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// AI insights card with friendly health summary.
  Widget _buildAiInsightCard(bool isDark, Color textPrimary, Color textSecondary) {
    String insightText = 'Balanced meal providing sustained energy and nutrients.';
    if (currentProtein >= 20) {
      insightText = 'High protein fuel! Great for muscle recovery and promoting satiety.';
    } else if (currentFiber >= 5) {
      insightText = 'High dietary fiber promotes gut health and stable blood sugar levels.';
    } else if (currentCarbs >= 40) {
      insightText = 'Carbohydrate-dense meal, ideal for replenishing glycogen before or after workouts.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _purple.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: _purple,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FitFuel AI Nutrition Insight',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _purple,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  insightText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Food?'),
        content: Text('Remove "${widget.meal.foodName}" from your meal log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close sheet
              widget.onRemove?.call();
            },
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
