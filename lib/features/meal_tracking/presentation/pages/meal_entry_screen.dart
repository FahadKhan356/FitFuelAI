import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../features/food_search/data/datasources/nutrition_api_datasource.dart';
import '../../../../core/data/models/nutrition_food.dart';

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

/// Maps a real API food result onto the screen's local `FoodItem` model so the
/// existing nutrition UI can render USDA / OpenFoodFacts data unchanged.
FoodItem _fromNutritionFood(NutritionFood n) {
  return FoodItem(
    id: n.externalId.isEmpty ? n.name : n.externalId,
    name: n.brand != null && n.brand!.isNotEmpty
        ? '${n.name} (${n.brand})'
        : n.name,
    caloriesPer100g: n.energyKcal.round(),
    proteinPer100g: n.protein.round(),
    carbsPer100g: n.carbs.round(),
    fatPer100g: n.fat.round(),
    fiberPer100g: n.fiber.round(),
    potassiumMgPer100g: n.potassiumMg.round(),
    calciumMgPer100g: n.calciumMg.round(),
    ironMgPer100g: n.ironMg.round(),
    vitaminCMgPer100g: n.vitaminCMg.round(),
    sodiumMgPer100g: n.sodiumMg.round(),
    category: 'All',
    servingLabel: '100 g',
  );
}

class MealEntryBottomSheet extends StatefulWidget {
  final void Function(String foodName, int calories, double protein,
      double carbs, double fat, String mealType) onMealAdded;
  final VoidCallback? onSearchFood;

  const MealEntryBottomSheet({required this.onMealAdded, this.onSearchFood});

  @override
  State<MealEntryBottomSheet> createState() => _MealEntryBottomSheetState();
}

class _MealEntryBottomSheetState extends State<MealEntryBottomSheet> {
  late TextEditingController _searchController;
  String selectedCategory = 'All';
  FoodItem? selectedFood;
  List<FoodItem> filteredFoods = [];
  bool _isSearching = false;
  Timer? _debounce;
  final categories = ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snack'];
  NutritionApiDataSource get _api => sl<NutritionApiDataSource>();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    filteredFoods = const [];
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _filterFoods(String query) {
    _debounce?.cancel();

    // Empty query → clear results; show search prompt state.
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        filteredFoods = const [];
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearching = true);
      List<NutritionFood> results;
      try {
        results = await _api.searchFoods(query);
      } catch (_) {
        results = const [];
      }
      if (!mounted) return;
      final mapped = results.map(_fromNutritionFood).toList();
      setState(() {
        _isSearching = false;
        filteredFoods = mapped;
      });
    });
  }

  void _selectCategory(String category) {
    setState(() {
      selectedCategory = category;
    });
    if (_searchController.text.trim().isNotEmpty) {
      _filterFoods(_searchController.text);
    }
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
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(color: _purple),
                  ),
                )
              else if (filteredFoods.isNotEmpty)
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
                  child: Text(
                    _searchController.text.trim().isEmpty
                        ? 'Search for a food (e.g. chicken, banana, oats) or use your camera to scan a barcode.'
                        : 'No matching food items found. Try another search term.',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _textSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              if (widget.onSearchFood != null)
                ElevatedButton.icon(
                  onPressed: widget.onSearchFood,
                  icon: const Icon(Icons.search_rounded, size: 20),
                  label: const Text('Search Food Database'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
  final void Function(String foodName, int calories, double protein,
      double carbs, double fat, String mealType) onMealAdded;

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
    selectedMealType = 'breakfast';
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
    widget.onMealAdded(
      widget.food.name,
      calories,
      protein.toDouble(),
      carbs.toDouble(),
      fat.toDouble(),
      selectedMealType,
    );
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
                  if (vitaminC > 0)
                    _MicronutrientRow(label: 'Vitamin C', value: '$vitaminC mg'),
                  if (iron > 0)
                    _MicronutrientRow(label: 'Iron', value: '$iron mg'),
                  if (calcium > 0)
                    _MicronutrientRow(label: 'Calcium', value: '$calcium mg'),
                  if (potassium > 0)
                    _MicronutrientRow(label: 'Potassium', value: '$potassium mg'),
                  if (fiber > 0)
                    _MicronutrientRow(label: 'Fiber', value: '$fiber g'),
                  if (sodium > 0)
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
