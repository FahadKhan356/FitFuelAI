import 'dart:math' as math;

import 'package:fitfuel_ai/core/config/routes.dart';
import 'package:fitfuel_ai/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/datasources/supabase_remote_datasource.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/domain/repositories/meal_repository.dart';
import '../../../../core/domain/repositories/subscription_repository.dart';
import '../../../../core/domain/repositories/user_repository.dart';
import '../../../../core/domain/repositories/water_repository.dart';
import '../../../../core/domain/repositories/weight_repository.dart';
import '../../../../core/services/avatar_uploader.dart';
import '../../../../core/services/home_data_refresh_notifier.dart';
import '../../../../core/services/water_goal_resolver.dart';
import '../../../../core/services/streak_service.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/weight_progress_calculator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/models/user_profile_model.dart';

const Color _kPrimary = Color(0xFF6366F1);
const Color _bg = Color(0xFFF8F9FE);
const Color _surface = Colors.white;
const Color _textPrimary = Color(0xFF0F172A);
const Color _textSecondary = Color(0xFF64748B);
const Color _border = Color(0xFFE2E8F0);


double _clamp01(double v) => v.clamp(0.0, 1.0);

/// Calories + protein consumed, computed from today's meal log. Used by the
/// "Today's Goals" card, which resolves both in a single pass over the meals.
class _MealTotals {
  const _MealTotals(this.calories, this.protein);

  final int calories;
  final double protein;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _rotateCtrl;
  late final AnimationController _flameCtrl;
  late final AnimationController _shimmerCtrl;

  // Today's goal live data (defaults shown until async fetch resolves).
  int _waterGoalMl = WaterGoalResolver.defaultWaterMl;
  int _waterConsumedMl = 0;
  int _calorieGoal = 2000;
  int _calorieConsumed = 0;
  double _proteinGoal = 120;
  double _proteinConsumed = 0;
  String? _avatarUrl;
  bool _changingPhoto = false;
  int _streak = 0;
  bool _streakTodayActive = false;
  String? _profileName;

  // Live account data — these tiles/lines used to show hardcoded mock values
  // ("Active", "Weight Loss", "Level 14").
  final GlobalKey _settingsKey = GlobalKey();
  bool _isPremium = false;
  String? _goalTypeTitle;
  int? _gamificationLevel;
  String? _gamificationTier;

  // Weight-lost metric card: real delta from `weight_entries`.
  String _weightLabel = 'WEIGHT\nLOST';
  String _weightValue = '0.0';
  String _weightSubtitle = 'No weight logs yet';

  @override
  void initState() {
    super.initState();
    _listenToAuthState();
    // Tiles (weight lost, today's goals) are shared with Home / Weight Tracker.
    // Re-fetch them whenever another screen writes new data so this tab never
    // shows a stale value after the user navigates back to it.
    HomeDataRefreshNotifier.instance.addListener(_onExternalRefresh);
    _mainCtrl = AnimationController(
      vsync: this,
      // Short entry animation: the previous 4.8s duration kept the staggered
      // reveal running for seconds, so cards were still fading/rolling in
      // long after the tab was opened (felt like laggy data).
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat(reverse: true);
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _flameCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();
    _loadTodayGoals();
    _loadProfileAvatar();
    _loadMembership();
    _loadWeightMetric();
    _loadGamification();
  }

  /// Fetches today's targets and totals so the "Today's Goals" card shows real
  /// data (consistently with the home screen / water tracker).
  ///
  /// The four lookups are independent, but used to run one after another — so
  /// the card waited on four sequential network round-trips before it could
  /// show today's numbers. They now run together, cutting that to roughly one.
  Future<void> _loadTodayGoals() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final wRepo = sl<WaterRepository>();
    final mRepo = sl<MealRepository>();
    final today = DateTime.now();

    // Targets from the goals table + the goal label (updates its own state).
    final goalsFuture = _resolveGoalTargets(user.id);

    final results = await Future.wait<Object>([
      // Water goal from the shared resolver (DB → weight fallback).
      WaterGoalResolver.resolve(user.id),
      _sumWaterToday(wRepo, user.id, today),
      _sumMealsToday(mRepo, user.id, today),
    ]);
    await goalsFuture;

    if (!mounted) return;
    final mealTotals = results[2] as _MealTotals;
    setState(() {
      _waterGoalMl = results[0] as int;
      _waterConsumedMl = results[1] as int;
      _calorieConsumed = mealTotals.calories;
      _proteinConsumed = mealTotals.protein;
    });
  }

