import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitfuel_ai/core/constants/app_colors.dart';

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
  String _category = 'Normal';
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
  }

  @override
  void dispose() {
    _animController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _calculateBmi() {
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final height = double.tryParse(_heightController.text) ?? 0.0;
    if (weight <= 0 || height <= 0) {
      return;
    }

    final bmi = weight / (height * height);
    String category;
    Color color;

    if (bmi < 18.5) {
      category = 'Underweight';
      color = const Color(0xFF3B82F6);
    } else if (bmi < 25) {
      category = 'Normal';
      color = const Color(0xFF22C55E);
    } else if (bmi < 30) {
      category = 'Overweight';
      color = const Color(0xFFF59E0B);
    } else {
      category = 'Obese';
      color = const Color(0xFFEF4444);
    }

    setState(() {
      _bmi = bmi;
      _category = category;
      _categoryColor = color;
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
                                              _category.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: _categoryColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Ideal 18.5 - 24.9',
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
                              'BMI helps you understand where you stand with body composition and how your weight supports healthy goals.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: _textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _StatusBadge(label: 'Underweight', color: const Color(0xFF3B82F6)),
                                _StatusBadge(label: 'Normal', color: const Color(0xFF22C55E)),
                                _StatusBadge(label: 'Overweight', color: const Color(0xFFF59E0B)),
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
