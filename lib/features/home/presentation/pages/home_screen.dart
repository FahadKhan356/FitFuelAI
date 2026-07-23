import 'package:fitfuel_ai/core/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import '../../../analytics/presentation/pages/analytics_screen.dart';
import '../../../food_scanner/presentation/pages/food_scanner_screen.dart';
import '../../../ai_coach/presentation/pages/ai_coach_screen.dart';
import '../../../profile/presentation/pages/profile_screen.dart';

// ─────────────────────────────────────────────
//  Design Tokens
// ─────────────────────────────────────────────
const Color kBg           = Color(0xFFF5F5FA);
const Color kWhite        = Color(0xFFFFFFFF);
const Color kPurple       = Color(0xFF5B4EE8);
const Color kPurpleLight  = Color(0xFFEDEBFB);
const Color kPurpleCard   = Color(0xFFD8D4F8);
const Color kPurpleMid    = Color(0xFFB8B0F0);
const Color kHeadline     = Color(0xFF14142B);
const Color kBody         = Color(0xFF8A8A9A);
const Color kBorder       = Color(0xFFE8E6F5);
const Color kCardBg       = Color(0xFFFFFFFF);
const Color kOrange       = Color(0xFFF5A623);
const Color kGreen        = Color(0xFF34C759);
const Color kRed          = Color(0xFFFF6B6B);
const Color kProgressBg   = Color(0xFFE4E0F8);

