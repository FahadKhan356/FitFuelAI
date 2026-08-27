import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitfuel_ai/core/constants/app_colors.dart';
import 'package:fitfuel_ai/core/di/service_locator.dart';
import 'package:fitfuel_ai/core/domain/usecases/all_usecases.dart';
import 'package:fitfuel_ai/core/utils/bmi_calculator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _bg = Color(0xFFF7F6FB);
const _surface = Colors.white;
const _purple = Color(AppColors.authPurple);
const _textPrimary = Color(0xFF1E1D2A);
const _textSecondary = Color(0xFF706D7B);
const _border = Color(0xFFE8E4EF);

class BmiScreen extends StatefulWidget {
  const BmiScreen({super.key});

  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  double _bmi = 23.4;
  String _categoryLabel = 'Normal weight';
  String _healthyRangeText = 'Healthy range';
  String _bmiPrime = '—';
  String _summary = '';
  Color _categoryColor = const Color(0xFF27B4D9);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..forward();

    _weightController = TextEditingController(text: '72.4');
    _heightController = TextEditingController(text: '1.75');
    _calculateBmi();
    _loadProfileValues();
  }

  /// Pre-fills the height/weight fields from the logged-in user's real profile
  /// (`user_profiles.height_cm` / `weight_kg`) so the calculator reflects their
  /// actual body metrics instead of the demo defaults. Falls back to the demo
  /// values when the profile isn't set up yet.
  Future<void> _loadProfileValues() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final profile = await sl<LoadUserProfileUseCase>().call(userId);
      if (profile == null || !mounted) return;

      String? weightText;
      if (profile.weightKg != null && profile.weightKg! > 0) {
        weightText = profile.weightKg!.toStringAsFixed(1);
      }
      String? heightText;
      if (profile.heightCm != null && profile.heightCm! > 0) {
        // Store in metres (the height field is in m).
        heightText = (profile.heightCm! / 100.0).toStringAsFixed(2);
      }

      if (weightText == null && heightText == null) return;
      setState(() {
        if (weightText != null) _weightController.text = weightText;
        if (heightText != null) _heightController.text = heightText;
        _calculateBmi();
      });
    } catch (_) {
      // Non-fatal — keep the demo defaults if the profile lookup fails.
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Color _colorFor(BmiCategory category) {
    switch (category) {
      case BmiCategory.severeUnderweight:
      case BmiCategory.moderateUnderweight:
      case BmiCategory.mildUnderweight:
        return const Color(0xFF3B82F6);
      case BmiCategory.normal:
        return const Color(0xFF22C55E);
      case BmiCategory.overweight:
        return const Color(0xFFF59E0B);
      case BmiCategory.obeseClassI:
      case BmiCategory.obeseClassII:
      case BmiCategory.obeseClassIII:
        return const Color(0xFFEF4444);
    }
  }

  void _calculateBmi() {
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final heightM = double.tryParse(_heightController.text) ?? 0.0;
    if (weight <= 0 || heightM <= 0) {
      return;
    }

    // Real-world WHO classification via BmiCalculator (height in cm).
    final result = BmiCalculator.calculate(
      weightKg: weight,
      heightCm: heightM * 100.0,
    );

    final String delta;
    if (result.deltaToHealthyKg == 0) {
      delta = 'You are already in a healthy weight band.';
    } else if (result.deltaToHealthyKg < 0) {
      delta =
          'Gain ${result.deltaToHealthyKg.abs().toStringAsFixed(1)} kg to reach '
          'your healthy (${result.healthyWeightMinKg.toStringAsFixed(0)}–'
          '${result.healthyWeightMaxKg.toStringAsFixed(0)}) kg band.';
    } else {
      delta =
          'Lose ${result.deltaToHealthyKg.toStringAsFixed(1)} kg to reach your '
          'healthy (${result.healthyWeightMinKg.toStringAsFixed(0)}–'
          '${result.healthyWeightMaxKg.toStringAsFixed(0)}) kg band.';
    }

    setState(() {
      _bmi = result.bmi;
      _categoryLabel = result.category.diagnostic;
      _categoryColor = _colorFor(result.category);
      _healthyRangeText =
          '${result.healthyWeightMinKg.toStringAsFixed(0)} – '
          '${result.healthyWeightMaxKg.toStringAsFixed(0)} kg';
      _bmiPrime = result.bmiPrime.toStringAsFixed(2);
      _summary = '${result.category.advice}\n\n$delta';
    });
  }

  Widget _stagger({
    required Widget child,
    required double start,
    required double end,
    double offsetY = 28,
  }) {
    final animation = CurvedAnimation(
      parent: _animController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = animation.value;
        return Transform.translate(
          offset: Offset(0, offsetY * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_bmi / 35).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkResponse(
                      onTap: () => Navigator.of(context).maybePop(),
                      radius: 22,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _border),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'BMI Calculator',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _stagger(
                      start: 0.05,
                      end: 0.22,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFDEE1E9)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Your BMI',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _bmi.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w900,
                                          color: _textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _categoryColor.withOpacity(0.14),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _categoryLabel.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: _categoryColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Healthy $_healthyRangeText',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: _textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 110,
                                  height: 110,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 110,
                                        height: 110,
                                        child: CircularProgressIndicator(
                                          value: progress,
                                          strokeWidth: 10,
                                          color: _categoryColor,
                                          backgroundColor: _categoryColor.withOpacity(0.16),
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${(_bmi / 35 * 100).clamp(0, 100).round()}%',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: _textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'of max',
                                            style: TextStyle(
                                              fontSize: 11,
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _stagger(
                      start: 0.18,
                      end: 0.35,
                      child: Row(
                        children: [
                          Expanded(child: _InputCard(
                            label: 'Weight',
                            suffix: 'kg',
                            controller: _weightController,
                            onChanged: (_) => _calculateBmi(),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _InputCard(
                            label: 'Height',
                            suffix: 'm',
                            controller: _heightController,
                            onChanged: (_) => _calculateBmi(),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _stagger(
                      start: 0.28,
                      end: 0.44,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Why BMI matters',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'BMI uses the WHO adult classification. BMI Prime is '
                              'your score as a fraction of the healthy upper limit (25).',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: _textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Icon(
                                  Icons.fiber_manual_record_rounded,
                                  size: 16,
                                  color: _categoryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'BMI Prime $_bmiPrime  ·  Healthy '
                                    '$_healthyRangeText',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_summary.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _categoryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _summary,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.45,
                                    color: _textPrimary,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            const Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _StatusBadge(label: 'Underweight', color: Color(0xFF3B82F6)),
                                _StatusBadge(label: 'Normal', color: Color(0xFF22C55E)),
                                _StatusBadge(label: 'Overweight', color: Color(0xFFF59E0B)),
                                _StatusBadge(label: 'Obese', color: Color(0xFFEF4444)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    _stagger(
                      start: 0.38,
                      end: 0.54,
                      child: ElevatedButton(
                        onPressed: _calculateBmi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _purple,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Recalculate BMI',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final String label;
  final String suffix;
  final TextEditingController controller;
  final void Function(String) onChanged;

  const _InputCard({
    required this.label,
    required this.suffix,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  onChanged: onChanged,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ),
              Text(
                suffix,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
