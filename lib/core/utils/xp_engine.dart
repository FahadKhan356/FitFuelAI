import '../constants/badge_catalog.dart';
import '../domain/entities/gamification_stats.dart';
import 'level_system.dart';

/// Every XP value in the game. Kept in one place so balance changes are a
/// single edit and can be asserted in tests.
class XpRules {
  const XpRules._();

  /// Per-day awards. Each is recorded at most once per calendar day for a
  /// given [XpSource], enforced by the ledger's unique index.
  static const int mealLogged = 15;
  static const int breakfastLogged = 5;
  static const int waterGoalHit = 20;
  static const int weightLogged = 25;
  static const int foodScan = 10;
  static const int coachMessage = 5;
  static const int perfectDay = 40;
  static const int proteinGoalHit = 30;

  /// One-off awards.
  static const int profileComplete = 100;

  /// Awarded the first time a streak reaches the key (days). Deliberately
  /// milestone-based rather than a per-day bonus: a per-day bonus would make
  /// the total drift every time the streak is recomputed.
  static const Map<int, int> streakMilestones = <int, int>{
    3: 50,
    7: 100,
    14: 200,
    30: 500,
    100: 1500,
  };
}

/// Ledger keys written to `xp_events.source`.
///
/// * `daily*` sources are idempotent per `(source, event_date)`.
/// * One-off sources are idempotent per `source` and are filtered against the
///   user's all-time granted set before being written.
class XpSource {
  const XpSource._();

  static const String mealLogged = 'meal_logged';
  static const String breakfastLogged = 'breakfast_logged';
  static const String waterGoalHit = 'water_goal_hit';
  static const String weightLogged = 'weight_logged';
  static const String foodScan = 'food_scan';
  static const String coachMessage = 'coach_message';
  static const String perfectDay = 'perfect_day';
  static const String proteinGoalHit = 'protein_goal_hit';
  static const String profileComplete = 'profile_complete';

  /// Sources that may be credited once per day.
  static const Set<String> daily = <String>{
    mealLogged,
    breakfastLogged,
    waterGoalHit,
    weightLogged,
    foodScan,
    coachMessage,
    perfectDay,
    proteinGoalHit,
  };

  static String streakMilestone(int days) => 'streak_milestone_$days';

  static String badgeUnlock(String badgeId) => 'badge_unlock_$badgeId';

  /// True for sources that may only ever be credited once.
  static bool isOneOff(String source) => !daily.contains(source);
}

/// A single pending ledger entry.
class XpAward {
  const XpAward({required this.source, required this.xp, required this.date});

  final String source;
  final int xp;
  final DateTime date;
}

/// A badge plus how far along the user is.
class BadgeProgress {
  const BadgeProgress({
    required this.badge,
    required this.progress,
    required this.unlocked,
    this.unlockedAt,
  });

  final BadgeDefinition badge;

  /// Counter value, clamped to the badge target so the progress bar cannot
  /// overflow (a 30-day streak shows 7/7 for the 7-day badge, not 30/7).
  final int progress;
  final bool unlocked;

  /// When the badge was first earned, or null if it was earned by this run and
  /// has not been persisted yet.
  final DateTime? unlockedAt;

  /// 0..1 progress towards unlocking.
  double get ratio =>
      badge.target <= 0 ? 1.0 : (progress / badge.target).clamp(0.0, 1.0);

  /// Earned in this run but not yet stored in `achievements`.
  bool get pendingPersistence => unlocked && unlockedAt == null;

