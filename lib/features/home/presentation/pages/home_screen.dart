import 'package:fitfuel_ai/core/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

import 'package:fitfuel_ai/core/di/service_locator.dart';
import 'package:fitfuel_ai/core/domain/entities/goal_entity.dart';
import 'package:fitfuel_ai/core/domain/entities/meal_entity.dart';
import 'package:fitfuel_ai/core/domain/entities/user_profile_entity.dart';
import 'package:fitfuel_ai/core/domain/usecases/all_usecases.dart';
import 'package:fitfuel_ai/core/services/home_data_cache.dart';
import 'package:fitfuel_ai/core/services/home_data_refresh_notifier.dart';
import 'package:fitfuel_ai/core/services/water_goal_resolver.dart';
import 'package:fitfuel_ai/core/utils/fitness_calculator.dart';
import '../../../analytics/presentation/pages/analytics_screen.dart';
import '../../../food_scanner/presentation/pages/food_scanner_screen.dart';
import '../../../ai_coach/presentation/pages/ai_coach_screen.dart';
import '../../../profile/presentation/pages/profile_screen.dart';

// ─────────────────────────────────────────────
//  Design Tokens
// ─────────────────────────────────────────────
const Color kBg = Color(0xFFF5F5FA);
const Color kWhite = Color(0xFFFFFFFF);
const Color kPurple = Color(0xFF5B4EE8);
const Color kPurpleLight = Color(0xFFEDEBFB);
const Color kPurpleCard = Color(0xFFD8D4F8);
const Color kPurpleMid = Color(0xFFB8B0F0);
const Color kHeadline = Color(0xFF14142B);
const Color kBody = Color(0xFF8A8A9A);
const Color kBorder = Color(0xFFE8E6F5);
const Color kCardBg = Color(0xFFFFFFFF);
const Color kOrange = Color(0xFFF5A623);
const Color kGreen = Color(0xFF34C759);
const Color kRed = Color(0xFFFF6B6B);
const Color kProgressBg = Color(0xFFE4E0F8);

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

  // ── Real, DB-backed dashboard data ──
  String _greetingName = 'there';
  int _dailyGoalKcal = 2000;
  int _consumedKcal = 0;
  int _burnedKcal = 0;
  double _proteinTarget = 0, _proteinConsumed = 0;
  double _carbsTarget = 0, _carbsConsumed = 0;
  double _fatTarget = 0, _fatConsumed = 0;
  int _waterTotalMl = 0;
  int _waterTargetMl = 2000;
  List<MealEntity> _meals = const [];
  bool _loading = true;

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

    // Reload dashboard whenever meal logging (or similar) signals a change.
    HomeDataRefreshNotifier.instance.addListener(_onExternalRefresh);

    _initFromCache();
    _loadData();
  }

  void _onExternalRefresh() {
    _loadData();
  }

  /// Immediately applies cached data synchronously on frame 0 to eliminate flicker
  void _initFromCache() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final cached = HomeDataCache.getCached(user.id);
      if (cached != null) {
        _applyCachedData(cached);
      } else {
        HomeDataCache.loadPersistent(user.id).then((saved) {
          if (saved != null && mounted && _loading) {
            setState(() {
              _applyCachedData(saved);
            });
          }
        });
      }
    }
  }

  void _applyCachedData(HomeCachedData cached) {
    if (cached.name != null && cached.name!.isNotEmpty) {
      _greetingName = cached.name!.split(' ').first;
    }
    _dailyGoalKcal = cached.targetCalories;
    _consumedKcal = cached.consumedCalories;
    _burnedKcal = cached.burnedCalories;
    _proteinTarget = cached.targetProtein;
    _proteinConsumed = cached.consumedProtein;
    _carbsTarget = cached.targetCarbs;
    _carbsConsumed = cached.consumedCarbs;
    _fatTarget = cached.targetFat;
    _fatConsumed = cached.consumedFat;
    _waterTotalMl = cached.consumedWaterMl;
    _waterTargetMl = cached.targetWaterMl;
    _loading = false;
  }

  // Fallback calculation methods for when goals are not available in DB
  int _calculateFallbackCalories(UserProfileEntity? profile) {
    if (profile == null ||
        profile.weightKg == null ||
        profile.heightCm == null ||
        profile.age == null ||
        profile.gender == null ||
        profile.activityLevel == null) {
      return 2000;
    }

    final bmr = FitnessCalculator.calculateBMR(
      weightKg: profile.weightKg!,
      heightCm: profile.heightCm!,
      age: profile.age!,
      gender: profile.gender!,
    );

    final tdee = FitnessCalculator.calculateTDEE(
      bmr: bmr,
      activityLevel: profile.activityLevel!,
    );

    return FitnessCalculator.calculateTargetCalories(
      tdee: tdee,
      goalType: profile.goalType ?? 'maintenance',
      weeklyPaceKg: 0.5,
    );
  }

  double _calculateFallbackProtein(UserProfileEntity? profile) {
    if (profile == null || profile.weightKg == null) {
      return 150.0;
    }
    return FitnessCalculator.calculateProtein(weightKg: profile.weightKg!);
  }

  double _calculateFallbackCarbs(
      UserProfileEntity? profile, int calories, double protein) {
    if (profile == null) {
      return 200.0;
    }
    return FitnessCalculator.calculateCarbs(
      targetCalories: calories,
      targetProtein: protein,
      targetFat: _calculateFallbackFat(calories),
    );
  }

  double _calculateFallbackFat(int calories) {
    return FitnessCalculator.calculateFat(targetCalories: calories);
  }

  /// Fetches DB dashboard (goals + profile + meals + water) in a single parallel query.
  Future<void> _loadData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      // Parallel fetch via single use case
      final dash =
          await sl<FetchHomeDashboardUseCase>().call(user.id, DateTime.now());

      final goals = dash['goals'] as GoalEntity?;
      final profile = dash['profile'] as UserProfileEntity?;
      final meals = dash['meals'] as List? ?? const <MealEntity>[];

      final hasValidGoals = goals != null && goals.targetCalories > 0;

      if (!hasValidGoals) {
        debugPrint(
            'HomeScreen: ⚠️ USING FALLBACK — goals is ${goals == null ? "null" : "invalid (calories=${goals.targetCalories})"}. Profile goalType: ${profile?.goalType}');
      } else {
        debugPrint(
            'HomeScreen: ✅ Using DB goals — calories=${goals.targetCalories}, protein=${goals.targetProtein}, carbs=${goals.targetCarbs}, fat=${goals.targetFat}, water=${goals.dailyWaterMl}');
      }

      final dailyKcal = hasValidGoals
          ? goals.targetCalories
          : _calculateFallbackCalories(profile);
      final proteinTarget = (hasValidGoals && goals.targetProtein > 0)
          ? goals.targetProtein
          : _calculateFallbackProtein(profile);
      final carbsTarget = (hasValidGoals && goals.targetCarbs > 0)
          ? goals.targetCarbs
          : _calculateFallbackCarbs(profile, dailyKcal, proteinTarget);
      final fatTarget = (hasValidGoals && goals.targetFat > 0)
          ? goals.targetFat
          : _calculateFallbackFat(dailyKcal);
      // Use the SAME shared resolver as the water tracker so both screens always
      // show an identical target (DB goal → weight-based fallback).
      final waterTarget =
          await WaterGoalResolver.resolve(user.id);

      debugPrint(
          'HomeScreen DB targets: dailyKcal=$dailyKcal (from DB: ${goals?.targetCalories}), protein=$proteinTarget, carbs=$carbsTarget, fat=$fatTarget, water=$waterTarget');

      // Macro totals from today's logged meals
      var protein = 0.0, carbs = 0.0, fat = 0.0;
      for (final meal in meals.whereType<MealEntity>()) {
        for (final item in meal.items) {
          protein += item.protein;
          carbs += item.carbs;
          fat += item.fat;
        }
      }

      final consumedCalories = (dash['total_calories'] as num?)?.toInt() ?? 0;
      final consumedWater = (dash['total_water_ml'] as num?)?.toInt() ?? 0;
      final resolvedName = (profile?.name?.isNotEmpty ?? false)
          ? profile!.name!
          : (user.userMetadata?['name'] as String? ?? '');

      // Persist to cache so next launch or tab switch is 0ms instant
      await HomeDataCache.save(
        user.id,
        HomeCachedData(
          name: resolvedName,
          targetCalories: dailyKcal,
          consumedCalories: consumedCalories,
          burnedCalories: _burnedKcal,
          targetProtein: proteinTarget,
          consumedProtein: protein,
          targetCarbs: carbsTarget,
          consumedCarbs: carbs,
          targetFat: fatTarget,
          consumedFat: fat,
          targetWaterMl: waterTarget,
          consumedWaterMl: consumedWater,
        ),
      );

      if (mounted) {
        setState(() {
          _greetingName =
              resolvedName.isNotEmpty ? resolvedName.split(' ').first : 'there';
          _dailyGoalKcal = dailyKcal;
          _consumedKcal = consumedCalories;
          _proteinTarget = proteinTarget;
          _carbsTarget = carbsTarget;
          _fatTarget = fatTarget;
          _proteinConsumed = protein;
          _carbsConsumed = carbs;
          _fatConsumed = fat;
          _waterTotalMl = consumedWater;
          _waterTargetMl = waterTarget;
          _meals = meals.whereType<MealEntity>().toList()
            ..sort((a, b) =>
                (b.createdAt ?? b.date).compareTo(a.createdAt ?? a.date));
          _loading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('HomeScreen _loadData error: $e\n$stack');
    }
    if (mounted && _loading) setState(() => _loading = false);
  }

  /// Time-based greeting prefix, e.g. "Good morning".
  String _greetingPrefix() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Placeholder tint for a meal card, keyed by meal type.
  Color _mealColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return const Color(0xFFF5DEB3);
      case 'lunch':
        return const Color(0xFFB8D8E8);
      case 'dinner':
        return const Color(0xFFEDE6F5);
      default:
        return const Color(0xFFF0E6D3);
    }
  }

  /// Emoji used on the meal card (falls back to a generic icon).
  String _mealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '🥑';
      case 'lunch':
        return '🥗';
      case 'dinner':
        return '🍽️';
      default:
        return '🥗';
    }
  }

  /// Best-effort meal name: first food item, else the meal type.
  String _mealName(MealEntity meal) {
    if (meal.items.isNotEmpty && meal.items.first.foodName.isNotEmpty) {
      return meal.items.first.foodName;
    }
    return meal.mealType.isEmpty ? 'Meal' : meal.mealType;
  }

  /// Formats a meal's timestamp as "h:mm AM/PM".
  String _formatMealTime(MealEntity meal) {
    final time = meal.createdAt ?? meal.date;
    final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  @override
  void dispose() {
    HomeDataRefreshNotifier.instance.removeListener(_onExternalRefresh);
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
                children: [
                  Text(
                    '${_greetingPrefix()}, $_greetingName ',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: kHeadline,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Text('👋', style: TextStyle(fontSize: 22)),
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
              child: Text(
                _loading
                    ? 'Fetching your daily targets…'
                    : 'Let’s hit today’s goals together.',
                style: const TextStyle(
                  fontSize: 13.5,
                  color: kBody,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _CalorieCard(
              animation: _entryController,
              dailyGoal: _dailyGoalKcal,
              consumed: _consumedKcal,
              burned: _burnedKcal,
            ),
            const SizedBox(height: 16),
            _MacroRow(
              animation: _entryController,
              proteinCurrent: _proteinConsumed,
              proteinTotal: _proteinTarget,
              carbsCurrent: _carbsConsumed,
              carbsTotal: _carbsTarget,
              fatCurrent: _fatConsumed,
              fatTotal: _fatTarget,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _WaterCard(
                    animation: _entryController,
                    totalMl: _waterTotalMl,
                    targetMl: _waterTargetMl,
                    onReload: _loadData,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _AICoachCard(animation: _entryController)),
              ],
            ),
AnimatedBuilder(
              animation: _entryController,
              builder: (context, child) {
                final t = _clamp01(CurvedAnimation(
                  parent: _entryController,
                  curve: const Interval(0.46, 0.66, curve: Curves.easeOutCubic),
                ).value);
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 24 * (1 - t)),
                    child: child,
                  ),
                );
              },
              child: _MealCard(animation: _entryController),
            ),
            const SizedBox(height: 14),
            const SizedBox(height: 14),
            AnimatedBuilder(
              animation: _entryController,
              builder: (context, child) {
                final t = CurvedAnimation(
                  parent: _entryController,
                  curve: const Interval(0.40, 0.60, curve: Curves.easeOutCubic),
                ).value;
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 28 * (1 - t)),
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.bmi),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kBorder, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: kPurpleLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.monitor_weight_rounded,
                            color: kPurple, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'BMI Calculator',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: kHeadline,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Check your body mass index and healthy range in one tap.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: kBody,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 18, color: kPurple),
                    ],
                  ),
                ),
              ),
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
            if (_meals.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kBorder, width: 1),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.restaurant_rounded, size: 30, color: kPurple),
                    SizedBox(height: 10),
                    Text(
                      'No meals recorded today yet.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kHeadline,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap See History to log a meal.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: kBody,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              for (var i = 0; i < _meals.length; i++) ...[
                if (i > 0) const SizedBox(height: 2),
                _MealItem(
                  animation: _entryController,
                  index: i,
                  imagePlaceholderColor: _mealColor(_meals[i].mealType),
                  mealType: _meals[i].mealType,
                  time: _formatMealTime(_meals[i]),
                  name: _mealName(_meals[i]),
                  kcal: '${_meals[i].totalCalories} kcal',
                  icon: _mealIcon(_meals[i].mealType),
                ),
              ],
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
                    const Icon(Icons.notifications_rounded,
                        color: kPurple, size: 20),
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
            const SizedBox(width: 10),
            // Activity calendar (extreme top-right)
            GestureDetector(
              onTap: () => context.push(AppRoutes.activityCalendar),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kPurpleLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: kPurple,
                  size: 20,
                ),
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
  const _CalorieCard({
    required this.animation,
    required this.dailyGoal,
    required this.consumed,
    required this.burned,
  });

  final Animation<double> animation;
  final int dailyGoal;
  final int consumed;
  final int burned;

  @override
  Widget build(BuildContext context) {
    final remaining = (dailyGoal - consumed).clamp(0, dailyGoal);
    final progress =
        dailyGoal <= 0 ? 0.0 : (consumed / dailyGoal).clamp(0.0, 1.0);
    final percentLeft =
        dailyGoal <= 0 ? 0 : ((remaining / dailyGoal) * 100).clamp(0, 100);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final spring = _clamp01(Curves.elasticOut.transform(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.08, 0.42),
          ).value,
        ));

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
                          text: remaining.toString(),
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
                    children: [
                      Text(
                        'Daily Goal: $dailyGoal kcal',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF6B5FD0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$percentLeft% left',
                        style: const TextStyle(
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
  const _MacroRow({
    required this.animation,
    required this.proteinCurrent,
    required this.proteinTotal,
    required this.carbsCurrent,
    required this.carbsTotal,
    required this.fatCurrent,
    required this.fatTotal,
  });

  final Animation<double> animation;
  final double proteinCurrent;
  final double proteinTotal;
  final double carbsCurrent;
  final double carbsTotal;
  final double fatCurrent;
  final double fatTotal;

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
            current: '${proteinCurrent.round()}g',
            total: '/ ${proteinTotal.round()}g',
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
            current: '${carbsCurrent.round()}g',
            total: '/ ${carbsTotal.round()}g',
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
            current: '${fatCurrent.round()}g',
            total: '/ ${fatTotal.round()}g',
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
          curve: Interval(intervalStart, intervalStart + 0.34,
              curve: Curves.elasticOut),
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
        child: Column(
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
                    text: current,
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
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Meal Add Card
// ─────────────────────────────────────────────
class _MealCard extends StatelessWidget {
  const _MealCard({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.46, 0.66, curve: Curves.easeOutBack),
        ).value);
        return Transform.translate(
          offset: Offset(0, 22 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.mealTracking),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: kOrange.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: kOrange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Track a Meal',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: kHeadline,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Add your breakfast, lunch or dinner in seconds.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: kBody,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kOrange,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, color: kWhite, size: 16),
                    SizedBox(width: 2),
                    Text(
                      'ADD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: kWhite,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────
//  Water Card
// ─────────────────────────────────────────────
class _WaterCard extends StatelessWidget {
  const _WaterCard({
    required this.animation,
    required this.totalMl,
    required this.targetMl,
    required this.onReload,
  });

  final Animation<double> animation;
  final int totalMl;
  final int targetMl;
  final VoidCallback onReload;

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
        child: GestureDetector(
          onTap: () async {
            await context.push(AppRoutes.waterTracker);
            onReload();
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder, width: 1),
            ),
            child: Column(
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
                        const Icon(
                          Icons.water_drop_outlined,
                          size: 18,
                          color: kPurple,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: kPurple.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        targetMl <= 0
                            ? '0% DONE'
                            : '${((totalMl / targetMl) * 100).clamp(0, 100).toInt()}% DONE',
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: kPurple,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'WATER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kBody,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: (totalMl / 1000.0).toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: kHeadline,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${(targetMl / 1000.0).toStringAsFixed(1)}L',
                        style: const TextStyle(
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
                  onTap: () async {
                    await context.push(AppRoutes.waterTracker);
                    onReload();
                  },
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
            ),
          ),
        ));
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
            final pulse =
                1.0 + (math.sin(animation.value * math.pi * 2) * 0.08);
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
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
                      const Icon(Icons.access_time_rounded,
                          size: 11, color: kBody),
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
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w400,
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

  // Fallback calculation methods for when goals are not available
  int _calculateFallbackCalories(UserProfileEntity? profile) {
    if (profile == null ||
        profile.weightKg == null ||
        profile.heightCm == null ||
        profile.age == null ||
        profile.gender == null ||
        profile.activityLevel == null) {
      return 2000; // Default fallback
    }

    final bmr = FitnessCalculator.calculateBMR(
      weightKg: profile.weightKg!,
      heightCm: profile.heightCm!,
      age: profile.age!,
      gender: profile.gender!,
    );

    final tdee = FitnessCalculator.calculateTDEE(
      bmr: bmr,
      activityLevel: profile.activityLevel!,
    );

    return FitnessCalculator.calculateTargetCalories(
      tdee: tdee,
      goalType: profile.goalType ?? 'maintain',
      weeklyPaceKg: 0.5,
    );
  }

  double _calculateFallbackProtein(UserProfileEntity? profile) {
    if (profile == null || profile.weightKg == null) {
      return 150.0; // Default fallback
    }
    return FitnessCalculator.calculateProtein(weightKg: profile.weightKg!);
  }

  double _calculateFallbackCarbs(
      UserProfileEntity? profile, int calories, double protein) {
    if (profile == null) {
      return 200.0; // Default fallback
    }
    return FitnessCalculator.calculateCarbs(
      targetCalories: calories,
      targetProtein: protein,
      targetFat: _calculateFallbackFat(calories),
    );
  }

  double _calculateFallbackFat(int calories) {
    return FitnessCalculator.calculateFat(targetCalories: calories);
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
