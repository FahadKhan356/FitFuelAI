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
  final int proteinPer100g;
  final int carbsPer100g;
  final int fatPer100g;
  final int fiberPer100g;
  final int potassiumMgPer100g;
  final int calciumMgPer100g;
  final int ironMgPer100g;
  final int vitaminCMgPer100g;
  final int sodiumMgPer100g;
  final String category;
  final String servingLabel;

  FoodItem({
    required this.id,
    required this.name,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.fiberPer100g,
    required this.potassiumMgPer100g,
    required this.calciumMgPer100g,
    required this.ironMgPer100g,
    required this.vitaminCMgPer100g,
    required this.sodiumMgPer100g,
    required this.category,
    required this.servingLabel,
  });
}

final sampleFoods = [
  FoodItem(
    id: '1',
    name: 'Chicken Breast',
    caloriesPer100g: 165,
    proteinPer100g: 31,
    carbsPer100g: 0,
    fatPer100g: 3,
    fiberPer100g: 0,
    potassiumMgPer100g: 256,
    calciumMgPer100g: 12,
    ironMgPer100g: 0,
    vitaminCMgPer100g: 0,
    sodiumMgPer100g: 74,
    category: 'lunch',
    servingLabel: '100 g',
  ),
  FoodItem(
    id: '2',
    name: 'Brown Rice',
    caloriesPer100g: 111,
    proteinPer100g: 2,
    carbsPer100g: 23,
    fatPer100g: 1,
    fiberPer100g: 2,
    potassiumMgPer100g: 43,
    calciumMgPer100g: 3,
    ironMgPer100g: 0,
    vitaminCMgPer100g: 0,
    sodiumMgPer100g: 5,
    category: 'lunch',
    servingLabel: '100 g',
  ),
  FoodItem(
    id: '3',
    name: 'Egg (1 large)',
    caloriesPer100g: 155,
    proteinPer100g: 13,
    carbsPer100g: 1,
    fatPer100g: 11,
    fiberPer100g: 0,
    potassiumMgPer100g: 126,
    calciumMgPer100g: 50,
    ironMgPer100g: 1,
    vitaminCMgPer100g: 0,
    sodiumMgPer100g: 124,
    category: 'breakfast',
    servingLabel: '1 large',
  ),
  FoodItem(
    id: '4',
    name: 'Oatmeal',
    caloriesPer100g: 389,
    proteinPer100g: 17,
    carbsPer100g: 66,
    fatPer100g: 7,
    fiberPer100g: 10,
    potassiumMgPer100g: 429,
    calciumMgPer100g: 54,
    ironMgPer100g: 4,
    vitaminCMgPer100g: 0,
    sodiumMgPer100g: 2,
    category: 'breakfast',
    servingLabel: '100 g',
  ),
  FoodItem(
    id: '5',
    name: 'Banana',
    caloriesPer100g: 89,
    proteinPer100g: 1,
    carbsPer100g: 23,
    fatPer100g: 0,
    fiberPer100g: 2,
    potassiumMgPer100g: 358,
    calciumMgPer100g: 5,
    ironMgPer100g: 0,
    vitaminCMgPer100g: 9,
    sodiumMgPer100g: 1,
    category: 'snack',
    servingLabel: '1 medium',
  ),
  FoodItem(
    id: '6',
    name: 'Almonds',
    caloriesPer100g: 579,
    proteinPer100g: 21,
    carbsPer100g: 22,
    fatPer100g: 50,
    fiberPer100g: 12,
    potassiumMgPer100g: 705,
    calciumMgPer100g: 264,
    ironMgPer100g: 3,
    vitaminCMgPer100g: 0,
    sodiumMgPer100g: 1,
    category: 'snack',
    servingLabel: '100 g',
  ),
  FoodItem(
    id: '7',
    name: 'Salmon',
    caloriesPer100g: 208,
    proteinPer100g: 20,
    carbsPer100g: 0,
    fatPer100g: 13,
    fiberPer100g: 0,
    potassiumMgPer100g: 363,
    calciumMgPer100g: 9,
    ironMgPer100g: 0,
    vitaminCMgPer100g: 0,
    sodiumMgPer100g: 59,
    category: 'dinner',
    servingLabel: '100 g',
  ),
  FoodItem(
    id: '8',
    name: 'Broccoli',
    caloriesPer100g: 34,
    proteinPer100g: 3,
    carbsPer100g: 7,
    fatPer100g: 0,
    fiberPer100g: 2,
    potassiumMgPer100g: 316,
    calciumMgPer100g: 47,
    ironMgPer100g: 1,
    vitaminCMgPer100g: 89,
    sodiumMgPer100g: 33,
    category: 'lunch',
    servingLabel: '100 g',
  ),
  FoodItem(
    id: '9',
    name: 'Greek Yogurt',
    caloriesPer100g: 59,
    proteinPer100g: 10,
    carbsPer100g: 3,
    fatPer100g: 0,
    fiberPer100g: 0,
    potassiumMgPer100g: 141,
    calciumMgPer100g: 110,
    ironMgPer100g: 0,
    vitaminCMgPer100g: 0,
    sodiumMgPer100g: 36,
    category: 'breakfast',
    servingLabel: '100 g',
  ),
  FoodItem(
    id: '10',
    name: 'Peanut Butter',
    caloriesPer100g: 588,
    proteinPer100g: 25,
    carbsPer100g: 20,
    fatPer100g: 50,
    fiberPer100g: 6,
    potassiumMgPer100g: 658,
    calciumMgPer100g: 43,
    ironMgPer100g: 2,
    vitaminCMgPer100g: 0,
    sodiumMgPer100g: 17,
    category: 'breakfast',
    servingLabel: '100 g',
  ),
];

