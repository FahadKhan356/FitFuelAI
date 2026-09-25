import '../../utils/xp_engine.dart';
import '../entities/leaderboard_entry.dart';

/// Single entry point for every gamification read and write.
///
/// The *rules* — XP values, badge criteria, the level curve — live in
/// [XpEngine] as pure functions. This interface is only about bridging those
/// rules to the database, which keeps the criteria unit testable and keeps SQL
/// free of business rules.
abstract class GamificationRepository {
  /// Re-evaluates the user's real activity and persists anything new.
  ///
  /// Safe to call on every screen open and after any write that could earn XP
  /// (meal, water, weight, scan, coach chat): per-day awards are idempotent
  /// through the ledger's unique key, and one-off awards are filtered against
  /// the sources already recorded.
  Future<GamificationSnapshot> sync(String userId);

  /// Reads the ranking without touching the caller's own progress.
  Future<List<LeaderboardEntry>> leaderboard({
    LeaderboardScope scope = LeaderboardScope.global,
    int limit = 50,
  });
}
