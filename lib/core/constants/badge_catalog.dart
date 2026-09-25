import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Where a badge belongs in the gallery. Also drives the badge colour, so
/// the gallery reads as groups rather than 23 arbitrary swatches.
enum BadgeCategory {
  consistency('Consistency'),
  nutrition('Nutrition'),
  hydration('Hydration'),
  tracking('Tracking'),
  coaching('Coaching'),
  account('Account');

  const BadgeCategory(this.label);

  final String label;
}

/// Purely presentational rarity. Carries the XP granted when the badge is
/// unlocked so the reward table lives in one place.
enum BadgeRarity {
  common('Common', 25),
  rare('Rare', 50),
  epic('Epic', 100),
  legendary('Legendary', 250);

  const BadgeRarity(this.label, this.xpReward);

  final String label;
  final int xpReward;
}

/// The counter a badge tracks.
///
/// Every value maps 1:1 onto a key returned by the
/// `compute_gamification_stats()` RPC, and `test/badge_catalog_test.dart`
/// asserts that contract against `supabase/schema.sql` so the two sides
/// cannot drift apart silently. [BadgeStat.profileComplete] is the only
/// boolean; it is read as 1 when the profile is filled in.
enum BadgeStat {
  currentStreak('current_streak_days'),
  longestStreak('longest_streak_days'),
  daysLogged7('days_logged_7'),
  mealsLogged('meals_logged'),
  waterGoalDays30('water_goal_days_30'),
  proteinGoalDays30('protein_goal_days_30'),
  perfectDays30('perfect_days_30'),
  breakfastDays7('breakfast_days_7'),
  distinctFoods('distinct_foods'),
  scansCount('scans_count'),
  weightEntries('weight_entries'),
  coachMessages('coach_messages'),
  profileComplete('profile_complete');

  const BadgeStat(this.key);

  final String key;
}

/// A badge *definition*.
///
/// Definitions live in code and are never stored in the database: icons,
/// colours and unlock rules are logic and presentation, so adding a badge
/// ships with an app release instead of a migration, works offline, and stays
/// unit testable.
///
/// The database only ever stores *earned* state, keyed by [id]
/// (`public.achievements.badge`).
class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.rarity,
    required this.icon,
    required this.stat,
    required this.target,
  });

  /// Stable slug. This is what is written to `achievements.badge`, so it must
  /// never be renamed once shipped.
  final String id;
  final String title;
  final String description;
  final BadgeCategory category;
  final BadgeRarity rarity;
  final IconData icon;
  final BadgeStat stat;

  /// Value of [stat] required to unlock.
  final int target;

  /// XP granted the moment this badge unlocks.
  int get xpReward => rarity.xpReward;

  /// Accent colour, derived from the category.
  Color get color => switch (category) {
        BadgeCategory.consistency => const Color(AppColors.streakOrange),
        BadgeCategory.nutrition => const Color(AppColors.success),
        BadgeCategory.hydration => const Color(AppColors.secondary),
        BadgeCategory.tracking => const Color(AppColors.rareBlue),
        BadgeCategory.coaching => const Color(AppColors.authPurple),
        BadgeCategory.account => const Color(AppColors.xpGold),
      };

  /// Human readable unlock rule, e.g. "7 day streak".
  String get criteriaLabel => switch (stat) {
        BadgeStat.currentStreak => '$target day streak',
        BadgeStat.longestStreak => '$target day best streak',
        BadgeStat.daysLogged7 => 'Log $target of the last 7 days',
        BadgeStat.mealsLogged =>
          target == 1 ? 'Log your first meal' : 'Log $target meals',
        BadgeStat.waterGoalDays30 => 'Hit your water goal $target times',
        BadgeStat.proteinGoalDays30 => 'Hit your protein goal $target times',
        BadgeStat.perfectDays30 => 'Stay within calories $target days',
        BadgeStat.breakfastDays7 => 'Log breakfast on $target of 7 days',
        BadgeStat.distinctFoods => 'Track $target different foods',
        BadgeStat.scansCount =>
          target == 1 ? 'Scan your first meal' : 'Scan $target meals',
        BadgeStat.weightEntries => 'Log your weight $target times',
        BadgeStat.coachMessages => 'Chat with your coach $target times',
        BadgeStat.profileComplete => 'Complete your profile',
      };
}

