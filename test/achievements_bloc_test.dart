import 'package:fitfuel_ai/core/domain/entities/leaderboard_entry.dart';
import 'package:fitfuel_ai/core/domain/repositories/gamification_repository.dart';
import 'package:fitfuel_ai/core/utils/xp_engine.dart';
import 'package:fitfuel_ai/features/achievements/presentation/bloc/achievements_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Every call fails with [error].
///
/// Stands in for a project where the gamification migration has not been
/// applied, which is what produces `PGRST202`/`PGRST205`/`42703` in practice.
class _FailingRepository implements GamificationRepository {
  _FailingRepository(this.error);

  final Object error;

  @override
  Future<GamificationSnapshot> sync(String userId) async {
    throw error;
  }

  @override
  Future<List<LeaderboardEntry>> leaderboard({
    LeaderboardScope scope = LeaderboardScope.global,
    int limit = 50,
  }) async {
    throw error;
  }
}

/// The sync succeeds, but the ranking read fails - the case where the user's
/// own progress must still render with an inline note.
class _LeaderboardFailsRepository implements GamificationRepository {
  _LeaderboardFailsRepository(this.error);

  final Object error;

  @override
  Future<GamificationSnapshot> sync(String userId) async =>
      GamificationSnapshot.empty;

  @override
  Future<List<LeaderboardEntry>> leaderboard({
    LeaderboardScope scope = LeaderboardScope.global,
    int limit = 50,
  }) async {
    throw error;
  }
}

/// The exact payload the live project returned before migration 010 was
/// applied (only `code` matters to the mapper).
const _missingFunction = PostgrestException(
  message: 'Could not find the function public.compute_gamification_stats '
      'without parameters in the schema cache',
  details: 'Searched for the function public.compute_gamification_stats '
      'without parameters or with a single unnamed json/jsonb parameter, but '
      'no matches were found in the schema cache.',
  code: 'PGRST202',
);

/// The payload the live project returned once the RPCs existed but the
/// `gamification` table still had no permissive write policy.
const _rlsViolation = PostgrestException(
  message:
      'new row violates row-level security policy for table "gamification"',
  details: 'Forbidden',
  code: '42501',
  hint: 'null',
);

void main() {
  group('AchievementsBloc error reporting', () {
    test('a missing RPC becomes an actionable setup message', () async {
      final bloc = AchievementsBloc(
        gamificationRepository: _FailingRepository(_missingFunction),
      );

      final emitted =
          bloc.stream.firstWhere((state) => state is AchievementsError);
      bloc.add(const LoadGamification('user-1'));
      final message = (await emitted as AchievementsError).message;

      expect(message, contains('010_gamification_leaderboard.sql'));
      // The raw SQL dump must never be what the user reads.
      expect(message, isNot(contains('PostgrestException')));
      expect(message, isNot(contains('schema cache')));

      await bloc.close();
    });

    test('a failed ranking read leaves the progress screen usable', () async {
      final bloc = AchievementsBloc(
        gamificationRepository: _LeaderboardFailsRepository(_missingFunction),
      );

      final emitted =
          bloc.stream.firstWhere((state) => state is AchievementsLoaded);
      bloc.add(const LoadGamification('user-1'));
      final state = await emitted;

      expect(state, isA<AchievementsLoaded>());
      expect(
        (state as AchievementsLoaded).leaderboardError,
        contains('010_gamification_leaderboard.sql'),
      );
      expect(state.leaderboard, isEmpty);

      await bloc.close();
    });

    test('unrelated failures keep their detailed message', () async {
      final bloc = AchievementsBloc(
        gamificationRepository: _FailingRepository(Exception('network down')),
      );

      final emitted =
          bloc.stream.firstWhere((state) => state is AchievementsError);
      bloc.add(const LoadGamification('user-1'));
      final state = await emitted as AchievementsError;

      expect(state.message, 'network down');

      await bloc.close();
    });

    test('an RLS write rejection becomes an actionable setup message',
        () async {
      final bloc = AchievementsBloc(
        gamificationRepository: _FailingRepository(_rlsViolation),
      );

      final emitted =
          bloc.stream.firstWhere((state) => state is AchievementsError);
      bloc.add(const LoadGamification('user-1'));
      final message = (await emitted as AchievementsError).message;

      expect(message, contains('010_gamification_leaderboard.sql'));
      // The table name and policy wording are deployment detail, not UX.
      expect(message, isNot(contains('row-level security policy')));
      expect(message, isNot(contains('PostgrestException')));

      await bloc.close();
    });

    test('other Postgrest failures never dump the raw exception', () async {
      final bloc = AchievementsBloc(
        gamificationRepository: _FailingRepository(
          const PostgrestException(
            message: 'duplicate key value violates unique constraint '
                '"idx_achievements_user_badge"',
            details:
                'Key (user_id, badge)=(user-1, first_meal) already exists.',
            code: '23505',
          ),
        ),
      );

      final emitted =
          bloc.stream.firstWhere((state) => state is AchievementsError);
      bloc.add(const LoadGamification('user-1'));
      final state = await emitted as AchievementsError;

      expect(
        state.message,
        'duplicate key value violates unique constraint '
        '"idx_achievements_user_badge"',
      );
      expect(state.message, isNot(contains('PostgrestException(')));
      expect(state.message, isNot(contains('details:')));

      await bloc.close();
    });
  });
}
