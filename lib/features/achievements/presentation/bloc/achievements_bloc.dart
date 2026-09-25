import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/domain/entities/leaderboard_entry.dart';
import '../../../../core/domain/repositories/gamification_repository.dart';
import '../../../../core/utils/xp_engine.dart';

// ==================== EVENTS ====================

abstract class AchievementsEvent extends Equatable {
  const AchievementsEvent();

  @override
  List<Object?> get props => [];
}

/// Re-evaluates the user's real activity, persists anything new, and loads the
/// all-time leaderboard in the same pass.
class LoadGamification extends AchievementsEvent {
  const LoadGamification(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Switches the leaderboard window.
///
/// Only meaningful once [LoadGamification] has produced a
/// [AchievementsLoaded] state, which is why the leaderboard screen dispatches
/// both; the handler ignores the event otherwise.
class LoadLeaderboard extends AchievementsEvent {
  const LoadLeaderboard({this.scope = LeaderboardScope.global});

  final LeaderboardScope scope;

  @override
  List<Object?> get props => [scope];
}

// ==================== STATES ====================

abstract class AchievementsState extends Equatable {
  const AchievementsState();

  @override
  List<Object?> get props => [];
}

class AchievementsInitial extends AchievementsState {}

class AchievementsLoading extends AchievementsState {}

/// Everything the achievements and leaderboard screens render.
///
/// The summary always comes from a completed [GamificationRepository.sync], so
/// XP totals, levels, streaks and badge progress are real values rather than
/// placeholders.
class AchievementsLoaded extends AchievementsState {
  const AchievementsLoaded({
    required this.summary,
    this.newlyUnlocked = const <BadgeProgress>[],
    this.xpAwarded = 0,
    this.leaderboard = const <LeaderboardEntry>[],
    this.leaderboardScope = LeaderboardScope.global,
    this.leaderboardLoading = false,
    this.leaderboardError,
  });

  final GamificationSummary summary;

  /// Badges that crossed their threshold during this load.
  final List<BadgeProgress> newlyUnlocked;

  /// XP added by this load, used for the "+N XP" celebration chip.
  final int xpAwarded;

  final List<LeaderboardEntry> leaderboard;
  final LeaderboardScope leaderboardScope;
  final bool leaderboardLoading;

  /// Set when the ranking failed but the user's own progress loaded fine, so
  /// the page still renders instead of showing a full-screen error.
  final String? leaderboardError;

  bool get hasRewards => xpAwarded > 0 || newlyUnlocked.isNotEmpty;

  AchievementsLoaded copyWith({
    GamificationSummary? summary,
    List<BadgeProgress>? newlyUnlocked,
    int? xpAwarded,
    List<LeaderboardEntry>? leaderboard,
    LeaderboardScope? leaderboardScope,
    bool? leaderboardLoading,
    String? leaderboardError,
    bool clearLeaderboardError = false,
  }) {
    return AchievementsLoaded(
      summary: summary ?? this.summary,
      newlyUnlocked: newlyUnlocked ?? this.newlyUnlocked,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      leaderboard: leaderboard ?? this.leaderboard,
      leaderboardScope: leaderboardScope ?? this.leaderboardScope,
      leaderboardLoading: leaderboardLoading ?? this.leaderboardLoading,
      leaderboardError: clearLeaderboardError
          ? null
          : (leaderboardError ?? this.leaderboardError),
    );
  }

  @override
  List<Object?> get props => [
        summary,
        newlyUnlocked,
        xpAwarded,
        leaderboard,
        leaderboardScope,
        leaderboardLoading,
        leaderboardError,
      ];
}

class AchievementsError extends AchievementsState {
  const AchievementsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

// ==================== BLOC ====================

/// Drives the achievements gallery and the leaderboard from one synced state.
///
/// All the rule evaluation happens in [GamificationRepository.sync]; this bloc
/// only sequences the calls and shapes the result for the UI.
class AchievementsBloc extends Bloc<AchievementsEvent, AchievementsState> {
  AchievementsBloc({required GamificationRepository gamificationRepository})
      : _repository = gamificationRepository,
        super(AchievementsInitial()) {
    on<LoadGamification>(_onLoadGamification);
    on<LoadLeaderboard>(_onLoadLeaderboard);
  }

  final GamificationRepository _repository;

  Future<void> _onLoadGamification(
    LoadGamification event,
    Emitter<AchievementsState> emit,
  ) async {
    emit(AchievementsLoading());
    try {
      final snapshot = await _repository.sync(event.userId);

      // The ranking is a separate, non-critical read. If it fails the user's
      // own progress still renders, with an inline note on the leaderboard.
      var board = const <LeaderboardEntry>[];
      String? boardError;
      try {
        board = await _repository.leaderboard();
      } catch (error) {
        boardError = _describe(error);
      }

      emit(
        AchievementsLoaded(
          summary: snapshot.summary,
          newlyUnlocked: snapshot.newlyUnlocked,
          xpAwarded: snapshot.xpAwarded,
          leaderboard: board,
          leaderboardError: boardError,
        ),
      );
    } catch (error) {
      emit(AchievementsError(_describe(error)));
    }
  }

  Future<void> _onLoadLeaderboard(
    LoadLeaderboard event,
    Emitter<AchievementsState> emit,
  ) async {
    final current = state;
    // Nothing to re-scope until the first sync has landed.
    if (current is! AchievementsLoaded) return;

    emit(
      current.copyWith(
        leaderboardScope: event.scope,
        leaderboardLoading: true,
        clearLeaderboardError: true,
      ),
    );

    try {
      final board = await _repository.leaderboard(scope: event.scope);
      emit(
        current.copyWith(
          leaderboard: board,
          leaderboardScope: event.scope,
          leaderboardLoading: false,
          clearLeaderboardError: true,
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          leaderboardScope: event.scope,
          leaderboardLoading: false,
          leaderboardError: _describe(error),
        ),
      );
    }
  }

  /// PostgREST/Postgres codes that mean "the project is missing an object the
  /// client asked for": `PGRST202` (function absent from the schema cache),
  /// `PGRST205` (table absent from the schema cache) and `42703` (column does
  /// not exist).
  ///
  /// All three appear when `supabase/migrations/010_gamification_leaderboard.sql`
  /// has not been applied to the project yet. That is a deployment problem, not
  /// something a retry can fix, so it must not reach the user as raw SQL.
  static const _missingSchemaCodes = <String>{'PGRST202', 'PGRST205', '42703'};

  /// `42501` is `insufficient_privilege`. Postgres raises it as
  /// `new row violates row-level security policy for table "gamification"`
  /// when a table has RLS enabled but no permissive policy covering the write
  /// the client attempted — the state an existing `gamification` or
  /// `achievements` table is left in when migration 010 has not been applied.
  /// Same cause as [_missingSchemaCodes], same remedy.
  static const _permissionCodes = <String>{'42501'};

  /// Keeps exception plumbing out of the UI layer.
  ///
  /// The raw `PostgrestException` dump is only meaningful to whoever applies
  /// the migrations, so release builds get a plain-language message instead.
  static String _describe(Object error) {
    if (error is PostgrestException) {
      if (_missingSchemaCodes.contains(error.code)) {
        return _migrationHint('Progress tracking');
      }
      if (_permissionCodes.contains(error.code)) {
        return _migrationHint('Saving your progress');
      }
      // Anything else is surfaced at message level only: `toString()` on the
      // exception embeds the request payload and the statement that failed.
      final message = error.message.trim();
      return message.isEmpty ? 'Something went wrong.' : message;
    }

    const prefix = 'Exception: ';
    final message = error.toString();
    final trimmed =
        message.startsWith(prefix) ? message.substring(prefix.length) : message;
    return trimmed.isEmpty ? 'Something went wrong.' : trimmed;
  }

  /// [action] is phrased as a subject so it reads naturally in both branches.
  static String _migrationHint(String action) => kDebugMode
      ? '$action is unavailable: this build is ahead of the database. Run '
          'supabase/migrations/010_gamification_leaderboard.sql in the Supabase '
          'SQL editor, then try again.'
      : '$action is temporarily unavailable. Please try again in a moment.';
}
