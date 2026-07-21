import 'package:flutter/material.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import 'package:flutter/material.dart';

// Import apka model class:
// import 'package:yourapp/models/food_item_model.dart';

// Simplified FoodItem class for this file
class FoodItem {
  final String name;
  final double carbs;
  final double protein;
  final double fat;
  final int calories;
  double portion;
  final double maxPortion;
  final String matchLevel;

  FoodItem({
    required this.name,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.calories,
    required this.portion,
    required this.maxPortion,
    required this.matchLevel,
  });

  double getTotalCalories() => calories * (portion / 100);
  double getTotalProtein() => protein * (portion / 100);
  double getTotalCarbs() => carbs * (portion / 100);
  double getTotalFat() => fat * (portion / 100);
}

class ScanResultScreen extends StatefulWidget {
  final String? scannedImageUrl;
  final Function(List<FoodItem>)? onSave;

  const ScanResultScreen({
    Key? key,
    this.scannedImageUrl,
    this.onSave,
  }) : super(key: key);

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  late List<FoodItem> detectedFoods;
  bool isLoading = false;

  // Nutrition targets
  final nutritionTargets = {
    'protein': 80,
    'carbs': 120,
    'fat': 60,
    'calories': 2000,
  };

  @override
  void initState() {
    super.initState();
    _initializeFoods();
  }

  void _initializeFoods() {
    detectedFoods = [
      FoodItem(
        name: 'Grilled Salmon',
        carbs: 3.2,
        protein: 24,
        fat: 11,
        calories: 210,
        portion: 120,
        maxPortion: 200,
        matchLevel: 'High Match',
      ),
      FoodItem(
        name: 'Fresh Avocado',
        carbs: 8.5,
        protein: 29,
        fat: 15,
        calories: 160,
        portion: 80,
        maxPortion: 150,
        matchLevel: 'High Match',
      ),
      FoodItem(
        name: 'Brown Rice',
        carbs: 23.5,
        protein: 2.6,
        fat: 0.9,
        calories: 112,
        portion: 100,
        maxPortion: 200,
        matchLevel: '',
      ),
    ];
  }

  double _getTotalNutrition(String nutrient) {
    return detectedFoods.fold(0, (sum, food) {
      switch (nutrient) {
        case 'protein':
          return sum + food.getTotalProtein();
        case 'carbs':
          return sum + food.getTotalCarbs();
        case 'fat':
          return sum + food.getTotalFat();
        case 'calories':
          return sum + food.getTotalCalories();
        default:
          return sum;
      }
    });
  }

  double _getProgressPercent(String nutrient) {
    final total = _getTotalNutrition(nutrient);
    final target = nutritionTargets[nutrient] ?? 1;
    return (total / target).clamp(0, 1).toDouble();
  }

  Future<void> _saveScannedFoods() async {
    setState(() => isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 1));

      // Callback to parent
      if (widget.onSave != null) {
        widget.onSave!(detectedFoods);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${detectedFoods.length} foods saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, detectedFoods);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _addFoodItem() {
    // TODO: Open food search/add dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add food item feature coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scan Result',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          if (isLoading)
            Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF6366FF),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveScannedFoods,
              child: Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF6366FF),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              // Food Bowl Image
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 280,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: widget.scannedImageUrl != null
                      ? Image.network(
                          widget.scannedImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        )
                      : Image.network(
                          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&h=400&fit=crop',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              SizedBox(height: 24),
              // Nutrition Target Section
              Row(
                children: [
                  Icon(Icons.track_changes, color: Color(0xFF6366FF), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Nutrition Target',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildNutritionTargetCard(),
              SizedBox(height: 32),
              // Detected Foods Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detected Foods',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: _addFoodItem,
                    child: Text(
                      '+ Add Item',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6366FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Food Items List
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: detectedFoods.length,
                itemBuilder: (context, index) {
                  return FoodItemCard(
                    foodItem: detectedFoods[index],
                    onPortionChanged: (newPortion) {
                      setState(() {
                        detectedFoods[index].portion = newPortion;
                      });
                    },
                    onDelete: () {
                      setState(() {
                        detectedFoods.removeAt(index);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${detectedFoods[index].name} removed',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 20),
              // AI Tip Section
              _buildAITipSection(),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFoodItem,
        backgroundColor: Color(0xFF6366FF),
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildNutritionTargetCard() {
    final totalCalories = _getTotalNutrition('calories');
    final calorieProgress = _getProgressPercent('calories');

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Progress
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: calorieProgress.clamp(0, 1),
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF6366FF),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      totalCalories.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'KCAL',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 24),
          // Nutrition Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NutritionRow(
                  label: 'Protein',
                  current: _getTotalNutrition('protein').toStringAsFixed(1),
                  target: nutritionTargets['protein'].toString(),
                  color: Colors.purple,
                ),
                SizedBox(height: 14),
                NutritionRow(
                  label: 'Carbs',
                  current: _getTotalNutrition('carbs').toStringAsFixed(1),
                  target: nutritionTargets['carbs'].toString(),
                  color: Colors.cyan,
                ),
                SizedBox(height: 14),
                NutritionRow(
                  label: 'Fats',
                  current: _getTotalNutrition('fat').toStringAsFixed(1),
                  target: nutritionTargets['fat'].toString(),
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAITipSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF3F2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFE9E5FF),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF6366FF),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NutriLens AI Tip',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6366FF),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Great source of Omega-3! Consider reducing the rice portion by 20% to stay perfectly within your evening carb goal.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FoodItemCard extends StatelessWidget {
  final FoodItem foodItem;
  final Function(double) onPortionChanged;
  final Function() onDelete;

  const FoodItemCard({
    Key? key,
    required this.foodItem,
    required this.onPortionChanged,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        foodItem.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      if (foodItem.matchLevel.isNotEmpty) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '✓ ${foodItem.matchLevel}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '${foodItem.carbs}g C • ${foodItem.protein}g P • ${foodItem.fat}g F • ${foodItem.calories} kcal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Text('Edit'),
                    onTap: () {},
                  ),
                  PopupMenuItem(
                    child: Text('Delete'),
                    onTap: onDelete,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          // Portion Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Portion',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${foodItem.portion.toStringAsFixed(0)}g',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          // Slider
          Row(
            children: [
              Text(
                '−',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w300,
                ),
              ),
              Expanded(
                child: Slider(
                  value: foodItem.portion,
                  min: 0,
                  max: foodItem.maxPortion,
                  activeColor: Color(0xFF6366FF),
                  inactiveColor: Colors.grey[200],
                  onChanged: onPortionChanged,
                ),
              ),
              Text(
                '+',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NutritionRow extends StatelessWidget {
  final String label;
  final String current;
  final String target;
  final Color color;

  const NutritionRow({
    Key? key,
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double currentVal = double.tryParse(current) ?? 0;
    double targetVal = double.tryParse(target) ?? 1;
    double progressValue = (currentVal / targetVal).clamp(0, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$current / ${target}g',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}