class MealEntryBottomSheet extends StatefulWidget {
  final Function(String foodName, int calories, String mealType) onMealAdded;

  const MealEntryBottomSheet({required this.onMealAdded});

  @override
  State<MealEntryBottomSheet> createState() => _MealEntryBottomSheetState();
}

class _MealEntryBottomSheetState extends State<MealEntryBottomSheet> {
  late TextEditingController _searchController;
  String selectedCategory = 'All';
  FoodItem? selectedFood;
  List<FoodItem> filteredFoods = [];
  final categories = ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    filteredFoods = sampleFoods;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFoods(String query) {
    setState(() {
      filteredFoods = sampleFoods.where((food) {
        final matchesSearch = query.isEmpty || food.name.toLowerCase().contains(query.toLowerCase());
        final matchesCategory = selectedCategory == 'All' || food.category.toLowerCase() == selectedCategory.toLowerCase();
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _selectCategory(String category) {
    setState(() {
      selectedCategory = category;
      _filterFoods(_searchController.text);
    });
  }

  Future<void> _openFoodDetail(FoodItem food) async {
    final didAdd = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FoodNutritionDetailSheet(
        food: food,
        onMealAdded: widget.onMealAdded,
      ),
    );

    if (!mounted) return;
    if (didAdd == true) {
      Navigator.pop(context);
    }
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
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Manual Food Search',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, color: _textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Search food items, inspect micronutrients, and log meals with a manual portion calculator.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
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
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _purple, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  hintText: 'Search for foods, e.g. chicken, oats',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB0ADB9),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, color: _textSecondary, size: 22),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _FoodCategoryChip(
                      label: category,
                      isSelected: selectedCategory == category,
                      onTap: () => _selectCategory(category),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              if (filteredFoods.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredFoods.length,
                  itemBuilder: (context, index) {
                    final food = filteredFoods[index];
                    return GestureDetector(
                      onTap: () => _openFoodDetail(food),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _border),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(0, 0, 0, 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _purpleSoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.fastfood_rounded, color: _purple),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    food.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        '${food.caloriesPer100g} kcal',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        food.servingLabel,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'View',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _purple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: const Text(
                    'No matching food items found. Try another search term or category.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _textSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FoodNutritionDetailSheet extends StatefulWidget {
  final FoodItem food;
  final Function(String foodName, int calories, String mealType) onMealAdded;

  const FoodNutritionDetailSheet({required this.food, required this.onMealAdded});

  @override
  State<FoodNutritionDetailSheet> createState() => _FoodNutritionDetailSheetState();
}

class _FoodNutritionDetailSheetState extends State<FoodNutritionDetailSheet> {
  double servingGrams = 100;
  late String selectedMealType;

  @override
  void initState() {
    super.initState();
    selectedMealType = widget.food.category;
  }

  int get calories => (widget.food.caloriesPer100g * servingGrams / 100).round();
  int get protein => (widget.food.proteinPer100g * servingGrams / 100).round();
  int get carbs => (widget.food.carbsPer100g * servingGrams / 100).round();
  int get fat => (widget.food.fatPer100g * servingGrams / 100).round();
  int get fiber => (widget.food.fiberPer100g * servingGrams / 100).round();
  int get potassium => (widget.food.potassiumMgPer100g * servingGrams / 100).round();
  int get calcium => (widget.food.calciumMgPer100g * servingGrams / 100).round();
  int get iron => (widget.food.ironMgPer100g * servingGrams / 100).round();
  int get vitaminC => (widget.food.vitaminCMgPer100g * servingGrams / 100).round();
  int get sodium => (widget.food.sodiumMgPer100g * servingGrams / 100).round();

  void _handleLogMeal() {
    widget.onMealAdded(widget.food.name, calories, selectedMealType);
    Navigator.pop(context, true);
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
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Nutrition Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, color: _textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                widget.food.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Adjust the portion and meal type, then log your entry with micronutrients included.',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEAE6FC)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
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
                          const SizedBox(height: 6),
                          Text(
                            '$calories kcal',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _MacroBadge(label: 'Protein', value: '$protein g', color: const Color(0xFF8F5BFF)),
                              _MacroBadge(label: 'Carbs', value: '$carbs g', color: const Color(0xFF3461FF)),
                              _MacroBadge(label: 'Fat', value: '$fat g', color: const Color(0xFFFF8E3A)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: (calories / 650).clamp(0.0, 1.0),
                            strokeWidth: 8,
                            color: _purple,
                            backgroundColor: const Color(0xFFE9E6FD),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${((calories / 650) * 100).clamp(0, 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _textPrimary,
                                ),
                              ),
                              const Text(
                                'of 650 kcal',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Serving Size',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${servingGrams.round()} g',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                  Text(
                    widget.food.servingLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
              Slider(
                value: servingGrams,
                min: 50,
                max: 300,
                divisions: 5,
                label: '${servingGrams.round()} g',
                activeColor: _purple,
                onChanged: (value) => setState(() => servingGrams = value),
              ),
              const SizedBox(height: 12),
              const Text(
                'Meal type',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FoodCategoryChip(
                    label: 'Breakfast',
                    isSelected: selectedMealType == 'breakfast',
                    onTap: () => setState(() => selectedMealType = 'breakfast'),
                  ),
                  _FoodCategoryChip(
                    label: 'Lunch',
                    isSelected: selectedMealType == 'lunch',
                    onTap: () => setState(() => selectedMealType = 'lunch'),
                  ),
                  _FoodCategoryChip(
                    label: 'Dinner',
                    isSelected: selectedMealType == 'dinner',
                    onTap: () => setState(() => selectedMealType = 'dinner'),
                  ),
                  _FoodCategoryChip(
                    label: 'Snack',
                    isSelected: selectedMealType == 'snack',
                    onTap: () => setState(() => selectedMealType = 'snack'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Micronutrients',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  _MicronutrientRow(label: 'Vitamin C', value: '$vitaminC mg'),
                  _MicronutrientRow(label: 'Iron', value: '$iron mg'),
                  _MicronutrientRow(label: 'Calcium', value: '$calcium mg'),
                  _MicronutrientRow(label: 'Potassium', value: '$potassium mg'),
                  _MicronutrientRow(label: 'Fiber', value: '$fiber g'),
                  _MicronutrientRow(label: 'Sodium', value: '$sodium mg'),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Back',
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
                      onPressed: _handleLogMeal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Log Meal',
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

class _MacroBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Color.fromRGBO(143, 91, 255, 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label • $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _FoodCategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FoodCategoryChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? _purple : const Color(0xFFF5F5FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? _purple : _border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : _textPrimary,
          ),
        ),
      ),
    );
  }
}

class _MicronutrientRow extends StatelessWidget {
  final String label;
  final String value;

  const _MicronutrientRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _purple,
            ),
          ),
        ],
      ),
    );
  }
}
