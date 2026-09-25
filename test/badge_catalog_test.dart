import 'dart:io';

import 'package:fitfuel_ai/core/constants/badge_catalog.dart';
import 'package:fitfuel_ai/core/utils/level_system.dart';
import 'package:flutter_test/flutter_test.dart';

/// Extracts the jsonb keys returned by `compute_gamification_stats()` straight
/// out of the SQL, so the Dart `BadgeStat` enum cannot silently drift away
/// from what the database actually sends.
///
/// The source is lowercased first because `schema.sql` uses upper-case SQL
/// keywords while the numbered migrations use lower-case.
Set<String> statsKeysFromSql(String sql) {
  final lower = sql.toLowerCase();
  final fnStart = lower.indexOf('function public.compute_gamification_stats');
  if (fnStart < 0) {
    throw StateError('compute_gamification_stats() not found in SQL source');
  }
  final fnEnd = lower.indexOf(r'$$;', fnStart);
  if (fnEnd < 0) {
    throw StateError('unterminated compute_gamification_stats() body');
  }
  final body = lower.substring(fnStart, fnEnd);
  final blockStart = body.lastIndexOf('return jsonb_build_object(');
  final blockEnd = body.indexOf(');', blockStart);
  if (blockStart < 0 || blockEnd < 0) {
    throw StateError('no return jsonb_build_object(...) found');
  }
  final block = body.substring(blockStart, blockEnd);
  // Every single-quoted token in the return block is a key - all values are
  // `v_*` variables or TRUE/FALSE.
  return RegExp(r"'([a-z0-9_]+)'")
      .allMatches(block)
      .map((match) => match.group(1)!)
      .toSet();
}

/// The values allowed by the `gamification.tier` CHECK constraint.
///
/// Matched case-insensitively but extracted from the original text, so the
/// tier names keep the capitalisation they are stored with.
Set<String> tierValuesFromSql(String sql) {
  final match = RegExp(r'tier\s+IN\s*\(([^)]*)\)', caseSensitive: false)
      .firstMatch(sql);
  if (match == null) throw StateError('gamification.tier CHECK not found');
  return RegExp(r"'([^']+)'")
      .allMatches(match.group(1)!)
      .map((group) => group.group(1)!)
      .toSet();
}

void main() {
  late String schema;
  late String migration;

  setUpAll(() {
    schema = File('supabase/schema.sql').readAsStringSync();
    migration = File(
      'supabase/migrations/010_gamification_leaderboard.sql',
    ).readAsStringSync();
  });

  group('BadgeCatalog integrity', () {
    test('ships a full gallery, not a placeholder handful', () {
      expect(BadgeCatalog.all.length, greaterThanOrEqualTo(20));
    });

    test('every id is a unique, slug-safe, stable identifier', () {
      final ids = BadgeCatalog.all.map((badge) => badge.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'duplicate badge id');
      for (final id in ids) {
        expect(id, matches(RegExp(r'^[a-z0-9_]+$')), reason: 'bad id: $id');
      }
    });

    test('every badge is documented and actionable', () {
      for (final badge in BadgeCatalog.all) {
        expect(badge.title.trim(), isNotEmpty, reason: badge.id);
        expect(badge.description.trim(), isNotEmpty, reason: badge.id);
        expect(badge.criteriaLabel.trim(), isNotEmpty, reason: badge.id);
      }
    });

    test('every target is a positive threshold', () {
      for (final badge in BadgeCatalog.all) {
        expect(badge.target, greaterThan(0), reason: badge.id);
      }
    });

    test('every category has at least one badge', () {
      for (final category in BadgeCategory.values) {
        expect(
          BadgeCatalog.byCategory(category),
          isNotEmpty,
          reason: 'no badges in ${category.label}',
        );
      }
    });

    test('rarity rewards rise with rarity', () {
      expect(BadgeRarity.common.xpReward, lessThan(BadgeRarity.rare.xpReward));
      expect(BadgeRarity.rare.xpReward, lessThan(BadgeRarity.epic.xpReward));
      expect(
        BadgeRarity.epic.xpReward,
        lessThan(BadgeRarity.legendary.xpReward),
      );
    });

    test('byId round-trips and returns null for an unknown slug', () {
      for (final badge in BadgeCatalog.all) {
        expect(BadgeCatalog.byId(badge.id)?.title, badge.title);
      }
      expect(BadgeCatalog.byId('does_not_exist'), isNull);
    });

    test('totalXpAvailable matches the rarity table', () {
      final expected = BadgeCatalog.all.fold<int>(
        0,
        (sum, badge) => sum + badge.rarity.xpReward,
      );
      expect(BadgeCatalog.totalXpAvailable, expected);
      expect(expected, greaterThan(0));
    });
  });

  group('SQL contract', () {
    test('every badge stat key is produced by compute_gamification_stats()', () {
      final keys = statsKeysFromSql(schema);
      expect(keys, isNotEmpty);
      for (final badge in BadgeCatalog.all) {
        expect(
          keys,
          contains(badge.stat.key),
          reason: '${badge.id} tracks ${badge.stat.key}, which the RPC does '
              'not return - the badge would be permanently locked',
        );
      }
    });

    test('every BadgeStat enum value is tracked by at least one badge', () {
      final used = BadgeCatalog.all.map((badge) => badge.stat).toSet();
      for (final stat in BadgeStat.values) {
        expect(used, contains(stat), reason: '${stat.key} is never tracked');
      }
    });

    test('the SQL tier list matches LevelSystem.tiers exactly', () {
      expect(tierValuesFromSql(schema), LevelSystem.tiers.toSet());
    });

    test('the schema declares everything the gamification layer needs', () {
      const required = <String>[
        'CREATE TABLE IF NOT EXISTS public.xp_events',
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_xp_events_user_source_date',
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_achievements_user_badge',
        'FUNCTION public.compute_gamification_stats()',
        'FUNCTION public.get_leaderboard(',
        'FUNCTION public.touch_gamification_updated_at()',
      ];
      for (final needle in required) {
        expect(schema, contains(needle), reason: 'missing from schema.sql');
      }
    });

    test('the migration exposes the same snapshot keys as the schema', () {
      expect(statsKeysFromSql(migration), statsKeysFromSql(schema));
    });

    test('the leaderboard only projects non-sensitive columns', () {
      final lower = schema.toLowerCase();
      final start = lower.indexOf('function public.get_leaderboard(');
      final end = lower.indexOf(r'$$;', start);
      final body = lower.substring(start, end);
      expect(body, contains('security definer'));
      for (final safe in <String>[
        'display_name',
        'avatar_url',
        'is_me',
        'streak_days',
      ]) {
        expect(body, contains(safe));
      }
      expect(body, isNot(contains('email')));
    });
  });
}
