import '../../domain/entities/gamification_stats.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../../utils/level_system.dart';
import '../../utils/xp_engine.dart';
import '../datasources/supabase_remote_datasource.dart';

/// Bridges the pure [XpEngine] rules to Supabase.
///
/// The engine decides *what* should be awarded; this class only reads the
/// counters, writes the result, and merges stored badge timestamps back in.
/// Nothing here decides XP values or unlock thresholds.
class GamificationRepositoryImpl implements GamificationRepository {
  GamificationRepositoryImpl(this._dataSource);

  final SupabaseRemoteDataSource _dataSource;

  @override
  Future<GamificationSnapshot> sync(String userId) async {
    final stats = GamificationStats.fromJson(
      await _dataSource.computeGamificationStats(),
    );

    // No session (or a signed-out client): render an empty catalog rather than
    // an error, so the screen still explains how badges are earned.
    if (!stats.authenticated) {
      return GamificationSnapshot(
        summary: XpEngine.summarize(
          xpTotal: 0,
          weeklyXp: 0,
          streakDays: 0,
          longestStreakDays: 0,
          badges: XpEngine.evaluate(GamificationStats.empty),
        ),
      );
    }

    final stored = await _storedBadges(userId);
    final plan = XpEngine.plan(stats: stats);
    final now = DateTime.now();

    // ── 1. XP ledger ──
    // `event_date` is deliberately left to the column default (`CURRENT_DATE`)
    // rather than sent from the device: `granted_sources_today` is computed
    // against the server clock, so stamping awards with a local date could
    // credit the same action twice around midnight.
    await _dataSource.insertXpEvents(
      plan.newAwards
          .map((award) => <String, dynamic>{
                'user_id': userId,
                'source': award.source,
                'xp': award.xp,
              })
          .toList(),
    );

    // ── 2. Badge progress ──
    final badges = <BadgeProgress>[];
    final newlyUnlocked = <BadgeProgress>[];
    final changedRows = <Map<String, dynamic>>[];

    for (final badge in plan.badges) {
      final previous = stored[badge.badge.id];
      final previousProgress = (previous?['progress'] as num?)?.toInt() ?? -1;
      final previousCompleted = previous?['completed'] as bool? ?? false;
      final previousAt = _parseTimestamp(previous?['completed_at']);

      // Never overwrite an existing unlock timestamp - that is when the badge
      // was actually earned and the UI sorts "recently unlocked" by it.
      final unlockedAt = previousAt ?? (badge.unlocked ? now : null);
      final resolved = badge.copyWith(unlockedAt: unlockedAt);

      badges.add(resolved);
      if (badge.unlocked && !previousCompleted) newlyUnlocked.add(resolved);

      final needsBackfill = badge.unlocked && previous != null && previousAt == null;
      if (!needsBackfill &&
          previousProgress == badge.progress &&
          previousCompleted == badge.unlocked) {
        continue;
      }

      changedRows.add(<String, dynamic>{
        'user_id': userId,
        'badge': badge.badge.id,
        'progress': badge.progress,
        'completed': badge.unlocked,
        'completed_at': unlockedAt?.toUtc().toIso8601String(),
      });
    }

    await _dataSource.upsertAchievements(changedRows);

    // ── 3. Rolled-up totals ──
    // Every new award is dated today, so it counts towards both totals.
    final xpTotal = stats.xpTotal + plan.newXp;
    final level = LevelSystem.levelForXp(xpTotal);

    await _dataSource.upsertGamification(<String, dynamic>{
      'user_id': userId,
      'xp_total': xpTotal,
      'streak_days': stats.currentStreakDays,
      'level': level,
      'tier': LevelSystem.tierForLevel(level),
    });

    return GamificationSnapshot(
      summary: XpEngine.summarize(
        xpTotal: xpTotal,
        weeklyXp: stats.xpThisWeek + plan.newXp,
        streakDays: stats.currentStreakDays,
        longestStreakDays: stats.longestStreakDays,
        badges: badges,
      ),
      xpAwarded: plan.newXp,
      newlyUnlocked: newlyUnlocked,
    );
  }

  @override
  Future<List<LeaderboardEntry>> leaderboard({
    LeaderboardScope scope = LeaderboardScope.global,
    int limit = 50,
  }) async {
    final rows = await _dataSource.getLeaderboard(
      scope: scope.rpcValue,
      limit: limit,
    );
    return rows.map(LeaderboardEntry.fromJson).toList();
  }

  /// Stored badge rows keyed by badge slug.
  Future<Map<String, Map<String, dynamic>>> _storedBadges(String userId) async {
    final rows = await _dataSource.getAchievements(userId);
    return <String, Map<String, dynamic>>{
      for (final row in rows)
        if (row['badge'] is String) row['badge'] as String: row,
    };
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