  /// Millilitres of water logged today; 0 when the lookup fails.
  Future<int> _sumWaterToday(
    WaterRepository repo,
    String userId,
    DateTime day,
  ) async {
    try {
      final entries = await repo.getWaterEntries(userId, day);
      return entries.fold<int>(0, (s, e) => s + e.amountMl);
    } catch (_) {
      return 0;
    }
  }

  /// Calories + protein from today's meals; zeroes when the lookup fails.
  Future<_MealTotals> _sumMealsToday(
    MealRepository repo,
    String userId,
    DateTime day,
  ) async {
    try {
      final meals = await repo.getMealsByDate(userId, day);
      var calories = 0;
      var protein = 0.0;
      for (final meal in meals) {
        calories += meal.totalCalories;
        for (final item in meal.items) {
          protein += item.protein;
        }
      }
      return _MealTotals(calories, protein);
    } catch (_) {
      return const _MealTotals(0, 0);
    }
  }

  /// Populates calorie/protein goals and the health-goal label from the goals
  /// table (the "Health Goals" tile used to hardcode "Weight Loss").
  Future<void> _resolveGoalTargets(String userId) async {
    try {
      final goals = await sl<UserRepository>().getUserGoals(userId);
      final cal = goals?.targetCalories ?? 0;
      final prot = goals?.targetProtein ?? 0;
      final goalType = goals?.goalType;
      if (!mounted) return;
      setState(() {
        if (cal > 0) _calorieGoal = cal;
        if (prot > 0) _proteinGoal = prot;
        if (goalType != null && goalType.isNotEmpty) {
          _goalTypeTitle = _titleCase(goalType);
        }
      });
    } catch (_) {}
  }

  /// `weight_loss` → `Weight Loss` (same casing as the Health Goals screen).
  String _titleCase(String value) => value
      .split('_')
      .map((word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');

  /// Loads the user's profile photo URL so the avatar shows the real image
  /// from `user_profiles.avatar_url` (falls back to the default illustration).
  Future<void> _loadProfileAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final profile =
          await sl<UserRepository>().getUserProfile(user.id);
      if (!mounted) return;
      setState(() {
        _avatarUrl = profile?.avatarUrl;
        _profileName = profile?.name;
        // Profile table owns `goal_type` too — use it when goals has none.
        final profileGoalType = profile?.goalType;
        if (_goalTypeTitle == null &&
            profileGoalType != null &&
            profileGoalType.isNotEmpty) {
          _goalTypeTitle = _titleCase(profileGoalType);
        }
      });
    } catch (_) {}
    // Streak is computed from meal history (independent of profile fetch).
    try {
      final info = await StreakService.compute(user.id);
      if (!mounted) return;
      setState(() {
        _streak = info.current;
        _streakTodayActive = info.todayActive;
      });
    } catch (_) {}
  }

