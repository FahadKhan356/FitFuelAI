/// The XP → level → tier curve.
///
/// Deliberately a pure static helper with no dependencies so the same numbers
/// can be asserted in tests and reused by the profile preview, the
/// achievements screen and the leaderboard.
///
/// The curve widens as you climb: level 1→2 costs [baseLevelCost] XP and each
/// further level costs [levelCostStep] XP more than the previous one, so early
/// progress feels quick and later levels feel earned.
class LevelSystem {
  const LevelSystem._();

  /// Hard ceiling. At this point [xpForNextLevel] returns 0 and the UI shows
  /// the player as maxed out.
  static const int maxLevel = 100;

  /// XP needed to go from level 1 to level 2.
  static const int baseLevelCost = 500;

  /// Extra XP each subsequent level costs over the one before it.
  static const int levelCostStep = 250;

  /// Tier bands. These strings are the exact values allowed by the
  /// `gamification.tier` CHECK constraint, so they must not change without a
  /// matching migration.
  static const List<String> tiers = <String>[
    'Bronze',
    'Silver',
    'Gold',
    'Platinum',
    'Diamond',
  ];

  /// Cumulative XP required to *be* at [level]. Level 1 starts at 0 XP.
  static int totalXpForLevel(int level) {
    if (level <= 1) return 0;
    final steps = (level - 1).clamp(0, maxLevel - 1);
    // sum over i in 1..steps of (base + (i - 1) * step)
    return steps * baseLevelCost + levelCostStep * (steps * (steps - 1) ~/ 2);
  }

  /// The level a player with [xp] total XP is on.
  static int levelForXp(int xp) {
    if (xp <= 0) return 1;
    var level = 1;
    while (level < maxLevel && xp >= totalXpForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  /// XP earned since the start of the current level.
  static int xpIntoLevel(int xp) => xp - totalXpForLevel(levelForXp(xp));

  /// XP required to finish the level the player is currently on, or 0 when
  /// they have hit [maxLevel].
  static int xpForNextLevel(int xp) {
    final level = levelForXp(xp);
    if (level >= maxLevel) return 0;
    return totalXpForLevel(level + 1) - totalXpForLevel(level);
  }

  /// Fraction of the way through the current level, clamped to 0..1.
  static double levelProgress(int xp) {
    final needed = xpForNextLevel(xp);
    if (needed <= 0) return 1;
    return (xpIntoLevel(xp) / needed).clamp(0.0, 1.0);
  }

  /// Tier name for a level. Mirrors the DB CHECK constraint exactly.
  static String tierForLevel(int level) {
    if (level >= 50) return 'Diamond';
    if (level >= 35) return 'Platinum';
    if (level >= 20) return 'Gold';
    if (level >= 10) return 'Silver';
    return 'Bronze';
  }

  /// The next tier up, or null when already [maxLevel]/Diamond.
  static String? nextTier(String tier) {
    final index = tiers.indexOf(tier);
    if (index < 0 || index >= tiers.length - 1) return null;
    return tiers[index + 1];
  }
}
