import 'package:fitfuel_ai/core/constants/badge_catalog.dart';
import 'package:fitfuel_ai/core/domain/entities/gamification_stats.dart';
import 'package:fitfuel_ai/core/utils/level_system.dart';
import 'package:fitfuel_ai/core/utils/xp_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LevelSystem curve', () {
    test('level 1 starts at zero and each level costs 250 XP more', () {
      expect(LevelSystem.totalXpForLevel(1), 0);
      expect(LevelSystem.totalXpForLevel(2), 500);
      expect(LevelSystem.totalXpForLevel(3), 1250); // 500 + 750
      expect(LevelSystem.totalXpForLevel(4), 2250); // 1250 + 1000
    });

    test('levelForXp is inclusive of each threshold', () {
      expect(LevelSystem.levelForXp(0), 1);
      expect(LevelSystem.levelForXp(-50), 1);
      expect(LevelSystem.levelForXp(499), 1);
      expect(LevelSystem.levelForXp(500), 2);
      expect(LevelSystem.levelForXp(1249), 2);
      expect(LevelSystem.levelForXp(1250), 3);
    });

    test('levelForXp never exceeds maxLevel', () {
      expect(LevelSystem.levelForXp(99999999), LevelSystem.maxLevel);
    });

    test('xpIntoLevel and xpForNextLevel describe the current level', () {
      expect(LevelSystem.xpIntoLevel(600), 100);
      expect(LevelSystem.xpForNextLevel(600), 750);
      expect(LevelSystem.xpForNextLevel(0), 500);
      expect(LevelSystem.xpIntoLevel(500), 0);
    });

    test('levelProgress is a clamped 0..1 fraction', () {
      expect(LevelSystem.levelProgress(0), 0);
      expect(LevelSystem.levelProgress(250), 0.5);
      expect(LevelSystem.levelProgress(500), 0);
      expect(LevelSystem.levelProgress(499), closeTo(0.998, 0.001));
    });

    test('a maxed player has no next level', () {
      final maxXp = LevelSystem.totalXpForLevel(LevelSystem.maxLevel);
      expect(LevelSystem.levelForXp(maxXp), LevelSystem.maxLevel);
      expect(LevelSystem.xpForNextLevel(maxXp), 0);
      expect(LevelSystem.levelProgress(maxXp), 1);
    });

    test('tiers step up at the documented levels', () {
      expect(LevelSystem.tierForLevel(1), 'Bronze');
      expect(LevelSystem.tierForLevel(9), 'Bronze');
      expect(LevelSystem.tierForLevel(10), 'Silver');
      expect(LevelSystem.tierForLevel(19), 'Silver');
      expect(LevelSystem.tierForLevel(20), 'Gold');
      expect(LevelSystem.tierForLevel(34), 'Gold');
      expect(LevelSystem.tierForLevel(35), 'Platinum');
      expect(LevelSystem.tierForLevel(49), 'Platinum');
      expect(LevelSystem.tierForLevel(50), 'Diamond');
      expect(LevelSystem.tierForLevel(LevelSystem.maxLevel), 'Diamond');
    });

    test('nextTier walks the ladder and stops at Diamond', () {
      expect(LevelSystem.nextTier('Bronze'), 'Silver');
      expect(LevelSystem.nextTier('Platinum'), 'Diamond');
      expect(LevelSystem.nextTier('Diamond'), isNull);
      expect(LevelSystem.nextTier('Nonsense'), isNull);
    });
  });

  group('GamificationStats.valueFor', () {
    test('reads every rolling counter the badges rely on', () {
      const stats = GamificationStats(
        currentStreakDays: 4,
        longestStreakDays: 9,
        daysLogged7: 3,
        mealsLogged: 12,
        waterGoalDays30: 2,
        proteinGoalDays30: 5,
        perfectDays30: 1,
        breakfastDays7: 6,
        distinctFoods: 18,
        scansCount: 7,
        weightEntries: 4,
        coachMessages: 2,
        profileComplete: true,
      );
      expect(stats.valueFor('current_streak_days'), 4);
      expect(stats.valueFor('longest_streak_days'), 9);
      expect(stats.valueFor('days_logged_7'), 3);
      expect(stats.valueFor('meals_logged'), 12);
      expect(stats.valueFor('water_goal_days_30'), 2);
      expect(stats.valueFor('protein_goal_days_30'), 5);
      expect(stats.valueFor('perfect_days_30'), 1);
      expect(stats.valueFor('breakfast_days_7'), 6);
      expect(stats.valueFor('distinct_foods'), 18);
      expect(stats.valueFor('scans_count'), 7);
      expect(stats.valueFor('weight_entries'), 4);
      expect(stats.valueFor('coach_messages'), 2);
      expect(stats.valueFor('profile_complete'), 1);
    });

    test('degrades to 0 for an unknown key instead of throwing', () {
      expect(GamificationStats.empty.valueFor('not_a_real_counter'), 0);
    });

    test('fromJson coerces numbers, booleans and jsonb arrays', () {
      final stats = GamificationStats.fromJson(<String, dynamic>{
        'authenticated': true,
        'meals_logged': 30,
        'distinct_foods': 4.0,
        'profile_complete': true,
        'xp_total': 1234,
        'xp_this_week': 90,
        'granted_sources': <dynamic>['meal_logged', 'profile_complete'],
        'granted_sources_today': <dynamic>['meal_logged'],
      });
      expect(stats.mealsLogged, 30);
      expect(stats.distinctFoods, 4);
      expect(stats.profileComplete, isTrue);
      expect(stats.xpTotal, 1234);
      expect(stats.xpThisWeek, 90);
      expect(stats.grantedSources, contains('profile_complete'));
      expect(stats.grantedSourcesToday, <String>{'meal_logged'});
    });

    test('fromJson tolerates a missing payload', () {
      final stats = GamificationStats.fromJson(const <String, dynamic>{});
      expect(stats.mealsLogged, 0);
      expect(stats.grantedSources, isEmpty);
    });
  });

  group('XpEngine.evaluate', () {
    test('a brand new user has every badge locked at 0 progress', () {
      final badges = XpEngine.evaluate(GamificationStats.empty);
      expect(badges.length, BadgeCatalog.all.length);
      expect(badges.every((badge) => !badge.unlocked), isTrue);
      expect(badges.every((badge) => badge.progress == 0), isTrue);
      expect(badges.every((badge) => badge.ratio == 0), isTrue);
    });

    test('progress is clamped to the target so bars cannot overflow', () {
      final badges = XpEngine.evaluate(
        const GamificationStats(currentStreakDays: 30, longestStreakDays: 30),
      );
      final week = badges.firstWhere((badge) => badge.badge.id == 'streak_7');
      expect(week.unlocked, isTrue);
      expect(week.progress, 7); // clamped from the raw 30
      expect(week.ratio, 1.0);

      final month = badges.firstWhere((badge) => badge.badge.id == 'streak_30');
      expect(month.unlocked, isTrue);
      expect(month.progress, 30);

      final centurion =
          badges.firstWhere((badge) => badge.badge.id == 'streak_100');
      expect(centurion.unlocked, isFalse);
      expect(centurion.progress, 30);
      expect(centurion.ratio, closeTo(0.3, 0.001));
    });

    test('unlocked is decided from the raw value, not the clamped one', () {
      final badges = XpEngine.evaluate(
        const GamificationStats(mealsLogged: 250),
      );
      expect(
        badges.firstWhere((badge) => badge.badge.id == 'meals_200').unlocked,
        isTrue,
      );
    });
  });

  group('XpEngine.plan daily awards', () {
    test('an idle day earns nothing at all', () {
      final plan = XpEngine.plan(stats: GamificationStats.empty);
      expect(plan.newAwards, isEmpty);
      expect(plan.newXp, 0);
      expect(plan.pendingBadges, isEmpty);
      expect(plan.isEmpty, isTrue);
    });

    test('a full day earns exactly the documented XP', () {
      final plan = XpEngine.plan(
        stats: const GamificationStats(
          mealLoggedToday: true,
          breakfastToday: true,
          waterGoalHitToday: true,
          weightLoggedToday: true,
          scanToday: true,
          coachToday: true,
          perfectDayToday: true,
          proteinGoalToday: true,
        ),
        today: DateTime(2026, 9, 25),
      );
      expect(plan.newXp, 15 + 5 + 20 + 25 + 10 + 5 + 40 + 30);
      expect(
        plan.newAwards.map((award) => award.source).toSet(),
        XpSource.daily,
      );
      expect(
        plan.newAwards.every((award) => award.date == DateTime(2026, 9, 25)),
        isTrue,
      );
    });

    test('an award already credited today is not repeated', () {
      final plan = XpEngine.plan(
        stats: const GamificationStats(
          mealLoggedToday: true,
          weightLoggedToday: true,
          grantedSourcesToday: <String>{'meal_logged'},
        ),
      );
      expect(
        plan.newAwards.map((award) => award.source),
        <String>['weight_logged'],
      );
      expect(plan.newXp, 25);
    });

    test("only today's meals earn the daily award, not historical ones", () {
      final plan = XpEngine.plan(
        stats: const GamificationStats(mealsLogged: 400, mealsLogged30: 90),
      );
      expect(
        plan.newAwards.where((award) => XpSource.daily.contains(award.source)),
        isEmpty,
      );
    });

    test("an all-time grant does not block today's award", () {
      final plan = XpEngine.plan(
        stats: const GamificationStats(
          mealLoggedToday: true,
          grantedSources: <String>{'meal_logged'},
        ),
      );
      expect(plan.newAwards.single.source, 'meal_logged');
    });
  });

  group('XpEngine.plan one-off awards', () {
    test('profile completion pays out exactly once', () {
      final first = XpEngine.plan(
        stats: const GamificationStats(profileComplete: true),
      );
      expect(
        first.newAwards
            .singleWhere((award) => award.source == XpSource.profileComplete)
            .xp,
        XpRules.profileComplete,
      );

      final repeat = XpEngine.plan(
        stats: const GamificationStats(
          profileComplete: true,
          grantedSources: <String>{'profile_complete'},
        ),
      );
      expect(
        repeat.newAwards.where((award) => award.source == XpSource.profileComplete),
        isEmpty,
      );
    });

    test('every reached streak milestone is paid once, past ones included', () {
      final plan = XpEngine.plan(
        stats: const GamificationStats(currentStreakDays: 7),
      );
      final milestones = plan.newAwards
          .where((award) => award.source.startsWith('streak_milestone_'))
          .toList();
      expect(
        milestones.map((award) => award.source),
        <String>['streak_milestone_3', 'streak_milestone_7'],
      );
      expect(
        milestones.fold<int>(0, (sum, award) => sum + award.xp),
        XpRules.streakMilestones[3]! + XpRules.streakMilestones[7]!,
      );
    });

    test('a streak pays every milestone below it', () {
      final plan = XpEngine.plan(
        stats: const GamificationStats(currentStreakDays: 45),
      );
      final sources = plan.newAwards
          .where((award) => award.source.startsWith('streak_milestone_'))
          .map((award) => award.source)
          .toList();
      expect(sources.length, 4); // 3, 7, 14 and 30 - not yet 100
      expect(sources, isNot(contains('streak_milestone_100')));
    });

    test('unlocking a badge grants its rarity XP exactly once', () {
      final plan = XpEngine.plan(
        stats: const GamificationStats(mealsLogged: 1),
      );
      final badgeAwards = plan.newAwards
          .where((award) => award.source.startsWith('badge_unlock_'))
          .toList();
      expect(badgeAwards.single.source, 'badge_unlock_first_meal');
      expect(badgeAwards.single.xp, BadgeRarity.common.xpReward);
      expect(plan.pendingBadges, hasLength(1));

      final repeat = XpEngine.plan(
        stats: const GamificationStats(
          mealsLogged: 1,
          grantedSources: <String>{'badge_unlock_first_meal'},
        ),
      );
      expect(
        repeat.newAwards.where((a) => a.source.startsWith('badge_unlock_')),
        isEmpty,
      );
    });

    test('one-off award sources are never treated as daily', () {
      expect(XpSource.isOneOff(XpSource.profileComplete), isTrue);
      expect(XpSource.isOneOff(XpSource.streakMilestone(7)), isTrue);
      expect(XpSource.isOneOff(XpSource.badgeUnlock('streak_7')), isTrue);
      expect(XpSource.isOneOff(XpSource.mealLogged), isFalse);
    });
  });

  group('XpEngine.summarize', () {
    final badges = XpEngine.evaluate(
      const GamificationStats(
        currentStreakDays: 7,
        mealsLogged: 60,
        coachMessages: 3,
      ),
    );

    test('resolves level, tier and level progress from the total', () {
      final summary = XpEngine.summarize(
        xpTotal: 600,
        weeklyXp: 140,
        streakDays: 7,
        longestStreakDays: 11,
        badges: badges,
      );
      expect(summary.level, 2);
      expect(summary.tier, 'Bronze');
      expect(summary.xpIntoLevel, 100);
      expect(summary.xpForNextLevel, 750);
      expect(summary.xpToNextLevel, 650);
      expect(summary.levelProgress, closeTo(0.1333, 0.001));
      expect(summary.weeklyXp, 140);
      expect(summary.isMaxLevel, isFalse);
    });

    test('counts unlocked badges and picks the closest remaining one', () {
      // Only the 3-day badge is earned, so the 7-day badge (6/7) is the
      // closest gap in the whole catalog.
      final almostWeek = XpEngine.evaluate(
        const GamificationStats(currentStreakDays: 6),
      );
      final summary = XpEngine.summarize(
        xpTotal: 0,
        weeklyXp: 0,
        streakDays: 6,
        longestStreakDays: 6,
        badges: almostWeek,
      );
      expect(summary.totalBadgeCount, BadgeCatalog.all.length);
      expect(summary.unlockedCount, 1);
      expect(summary.nextMilestone, isNotNull);
      expect(summary.nextMilestone!.badge.id, 'streak_7');
      expect(summary.nextMilestone!.unlocked, isFalse);
      expect(summary.nextMilestone!.progress, 6);
    });

    test('a fully unlocked player has no next milestone', () {
      final allUnlocked = XpEngine.evaluate(GamificationStats.empty)
          .map((badge) => badge.copyWith(unlocked: true))
          .toList();
      final summary = XpEngine.summarize(
        xpTotal: 0,
        weeklyXp: 0,
        streakDays: 0,
        longestStreakDays: 0,
        badges: allUnlocked,
      );
      expect(summary.nextMilestone, isNull);
      expect(summary.unlockedCount, BadgeCatalog.all.length);
    });

    test('most recent unlock prefers a badge earned by the current run', () {
      final stored = badges
          .map((badge) => badge.unlocked
              ? badge.copyWith(unlockedAt: DateTime(2026, 1, 1))
              : badge)
          .toList();
      final withPending = stored
          .map((badge) => badge.badge.id == 'scan_1'
              ? badge.copyWith(unlocked: true)
              : badge)
          .toList();

      final summary = XpEngine.summarize(
        xpTotal: 0,
        weeklyXp: 0,
        streakDays: 0,
        longestStreakDays: 0,
        badges: withPending,
      );
      expect(summary.mostRecentUnlocked!.badge.id, 'scan_1');
      expect(summary.mostRecentUnlocked!.pendingPersistence, isTrue);
    });

    test('falling back to the newest stored unlock when nothing is pending', () {
      final stored = badges
          .map((badge) => badge.badge.id == 'meals_50'
              ? badge.copyWith(unlocked: true, unlockedAt: DateTime(2026, 8, 1))
              : badge.badge.id == 'coach_1'
                  ? badge.copyWith(
                      unlocked: true, unlockedAt: DateTime(2026, 9, 1))
                  : badge.copyWith(unlocked: false))
          .toList();
      final summary = XpEngine.summarize(
        xpTotal: 0,
        weeklyXp: 0,
        streakDays: 0,
        longestStreakDays: 0,
        badges: stored,
      );
      expect(summary.mostRecentUnlocked!.badge.id, 'coach_1');
      expect(summary.mostRecentUnlocked!.pendingPersistence, isFalse);
    });

    test('a user with nothing unlocked has no recent badge', () {
      final summary = XpEngine.summarize(
        xpTotal: 0,
        weeklyXp: 0,
        streakDays: 0,
        longestStreakDays: 0,
        badges: XpEngine.evaluate(GamificationStats.empty),
      );
      expect(summary.mostRecentUnlocked, isNull);
      expect(summary.unlockedCount, 0);
    });
  });
}
