import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

const _surface = Colors.white;
const _purple = Color(AppColors.authPurple);
const _purpleSoft = Color(0xFFF0ECFF);
const _textPrimary = Color(0xFF1F1F2E);
const _textSecondary = Color(0xFF706D7B);
const _border = Color(0xFFE7E3EF);

// ─────────────────────────────────────────────
//  Food Item Model
// ─────────────────────────────────────────────
class FoodItem {
  final String id;
  final String name;
  final int caloriesPer100g;
  final String category; // breakfast, lunch, dinner, snack

  FoodItem({
    required this.id,
    required this.name,
    required this.caloriesPer100g,
    required this.category,
  });
}

// Sample food database
final sampleFoods = [
  FoodItem(id: '1', name: 'Chicken Breast (100g)', caloriesPer100g: 165, category: 'lunch'),
  FoodItem(id: '2', name: 'Brown Rice (100g)', caloriesPer100g: 111, category: 'lunch'),
  FoodItem(id: '3', name: 'Egg (1 large)', caloriesPer100g: 155, category: 'breakfast'),
  FoodItem(id: '4', name: 'Oatmeal (100g)', caloriesPer100g: 389, category: 'breakfast'),
  FoodItem(id: '5', name: 'Banana (1 medium)', caloriesPer100g: 89, category: 'snack'),
  FoodItem(id: '6', name: 'Almonds (28g)', caloriesPer100g: 164, category: 'snack'),
  FoodItem(id: '7', name: 'Salmon (100g)', caloriesPer100g: 208, category: 'lunch'),
  FoodItem(id: '8', name: 'Broccoli (100g)', caloriesPer100g: 34, category: 'lunch'),
  FoodItem(id: '9', name: 'Yogurt (100g)', caloriesPer100g: 59, category: 'breakfast'),
  FoodItem(id: '10', name: 'Peanut Butter (1 tbsp)', caloriesPer100g: 188, category: 'breakfast'),
];

// ─────────────────────────────────────────────
//  Meal Entry Bottom Sheet
// ─────────────────────────────────────────────
class MealEntryBottomSheet extends StatefulWidget {
  final Function(String foodName, int calories, String mealType) onMealAdded;

  const MealEntryBottomSheet({required this.onMealAdded});

  @override
  State<MealEntryBottomSheet> createState() => _MealEntryBottomSheetState();
}

class _MealEntryBottomSheetState extends State<MealEntryBottomSheet> {
  late TextEditingController _searchController;
  late TextEditingController _caloriesController;
  String selectedMealType = 'lunch';
  FoodItem? selectedFood;
  List<FoodItem> filteredFoods = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _caloriesController = TextEditingController();
    filteredFoods = sampleFoods;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _filterFoods(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredFoods = sampleFoods;
      } else {
        filteredFoods = sampleFoods
            .where((food) => food.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _handleAddMeal() {
    if (selectedFood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a food item')),
      );
      return;
    }

    int calories = int.tryParse(_caloriesController.text) ?? selectedFood!.caloriesPer100g;

    if (calories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid calories')),
      );
      return;
    }

    widget.onMealAdded(selectedFood!.name, calories, selectedMealType);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Text(
                    'Add Meal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, color: _textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Meal Type Selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meal Type',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _MealTypeButton(
                        label: 'Breakfast',
                        isSelected: selectedMealType == 'breakfast',
                        onTap: () => setState(() => selectedMealType = 'breakfast'),
                      ),
                      const SizedBox(width: 8),
                      _MealTypeButton(
                        label: 'Lunch',
                        isSelected: selectedMealType == 'lunch',
                        onTap: () => setState(() => selectedMealType = 'lunch'),
                      ),
                      const SizedBox(width: 8),
                      _MealTypeButton(
                        label: 'Dinner',
                        isSelected: selectedMealType == 'dinner',
                        onTap: () => setState(() => selectedMealType = 'dinner'),
                      ),
                      const SizedBox(width: 8),
                      _MealTypeButton(
                        label: 'Snack',
                        isSelected: selectedMealType == 'snack',
                        onTap: () => setState(() => selectedMealType = 'snack'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Food Search
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search Food',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    onChanged: _filterFoods,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _purple, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      hintText: 'Search foods...',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB0ADB9),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: _textSecondary, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Food List
              if (filteredFoods.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredFoods.length,
                    itemBuilder: (context, index) {
                      final food = filteredFoods[index];
                      final isSelected = selectedFood?.id == food.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() => selectedFood = food);
                          _caloriesController.text = food.caloriesPer100g.toString();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? _purpleSoft : const Color(0xFFF5F5FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? _purple : _border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      food.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${food.caloriesPer100g} cal',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: _textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_rounded, color: _purple, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),

              // Calorie Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calories',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _caloriesController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _purple, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      hintText: 'Enter calories',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB0ADB9),
                      ),
                      suffixText: 'kcal',
                      suffixStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleAddMeal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Add Meal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Meal Type Button
// ─────────────────────────────────────────────
class _MealTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MealTypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _purple : const Color(0xFFF5F5FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _purple : _border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : _textPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
