import 'package:flutter/material.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';

class ScanResultScreen extends StatelessWidget {
  final String imagePath;
  final String foodName;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;

  const ScanResultScreen({
    Key? key,
    required this.imagePath,
    this.foodName = 'Grilled Chicken Salad',
    this.calories = 340,
    this.protein = 28,
    this.carbs = 12,
    this.fats = 18,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.authBackground),
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(AppColors.backgroundLight),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Color(AppColors.authHeadline),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Scan Result',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(AppColors.authHeadline),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 38),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Food image preview ──
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: FileImage(File(imagePath)),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {},
                      ),
                        color: const Color(0xFFEEECF8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 60,
                          color: const Color(AppColors.authPurple).withValues(alpha: 0.3),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Food name ──
                    Text(
                      foodName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(AppColors.authHeadline),
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Detected via AI Vision',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(AppColors.authBody).withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Calorie card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFCFC9F5), Color(0xFFE3DFFD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'CALORIES',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B5FD0),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$calories',
                                  style: const TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    color: Color(AppColors.authHeadline),
                                    letterSpacing: -2,
                                    height: 1.0,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' kcal',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6B5FD0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Macros row ──
                    const Text(
                      'Macronutrients',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(AppColors.authHeadline),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _MacroResultCard(
                            icon: Icons.bolt_rounded,
                            label: 'PROTEIN',
                            value: '${protein.toInt()}g',
                            color: const Color(AppColors.authPurple),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MacroResultCard(
                            icon: Icons.restaurant_rounded,
                            label: 'CARBS',
                            value: '${carbs.toInt()}g',
                            color: const Color(0xFF8A7FF0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MacroResultCard(
                            icon: Icons.local_fire_department_rounded,
                            label: 'FATS',
                            value: '${fats.toInt()}g',
                            color: const Color(0xFFFF6B6B),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Log Food Button ──
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(AppColors.authPurpleLight),
                            Color(AppColors.authPurpleDark),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(AppColors.authPurple).withValues(alpha: 0.38),
                            blurRadius: 22,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          splashColor: Colors.white.withValues(alpha: 0.12),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Meal logged successfully!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: Colors.white, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Log This Meal',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Footer ──
                    Text(
                      'SECURED BY FITFUEL AI ENGINE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.5,
                        letterSpacing: 1.5,
                        color: const Color(AppColors.authBody).withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 20),
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

// ── Macro Result Card ──
class _MacroResultCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MacroResultCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(AppColors.backgroundLight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(AppColors.authBorder),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(AppColors.authBody),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(AppColors.authHeadline),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}