// lib/screens/food_search_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_result.dart';
import '../services/food_search_service.dart';

// Color tokens (already defined in app)
const Color kPurple = Color(0xFF5B4EE8);
const Color kPurpleLight = Color(0xFFEDEBFB);
const Color kBg = Color(0xFFF5F5FA);
const Color kWhite = Color(0xFFFFFFFF);
const Color kHeadline = Color(0xFF14142B);
const Color kBody = Color(0xFF8A8A9A);
const Color kBorder = Color(0xFFE8E6F5);
const Color kGreen = Color(0xFF34C759);
const Color kAmber = Color(0xFFFFA040);

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({
    super.key,
    this.mealType = 'lunch',
    this.onFoodSelected,
  });

  final String mealType; // 'breakfast' | 'lunch' | 'dinner' | 'snack'
  final Function(String name, int calories, double protein, double carbs, double fat)?
      onFoodSelected;

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _controller = TextEditingController();
  List<FoodResult> _results = [];
  bool _loading = false;
  String? _error;
  // Country code — in real app get from user profile
  final String _country = 'PK';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final results = await FoodSearchService.search(
      query,
      countryCode: _country,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _results = results;
      if (results.isEmpty) {
        _error = 'No results found. Try a different name.';
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kWhite,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: kHeadline, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Search Food',
            style: TextStyle(
              color: kHeadline,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Column(
          children: [
            // ── Search bar ──────────────────────────────────────────────
            Container(
              color: kWhite,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                child: TextField(
                  controller: _controller,
                  onSubmitted: _search,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(color: kHeadline, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search food (e.g. Aloo Paratha, Rice)',
                    hintStyle: const TextStyle(color: kBody, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: kBody),
                    suffixIcon: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kPurple,
                              ),
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            const Divider(height: 1, color: kBorder),

            // ── Results ─────────────────────────────────────────────────
            Expanded(
              child: _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: kBody, fontSize: 14),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _FoodResultCard(
                        item: _results[i],
                        mealType: widget.mealType,
                        onFoodSelected: widget.onFoodSelected,
                      ),
                    ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────
//  Food Result Card
// ─────────────────────────────────────────────
class _FoodResultCard extends StatefulWidget {
  const _FoodResultCard({
    required this.item,
    required this.mealType,
    this.onFoodSelected,
  });

  final FoodResult item;
  final String mealType;
  final Function(String name, int calories, double protein, double carbs, double fat)?
      onFoodSelected;

  @override
  State<_FoodResultCard> createState() => _FoodResultCardState();
}

class _FoodResultCardState extends State<_FoodResultCard> {
  late double _quantity;
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _quantity = widget.item.servingUnit == 'piece' ? 1.0 : 50.0;
    _qtyController = TextEditingController(
      text: _quantity == _quantity.roundToDouble()
          ? _quantity.round().toString()
          : _quantity.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _setQuantity(double q) {
    final clamped = q.clamp(1.0, 2000.0);
    setState(() {
      _quantity = clamped;
      _qtyController.text = clamped == clamped.roundToDouble()
          ? clamped.round().toString()
          : clamped.toStringAsFixed(1);
    });
  }

  FoodResult get _scaled => widget.item.scaleToQuantity(_quantity);

  Future<void> _logFood() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    final scaled = _scaled;

    if (userId == null) {
      if (widget.onFoodSelected != null) {
        widget.onFoodSelected!(
          scaled.foodName,
          scaled.calories.round(),
          scaled.proteinG,
          scaled.carbsG,
          scaled.fatG,
        );
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }
    }

    final today = DateTime.now().toIso8601String().substring(0, 10);

    try {
      if (userId != null) {
        // Get or create today's meal
        final existingMeals = await supabase
            .from('meals')
            .select('id')
            .eq('user_id', userId)
            .eq('date', today)
            .eq('meal_type', widget.mealType)
            .limit(1);

        String mealId;
        if ((existingMeals as List).isNotEmpty) {
          mealId = existingMeals.first['id'] as String;
        } else {
          final newMeal = await supabase
              .from('meals')
              .insert({
                'user_id': userId,
                'date': today,
                'meal_type': widget.mealType,
                'total_calories': 0,
              })
              .select('id')
              .single();
          mealId = newMeal['id'] as String;
        }

        // Insert meal item
        await supabase.from('meal_items').insert({
          'meal_id': mealId,
          'food_name': scaled.foodName,
          'calories': scaled.calories.round(),
          'protein': scaled.proteinG,
          'carbs': scaled.carbsG,
          'fat': scaled.fatG,
          'fiber': scaled.fiberG,
          'serving_size': scaled.servingQuantity,
          'serving_unit': scaled.servingUnit,
        });
      }

      if (widget.onFoodSelected != null) {
        widget.onFoodSelected!(
          scaled.foodName,
          scaled.calories.round(),
          scaled.proteinG,
          scaled.carbsG,
          scaled.fatG,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${scaled.foodName} logged to ${widget.mealType}'),
            backgroundColor: kPurple,
          ),
        );
        Navigator.pop(context);
      }
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaled = _scaled;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  scaled.foodName,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: kHeadline,
                  ),
                ),
              ),
              // Source badge
              if (widget.item.accuracyWarning)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: kAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'AI Estimated',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: kAmber,
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: kGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '✓ Verified',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: kGreen,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Macros row
          Row(
            children: [
              _MacroChip('Cal', '${scaled.calories.round()}', kPurple),
              const SizedBox(width: 8),
              _MacroChip('P', '${scaled.proteinG}g', const Color(0xFF3A8EF6)),
              const SizedBox(width: 8),
              _MacroChip('C', '${scaled.carbsG}g', kAmber),
              const SizedBox(width: 8),
              _MacroChip('F', '${scaled.fatG}g', const Color(0xFFE24B4A)),
            ],
          ),

          const SizedBox(height: 12),

          // Quantity adjuster
          Row(
            children: [
              const Text(
                'Amount:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kBody,
                ),
              ),
              const Spacer(),
              // Minus 5
              _QtyBtn(
                icon: Icons.remove_rounded,
                onTap: () => _setQuantity(_quantity - 5),
              ),
              const SizedBox(width: 6),
              // Direct Editable Input Box
              Container(
                width: 72,
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kPurple, width: 1.4),
                ),
                child: TextField(
                  controller: _qtyController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: kHeadline,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    suffixText: widget.item.servingUnit == 'piece' ? 'pc' : 'g',
                    suffixStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: kPurple,
                    ),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null && parsed > 0) {
                      setState(() {
                        _quantity = parsed.clamp(1.0, 2000.0);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 6),
              // Plus 5
              _QtyBtn(
                icon: Icons.add_rounded,
                onTap: () => _setQuantity(_quantity + 5),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Quick presets
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [2.0, 5.0, 10.0, 30.0, 50.0, 100.0].map((preset) {
              final isSelected = (_quantity - preset).abs() < 0.5;
              final unitLabel =
                  widget.item.servingUnit == 'piece' ? 'pc' : 'g';
              return GestureDetector(
                onTap: () => _setQuantity(preset),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? kPurple : kPurpleLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${preset.round()}$unitLabel',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? kWhite : kPurple,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Log button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _logFood,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Add to Meal',
                style: TextStyle(
                  color: kWhite,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: kPurpleLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: kPurple),
        ),
      );
}
