import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
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
  final String foodName;
  final int calories;
  final String mealType;
  final DateTime date;

  MealLog({
    required this.foodName,
    required this.calories,
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
  int totalCalories = 1850;
  int calorieGoal = 2000;
  List<MealLog> todaysMeals = [
    MealLog(
      foodName: 'Oatmeal + Banana',
      calories: 450,
      mealType: 'breakfast',
      date: DateTime.now(),
    ),
    MealLog(
      foodName: 'Chicken + Brown Rice',
      calories: 550,
      mealType: 'lunch',
      date: DateTime.now(),
    ),
    MealLog(
      foodName: 'Salmon + Broccoli',
      calories: 450,
      mealType: 'dinner',
      date: DateTime.now(),
    ),
  ];

  void _showMealEntryDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MealEntryBottomSheet(
        onMealAdded: (foodName, calories, mealType) {
          setState(() {
            totalCalories += calories;
            todaysMeals.add(
              MealLog(
                foodName: foodName,
                calories: calories,
                mealType: mealType,
                date: DateTime.now(),
              ),
            );
          });
        },
      ),
    );
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
                    onRemove: () {
                      setState(() {
                        totalCalories -= meal.calories;
                        todaysMeals.removeAt(index);
                      });
                    },
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