// ─────────────────────────────────────────────
//  Home Screen
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  final Map<int, int> _tabKeys = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0};

  void _openScan() => _switchTab(2);

  void _switchTab(int index) {
    setState(() {
      _navIndex = index;
      _tabKeys[index] = _tabKeys[index]! + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      floatingActionButton: _CameraFAB(onTap: _openScan),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _BottomNav(
        currentIndex: _navIndex,
        onTap: _switchTab,
      ),
      body: IndexedStack(
        index: _navIndex,
        children: [
          _HomeContent(key: ValueKey('home_${_tabKeys[0]}')),
          AnalyticsScreen(key: ValueKey('analytics_${_tabKeys[1]}')),
          FoodScannerScreen(key: ValueKey('scanner_${_tabKeys[2]}')),
          AiCoachScreen(key: ValueKey('coach_${_tabKeys[3]}')),
          ProfileScreen(key: ValueKey('profile_${_tabKeys[4]}')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Home Tab Content
// ─────────────────────────────────────────────
class _HomeContent extends StatefulWidget {
  const _HomeContent({super.key});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),

            _TopBar(floating: _floatingController),

            const SizedBox(height: 20),

            AnimatedBuilder(
              animation: _entryController,
              builder: (context, child) {
                final t = Curves.easeOutCubic.transform(
                  CurvedAnimation(
                    parent: _entryController,
                    curve: const Interval(0.00, 0.22),
                  ).value,
                );
                return Transform.translate(
                  offset: Offset(0, -15 * (1 - t)),
                  child: Opacity(opacity: t, child: child),
                );
              },
              child: Row(
                children: const [
                  Text(
                    'Morning, Alex ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: kHeadline,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text('👋', style: TextStyle(fontSize: 22)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            AnimatedBuilder(
              animation: _entryController,
              builder: (context, child) {
                final t = Curves.easeOutCubic.transform(
                  CurvedAnimation(
                    parent: _entryController,
                    curve: const Interval(0.02, 0.24),
                  ).value,
                );
                return Transform.translate(
                  offset: Offset(0, -15 * (1 - t)),
                  child: Opacity(opacity: t, child: child),
                );
              },
              child: const Text(
                "You're doing great! Keep it up.",
                style: TextStyle(
                  fontSize: 13.5,
                  color: kBody,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            const SizedBox(height: 18),

            _CalorieCard(animation: _entryController),

            const SizedBox(height: 16),

            _MacroRow(animation: _entryController),

            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _WaterCard(animation: _entryController)),
                const SizedBox(width: 12),
                Expanded(child: _AICoachCard(animation: _entryController)),
              ],
            ),

            const SizedBox(height: 22),

            AnimatedBuilder(
              animation: _entryController,
              builder: (context, child) {
                final t = CurvedAnimation(
                  parent: _entryController,
                  curve: const Interval(0.62, 0.82, curve: Curves.easeOutCubic),
                ).value;
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 40 * (1 - t)),
                    child: child,
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Meals',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: kHeadline,
                      letterSpacing: -0.2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.mealTracking),
                    child: const Text(
                      'See History',
                      style: TextStyle(
                        fontSize: 13,
                        color: kPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            _MealItem(
              animation: _entryController,
              index: 0,
              imagePlaceholderColor: const Color(0xFFF5DEB3),
              mealType: 'Breakfast',
              time: '08:30 AM',
              name: 'Avocado Toast with Egg',
              kcal: '340 kcal',
              icon: '🥑',
            ),
            const SizedBox(height: 2),
            _MealItem(
              animation: _entryController,
              index: 1,
              imagePlaceholderColor: const Color(0xFFB8D8E8),
              mealType: 'Lunch',
              time: '01:15 PM',
              name: 'Grilled Salmon Salad',
              kcal: '480 kcal',
              icon: '🐟',
            ),
            const SizedBox(height: 2),
            _MealItem(
              animation: _entryController,
              index: 2,
              imagePlaceholderColor: const Color(0xFFF0E6D3),
              mealType: 'Snack',
              time: '04:00 PM',
              name: 'Greek Yogurt Bowl',
              kcal: '210 kcal',
              icon: '🥣',
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

double _clamp01(double value) => value.clamp(0.0, 1.0);

// ─────────────────────────────────────────────
//  Top Bar
// ─────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.floating});

  final Animation<double> floating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AnimatedBuilder(
          animation: floating,
          builder: (context, child) {
            final offset = math.sin(floating.value * math.pi * 2) * 4;
            return Transform.translate(
              offset: Offset(0, offset),
              child: child,
            );
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kHeadline,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.bolt_rounded, color: kWhite, size: 22),
          ),
        ),

        Row(
          children: [
            // Notifications bell
            GestureDetector(
              onTap: () => context.push(AppRoutes.notifications),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kPurpleLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.notifications_rounded, color: kPurple, size: 20),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B6B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '3 DAY STREAK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kPurple,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: const [
                    Text('🔥', style: TextStyle(fontSize: 14)),
                    Text('🔥', style: TextStyle(fontSize: 14)),
                    Text('🔥', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPurpleCard,
                border: Border.all(color: kPurple, width: 2),
              ),
              child: const Center(
                child: Text('👤', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Calorie Card
// ─────────────────────────────────────────────
class _CalorieCard extends StatelessWidget {
  const _CalorieCard({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    const double progress = 0.29;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final spring = _clamp01(Curves.elasticOut.transform(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.08, 0.42),
          ).value,
        ));
        final roll = _clamp01(Curves.easeOutBack.transform(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.12, 0.55),
          ).value,
        ));
        final mainCalories = (roll * 1420).toInt();
        final consumed = (Curves.easeOutCubic.transform(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.18, 0.56),
          ).value,
        ) * 580).toInt();
        final burned = (Curves.easeOutCubic.transform(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.22, 0.60),
          ).value,
        ) * 245).toInt();

        return Transform.scale(
          scale: 0.95 + (spring * 0.07),
          child: Transform.rotate(
            angle: (1 - spring) * 0.026,
            child: Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'REMAINING',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B5FD0),
                          letterSpacing: 1.5,
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.trending_up_rounded,
                          size: 16,
                          color: Color(0xFF6B5FD0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: mainCalories.toString(),
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: kHeadline,
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _CalorieStat(label: 'Consumed', value: '$consumed kcal'),
                      const SizedBox(width: 32),
                      _CalorieStat(label: 'Burned', value: '$burned kcal'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Daily Goal: 2,000 kcal',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF6B5FD0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '71% left',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF6B5FD0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withOpacity(0.45),
                      valueColor: const AlwaysStoppedAnimation<Color>(kPurple),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CalorieStat extends StatelessWidget {
  final String label;
  final String value;

  const _CalorieStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B5FD0),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: kHeadline,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Macro Row
// ─────────────────────────────────────────────
class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MacroCard(
            animation: animation,
            index: 0,
            icon: Icons.bolt_rounded,
            iconColor: kPurple,
            label: 'PROTEIN',
            current: '65g',
            total: '/ 140g',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MacroCard(
            animation: animation,
            index: 1,
            icon: Icons.restaurant_rounded,
            iconColor: const Color(0xFF8A7FF0),
            label: 'CARBS',
            current: '120g',
            total: '/ 250g',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MacroCard(
            animation: animation,
            index: 2,
            icon: Icons.local_fire_department_rounded,
            iconColor: kRed,
            label: 'FATS',
            current: '42g',
            total: '/ 70g',
          ),
        ),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.animation,
    required this.index,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.current,
    required this.total,
  });

  final Animation<double> animation;
  final int index;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String current;
  final String total;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final intervalStart = 0.22 + (index * 0.06);
        final t = CurvedAnimation(
          parent: animation,
          curve: Interval(intervalStart, intervalStart + 0.34, curve: Curves.elasticOut),
        ).value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - t)),
            child: Transform.scale(
              scale: 0.94 + (t * 0.08),
              child: child,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder, width: 1),
        ),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final intervalStart = 0.22 + (index * 0.06);
            final t = CurvedAnimation(
              parent: animation,
              curve: Interval(intervalStart, intervalStart + 0.34, curve: Curves.easeOut),
            ).value;
            final count = (t * _extractValue(current)).toInt();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 14, color: iconColor),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: kBody,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${count}g',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: kHeadline,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: ' $total',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: kBody,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

int _extractValue(String value) {
  final parsed = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
  return parsed ?? 0;
}

// ─────────────────────────────────────────────
//  Water Card
// ─────────────────────────────────────────────
class _WaterCard extends StatelessWidget {
  const _WaterCard({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.46, 0.67, curve: Curves.easeOutBack),
        ).value);
        return Transform.translate(
          offset: Offset(0, 22 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder, width: 1),
        ),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final t = _clamp01(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.46, 0.67, curve: Curves.easeOutBack),
            ).value);
            final liters = t * 1.8;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: kPurpleLight,
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 34 * t,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0x804F46E5), Color(0x336366F1)],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.water_drop_outlined,
                          size: 18,
                          color: kPurple,
                        ),
                      ],
                    ),
                    Transform.scale(
                      scale: 0.92 + (t * 0.08),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: kPurple.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          '75% DONE',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: kPurple,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'WATER',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: kBody,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${liters.toStringAsFixed(1)}L',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: kHeadline,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const TextSpan(
                        text: ' / 2.5L',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: kBody,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.waterTracker),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: kPurpleLight,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Center(
                      child: Text(
                        '+250ml',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kPurple,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  AI Coach Card
// ─────────────────────────────────────────────
class _AICoachCard extends StatelessWidget {
  const _AICoachCard({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.54, 0.74, curve: Curves.easeOutCubic),
        ).value);
        return Transform.translate(
          offset: Offset(0, 22 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder, width: 1),
        ),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final t = _clamp01(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.54, 0.74, curve: Curves.easeOutCubic),
            ).value);
            final pulse = 1.0 + (math.sin(animation.value * math.pi * 2) * 0.08);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Transform.scale(
                      scale: pulse,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: kPurpleLight,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          size: 18,
                          color: kPurple,
                        ),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: kBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: kBorder, width: 1),
                      ),
                      child: const Center(
                        child: Text('ℹ️', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'AI COACH',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: kBody,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  '"Ready to plan your dinner?"',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kHeadline,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () {},
                  child: Stack(
                    children: [
                      Row(
                        children: const [
                          Text(
                            'ASK NOW',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: kPurple,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 3),
                          Text(
                            '→',
                            style: TextStyle(
                              fontSize: 13,
                              color: kPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.18 + (0.22 * t),
                          child: const _ShineSweep(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Meal Item
// ─────────────────────────────────────────────
class _MealItem extends StatelessWidget {
  const _MealItem({
    required this.animation,
    required this.index,
    required this.imagePlaceholderColor,
    required this.mealType,
    required this.time,
    required this.name,
    required this.kcal,
    required this.icon,
  });

  final Animation<double> animation;
  final int index;
  final Color imagePlaceholderColor;
  final String mealType;
  final String time;
  final String name;
  final String kcal;
  final String icon;

  Color get _mealTypeColor {
    switch (mealType) {
      case 'Breakfast':
        return const Color(0xFF34C759);
      case 'Lunch':
        return const Color(0xFF5B4EE8);
      case 'Snack':
        return const Color(0xFFF5A623);
      default:
        return kBody;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final start = 0.66 + (index * 0.06);
        final t = _clamp01(CurvedAnimation(
          parent: animation,
          curve: Interval(start, start + 0.22, curve: Curves.easeOutCubic),
        ).value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: imagePlaceholderColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _mealTypeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          mealType,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: _mealTypeColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.access_time_rounded, size: 11, color: kBody),
                      const SizedBox(width: 3),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: kBody,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kHeadline,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    kcal,
                    style: const TextStyle(
                      fontSize: 12,
                      color: kPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: kBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShineSweep extends StatefulWidget {
  const _ShineSweep();

  @override
  State<_ShineSweep> createState() => _ShineSweepState();
}

class _ShineSweepState extends State<_ShineSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final x = -0.8 + (_controller.value * 1.8);
          return Transform.translate(
            offset: Offset(x * 90, 0),
            child: Transform.rotate(
              angle: -0.25,
              child: Container(
                width: 70,
                height: 18,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.65),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Camera FAB
// ─────────────────────────────────────────────
class _CameraFAB extends StatelessWidget {
  final VoidCallback onTap;

  const _CameraFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: kPurple,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: kPurple.withOpacity(0.42),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onTap,
          child: const Icon(
            Icons.camera_alt_rounded,
            color: kWhite,
            size: 26,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Bottom Navigation Bar
// ─────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.bar_chart_rounded, label: 'Stats'),
      _NavItem(icon: Icons.qr_code_scanner_rounded, label: 'Scan'),
      _NavItem(icon: Icons.smart_toy_outlined, label: 'Coach'),
      _NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        border: Border(top: BorderSide(color: kBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final bool active = i == currentIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 56,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i].icon,
                        size: 24,
                        color: active ? kPurple : kBody,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: active ? kPurple : kBody,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: active ? 18 : 0,
                        height: 3,
                        decoration: BoxDecoration(
                          color: kPurple,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
