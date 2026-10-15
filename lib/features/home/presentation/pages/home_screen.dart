import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:fitfuel_ai/core/config/routes.dart';
import 'package:fitfuel_ai/core/di/service_locator.dart';
import 'package:fitfuel_ai/core/domain/entities/goal_entity.dart';
import 'package:fitfuel_ai/core/domain/entities/meal_entity.dart';
import 'package:fitfuel_ai/core/domain/entities/user_profile_entity.dart';
import 'package:fitfuel_ai/core/domain/usecases/all_usecases.dart';
import 'package:fitfuel_ai/core/services/calorie_goal_resolver.dart';
import 'package:fitfuel_ai/core/services/home_data_cache.dart';
import 'package:fitfuel_ai/core/services/home_data_refresh_notifier.dart';
import 'package:fitfuel_ai/core/services/streak_service.dart';
import 'package:fitfuel_ai/core/services/water_goal_resolver.dart';
import 'package:fitfuel_ai/core/theme/theme_controller.dart';
import 'package:fitfuel_ai/core/utils/fitness_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../screens/camera_scan_screen.dart';
import '../../../ai_coach/presentation/pages/ai_coach_screen.dart';
import '../../../analytics/presentation/pages/analytics_screen.dart';
import '../../../profile/presentation/pages/profile_screen.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../core/domain/repositories/meal_repository.dart';
import '../../../meal_tracking/presentation/pages/food_nutrition_detail_sheet.dart';
import '../../../meal_tracking/presentation/pages/meal_tracking_screen.dart' show MealLog;
import '../../../posture_coach/screens/posture_coach_screen.dart';

// ─────────────────────────────────────────────
//  Design Tokens
// ─────────────────────────────────────────────
const Color kBg = Color(0xFFF8F9FE);
const Color kWhite = Color(0xFFFFFFFF);
const Color kPurple = Color(0xFF6366F1);
const Color kPurpleLight = Color(0xFFEEF2FF);
const Color kPurpleCard = Color(0xFFE0E7FF);
const Color kPurpleMid = Color(0xFF818CF8);
const Color kHeadline = Color(0xFF0F172A);
const Color kBody = Color(0xFF64748B);
const Color kBorder = Color(0xFFF1F5F9);
const Color kCardBg = Color(0xFFFFFFFF);
const Color kOrange = Color(0xFFF5A623);
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFF43F5E);
const Color kProgressBg = Color(0xFFE2E8F0);

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

  void _openScan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraScanScreen()),
    );
  }

  void _switchTab(int index) {
    // IndexedStack keeps inactive tabs alive. Replacing their keys here used
    // to dispose and recreate every screen on each tap, causing a fresh DB
    // request and visible late-changing values after navigation.
    if (index == _navIndex) {
      return;
    }
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // The Scan tab is already the scanner, and the Coach tab has its own chat input bar.
      floatingActionButton: (_navIndex == 2 || _navIndex == 3)
          ? null
          : _CameraFAB(onTap: _openScan),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _BottomNav(
        currentIndex: _navIndex,
        onTap: _switchTab,
      ),
      body: IndexedStack(
        index: _navIndex,
        children: [
          _HomeContent(
            onNavigateToProfile: () => _switchTab(4),
            onNavigateToCoach: () => _switchTab(3),
          ),
          const AnalyticsScreen(),
          const CameraScanScreen(embedded: true),
          const AiCoachScreen(),
          const ProfileScreen(),
        ],
      ),
    );
}

// ─────────────────────────────────────────────
//  Home Tab Content
// ─────────────────────────────────────────────
class _HomeContent extends StatefulWidget {
  const _HomeContent({
    this.onNavigateToProfile,
    this.onNavigateToCoach,
  });

  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToCoach;

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _floatingController;