/// The single source of truth for what badges exist.
class BadgeCatalog {
  const BadgeCatalog._();

  /// All badges, in gallery order.
  static const List<BadgeDefinition> all = <BadgeDefinition>[
    // ── Consistency ──
    BadgeDefinition(
      id: 'streak_3',
      title: 'Warming Up',
      description: 'Three days in a row logged.',
      category: BadgeCategory.consistency,
      rarity: BadgeRarity.common,
      icon: Icons.local_fire_department_outlined,
      stat: BadgeStat.currentStreak,
      target: 3,
    ),
    BadgeDefinition(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'A full week without missing a day.',
      category: BadgeCategory.consistency,
      rarity: BadgeRarity.rare,
      icon: Icons.bolt_rounded,
      stat: BadgeStat.currentStreak,
      target: 7,
    ),
    BadgeDefinition(
      id: 'streak_30',
      title: 'Unbreakable',
      description: 'Thirty days of steady tracking.',
      category: BadgeCategory.consistency,
      rarity: BadgeRarity.epic,
      icon: Icons.local_fire_department_rounded,
      stat: BadgeStat.currentStreak,
      target: 30,
    ),
    BadgeDefinition(
      id: 'streak_100',
      title: 'Centurion',
      description: 'The hundred day club.',
      category: BadgeCategory.consistency,
      rarity: BadgeRarity.legendary,
      icon: Icons.emoji_events_outlined,
      stat: BadgeStat.longestStreak,
      target: 100,
    ),
    BadgeDefinition(
      id: 'active_week',
      title: 'Seven For Seven',
      description: 'Logged something every day this week.',
      category: BadgeCategory.consistency,
      rarity: BadgeRarity.epic,
      icon: Icons.event_available_outlined,
      stat: BadgeStat.daysLogged7,
      target: 7,
    ),
    // ── Nutrition ──
    BadgeDefinition(
      id: 'perfect_7',
      title: 'Perfect Week',
      description: 'Seven days inside your calorie target.',
      category: BadgeCategory.nutrition,
      rarity: BadgeRarity.rare,
      icon: Icons.verified_outlined,
      stat: BadgeStat.perfectDays30,
      target: 7,
    ),
    BadgeDefinition(
      id: 'perfect_21',
      title: 'Precision Eater',
      description: 'Three weeks of hitting your calories.',
      category: BadgeCategory.nutrition,
      rarity: BadgeRarity.legendary,
      icon: Icons.workspace_premium_outlined,
      stat: BadgeStat.perfectDays30,
      target: 21,
    ),
    BadgeDefinition(
      id: 'protein_10',
      title: 'Protein Pro',
      description: 'Protein target nailed ten times.',
      category: BadgeCategory.nutrition,
      rarity: BadgeRarity.rare,
      icon: Icons.fitness_center,
      stat: BadgeStat.proteinGoalDays30,
      target: 10,
    ),
    BadgeDefinition(
      id: 'breakfast_5',
      title: 'Early Riser',
      description: 'Breakfast logged five mornings this week.',
      category: BadgeCategory.nutrition,
      rarity: BadgeRarity.rare,
      icon: Icons.wb_sunny_outlined,
      stat: BadgeStat.breakfastDays7,
      target: 5,
    ),
    BadgeDefinition(
      id: 'foods_25',
      title: 'Variety Seeker',
      description: 'Twenty-five different foods tracked.',
      category: BadgeCategory.nutrition,
      rarity: BadgeRarity.rare,
      icon: Icons.restaurant_menu,
      stat: BadgeStat.distinctFoods,
      target: 25,
    ),
    // ── Hydration ──
    BadgeDefinition(
      id: 'water_first',
      title: 'Hydrated Start',
      description: 'Your first water goal reached.',
      category: BadgeCategory.hydration,
      rarity: BadgeRarity.common,
      icon: Icons.opacity,
      stat: BadgeStat.waterGoalDays30,
      target: 1,
    ),
    BadgeDefinition(
      id: 'water_7',
      title: 'H2O Master',
      description: 'Water goal hit seven times.',
      category: BadgeCategory.hydration,
      rarity: BadgeRarity.rare,
      icon: Icons.water_drop_outlined,
      stat: BadgeStat.waterGoalDays30,
      target: 7,
    ),
    BadgeDefinition(
      id: 'water_21',
      title: 'Hydration Hero',
      description: 'Three weeks of proper hydration.',
      category: BadgeCategory.hydration,
      rarity: BadgeRarity.epic,
      icon: Icons.water_drop_rounded,
      stat: BadgeStat.waterGoalDays30,
      target: 21,
    ),
    // ── Tracking ──
    BadgeDefinition(
      id: 'first_meal',
      title: 'First Bite',
      description: 'You logged your very first meal.',
      category: BadgeCategory.tracking,
      rarity: BadgeRarity.common,
      icon: Icons.restaurant,
      stat: BadgeStat.mealsLogged,
      target: 1,
    ),
    BadgeDefinition(
      id: 'meals_50',
      title: 'Meal Prepper',
      description: 'Fifty meals logged.',
      category: BadgeCategory.tracking,
      rarity: BadgeRarity.rare,
      icon: Icons.lunch_dining,
      stat: BadgeStat.mealsLogged,
      target: 50,
    ),
    BadgeDefinition(
      id: 'meals_200',
      title: 'Kitchen Regular',
      description: 'Two hundred meals logged.',
      category: BadgeCategory.tracking,
      rarity: BadgeRarity.epic,
      icon: Icons.dinner_dining,
      stat: BadgeStat.mealsLogged,
      target: 200,
    ),
    BadgeDefinition(
      id: 'scan_1',
      title: 'First Scan',
      description: 'Tried the AI food scanner.',
      category: BadgeCategory.tracking,
      rarity: BadgeRarity.common,
      icon: Icons.center_focus_strong,
      stat: BadgeStat.scansCount,
      target: 1,
    ),
    BadgeDefinition(
      id: 'scan_25',
      title: 'Scanner Pro',
      description: 'Twenty-five meals scanned.',
      category: BadgeCategory.tracking,
      rarity: BadgeRarity.rare,
      icon: Icons.qr_code_scanner_rounded,
      stat: BadgeStat.scansCount,
      target: 25,
    ),
    BadgeDefinition(
      id: 'weight_5',
      title: 'Weight Watcher',
      description: 'Weight logged five times.',
      category: BadgeCategory.tracking,
      rarity: BadgeRarity.common,
      icon: Icons.monitor_weight_outlined,
      stat: BadgeStat.weightEntries,
      target: 5,
    ),
    BadgeDefinition(
      id: 'weight_20',
      title: 'Trend Tracker',
      description: 'Twenty weight entries - the trend is clear.',
      category: BadgeCategory.tracking,
      rarity: BadgeRarity.rare,
      icon: Icons.insights_rounded,
      stat: BadgeStat.weightEntries,
      target: 20,
    ),
    // ── Coaching ──
    BadgeDefinition(
      id: 'coach_1',
      title: 'Coach Intro',
      description: 'First conversation with your AI coach.',
      category: BadgeCategory.coaching,
      rarity: BadgeRarity.common,
      icon: Icons.forum_outlined,
      stat: BadgeStat.coachMessages,
      target: 1,
    ),
    BadgeDefinition(
      id: 'coach_25',
      title: 'AI Expert',
      description: 'Twenty-five coach conversations.',
      category: BadgeCategory.coaching,
      rarity: BadgeRarity.epic,
      icon: Icons.psychology_outlined,
      stat: BadgeStat.coachMessages,
      target: 25,
    ),
    // ── Account ──
    BadgeDefinition(
      id: 'profile_ready',
      title: 'Set Up For Success',
      description: 'Profile, goals and activity level filled in.',
      category: BadgeCategory.account,
      rarity: BadgeRarity.common,
      icon: Icons.badge_outlined,
      stat: BadgeStat.profileComplete,
      target: 1,
    ),

  ];

  static final Map<String, BadgeDefinition> _byId = {
    for (final badge in all) badge.id: badge,
  };

  /// Looks a badge up by its stored slug, or null when a row refers to a badge
  /// that no longer exists in this app version.
  static BadgeDefinition? byId(String id) => _byId[id];

  static List<BadgeDefinition> byCategory(BadgeCategory category) =>
      all.where((badge) => badge.category == category).toList();

  /// Total XP a brand new user could earn purely from badge unlocks.
  static int get totalXpAvailable =>
      all.fold<int>(0, (sum, badge) => sum + badge.xpReward);
}