  BadgeProgress copyWith({int? progress, bool? unlocked, DateTime? unlockedAt}) {
    return BadgeProgress(
      badge: badge,
      progress: progress ?? this.progress,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

/// The result of evaluating a [GamificationStats] snapshot: what still needs
/// to be written to the database, and where every badge stands.
class XpPlan {
  const XpPlan({required this.newAwards, required this.badges});

  /// Ledger rows to insert. Per-day awards are filtered against what was
  /// already credited today, and one-off awards against the all-time set, so
  /// this list contains no duplicates by construction.
  final List<XpAward> newAwards;

  final List<BadgeProgress> badges;

  /// Total XP this plan will add once persisted.
  int get newXp => newAwards.fold<int>(0, (sum, award) => sum + award.xp);

  /// Badges earned by this run that are not in `achievements` yet.
  List<BadgeProgress> get pendingBadges =>
      badges.where((badge) => badge.pendingPersistence).toList();

  bool get isEmpty => newAwards.isEmpty && pendingBadges.isEmpty;
}

/// Everything the UI needs to render gamification, already resolved.
///
/// Built by [XpEngine.summarize] so no widget has to know about the level
/// curve, the ledger or badge targets.
class GamificationSummary {
  const GamificationSummary({
    required this.xpTotal,
    required this.weeklyXp,
    required this.level,
    required this.tier,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
    required this.streakDays,
    required this.longestStreakDays,
    required this.badges,
  });

  /// A user who has not earned anything yet.
  static const GamificationSummary empty = GamificationSummary(
    xpTotal: 0,
    weeklyXp: 0,
    level: 1,
    tier: 'Bronze',
    xpIntoLevel: 0,
    xpForNextLevel: LevelSystem.baseLevelCost,
    streakDays: 0,
    longestStreakDays: 0,
    badges: <BadgeProgress>[],
  );

  final int xpTotal;
  final int weeklyXp;
  final int level;
  final String tier;

  /// XP earned inside the current level, and the size of the current level.
  final int xpIntoLevel;
  final int xpForNextLevel;

  final int streakDays;
  final int longestStreakDays;

  /// Every catalog badge with its progress, in catalog order.
  final List<BadgeProgress> badges;

  bool get isMaxLevel => level >= LevelSystem.maxLevel;

  double get levelProgress => xpForNextLevel <= 0
      ? 1.0
      : (xpIntoLevel / xpForNextLevel).clamp(0.0, 1.0);

  /// XP still needed to reach the next level (0 when maxed).
  int get xpToNextLevel =>
      xpForNextLevel <= 0 ? 0 : (xpForNextLevel - xpIntoLevel).clamp(0, xpForNextLevel);

  int get unlockedCount => badges.where((badge) => badge.unlocked).length;

  int get totalBadgeCount => badges.length;

  /// The most recently unlocked badge — anything earned by the current run
  /// wins, since its timestamp has not been stored yet.
  BadgeProgress? get mostRecentUnlocked {
    final unlocked = badges.where((badge) => badge.unlocked).toList();
    if (unlocked.isEmpty) return null;
    unlocked.sort((a, b) {
      final aPending = a.unlockedAt == null ? 1 : 0;
      final bPending = b.unlockedAt == null ? 1 : 0;
      if (aPending != bPending) return bPending - aPending;
      if (a.unlockedAt == null || b.unlockedAt == null) return 0;
      return b.unlockedAt!.compareTo(a.unlockedAt!);
    });
    return unlocked.first;
  }

  /// The locked badge the user is closest to earning, used for the
  /// "next milestone" card.
  BadgeProgress? get nextMilestone {
    final locked = badges.where((badge) => !badge.unlocked).toList();
    if (locked.isEmpty) return null;
    locked.sort((a, b) => b.ratio.compareTo(a.ratio));
    return locked.first;
  }
}

/// The outcome of one synchronisation.
///
/// Carries the resolved summary plus whatever was newly written, so the UI can
/// celebrate a level-up or a fresh badge on the same pass that it renders.
class GamificationSnapshot {
  const GamificationSnapshot({
    required this.summary,
    this.xpAwarded = 0,
    this.newlyUnlocked = const <BadgeProgress>[],
  });

  /// Nothing earned, nothing stored - used before the first sync lands.
  static const GamificationSnapshot empty =
      GamificationSnapshot(summary: GamificationSummary.empty);

  final GamificationSummary summary;

  /// XP added to the ledger by this sync (0 when the evaluator found nothing new).
  final int xpAwarded;

  /// Badges that crossed their threshold during this sync.
  final List<BadgeProgress> newlyUnlocked;

  bool get hasRewards => xpAwarded > 0 || newlyUnlocked.isNotEmpty;
}

/// Turns raw counters into XP awards, badge progress, levels and tiers.
///
/// Deliberately pure and synchronous: no Supabase, no `DateTime.now()` unless
/// the caller omits it. That makes every rule here testable with plain values,
/// which is why the criteria live in Dart rather than in SQL triggers.
class XpEngine {
  const XpEngine._();

  /// Evaluates a snapshot and returns what needs persisting.
  ///
  /// `stats.grantedSources` guards one-off awards and
  /// `stats.grantedSourcesToday` guards per-day awards, both supplied by the
  /// `compute_gamification_stats()` RPC.
  static XpPlan plan({
    required GamificationStats stats,
    DateTime? today,
  }) {
    final date = _dateOnly(today ?? DateTime.now());
    final awards = <XpAward>[];

    void daily(String source, int xp, bool happened) {
      if (!happened || xp <= 0) return;
      if (stats.grantedSourcesToday.contains(source)) return;
      awards.add(XpAward(source: source, xp: xp, date: date));
    }

    void oneOff(String source, int xp, bool condition) {
      if (!condition || xp <= 0) return;
      if (stats.grantedSources.contains(source)) return;
      awards.add(XpAward(source: source, xp: xp, date: date));
    }

    // ── Today's actions ──
    daily(XpSource.mealLogged, XpRules.mealLogged, stats.mealLoggedToday);
    daily(XpSource.breakfastLogged, XpRules.breakfastLogged, stats.breakfastToday);
    daily(XpSource.waterGoalHit, XpRules.waterGoalHit, stats.waterGoalHitToday);
    daily(XpSource.weightLogged, XpRules.weightLogged, stats.weightLoggedToday);
    daily(XpSource.foodScan, XpRules.foodScan, stats.scanToday);
    daily(XpSource.coachMessage, XpRules.coachMessage, stats.coachToday);
    daily(XpSource.perfectDay, XpRules.perfectDay, stats.perfectDayToday);
    daily(XpSource.proteinGoalHit, XpRules.proteinGoalHit, stats.proteinGoalToday);

    // ── One-off milestones ──
    oneOff(XpSource.profileComplete, XpRules.profileComplete, stats.profileComplete);
    XpRules.streakMilestones.forEach((days, xp) {
      oneOff(XpSource.streakMilestone(days), xp, stats.currentStreakDays >= days);
    });

    // ── Badge unlocks award their rarity's XP, once ──
    final badges = evaluate(stats);
    for (final badge in badges) {
      if (badge.unlocked) {
        oneOff(
          XpSource.badgeUnlock(badge.badge.id),
          badge.badge.xpReward,
          true,
        );
      }
    }

    return XpPlan(newAwards: awards, badges: badges);
  }

  /// Works out where every catalog badge stands for a snapshot.
  ///
  /// Doesn't know about persistence, so `unlockedAt` is always null here —
  /// the repository merges the stored timestamps in afterwards.
  static List<BadgeProgress> evaluate(GamificationStats stats) {
    return BadgeCatalog.all.map((badge) {
      final value = stats.valueFor(badge.stat.key);
      return BadgeProgress(
        badge: badge,
        progress: value.clamp(0, badge.target),
        unlocked: value >= badge.target,
      );
    }).toList();
  }

  /// Wraps a persisted XP total and badge list into the view model the UI uses.
  static GamificationSummary summarize({
    required int xpTotal,
    required int weeklyXp,
    required int streakDays,
    required int longestStreakDays,
    required List<BadgeProgress> badges,
  }) {
    final level = LevelSystem.levelForXp(xpTotal);
    return GamificationSummary(
      xpTotal: xpTotal,
      weeklyXp: weeklyXp,
      level: level,
      tier: LevelSystem.tierForLevel(level),
      xpIntoLevel: LevelSystem.xpIntoLevel(xpTotal),
      xpForNextLevel: LevelSystem.xpForNextLevel(xpTotal),
      streakDays: streakDays,
      longestStreakDays: longestStreakDays,
      badges: badges,
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