  /// Membership state for the pill + "Premium Subscription" tile (the tile
  /// always said "Active" and had no tap target).
  Future<void> _loadMembership() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final active = await sl<SubscriptionRepository>().isSubscribed(user.id);
      if (!mounted) return;
      setState(() => _isPremium = active);
    } catch (_) {}
  }

  /// Real level / tier from the `gamification` table behind the name.
  Future<void> _loadGamification() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await sl<SupabaseRemoteDataSource>().getGamification(user.id);
      if (!mounted || data == null) return;
      setState(() {
        _gamificationLevel = (data['level'] as num?)?.toInt();
        _gamificationTier = data['tier'] as String?;
      });
    } catch (_) {}
  }

  /// Replaces the mocked "4.2 kg lost since Jan 2024" card with the real
  /// difference between the user's first and latest weight log.
  Future<void> _loadWeightMetric() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final history = await sl<WeightRepository>().getWeightHistory(user.id);
      if (!mounted) return;
      final progress = WeightProgressCalculator.fromEntries(history);

      setState(() {
        if (progress == null) {
          _weightLabel = 'WEIGHT\nLOST';
          _weightValue = '0.0';
          _weightSubtitle = 'No weight logs yet';
        } else if (!progress.hasBaseline) {
          _weightLabel = 'WEIGHT\nLOST';
          _weightValue = '0.0';
          _weightSubtitle = 'First log ${_monthYear(progress.since)}';
        } else {
          _weightLabel =
              progress.gained ? 'WEIGHT\nGAINED' : 'WEIGHT\nLOST';
          _weightValue = progress.changeKg.abs().toStringAsFixed(1);
          _weightSubtitle = progress.hasChange
              ? 'Since ${_monthYear(progress.since)}'
              : 'Holding steady since ${_monthYear(progress.since)}';
        }
      });
    } catch (_) {}
  }

  static const List<String> _months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _monthYear(DateTime? date) =>
      date == null ? 'your first log' : '${_months[date.month - 1]} ${date.year}';

  /// Display name: saved profile name → auth metadata → email prefix → a
  /// friendly default (the screen used to show the mock name "Alex Johnson").
  String get _displayName {
    final saved = _profileName?.trim();
    if (saved != null && saved.isNotEmpty) return saved;

    final user = Supabase.instance.client.auth.currentUser;
    final meta = user?.userMetadata;
    final fromMeta = meta?['full_name'] ?? meta?['name'];
    if (fromMeta is String && fromMeta.trim().isNotEmpty) {
      return fromMeta.trim();
    }

    final email = user?.email ?? '';
    if (email.contains('@')) return email.split('@').first;
    return 'Athlete';
  }

  /// Level line under the name, from real gamification data when present.
  String get _levelLine {
    final level = _gamificationLevel;
    if (level == null) return 'Fitness Enthusiast';
    final tier = _gamificationTier;
    return tier == null || tier.isEmpty
        ? 'Level $level Fitness Enthusiast'
        : 'Level $level • $tier Tier';
  }

  /// The gear icon scrolls to ACCOUNT SETTINGS (settings live on this page —
  /// the button used to be `onTap: () {}`).
  void _scrollToSettings() {
    final ctx = _settingsKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
      alignment: 0,
    );
  }

  /// Red destructive button gets a confirm step so a stray tap can't sign the
  /// user out instantly.
  Future<void> _confirmLogout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141824) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? const Color(0xFF282D4A) : const Color(0xFFE2E8F0),
          ),
        ),
        title: Text(
          'Logout Account?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF8FAFC) : _textPrimary,
          ),
        ),
        content: Text(
          'You will need to sign in again to access your tracked meals, '
          'water and weight history.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : _textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF94A3B8) : _textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // AuthBloc -> Unauthenticated -> _listenToAuthState redirects to splash.
    context.read<AuthBloc>().add(SignOutRequested());
  }


  void _showThemeSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141824) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final currentMode = AppThemeController.instance.themeMode;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Choose App Appearance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E1B3A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select how FitFuel AI looks on your device.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 18),
                _themeOptionTile(
                  context: sheetContext,
                  title: 'Light Mode',
                  subtitle: 'Crisp daylight clean interface',
                  icon: Icons.light_mode_rounded,
                  selected: currentMode == ThemeMode.light,
                  onTap: () {
                    AppThemeController.instance.setThemeMode(ThemeMode.light);
                    Navigator.pop(sheetContext);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 10),
                _themeOptionTile(
                  context: sheetContext,
                  title: 'Dark Mode',
                  subtitle: 'Deep OLED sleek night interface',
                  icon: Icons.dark_mode_rounded,
                  selected: currentMode == ThemeMode.dark,
                  onTap: () {
                    AppThemeController.instance.setThemeMode(ThemeMode.dark);
                    Navigator.pop(sheetContext);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 10),
                _themeOptionTile(
                  context: sheetContext,
                  title: 'System Default',
                  subtitle: 'Automatically matches your device settings',
                  icon: Icons.brightness_auto_rounded,
                  selected: currentMode == ThemeMode.system,
                  onTap: () {
                    AppThemeController.instance.setThemeMode(ThemeMode.system);
                    Navigator.pop(sheetContext);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _themeOptionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? (isDark
                  ? const Color(0xFF6366F1).withValues(alpha: 0.18)
                  : const Color(0xFFEEF2FF))
              : (isDark ? const Color(0xFF1E2436) : const Color(0xFFF8F9FE)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF6366F1)
                : (isDark ? const Color(0xFF282D42) : const Color(0xFFE2E8F0)),
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF6366F1)
                    : (isDark ? const Color(0xFF2B334C) : const Color(0xFFE0E7FF)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: selected
                    ? Colors.white
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF4F46E5)),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF6366F1),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  /// Tap avatar -> pick a photo, upload to storage, save the URL to the
  /// profile and refresh the avatar everywhere immediately.
  Future<void> _changeAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _changingPhoto = true);
      final bytes = await picked.readAsBytes();

      final url = await AvatarUploader.upload(
        userId: user.id,
        bytes: bytes,
      );

      await sl<UserRepository>().updateUserProfile(
        user.id,
        {'avatar_url': url},
      );

      if (!mounted) return;
      setState(() {
        _avatarUrl = url;
        _changingPhoto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated ✓'),
          backgroundColor: Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Profile avatar change error: $e');
      debugPrint('Profile avatar change error type: ${e.runtimeType}');
      if (e is StorageException) {
        debugPrint('Profile avatar StorageException status=${e.statusCode} '
            'msg=${e.message}');
      }
      if (!mounted) return;
      setState(() => _changingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update photo. Please try again.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _listenToAuthState() {
    final authBloc = context.read<AuthBloc>();
    authBloc.stream.listen((state) {
      if (state is Unauthenticated && mounted) {
        context.go(AppRoutes.splash);
      }
    });
  }

  /// Fired by [HomeDataRefreshNotifier] whenever another screen mutates shared
  /// tracking data (meal logged, water logged, weight logged). Only the tiles
  /// that actually depend on that data are refreshed, and the last known values
  /// stay on screen while the fetch runs — no flicker, no stale numbers.
  void _onExternalRefresh() {
    if (!mounted) return;
    _loadWeightMetric();
    _loadTodayGoals();
  }

  @override
  void dispose() {
    HomeDataRefreshNotifier.instance.removeListener(_onExternalRefresh);
    _mainCtrl.dispose();
    _floatCtrl.dispose();
    _rotateCtrl.dispose();
    _flameCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : _textPrimary;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : _textSecondary;
    final bgColor = isDark ? const Color(0xFF0B0E14) : _bg;
    final surfaceAlt = isDark ? const Color(0xFF1B2237) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? const Color(0xFF282D4A) : _border;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile',
                          style: textTheme.headlineSmall?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Account & Preferences',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _TopIconButton(
                      icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
                      onTap: () {
                        AppThemeController.instance.toggleTheme();
                        setState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    _TopIconButton(
                      icon: Icons.workspace_premium_rounded,
                      color: _isPremium ? const Color(0xFFF59E0B) : null,
                      onTap: () => context.push(AppRoutes.subscription),
                    ),
                    const SizedBox(width: 8),
                    _TopIconButton(
                      icon: Icons.settings_outlined,
                      onTap: _scrollToSettings,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Hero Profile Section ──
              Center(
                child: Column(
                  children: [
                    _AvatarWithBadge(
                      floatCtrl: _floatCtrl,
                      rotateCtrl: _rotateCtrl,
                      mainCtrl: _mainCtrl,
                      avatarUrl: _avatarUrl,
                      changing: _changingPhoto,
                      onTap: _changeAvatar,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _displayName,
                      style: TextStyle(
                        fontSize: 26,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: surfaceAlt,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.military_tech_rounded,
                            size: 16,
                            color: _kPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _levelLine,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PremiumPill(
                      mainCtrl: _mainCtrl,
                      shimmerCtrl: _shimmerCtrl,
                      isPremium: _isPremium,
                      onTap: () => context.push(AppRoutes.subscription),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              // ── Metric Cards (Streak & Weight Progress) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        mainCtrl: _mainCtrl,
                        flameCtrl: _flameCtrl,
                        icon: Icons.local_fire_department_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        iconBackground: isDark
                            ? const Color(0xFF78350F).withValues(alpha: 0.35)
                            : const Color(0xFFFEF3C7),
                        iconBorder: isDark
                            ? const Color(0xFFB45309).withValues(alpha: 0.3)
                            : const Color(0xFFFDE68A),
                        label: 'STREAK',
                        targetValue: '$_streak',
                        suffix: ' Days',
                        subtitle: _streakTodayActive
                            ? 'Keep it up, today!'
                            : 'Log a meal today to continue',
                        isActive: _streakTodayActive,
                        index: 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        mainCtrl: _mainCtrl,
                        flameCtrl: _flameCtrl,
                        icon: _weightLabel.contains('GAINED')
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        iconColor: const Color(0xFF10B981),
                        iconBackground: isDark
                            ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                            : const Color(0xFFD1FAE5),
                        iconBorder: isDark
                            ? const Color(0xFF047857).withValues(alpha: 0.3)
                            : const Color(0xFFA7F3D0),
                        label: _weightLabel,
                        targetValue: _weightValue,
                        suffix: ' kg',
                        subtitle: _weightSubtitle,
                        isActive: false,
                        index: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ── Achievements Showcase ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        size: 17,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Achievements',
                      style: textTheme.headlineSmall?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => context.push(AppRoutes.achievements),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              'View All',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: _kPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _AchievementItem(
                        mainCtrl: _mainCtrl,
                        index: 0,
                        icon: Icons.bolt_rounded,
                        label: 'Early Riser',
                        subtitle: 'Streak',
                        onTap: () => context.push(AppRoutes.achievements),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AchievementItem(
                        mainCtrl: _mainCtrl,
                        index: 1,
                        icon: Icons.water_drop_rounded,
                        label: 'H2O Master',
                        subtitle: 'Hydration',
                        onTap: () => context.push(AppRoutes.achievements),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AchievementItem(
                        mainCtrl: _mainCtrl,
                        index: 2,
                        icon: Icons.center_focus_strong_rounded,
                        label: 'Macro King',
                        subtitle: 'Nutrition',
                        onTap: () => context.push(AppRoutes.achievements),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ── Today's Goals Card ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _GoalsCard(
                  textTheme: textTheme,
                  mainCtrl: _mainCtrl,
                  waterGoal: _waterGoalMl,
                  waterConsumed: _waterConsumedMl,
                  calorieGoal: _calorieGoal,
                  calorieConsumed: _calorieConsumed,
                  proteinGoal: _proteinGoal,
                  proteinConsumed: _proteinConsumed,
                ),
              ),
              const SizedBox(height: 24),

              // ── Account Settings Header ──
              Padding(
                key: _settingsKey,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ACCOUNT SETTINGS',
                      style: textTheme.labelLarge?.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Settings Menu ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _SettingTile(
                      mainCtrl: _mainCtrl,
                      index: 0,
                      icon: Icons.person_outline_rounded,
                      iconColor: const Color(0xFF6366F1),
                      title: 'Personal Information',
                      trailingText: 'View & edit',
                      onTap: () async {
                        final updated =
                            await context.push<dynamic>(AppRoutes.personalInfo);
                        if (!mounted) {
                          return;
                        }
                        if (updated is UserProfileModel) {
                          setState(() {
                            _profileName = updated.name;
                            _avatarUrl = updated.avatarUrl ?? _avatarUrl;
                            if (updated.targetCalories > 0) {
                              _calorieGoal = updated.targetCalories;
                            }
                            if (updated.targetProtein > 0) {
                              _proteinGoal = updated.targetProtein;
                            }
                            if (updated.dailyWaterMl > 0) {
                              _waterGoalMl = updated.dailyWaterMl;
                            }
                          });
                        }
                        await _loadTodayGoals();
                      },
                    ),
                    const SizedBox(height: 10),
                    _SettingTile(
                      mainCtrl: _mainCtrl,
                      index: 1,
                      icon: Icons.palette_outlined,
                      iconColor: const Color(0xFF8B5CF6),
                      title: 'App Appearance',
                      trailingText: AppThemeController.instance.themeModeLabel,
                      onTap: () => _showThemeSheet(context),
                    ),
                    const SizedBox(height: 10),
                    _SettingTile(
                      mainCtrl: _mainCtrl,
                      index: 2,
                      icon: Icons.workspace_premium_outlined,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Premium Subscription',
                      trailingText: _isPremium ? 'Active' : 'Upgrade',
                      isHighlight: _isPremium,
                      onTap: () => context.push(AppRoutes.subscription),
                    ),
                    const SizedBox(height: 10),
                    _SettingTile(
                      mainCtrl: _mainCtrl,
                      index: 3,
                      icon: Icons.notifications_none_rounded,
                      iconColor: const Color(0xFFF43F5E),
                      title: 'Notifications',
                      trailingText: 'Daily Reminders',
                      onTap: () => context.push(AppRoutes.notifications),
                    ),
                    const SizedBox(height: 10),
                    _SettingTile(
                      mainCtrl: _mainCtrl,
                      index: 4,
                      icon: Icons.track_changes_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'Health Goals',
                      trailingText: _goalTypeTitle ?? 'Not set',
                      onTap: () => context.push(AppRoutes.healthGoals),
                    ),
                    const SizedBox(height: 10),
                    _SettingTile(
                      mainCtrl: _mainCtrl,
                      index: 5,
                      icon: Icons.monitor_weight_outlined,
                      iconColor: const Color(0xFF0EA5E9),
                      title: 'BMI Calculator',
                      trailingText: 'Quick check',
                      onTap: () => context.push(AppRoutes.bmi),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Logout Button ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SettingTile(
                  mainCtrl: _mainCtrl,
                  index: 6,
                  icon: Icons.logout_rounded,
                  iconColor: const Color(0xFFEF4444),
                  title: 'Logout Account',
                  isLogout: true,
                  onTap: _confirmLogout,
                ),
              ),
              const SizedBox(height: 18),

              // ── Footer ──
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'FitFuel AI v2.4.0 • Crafted for Health',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.bolt_rounded,
                      size: 14,
                      color: _kPrimary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Top Icon Button
// ─────────────────────────────────────────────
class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = color ?? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141824) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF282D4A) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  A. Avatar With Badge – Floating + Rotating Ring + Spring Badge
// ─────────────────────────────────────────────
class _AvatarWithBadge extends StatelessWidget {
  const _AvatarWithBadge({
    required this.floatCtrl,
    required this.rotateCtrl,
    required this.mainCtrl,
    this.avatarUrl,
    this.onTap,
    this.changing = false,
  });

  final Animation<double> floatCtrl;
  final Animation<double> rotateCtrl;
  final Animation<double> mainCtrl;
  final String? avatarUrl;
  final VoidCallback? onTap;
  final bool changing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: floatCtrl,
      builder: (context, child) {
        final floatY = math.sin(floatCtrl.value * math.pi * 2) * 3.0;
        return Transform.translate(
          offset: Offset(0, floatY),
          child: child,
        );
      },
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Rotating border ring
            AnimatedBuilder(
              animation: rotateCtrl,
              builder: (context, child) {
                final angle = rotateCtrl.value * 2 * math.pi;
                return Transform.rotate(
                  angle: angle,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF384364)
                            : const Color(0xFFD8D3F7),
                        width: 1.8,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: CustomPaint(
                      painter: _DottedBorderPainter(isDark: isDark),
                    ),
                  ),
                );
              },
            ),
            // Avatar image
            Center(
              child: GestureDetector(
                onTap: changing ? null : onTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _kPrimary.withValues(alpha: isDark ? 0.30 : 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: SizedBox(
                          width: 104,
                          height: 104,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (avatarUrl != null && avatarUrl!.isNotEmpty)
                                Image.network(
                                  avatarUrl!,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  errorBuilder: (context, error, stack) =>
                                      Image.asset(
                                    'assets/images/onBoarding_Hero_Image.png',
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                  ),
                                )
                              else
                                Image.asset(
                                  'assets/images/onBoarding_Hero_Image.png',
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                ),
                              Container(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.1)
                                    : const Color(0x1AFFFFFF),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Camera / edit badge at bottom-left
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kPrimary,
                          border: Border.all(
                            color: isDark ? const Color(0xFF141824) : Colors.white,
                            width: 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _kPrimary.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: changing
                            ? const Padding(
                                padding: EdgeInsets.all(7),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Level badge with spring entrance
            Positioned(
              right: 2,
              bottom: 4,
              child: AnimatedBuilder(
                animation: mainCtrl,
                builder: (context, child) {
                  final t = _clamp01(CurvedAnimation(
                    parent: mainCtrl,
                    curve: const Interval(0.04, 0.18, curve: Curves.elasticOut),
                  ).value);
                  final scale = (t * 1.12).clamp(0.0, 1.12);
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF141824) : Colors.white,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withValues(alpha: 0.40),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Dotted Border Painter for Avatar Ring
// ─────────────────────────────────────────────
class _DottedBorderPainter extends CustomPainter {
  const _DottedBorderPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? const Color(0xFF818CF8) : _kPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    final path = Path()..addOval(rect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        final segment = metric.extractPath(distance, end);
        canvas.drawPath(segment, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

// ─────────────────────────────────────────────
//  Premium Pill – Shimmer sweep
// ─────────────────────────────────────────────
class _PremiumPill extends StatelessWidget {
  const _PremiumPill({
    required this.mainCtrl,
    required this.shimmerCtrl,
    this.isPremium = false,
    this.onTap,
  });

  final Animation<double> mainCtrl;
  final Animation<double> shimmerCtrl;
  final bool isPremium;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: mainCtrl,
        builder: (context, child) {
          final t = _clamp01(CurvedAnimation(
            parent: mainCtrl,
            curve: const Interval(0.06, 0.22, curve: Curves.easeOutBack),
          ).value);
          return Transform.scale(
            scale: 0.9 + (t * 0.1),
            child: Opacity(
              opacity: t,
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: isPremium
                          ? const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            )
                          : null,
                      color: isPremium
                          ? null
                          : (isDark ? const Color(0xFF1B2237) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isPremium
                            ? const Color(0xFF818CF8)
                            : (isDark ? const Color(0xFF282D4A) : const Color(0xFFE2E8F0)),
                      ),
                      boxShadow: isPremium
                          ? [
                              BoxShadow(
                                color: _kPrimary.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPremium ? Icons.workspace_premium_rounded : Icons.stars_rounded,
                          size: 15,
                          color: isPremium
                              ? Colors.white
                              : const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPremium ? 'Pro Member' : 'Free Plan • Upgrade',
                          style: TextStyle(
                            color: isPremium
                                ? Colors.white
                                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (!isPremium) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: _kPrimary,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Shimmer sweep (premium only)
                  if (isPremium)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: AnimatedBuilder(
                            animation: shimmerCtrl,
                            builder: (context, child) {
                              final shimmerX = -0.8 + (shimmerCtrl.value * 1.8);
                              return Transform.translate(
                                offset: Offset(shimmerX * 140, 0),
                                child: Transform.rotate(
                                  angle: -0.2,
                                  child: Container(
                                    width: 70,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.white.withValues(alpha: 0.40),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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
//  B. Metric Card – Number Roll + Streak Flame
// ─────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.mainCtrl,
    required this.flameCtrl,
    required this.icon,
    required this.iconBackground,
    required this.iconBorder,
    required this.iconColor,
    required this.label,
    required this.targetValue,
    required this.suffix,
    required this.subtitle,
    required this.isActive,
    required this.index,
  });

  final Animation<double> mainCtrl;
  final Animation<double> flameCtrl;
  final IconData icon;
  final Color iconBackground;
  final Color iconBorder;
  final Color iconColor;
  final String label;
  final String targetValue;
  final String suffix;
  final String subtitle;
  final bool isActive;
  final int index;

  @override
  Widget build(BuildContext context) {
    final stagger = 0.02 + (index * 0.06);

    return AnimatedBuilder(
      animation: mainCtrl,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mainCtrl,
          curve: Interval(stagger, stagger + 0.18, curve: Curves.elasticOut),
        ).value);
        final scale = 0.94 + (t * 0.07);
        return Transform.scale(
          scale: scale,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - t)),
            child: Opacity(opacity: t, child: child),
          ),
        );
      },
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141824) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF282D4A) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                  blurRadius: 14,
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
                    // Icon badge
                    AnimatedBuilder(
                      animation: flameCtrl,
                      builder: (context, child) {
                        final glow = index == 0
                            ? 0.75 + (flameCtrl.value * 0.25)
                            : 1.0;
                        return Opacity(
                          opacity: glow,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: iconBackground,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(color: iconBorder),
                            ),
                            child: Icon(icon, color: iconColor, size: 20),
                          ),
                        );
                      },
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Target Value
                Text(
                  '$targetValue$suffix',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (isActive) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  C. Achievement Badge – Radial pop-in + glow
// ─────────────────────────────────────────────
class _AchievementItem extends StatelessWidget {
  const _AchievementItem({
    required this.mainCtrl,
    required this.index,
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
  });

  final Animation<double> mainCtrl;
  final int index;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final stagger = 0.20 + (index * 0.09);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: mainCtrl,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mainCtrl,
          curve: Interval(stagger, stagger + 0.20, curve: Curves.elasticOut),
        ).value);
        final scale = t.clamp(0.0, 1.2);
        return Transform.scale(
          scale: scale > 1.0 ? scale - (scale - 1.0) * 0.8 : scale,
          child: Opacity(opacity: t, child: child),
        );
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2237) : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF282D4A) : const Color(0xFFE0E7FF),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: isDark ? 0.20 : 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: _kPrimary,
                  size: 26,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
//  D. Today's Goals Card – Animated Progress + Percentage Fade
// ─────────────────────────────────────────────
class _GoalsCard extends StatelessWidget {
  const _GoalsCard({
    required this.textTheme,
    required this.mainCtrl,
    this.waterGoal = 2000,
    this.waterConsumed = 0,
    this.calorieGoal = 2000,
    this.calorieConsumed = 0,
    this.proteinGoal = 120,
    this.proteinConsumed = 0,
  });

  final TextTheme textTheme;
  final Animation<double> mainCtrl;
  final int waterGoal;
  final int waterConsumed;
  final int calorieGoal;
  final int calorieConsumed;
  final double proteinGoal;
  final double proteinConsumed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overall = _goalPercent(calorieConsumed, calorieGoal);

    return AnimatedBuilder(
      animation: mainCtrl,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mainCtrl,
          curve: const Interval(0.34, 0.54, curve: Curves.easeOutCubic),
        ).value);
        return Transform.translate(
          offset: Offset(0, 24 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141824) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? const Color(0xFF282D4A) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Goals",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Daily nutrition & hydration targets',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2438) : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2E3856) : const Color(0xFFE0E7FF),
                    ),
                  ),
                  child: Text(
                    '$overall% Done',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _kPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _GoalRow(
              mainCtrl: mainCtrl,
              index: 0,
              icon: Icons.local_fire_department_rounded,
              iconColor: const Color(0xFF6366F1),
              gradientColors: const [Color(0xFF6366F1), Color(0xFF818CF8)],
              label: 'Calories',
              progress: _goalProgress(calorieConsumed, calorieGoal),
              value: '$calorieConsumed / $calorieGoal kcal',
              onTap: () => context.push(AppRoutes.mealTracking),
            ),
            const SizedBox(height: 14),
            _GoalRow(
              mainCtrl: mainCtrl,
              index: 1,
              icon: Icons.water_drop_rounded,
              iconColor: const Color(0xFF06B6D4),
              gradientColors: const [Color(0xFF06B6D4), Color(0xFF38BDF8)],
              label: 'Water Intake',
              progress: _goalProgress(waterConsumed, waterGoal),
              value: '$waterConsumed / $waterGoal ml',
              onTap: () => context.push(AppRoutes.waterTracker),
            ),
            const SizedBox(height: 14),
            _GoalRow(
              mainCtrl: mainCtrl,
              index: 2,
              icon: Icons.fitness_center_rounded,
              iconColor: const Color(0xFF10B981),
              gradientColors: const [Color(0xFF10B981), Color(0xFF34D399)],
              label: 'Protein',
              progress: _goalProgress(proteinConsumed.toInt(), proteinGoal.toInt()),
              value:
                  '${proteinConsumed.toStringAsFixed(0)} / ${proteinGoal.toStringAsFixed(0)} g',
              onTap: () => context.push(AppRoutes.mealTracking),
            ),
          ],
        ),
      ),
    );
  }

  static double _goalProgress(int consumed, int target) {
    if (target <= 0) {
      return 0;
    }
    return (consumed / target).clamp(0.0, 1.0);
  }

  static int _goalPercent(int consumed, int target) {
    if (target <= 0) {
      return 0;
    }
    return ((consumed / target) * 100).round().clamp(0, 999);
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.mainCtrl,
    required this.index,
    required this.icon,
    required this.iconColor,
    required this.gradientColors,
    required this.label,
    required this.progress,
    required this.value,
    this.onTap,
  });

  final Animation<double> mainCtrl;
  final int index;
  final IconData icon;
  final Color iconColor;
  final List<Color> gradientColors;
  final String label;
  final double progress;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final stagger = 0.36 + (index * 0.06);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedBuilder(
        animation: mainCtrl,
        builder: (context, child) {
          final t = _clamp01(CurvedAnimation(
            parent: mainCtrl,
            curve: Interval(stagger, stagger + 0.16, curve: Curves.easeOutCubic),
          ).value);
          final animatedProgress = progress * _clamp01(CurvedAnimation(
            parent: mainCtrl,
            curve: Interval(stagger, stagger + 0.26, curve: Curves.fastOutSlowIn),
          ).value);

          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: isDark ? 0.20 : 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: t,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 7,
                  width: double.infinity,
                  color: isDark ? const Color(0xFF1E2436) : const Color(0xFFF1F5F9),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: animatedProgress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  E. Setting Tile – Modern Card Style
// ─────────────────────────────────────────────
class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.mainCtrl,
    required this.index,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailingText,
    this.isHighlight = false,
    this.isLogout = false,
    this.onTap,
  });

  final Animation<double> mainCtrl;
  final int index;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? trailingText;
  final bool isHighlight;
  final bool isLogout;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final stagger = 0.50 + (index * 0.05);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: mainCtrl,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mainCtrl,
          curve: Interval(stagger, stagger + 0.16, curve: Curves.easeOutCubic),
        ).value);
        return Transform.translate(
          offset: Offset(0, 20 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: isLogout
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFFEF4444).withValues(alpha: 0.10)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFFEF4444).withValues(alpha: 0.25)
                          : const Color(0xFFFECACA),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: 19,
                        color: Color(0xFFEF4444),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Logout Account',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Material(
              color: isDark ? const Color(0xFF141824) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF282D4A) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: isDark ? 0.18 : 0.10),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          icon,
                          size: 19,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (trailingText != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isHighlight || trailingText == 'Active'
                                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                : trailingText == 'Upgrade'
                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                                    : (isDark
                                        ? const Color(0xFF1E2437)
                                        : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isHighlight || trailingText == 'Active'
                                  ? const Color(0xFF10B981).withValues(alpha: 0.25)
                                  : trailingText == 'Upgrade'
                                      ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                                      : (isDark
                                          ? const Color(0xFF282D4A)
                                          : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Text(
                            trailingText!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isHighlight ||
                                      trailingText == 'Active' ||
                                      trailingText == 'Upgrade'
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isHighlight || trailingText == 'Active'
                                  ? const Color(0xFF10B981)
                                  : trailingText == 'Upgrade'
                                      ? const Color(0xFFF59E0B)
                                      : (isDark
                                          ? const Color(0xFFCBD5E1)
                                          : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}