  // ── Real, DB-backed dashboard data ──
  String _greetingName = 'there';
  String? _avatarUrl;
  int _dailyGoalKcal = 2000;
  int _consumedKcal = 0;
  int _burnedKcal = 0;
  double _proteinTarget = 0, _proteinConsumed = 0;
  double _carbsTarget = 0, _carbsConsumed = 0;
  double _fatTarget = 0, _fatConsumed = 0;
  int _waterTotalMl = 0;
  int _waterTargetMl = 2000;
  int _streak = 0;
  bool _streakTodayActive = false;
  List<MealEntity> _meals = const [];
  bool _loading = true;
  int _loadGeneration = 0;

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
    // Guard against stale cached 0/negative targets (older buggy saves wrote 0
    // for the calorie goal). Default to 2000 so the card never shows a dead 0.
    _dailyGoalKcal = cached.targetCalories > 0 ? cached.targetCalories : 2000;
    _consumedKcal = cached.consumedCalories;
    _burnedKcal = cached.burnedCalories;
    _proteinTarget = cached.targetProtein > 0 ? cached.targetProtein : 150;
    _proteinConsumed = cached.consumedProtein;
    _carbsTarget = cached.targetCarbs > 0 ? cached.targetCarbs : 200;
    _carbsConsumed = cached.consumedCarbs;
    _fatTarget = cached.targetFat > 0 ? cached.targetFat : 65;
    _fatConsumed = cached.consumedFat;
    _waterTotalMl = cached.consumedWaterMl;
    _waterTargetMl = cached.targetWaterMl > 0 ? cached.targetWaterMl : 2000;
    _loading = false;
  }

  // Fallback calculation methods for when goals are not available in DB
  double _calculateFallbackProtein(UserProfileEntity? profile) {
    final weight = profile?.currentWeightKg ?? profile?.weightKg;
    if (weight == null) {
      return 150;
    }
    return FitnessCalculator.calculateProtein(weightKg: weight);
  }

  double _calculateFallbackCarbs(
      UserProfileEntity? profile, int calories, double protein) {
    if (profile == null) {
      return 200;
    }
    return FitnessCalculator.calculateCarbs(
      targetCalories: calories,
      targetProtein: protein,
      targetFat: _calculateFallbackFat(calories),
    );
  }

  double _calculateFallbackFat(int calories) => FitnessCalculator.calculateFat(targetCalories: calories);

  /// Fetches DB dashboard (goals + profile + meals + water) in a single parallel query.
  Future<void> _loadData() async {
    final generation = ++_loadGeneration;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted && generation == _loadGeneration) {
          setState(() => _loading = false);
        }
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

      // These do not depend on each other. Running them concurrently keeps a
      // refresh quick, while cached values remain visible in the meantime.
      final resolved = await Future.wait<Object>([
        CalorieGoalResolver.resolve(user.id),
        WaterGoalResolver.resolve(user.id),
        StreakService.compute(user.id),
      ]);
      if (generation != _loadGeneration) {
        return;
      }
      final dailyKcal = resolved[0] as int;
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
      final waterTarget = resolved[1] as int;
      final streakInfo = resolved[2] as StreakInfo;

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
      // `save` updates the in-memory cache before its first await. Do not
      // make the UI wait for SharedPreferences disk I/O before rendering the
      // newly fetched dashboard.
      unawaited(HomeDataCache.save(
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
      ));

      if (mounted && generation == _loadGeneration) {
        setState(() {
          _greetingName =
              resolvedName.isNotEmpty ? resolvedName.split(' ').first : 'there';
          _avatarUrl = profile?.avatarUrl;
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
          _streak = streakInfo.current;
          _streakTodayActive = streakInfo.todayActive;
          _meals = meals.whereType<MealEntity>().toList()
            ..sort((a, b) =>
                (b.createdAt ?? b.date).compareTo(a.createdAt ?? a.date));
          _loading = false;
        });
      }
    } on Object catch (e, stack) {
      if (generation == _loadGeneration) {
        debugPrint('HomeScreen _loadData error: $e\n$stack');
      }
    }
    if (mounted && generation == _loadGeneration && _loading) {
      setState(() => _loading = false);
    }
  }

  /// Time-based greeting prefix, e.g. "Good morning".
  String _greetingPrefix() {
    final h = DateTime.now().hour;
    if (h < 12) {
      return 'Good morning';
    }
    if (h < 17) {
      return 'Good afternoon';
    }
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

  /// Icon used on the meal card (falls back to a generic icon).
  ///
  /// Material icons rather than emoji: the app's text theme is Poppins, which
  /// has no colour-emoji glyphs, so emoji render as empty "tofu" boxes on iOS.
  IconData _mealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast_rounded;
      case 'lunch':
        return Icons.lunch_dining_rounded;
      case 'dinner':
        return Icons.dinner_dining_rounded;
      default:
        return Icons.restaurant_rounded;
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

  void _onMealTap(MealEntity meal) {
    HapticFeedback.selectionClick();
    if (meal.items.length > 1) {
      _showMultiItemPicker(meal);
    } else {
      final it = meal.items.isNotEmpty ? meal.items.first : null;
      double p = 0.0, c = 0.0, f = 0.0, fib = 0.0;
      for (final item in meal.items) {
        p += item.protein;
        c += item.carbs;
        f += item.fat;
        fib += item.fiber;
      }
      final mealLog = MealLog(
        mealId: meal.id,
        itemId: it?.id ?? '',
        foodName: _mealName(meal),
        calories: meal.totalCalories,
        protein: p,
        carbs: c,
        fat: f,
        fiber: fib,
        servingSize: it?.servingSize ?? 100.0,
        servingUnit: it?.servingUnit ?? 'g',
        mealType: meal.mealType,
        date: meal.createdAt ?? meal.date,
      );
      FoodNutritionDetailSheet.show(
        context,
        meal: mealLog,
        dailyCalorieGoal: _dailyGoalKcal,
        onRemove: () async {
          final user = Supabase.instance.client.auth.currentUser;
          if (user != null && it != null && it.id.isNotEmpty) {
            await sl<MealRepository>().deleteMealItem(it.id, meal.id);
            HomeDataRefreshNotifier.instance.refresh();
            _loadData();
          }
        },
      );
    }
  }

  void _showMultiItemPicker(MealEntity meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: isDark ? AppDarkColors.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${meal.mealType.toUpperCase()} FOOD ITEMS',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kPurple,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    '${meal.totalCalories} kcal total',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kPurple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final it in meal.items) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.restaurant_rounded, color: kPurple, size: 20),
                  ),
                  title: Text(
                    it.foodName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppDarkColors.textPrimary : kHeadline,
                    ),
                  ),
                  subtitle: Text(
                    'P ${it.protein.round()}g · C ${it.carbs.round()}g · F ${it.fat.round()}g',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppDarkColors.textSecondary : kBody,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${it.calories} kcal',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: kPurple,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, color: kPurple, size: 20),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    final mealLog = MealLog(
                      mealId: meal.id,
                      itemId: it.id,
                      foodName: it.foodName,
                      calories: it.calories,
                      protein: it.protein,
                      carbs: it.carbs,
                      fat: it.fat,
                      fiber: it.fiber,
                      servingSize: it.servingSize,
                      servingUnit: it.servingUnit,
                      mealType: meal.mealType,
                      date: it.createdAt ?? meal.date,
                    );
                    FoodNutritionDetailSheet.show(
                      context,
                      meal: mealLog,
                      dailyCalorieGoal: _dailyGoalKcal,
                      onRemove: () async {
                        final user = Supabase.instance.client.auth.currentUser;
                        if (user != null && it.id.isNotEmpty) {
                          await sl<MealRepository>().deleteMealItem(it.id, meal.id);
                          HomeDataRefreshNotifier.instance.refresh();
                          _loadData();
                        }
                      },
                    );
                  },
                ),
                const Divider(height: 1),
              ],
            ],
          ),
        );
      },
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            _TopBar(
              floating: _floatingController,
              avatarUrl: _avatarUrl,
              streak: _streak,
              streakTodayActive: _streakTodayActive,
              onAvatarTap: widget.onNavigateToProfile,
            ),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _entryController,
              builder: (context, child) {
                final t = Curves.easeOutCubic.transform(
                  CurvedAnimation(
                    parent: _entryController,
                    curve: const Interval(0, 0.22),
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
                      color: isDark ? AppDarkColors.textPrimary : kHeadline,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Icon(Icons.waving_hand_rounded,
                      size: 22, color: kOrange),
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
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? AppDarkColors.textSecondary : kBody,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 18),
            // The daily targets (calories/macros/water) only render once real
            // data has arrived — either from cache or the DB. Rendering them
            // with the 2000/150/2500 defaults while loading caused a visible
            // 2000 → actual (e.g. 2507) flash on every cold open.
            if (_loading)
              const _DashboardLoading()
            else ...[
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
                  Expanded(
                    child: _AICoachCard(
                      animation: _entryController,
                      onTap: () {
                        if (widget.onNavigateToCoach != null) {
                          widget.onNavigateToCoach!();
                        } else {
                          context.push(AppRoutes.aiCoach);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
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
                    color: isDark ? AppDarkColors.surface : kWhite,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? AppDarkColors.border : const Color(0xFFEDE9FE),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.2)
                            : const Color(0xFF6366F1).withValues(alpha: 0.05),
                        blurRadius: 14,
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
                          color: isDark ? AppDarkColors.surfaceAlt : const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: isDark ? AppDarkColors.border : const Color(0xFFE0E7FF),
                          ),
                        ),
                        child: const Icon(
                          Icons.monitor_weight_rounded,
                          color: Color(0xFF6366F1),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BMI Calculator',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppDarkColors.textPrimary : kHeadline,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Check your body mass index and healthy range in one tap.',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppDarkColors.textSecondary : kBody,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.surfaceAlt : const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // AI Posture Coach Card
            AnimatedBuilder(
              animation: _entryController,
              builder: (context, child) {
                final t = CurvedAnimation(
                  parent: _entryController,
                  curve: const Interval(0.48, 0.68, curve: Curves.easeOutCubic),
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PostureCoachScreen(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? const [Color(0xFF261D4E), Color(0xFF1E1738)]
                          : const [Color(0xFFF3F0FF), Color(0xFFEDE8FE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF5B4EE8).withValues(alpha: 0.3)
                          : const Color(0xFFDCD2FD),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B4EE8).withValues(alpha: 0.08),
                        blurRadius: 14,
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5B4EE8), Color(0xFF7B6FF0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5B4EE8).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.accessibility_new_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'AI Posture Coach',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppDarkColors.textPrimary : kHeadline,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5B4EE8).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF5B4EE8),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Live exercise form check, rep counting & injury alerts.',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppDarkColors.textSecondary : kBody,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B4EE8).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: Color(0xFF5B4EE8),
                        ),
                      ),
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
                  Text(
                    'Recent Meals',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppDarkColors.textPrimary : kHeadline,
                      letterSpacing: -0.2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.mealTracking),
                    child: Text(
                      'See History',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF818CF8) : kPurple,
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
                  color: isDark ? AppDarkColors.surface : kCardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppDarkColors.border : kBorder,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.restaurant_rounded,
                      size: 30,
                      color: isDark ? const Color(0xFF818CF8) : kPurple,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No meals recorded today yet.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppDarkColors.textPrimary : kHeadline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap See History to log a meal.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppDarkColors.textSecondary : kBody,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              for (var i = 0; i < _meals.length; i++) ...[
                if (i > 0) const SizedBox(height: 2),
                Builder(
                  builder: (context) {
                    final meal = _meals[i];
                    double p = 0.0, c = 0.0, f = 0.0;
                    for (final item in meal.items) {
                      p += item.protein;
                      c += item.carbs;
                      f += item.fat;
                    }
                    return _MealItem(
                      animation: _entryController,
                      index: i,
                      imagePlaceholderColor: _mealColor(meal.mealType),
                      mealType: meal.mealType,
                      time: _formatMealTime(meal),
                      name: _mealName(meal),
                      kcal: '${meal.totalCalories} kcal',
                      icon: _mealIcon(meal.mealType),
                      protein: p,
                      carbs: c,
                      fat: f,
                      itemCount: meal.items.length,
                      onTap: () => _onMealTap(meal),
                    );
                  },
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
  const _TopBar({
    required this.floating,
    this.avatarUrl,
    this.onAvatarTap,
    this.streak = 0,
    this.streakTodayActive = false,
  });

  final Animation<double> floating;
  final String? avatarUrl;
  final VoidCallback? onAvatarTap;
  final int streak;
  final bool streakTodayActive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AnimatedBuilder(
          animation: floating,
          builder: (context, child) {
            final offset = math.sin(floating.value * math.pi * 2) * 3;
            return Transform.translate(
              offset: Offset(0, offset),
              child: child,
            );
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.bolt_rounded, color: kWhite, size: 24),
          ),
        ),
        Row(
          children: [
            // Gamified Streak Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF2E2214), Color(0xFF382914)]
                      : const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF6B4515) : const Color(0xFFFDE68A),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.2 : 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 16,
                    color: Color(0xFFF97316),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$streak ${streak == 1 ? 'DAY' : 'DAYS'}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFEA580C),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Quick Theme Switcher
            GestureDetector(
              onTap: AppThemeController.instance.toggleTheme,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? AppDarkColors.surface : kWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppDarkColors.border : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
                  color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
                  size: 19,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Notifications Bell
            GestureDetector(
              onTap: () => context.push(AppRoutes.notifications),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? AppDarkColors.surface : kWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppDarkColors.border : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1),
                      size: 19,
                    ),
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppDarkColors.surface : kWhite,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Profile Avatar
            GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppDarkColors.surfaceAlt : const Color(0xFFEEF2FF),
                  border: Border.all(
                    color: isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? Image.network(
                        avatarUrl!,
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: 19,
                            color: isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 19,
                          color: isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            // Activity Calendar
            GestureDetector(
              onTap: () => context.push(AppRoutes.activityCalendar),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? AppDarkColors.surface : kWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppDarkColors.border : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1),
                  size: 19,
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
//  Dashboard Loading Placeholder
// ─────────────────────────────────────────────
/// Shown in place of the calorie/macro/water cards until real dashboard data
/// has loaded (from cache or DB). Prevents the 2000 -> actual flash on open.
class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppDarkColors.border : kBorder,
          width: 1,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: kPurple),
      ),
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
    final isOverBudget = dailyGoal > 0 && consumed > dailyGoal;
    final overAmount = consumed - dailyGoal;
    final remaining = (dailyGoal - consumed).clamp(0, dailyGoal);
    final progress =
        dailyGoal <= 0 ? 0.0 : (consumed / dailyGoal).clamp(0.0, 1.0);
    final percentLeft = dailyGoal <= 0
        ? 0
        : ((remaining / dailyGoal) * 100).clamp(0, 100).round();
    final percentOver = dailyGoal <= 0
        ? 0
        : ((overAmount / dailyGoal) * 100).round();

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
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOverBudget
                      ? const [
                          Color(0xFF4338CA),
                          Color(0xFF5B21B6),
                          Color(0xFF881337),
                        ]
                      : const [
                          Color(0xFF4338CA),
                          Color(0xFF6366F1),
                          Color(0xFF7C3AED),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isOverBudget
                            ? const Color(0xFFE11D48)
                            : const Color(0xFF6366F1))
                        .withValues(alpha: 0.38),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isOverBudget
                              ? const Color(0xFFEF4444).withValues(alpha: 0.28)
                              : Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isOverBudget
                                ? const Color(0xFFFCA5A5)
                                    .withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOverBudget
                                  ? Icons.local_fire_department_rounded
                                  : Icons.bolt_rounded,
                              size: 14,
                              color: isOverBudget
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFFFDE047),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOverBudget ? 'OVER BUDGET' : 'REMAINING',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Icon(
                          isOverBudget
                              ? Icons.priority_high_rounded
                              : Icons.trending_up_rounded,
                          size: 17,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: isOverBudget
                              ? '+$overAmount'
                              : remaining.toString(),
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: isOverBudget
                                ? const Color(0xFFFFE4E6)
                                : Colors.white,
                            letterSpacing: -2,
                            height: 1.05,
                          ),
                        ),
                        TextSpan(
                          text: isOverBudget ? ' kcal over' : ' kcal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isOverBudget
                                ? const Color(0xFFFECDD3)
                                : Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _CalorieStat(
                          label: 'Consumed',
                          value: '$consumed kcal',
                          indicatorColor: const Color(0xFF4ADE80),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CalorieStat(
                          label: 'Burned',
                          value: '$burned kcal',
                          indicatorColor: const Color(0xFFFB923C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daily Goal: $dailyGoal kcal',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isOverBudget
                              ? const Color(0xFFEF4444).withValues(alpha: 0.28)
                              : Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: isOverBudget
                              ? Border.all(
                                  color: const Color(0xFFFCA5A5)
                                      .withValues(alpha: 0.45),
                                )
                              : null,
                        ),
                        child: Text(
                          isOverBudget
                              ? '+$percentOver% over'
                              : '$percentLeft% left',
                          style: TextStyle(
                            fontSize: 11,
                            color: isOverBudget
                                ? const Color(0xFFFFE4E6)
                                : Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Stack(
                      children: [
                        Container(
                          height: 7,
                          width: double.infinity,
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            height: 7,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isOverBudget
                                    ? const [
                                        Color(0xFFF97316),
                                        Color(0xFFEF4444),
                                      ]
                                    : const [
                                        Color(0xFF38BDF8),
                                        Color(0xFFFDE047),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(100),
                            ),
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
      },
    );
  }
}

class _CalorieStat extends StatelessWidget {
  const _CalorieStat({
    required this.label,
    required this.value,
    this.indicatorColor = Colors.white,
  });

  final String label;
  final String value;
  final Color indicatorColor;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: _MacroCard(
            animation: animation,
            index: 0,
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFF6366F1),
            label: 'PROTEIN',
            current: '${proteinCurrent.round()}g',
            total: '/ ${proteinTotal.round()}g',
            progress: proteinTotal <= 0
                ? 0.0
                : (proteinCurrent / proteinTotal).clamp(0.0, 1.0),
            bgColor: isDark ? AppDarkColors.surface : const Color(0xFFF8F7FF),
            borderColor: isDark ? AppDarkColors.border : const Color(0xFFE0E7FF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MacroCard(
            animation: animation,
            index: 1,
            icon: Icons.restaurant_rounded,
            iconColor: const Color(0xFFF59E0B),
            label: 'CARBS',
            current: '${carbsCurrent.round()}g',
            total: '/ ${carbsTotal.round()}g',
            progress: carbsTotal <= 0
                ? 0.0
                : (carbsCurrent / carbsTotal).clamp(0.0, 1.0),
            bgColor: isDark ? AppDarkColors.surface : const Color(0xFFFFFDF5),
            borderColor: isDark ? const Color(0xFF4A381C) : const Color(0xFFFEF3C7),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MacroCard(
            animation: animation,
            index: 2,
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFF43F5E),
            label: 'FATS',
            current: '${fatCurrent.round()}g',
            total: '/ ${fatTotal.round()}g',
            progress: fatTotal <= 0
                ? 0.0
                : (fatCurrent / fatTotal).clamp(0.0, 1.0),
            bgColor: isDark ? AppDarkColors.surface : const Color(0xFFFFF5F6),
            borderColor: isDark ? const Color(0xFF4E2429) : const Color(0xFFFFE4E6),
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
    this.progress = 0.0,
    this.bgColor = kCardBg,
    this.borderColor = kBorder,
  });

  final Animation<double> animation;
  final int index;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String current;
  final String total;
  final double progress;
  final Color bgColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Icon(icon, size: 13, color: iconColor),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: iconColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: current,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppDarkColors.textPrimary : kHeadline,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: ' $total',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppDarkColors.textSecondary : kBody,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Container(
                    height: 4.5,
                    width: double.infinity,
                    color: iconColor.withValues(alpha: 0.14),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: iconColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
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

// ─────────────────────────────────────────────
//  Meal Add Card
// ─────────────────────────────────────────────
class _MealCard extends StatelessWidget {
  const _MealCard({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
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
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return GestureDetector(
            onTap: () => context.push(AppRoutes.mealTracking),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppDarkColors.surface : kCardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppDarkColors.border : const Color(0xFFFFEDD5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF97316).withValues(alpha: isDark ? 0.03 : 0.06),
                    blurRadius: 14,
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFB923C), Color(0xFFEA580C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: kWhite,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Track a Meal',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppDarkColors.textPrimary : kHeadline,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Add your breakfast, lunch or dinner in seconds.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppDarkColors.textSecondary : kBody,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, color: kWhite, size: 16),
                    SizedBox(width: 3),
                    Text(
                      'ADD',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: kWhite,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  ),
);
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
    final progress =
        targetMl <= 0 ? 0.0 : (totalMl / targetMl).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();

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
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return GestureDetector(
            onTap: () async {
              await context.push(AppRoutes.waterTracker);
              onReload();
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppDarkColors.surface : const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppDarkColors.border : const Color(0xFFBAE6FD),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.03 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.water_drop_rounded,
                            size: 20,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.surfaceAlt : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '$percent% DONE',
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0284C7),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'WATER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppDarkColors.textSecondary : const Color(0xFF64748B),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: (totalMl / 1000.0).toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppDarkColors.textPrimary : kHeadline,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: ' / ${(targetMl / 1000.0).toStringAsFixed(1)}L',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppDarkColors.textSecondary : kBody,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Container(
                          height: 4,
                          width: double.infinity,
                          color: const Color(0xFFBAE6FD).withValues(alpha: 0.5),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      await context.push(AppRoutes.waterTracker);
                      onReload();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppDarkColors.surfaceAlt : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? AppDarkColors.border : const Color(0xFFBAE6FD),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '+250ml',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  AI Coach Card (Interactive & Living Micro-Animations)
// ─────────────────────────────────────────────
class _AICoachCard extends StatefulWidget {
  const _AICoachCard({
    required this.animation,
    this.onTap,
  });

  final Animation<double> animation;
  final VoidCallback? onTap;

  @override
  State<_AICoachCard> createState() => _AICoachCardState();
}

class _AICoachCardState extends State<_AICoachCard>
    with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    // Continuous subtle breathing loop
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Fast, responsive touch scale spring
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _idleController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      context.push(AppRoutes.aiCoach);
    }
  }

  String _getCoachPrompt() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      return '"Ready to plan your breakfast?"';
    }
    if (hour < 15) {
      return '"Need healthy lunch ideas?"';
    }
    if (hour < 18) {
      return '"Time for an afternoon snack?"';
    }
    if (hour < 22) {
      return '"Ready to plan your dinner?"';
    }
    return '"Review today\'s nutrition?"';
  }

  void _showInfoSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: isDark ? AppDarkColors.surface : Colors.white.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(
              color: isDark ? AppDarkColors.border : Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B4BDB).withValues(alpha: 0.14),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surfaceHighlight : const Color(0xFFE3DEFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7E70F6), Color(0xFF5B4BDB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5B4BDB).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Nutrition Coach',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppDarkColors.textPrimary : const Color(0xFF1E1B3A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Powered by Google Gemini Flash',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppDarkColors.textSecondary : const Color(0xFF7A7699),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'FitFuel AI Coach continuously synchronizes with your logged meals, calories, macro goals, and hydration to offer personalized coaching, deficit adjustments, and instant recipe suggestions 24/7.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  color: isDark ? AppDarkColors.textSecondary : const Color(0xFF4A4670),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleTap();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B4BDB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text(
                    'Chat with AI Coach',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: Listenable.merge([widget.animation, _idleController, _pressController]),
      builder: (context, _) {
        final t = _clamp01(CurvedAnimation(
          parent: widget.animation,
          curve: const Interval(0.54, 0.74, curve: Curves.easeOutCubic),
        ).value);
        final idle = _idleController.value;
        final pressScale = 1.0 - (0.04 * _pressController.value);

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Transform.translate(
          offset: Offset(0, 22 * (1 - t)),
          child: Opacity(
            opacity: t,
            child: Transform.scale(
              scale: pressScale,
              child: GestureDetector(
                onTapDown: (_) => _pressController.forward(),
                onTapUp: (_) {
                  _pressController.reverse();
                  _handleTap();
                },
                onTapCancel: () => _pressController.reverse(),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              AppDarkColors.surface,
                              Color.lerp(
                                AppDarkColors.surface,
                                AppDarkColors.surfaceAlt,
                                idle * 0.75,
                              )!,
                            ]
                          : [
                              Colors.white,
                              Color.lerp(
                                Colors.white,
                                const Color(0xFFF6F3FF),
                                idle * 0.75,
                              )!,
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Color.lerp(
                              AppDarkColors.border,
                              const Color(0xFF6366F1),
                              idle,
                            )!
                          : Color.lerp(
                              const Color(0xFFE8E5FB),
                              const Color(0xFFC7BFF8),
                              idle,
                            )!,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B4BDB).withValues(
                          alpha: isDark ? 0.08 : (0.05 + (0.07 * idle)),
                        ),
                        blurRadius: 16 + (8 * idle),
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Animated Badge + Info Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Breathing Glow Bolt Badge
                          Transform.scale(
                            scale: 1.0 + (0.07 * idle),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7E70F6),
                                    Color(0xFF5B4BDB),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF5B4BDB).withValues(
                                      alpha: 0.28 + (0.24 * idle),
                                    ),
                                    blurRadius: 8 + (5 * idle),
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.bolt_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // Info Button
                          GestureDetector(
                            onTap: () => _showInfoSheet(context),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isDark ? AppDarkColors.surfaceAlt : const Color(0xFFF6F4FF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? AppDarkColors.border : const Color(0xFFE5E1FA),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: isDark ? AppDarkColors.textSecondary : const Color(0xFF7A7699),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Label with live pulsing status dot
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                const Color(0xFF16A34A),
                                const Color(0xFF5B4BDB),
                                idle,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'AI COACH',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppDarkColors.textSecondary : const Color(0xFF7A7699),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Dynamic Context-Aware Prompt
                      Text(
                        _getCoachPrompt(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppDarkColors.textPrimary : const Color(0xFF1E1B3A),
                          height: 1.35,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Animated "ASK NOW →" button with bounce & shimmer
                      Row(
                        children: [
                          Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark ? AppDarkColors.surfaceAlt : const Color(0xFFEDE9FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark
                                        ? AppDarkColors.border
                                        : Color.lerp(
                                            const Color(0xFFDFD9FF),
                                            const Color(0xFFC7BFF8),
                                            idle,
                                          )!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'ASK NOW',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? const Color(0xFF818CF8) : const Color(0xFF5B4BDB),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Transform.translate(
                                      offset: Offset(3.0 * idle, 0),
                                      child: const Text(
                                        '→',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF5B4BDB),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Opacity(
                                    opacity: 0.25 + (0.35 * idle),
                                    child: const _ShineSweep(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
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
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    this.itemCount = 1,
    this.onTap,
  });

  final Animation<double> animation;
  final int index;
  final Color imagePlaceholderColor;
  final String mealType;
  final String time;
  final String name;
  final String kcal;
  final IconData icon;
  final double protein;
  final double carbs;
  final double fat;
  final int itemCount;
  final VoidCallback? onTap;

  Color get _mealTypeColor {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return const Color(0xFF10B981);
      case 'lunch':
        return const Color(0xFF6366F1);
      case 'snack':
        return const Color(0xFFF59E0B);
      case 'dinner':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
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
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isDark ? AppDarkColors.surface : kCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppDarkColors.border : const Color(0xFFF1F5F9),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: imagePlaceholderColor.withValues(alpha: isDark ? 0.28 : 0.22),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            size: 24,
                            color: isDark ? AppDarkColors.textPrimary : kHeadline,
                          ),
                        ),
                      ),
                      const SizedBox(width: 13),
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
                                    color: _mealTypeColor.withValues(alpha: 0.12),
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
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: isDark ? AppDarkColors.textSecondary : kBody,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppDarkColors.textSecondary : kBody,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (itemCount > 1) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppDarkColors.surfaceAlt : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$itemCount items',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppDarkColors.textSecondary : kBody,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppDarkColors.textPrimary : kHeadline,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  kcal,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (protein > 0 || carbs > 0 || fat > 0) ...[
                                  const SizedBox(width: 8),
                                  _macroPill('P', '${protein.round()}g', const Color(0xFF6366F1), isDark),
                                  const SizedBox(width: 4),
                                  _macroPill('C', '${carbs.round()}g', const Color(0xFFF59E0B), isDark),
                                  const SizedBox(width: 4),
                                  _macroPill('F', '${fat.round()}g', const Color(0xFF06B6D4), isDark),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.surfaceAlt : const Color(0xFFF8F9FE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppDarkColors.border : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: kPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

  Widget _macroPill(String label, String value, Color color, bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
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
  Widget build(BuildContext context) => ClipRect(
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

// ─────────────────────────────────────────────
//  Camera FAB
// ─────────────────────────────────────────────
class _CameraFAB extends StatelessWidget {
  const _CameraFAB({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.45),
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

// ─────────────────────────────────────────────
//  Bottom Navigation Bar
// ─────────────────────────────────────────────
class _BottomNav extends StatelessWidget {

  const _BottomNav({required this.currentIndex, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? const Color(0xFF818CF8) : kPurple;
    final inactiveColor = isDark ? AppDarkColors.textSecondary : kBody;

    final items = [
      const _NavItem(icon: Icons.home_rounded, label: 'Home'),
      const _NavItem(icon: Icons.bar_chart_rounded, label: 'Stats'),
      const _NavItem(icon: Icons.qr_code_scanner_rounded, label: 'Scan'),
      const _NavItem(icon: Icons.smart_toy_outlined, label: 'Coach'),
      const _NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.bottomNav : kWhite,
        border: Border(
          top: BorderSide(
            color: isDark ? AppDarkColors.borderSubtle : kBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
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
              final active = i == currentIndex;
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
                        color: active ? activeColor : inactiveColor,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w400,
                          color: active ? activeColor : inactiveColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: active ? 18 : 0,
                        height: 3,
                        decoration: BoxDecoration(
                          color: activeColor,
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
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
